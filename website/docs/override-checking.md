---
id: override-checking
title: Override Checking
---

Sorbet supports method override checking. These checks are implemented as `sig`
annotations:

- `overridable` means children can override this method
- `override` means this method overrides a method on its parent (or ancestor)
- `abstract` means this method is abstract (has no implementation) and must be
  implemented by being overridden in all concrete subclasses.
- `implementation` means this method implements an abstract method

These annotations can be chained, for example `.implementation.overridable` lets
a grandchild class override a concrete implementation of its parent.

Use this table to track when annotations can be used, although the error
messages are the canonical source of truth. ✅ means "this pairing is allowed"
while ❌ means "this is an error" (most of these errors are static errors,
though some are still only implemented in the runtime).

> Below, `standard` (for the child or parent) means "has a `sig`, but has none
> of the special modifiers."

| ↓Parent \ Child → | no sig | `standard` | `override` | `implementation` |
| ----------------- | :----: | :--------: | :--------: | :--------------: |
| no sig            |   ✅   |     ✅     |     ✅     |        ❌        |
| `standard`        |   ✅   |     ✅     |     ❌     |        ❌        |
| `overridable`     |   ✅   |     ❌     |     ✅     |        ❌        |
| `override`        |   ✅   |     ❌     |     ✅     |        ❌        |
| `implementation`  |   ✅   |     ❌     |     ❌     |        ❌        |
| `abstract`        |   ✅   |     ❌     |     ❌     |        ✅        |

Some other things are checked that don't fit into the above table:

- It is an error to mark a method `override` or `implementation` if the method
  doesn't actually override anything.
- If the implementation methods are inherited--from either a class or mixin--the
  methods don't need the `implementation` annotation.

Note that the **absence** of `abstract` or `overridable` does **not** mean that
a method is never overridden. To declare that a method can never be overridden,
look into [final methods](final.md).

## What's next?

- [Final Methods, Classes, and Modules](final.md)

  Learn how to prohibit overriding entirely, both at the method level and the
  class level.

- [Abstract Classes and Interfaces](abstract.md)

  Marking methods as `abstract` and requiring child classes to implement them is
  a powerful tool for code organization and correctness. Learn more about
  Sorbet's support for abstract classes and interfaces.
