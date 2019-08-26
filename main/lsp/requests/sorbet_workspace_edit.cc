#include "absl/strings/match.h"
#include "common/FileOps.h"
#include "core/lsp/QueryResponse.h"
#include "main/lsp/lsp.h"

using namespace std;

namespace sorbet::realmain::lsp {

string readFile(string_view path, const FileSystem &fs) {
    try {
        return fs.readFile(path);
    } catch (FileNotFoundException e) {
        // Act as if file is completely empty.
        // NOTE: It is not appropriate to throw an error here. Sorbet does not differentiate between Watchman updates
        // that specify if a file has changed or has been deleted, so this is the 'golden path' for deleted files.
        // TODO(jvilk): Use Tombstone files instead.
        return "";
    }
}

string_view LSPLoop::getFileContents(UnorderedMap<string, LSPLoop::SorbetWorkspaceFileUpdate> &updates,
                                     const core::GlobalState &initialGS, string_view path) {
    if (updates.find(path) != updates.end()) {
        return updates[path].contents;
    }

    auto currentFileRef = initialGS.findFileByPath(path);
    if (currentFileRef.exists()) {
        return currentFileRef.data(initialGS).source();
    } else {
        return "";
    }
}

void LSPLoop::preprocessSorbetWorkspaceEdit(const DidChangeTextDocumentParams &changeParams,
                                            UnorderedMap<string, LSPLoop::SorbetWorkspaceFileUpdate> &updates) const {
    string_view uri = changeParams.textDocument->uri;
    if (absl::StartsWith(uri, rootUri)) {
        string localPath = remoteName2Local(uri);
        if (FileOps::isFileIgnored(rootPath, localPath, opts.absoluteIgnorePatterns, opts.relativeIgnorePatterns)) {
            return;
        }
        string fileContents = string(getFileContents(updates, *initialGS, localPath));
        for (auto &change : changeParams.contentChanges) {
            if (change->range) {
                auto &range = *change->range;
                // incremental update
                core::Loc::Detail start, end;
                start.line = range->start->line + 1;
                start.column = range->start->character + 1;
                end.line = range->end->line + 1;
                end.column = range->end->character + 1;
                core::File old(string(localPath), string(fileContents), core::File::Type::Normal);
                auto startOffset = core::Loc::pos2Offset(old, start);
                auto endOffset = core::Loc::pos2Offset(old, end);
                fileContents = fileContents.replace(startOffset, endOffset - startOffset, change->text);
            } else {
                // replace
                fileContents = change->text;
            }
        }
        // Preserve opened/closed flags.
        updates[localPath].contents = fileContents;
    }
}

void LSPLoop::preprocessSorbetWorkspaceEdit(const DidOpenTextDocumentParams &openParams,
                                            UnorderedMap<string, LSPLoop::SorbetWorkspaceFileUpdate> &updates) const {
    string_view uri = openParams.textDocument->uri;
    if (absl::StartsWith(uri, rootUri)) {
        string localPath = remoteName2Local(uri);
        if (!FileOps::isFileIgnored(rootPath, localPath, opts.absoluteIgnorePatterns, opts.relativeIgnorePatterns)) {
            // File is now open, so reset closed flag.
            updates[localPath] = {move(openParams.textDocument->text), /* newlyOpened */ true, /* newlyClosed */ false};
        }
    }
}

void LSPLoop::preprocessSorbetWorkspaceEdit(const DidCloseTextDocumentParams &closeParams,
                                            UnorderedMap<string, LSPLoop::SorbetWorkspaceFileUpdate> &updates) const {
    string_view uri = closeParams.textDocument->uri;
    if (absl::StartsWith(uri, rootUri)) {
        string localPath = remoteName2Local(uri);
        if (!FileOps::isFileIgnored(rootPath, localPath, opts.absoluteIgnorePatterns, opts.relativeIgnorePatterns)) {
            // File is now closed. Use contents of file on disk, reset open flag, set closed flag.
            updates[localPath] = {readFile(localPath, *opts.fs), /* newlyOpened */ false, /* newlyClosed */ true};
        }
    }
}

void LSPLoop::preprocessSorbetWorkspaceEdit(const WatchmanQueryResponse &queryResponse,
                                            UnorderedMap<string, LSPLoop::SorbetWorkspaceFileUpdate> &updates) const {
    for (auto file : queryResponse.files) {
        string localPath = absl::StrCat(rootPath, "/", file);
        if (!FileOps::isFileIgnored(rootPath, localPath, opts.absoluteIgnorePatterns, opts.relativeIgnorePatterns)) {
            auto &entry = updates[localPath];
            const bool isFileOpenInEditor = entry.newlyOpened || (openFiles.contains(localPath) && !entry.newlyClosed);
            // Editor contents supercede file system updates.
            if (!isFileOpenInEditor) {
                entry.contents = readFile(localPath, *opts.fs);
            }
        }
    }
}

LSPLoop::TypecheckRun
LSPLoop::commitSorbetWorkspaceEdits(unique_ptr<core::GlobalState> gs, int msgEpoch,
                                    UnorderedMap<string, LSPLoop::SorbetWorkspaceFileUpdate> &updates) const {
    if (!updates.empty()) {
        FileUpdates fileUpdates;
        fileUpdates.updateEpoch = msgEpoch;
        fileUpdates.updatedFiles.reserve(updates.size());
        for (auto &update : updates) {
            auto file =
                make_shared<core::File>(string(update.first), move(update.second.contents), core::File::Type::Normal);
            if (update.second.newlyClosed) {
                fileUpdates.closedFiles.push_back(string(file->path()));
            }
            if (update.second.newlyOpened) {
                fileUpdates.openedFiles.push_back(string(file->path()));
            }
            fileUpdates.updatedFiles.push_back(move(file));
        }
        return runTypechecking(move(gs), move(fileUpdates));
    } else {
        return TypecheckRun(move(gs));
    }
}

LSPLoop::TypecheckRun LSPLoop::handleSorbetWorkspaceEdit(unique_ptr<core::GlobalState> gs, int msgEpoch,
                                                         const DidChangeTextDocumentParams &changeParams) const {
    UnorderedMap<string, LSPLoop::SorbetWorkspaceFileUpdate> updates;
    preprocessSorbetWorkspaceEdit(changeParams, updates);
    return commitSorbetWorkspaceEdits(move(gs), msgEpoch, updates);
}

LSPLoop::TypecheckRun LSPLoop::handleSorbetWorkspaceEdit(unique_ptr<core::GlobalState> gs, int msgEpoch,
                                                         const DidOpenTextDocumentParams &openParams) const {
    UnorderedMap<string, LSPLoop::SorbetWorkspaceFileUpdate> updates;
    preprocessSorbetWorkspaceEdit(openParams, updates);
    return commitSorbetWorkspaceEdits(move(gs), msgEpoch, updates);
}

LSPLoop::TypecheckRun LSPLoop::handleSorbetWorkspaceEdit(unique_ptr<core::GlobalState> gs, int msgEpoch,
                                                         const DidCloseTextDocumentParams &closeParams) const {
    UnorderedMap<string, LSPLoop::SorbetWorkspaceFileUpdate> updates;
    preprocessSorbetWorkspaceEdit(closeParams, updates);
    return commitSorbetWorkspaceEdits(move(gs), msgEpoch, updates);
}

LSPLoop::TypecheckRun LSPLoop::handleSorbetWorkspaceEdit(unique_ptr<core::GlobalState> gs, int msgEpoch,
                                                         const WatchmanQueryResponse &queryResponse) const {
    UnorderedMap<string, LSPLoop::SorbetWorkspaceFileUpdate> updates;
    preprocessSorbetWorkspaceEdit(queryResponse, updates);
    return commitSorbetWorkspaceEdits(move(gs), msgEpoch, updates);
}

LSPLoop::TypecheckRun LSPLoop::handleSorbetWorkspaceEdits(unique_ptr<core::GlobalState> gs, int msgEpoch,
                                                          vector<unique_ptr<SorbetWorkspaceEdit>> &edits) const {
    // path => new file contents
    UnorderedMap<string, LSPLoop::SorbetWorkspaceFileUpdate> updates;
    for (auto &edit : edits) {
        switch (edit->type) {
            case SorbetWorkspaceEditType::EditorOpen: {
                preprocessSorbetWorkspaceEdit(*get<unique_ptr<DidOpenTextDocumentParams>>(edit->contents), updates);
                break;
            }
            case SorbetWorkspaceEditType::EditorChange: {
                preprocessSorbetWorkspaceEdit(*get<unique_ptr<DidChangeTextDocumentParams>>(edit->contents), updates);
                break;
            }
            case SorbetWorkspaceEditType::EditorClose: {
                preprocessSorbetWorkspaceEdit(*get<unique_ptr<DidCloseTextDocumentParams>>(edit->contents), updates);
                break;
            }
            case SorbetWorkspaceEditType::FileSystem: {
                preprocessSorbetWorkspaceEdit(*get<unique_ptr<WatchmanQueryResponse>>(edit->contents), updates);
                break;
            }
        }
    }
    return commitSorbetWorkspaceEdits(move(gs), msgEpoch, updates);
}

} // namespace sorbet::realmain::lsp
