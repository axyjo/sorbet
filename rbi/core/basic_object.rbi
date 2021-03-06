# typed: __STDLIB_INTERNAL

# [BasicObject](BasicObject) is the parent class of
# all classes in Ruby. It's an explicit blank class.
#
# [BasicObject](BasicObject) can be used for creating
# object hierarchies independent of Ruby's object hierarchy, proxy objects
# like the Delegator class, or other uses where namespace pollution from
# Ruby's methods and classes must be avoided.
#
# To avoid polluting [BasicObject](BasicObject) for
# other users an appropriately named subclass of
# [BasicObject](BasicObject) should be created instead
# of directly modifying BasicObject:
#
# ```ruby
# class MyObjectSystem < BasicObject
# end
# ```
#
# [BasicObject](BasicObject) does not include
# [Kernel](https://ruby-doc.org/core-2.6.3/Kernel.html) (for methods like
# `puts` ) and [BasicObject](BasicObject) is outside
# of the namespace of the standard library so common classes will not be
# found without using a full class path.
#
# A variety of strategies can be used to provide useful portions of the
# standard library to subclasses of
# [BasicObject](BasicObject). A subclass could
# `include Kernel` to obtain `puts`, `exit`, etc. A custom Kernel-like
# module could be created and included or delegation can be used via
# [method\_missing](BasicObject#method-i-method_missing)
# :
#
# ```ruby
# class MyObjectSystem < BasicObject
#   DELEGATE = [:puts, :p]
#
#   def method_missing(name, *args, &block)
#     super unless DELEGATE.include? name
#     ::Kernel.send(name, *args, &block)
#   end
#
#   def respond_to_missing?(name, include_private = false)
#     DELEGATE.include?(name) or super
#   end
# end
# ```
#
# Access to classes and modules from the Ruby standard library can be
# obtained in a [BasicObject](BasicObject) subclass by
# referencing the desired constant from the root like `::File` or
# `::Enumerator` . Like
# [method\_missing](BasicObject#method-i-method_missing)
# , const\_missing can be used to delegate constant lookup to `Object` :
#
# ```ruby
# class MyObjectSystem < BasicObject
#   def self.const_missing(name)
#     ::Object.const_get(name)
#   end
# end
# ```
class BasicObject
  # Boolean negate.
  sig {returns(T::Boolean)}
  def !(); end

  # Returns true if two objects are not-equal, otherwise false.
  sig do
    params(
        other: BasicObject,
    )
    .returns(T::Boolean)
  end
  def !=(other); end

  # Equality — At the `Object` level, `==` returns `true` only if `obj` and
  # `other` are the same object. Typically, this method is overridden in
  # descendant classes to provide class-specific meaning.
  #
  # Unlike `==`, the `equal?` method should never be overridden by
  # subclasses as it is used to determine object identity (that is,
  # `a.equal?(b)` if and only if `a` is the same object as `b` ):
  #
  # ```ruby
  # obj = "a"
  # other = obj.dup
  #
  # obj == other      #=> true
  # obj.equal? other  #=> false
  # obj.equal? obj    #=> true
  # ```
  #
  # The `eql?` method returns `true` if `obj` and `other` refer to the same
  # hash key. This is used by
  # [Hash](https://ruby-doc.org/core-2.6.3/Hash.html) to test members for
  # equality. For objects of class `Object`, `eql?` is synonymous with `==`
  # . Subclasses normally continue this tradition by aliasing `eql?` to
  # their overridden `==` method, but there are exceptions. `Numeric` types,
  # for example, perform type conversion across `==`, but not across `eql?`
  # , so:
  #
  # ```ruby
  # 1 == 1.0     #=> true
  # 1.eql? 1.0   #=> false
  # ```
  sig do
    params(
        other: BasicObject,
    )
    .returns(T::Boolean)
  end
  def ==(other); end

  # Returns an integer identifier for `obj` .
  #
  # The same number will be returned on all calls to `object_id` for a given
  # object, and no two active objects will share an id.
  #
  # Note: that some objects of builtin classes are reused for optimization.
  # This is the case for immediate values and frozen string literals.
  #
  # Immediate values are not passed by reference but are passed by value:
  # `nil`, `true`, `false`, Fixnums, Symbols, and some Floats.
  #
  # ```ruby
  # Object.new.object_id  == Object.new.object_id  # => false
  # (21 * 2).object_id    == (21 * 2).object_id    # => true
  # "hello".object_id     == "hello".object_id     # => false
  # "hi".freeze.object_id == "hi".freeze.object_id # => true
  # ```
  sig {returns(Integer)}
  def __id__(); end

  # Invokes the method identified by *symbol* , passing it any arguments
  # specified. You can use `__send__` if the name `send` clashes with an
  # existing method in *obj* . When the method is identified by a string,
  # the string is converted to a symbol.
  #
  # ```ruby
  # class Klass
  #   def hello(*args)
  #     "Hello " + args.join(' ')
  #   end
  # end
  # k = Klass.new
  # k.send :hello, "gentle", "readers"   #=> "Hello gentle readers"
  # ```
  sig do
    params(
        arg0: Symbol,
        arg1: BasicObject,
    )
    .returns(T.untyped)
  end
  def __send__(arg0, *arg1); end

  # Equality — At the `Object` level, `==` returns `true` only if `obj` and
  # `other` are the same object. Typically, this method is overridden in
  # descendant classes to provide class-specific meaning.
  #
  # Unlike `==`, the `equal?` method should never be overridden by
  # subclasses as it is used to determine object identity (that is,
  # `a.equal?(b)` if and only if `a` is the same object as `b` ):
  #
  # ```ruby
  # obj = "a"
  # other = obj.dup
  #
  # obj == other      #=> true
  # obj.equal? other  #=> false
  # obj.equal? obj    #=> true
  # ```
  #
  # The `eql?` method returns `true` if `obj` and `other` refer to the same
  # hash key. This is used by
  # [Hash](https://ruby-doc.org/core-2.6.3/Hash.html) to test members for
  # equality. For objects of class `Object`, `eql?` is synonymous with `==`
  # . Subclasses normally continue this tradition by aliasing `eql?` to
  # their overridden `==` method, but there are exceptions. `Numeric` types,
  # for example, perform type conversion across `==`, but not across `eql?`
  # , so:
  #
  # ```ruby
  # 1 == 1.0     #=> true
  # 1.eql? 1.0   #=> false
  # ```
  sig do
    params(
        other: BasicObject,
    )
    .returns(T::Boolean)
  end
  def equal?(other); end

  # Evaluates a string containing Ruby source code, or the given block,
  # within the context of the receiver ( *obj* ). In order to set the
  # context, the variable `self` is set to *obj* while the code is
  # executing, giving the code access to *obj* ’s instance variables and
  # private methods.
  #
  # When `instance_eval` is given a block, *obj* is also passed in as the
  # block’s only argument.
  #
  # When `instance_eval` is given a `String`, the optional second and third
  # parameters supply a filename and starting line number that are used when
  # reporting compilation errors.
  #
  # ```ruby
  # class KlassWithSecret
  #   def initialize
  #     @secret = 99
  #   end
  #   private
  #   def the_secret
  #     "Ssssh! The secret is #{@secret}."
  #   end
  # end
  # k = KlassWithSecret.new
  # k.instance_eval { @secret }          #=> 99
  # k.instance_eval { the_secret }       #=> "Ssssh! The secret is 99."
  # k.instance_eval {|obj| obj == self } #=> true
  # ```
  sig do
    params(
        arg0: String,
        filename: String,
        lineno: Integer,
    )
    .returns(T.untyped)
  end
  sig do
    type_parameters(:U)
    .params(
        blk: T.proc.bind(T.untyped).params().returns(T.type_parameter(:U)),
    )
    .returns(T.type_parameter(:U))
  end
  def instance_eval(arg0=T.unsafe(nil), filename=T.unsafe(nil), lineno=T.unsafe(nil), &blk); end

  # Executes the given block within the context of the receiver ( *obj* ).
  # In order to set the context, the variable `self` is set to *obj* while
  # the code is executing, giving the code access to *obj* ’s instance
  # variables. Arguments are passed as block parameters.
  #
  # ```ruby
  # class KlassWithSecret
  #   def initialize
  #     @secret = 99
  #   end
  # end
  # k = KlassWithSecret.new
  # k.instance_exec(5) {|x| @secret+x }   #=> 104
  # ```
  sig do
    type_parameters(:U, :V)
    .params(
        args: T.type_parameter(:V),
        blk: T.proc.bind(T.untyped).params(args: T.untyped).returns(T.type_parameter(:U)),
    )
    .returns(T.type_parameter(:U))
  end
  def instance_exec(*args, &blk); end
end
