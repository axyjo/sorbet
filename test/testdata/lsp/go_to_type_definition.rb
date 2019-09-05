# typed: true

class A; end
#     ^ type-def: A

class B
  extend T::Sig

  sig {returns(A)}
  def self.returns_A; A.new; end
end

class TestClass
  a = A.new
# ^ type: A
  puts a
#      ^ type: A

  puts B.returns_A
#        ^ type: A
end

# TODO(jez) T.class_of?
# TODO(jez) method?
# TODO(jez) self.method?
# TODO(jez) local variable?
# TODO(jez) union type?
# TODO(jez) intersection type?
# TODO(jez) more than one level of nesting?
