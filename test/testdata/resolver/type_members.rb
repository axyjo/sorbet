# typed: true
# disable-fast-path: true
class CovariantNotAllowed
  extend T::Generic
  Elem = type_member(:in) # error: can only have invariant type members
end

class Invalids
  extend T::Generic
  Exp = type_member(1+1) # error: Invalid param, must be a :symbol
  Baz = type_member(:baz) # error: Invalid variance kind, only `:out` and `:in` are supported
  Mama = type_member("mama") # error: Invalid param, must be a :symbol
  One = type_member(1) # error: Invalid param, must be a :symbol
  ArrOne = type_member([1]) # error: Invalid param, must be a :symbol
  BadArg = type_member(junk: 1)
         # ^^^^^^^^^^^^^^^^^^^^ error: Missing required param `fixed`
         # ^^^^^^^^^^^^^^^^^^^^ error: Unrecognized keyword argument `junk` passed for method
                           # ^ error: Unsupported type syntax
end


class Parent
  extend T::Generic
  Elem = type_member
end

class GoodChild < Parent
  extend T::Generic
  Elem = type_member
  My = type_member
end

class BadChild1 < Parent
  extend T::Generic
  My = type_member
  Elem = type_member # error: Type members in wrong order
end

class BadChild2 < Parent # error: must be re-declared
  extend T::Generic
  My = type_member
end

class BadChild3 < Parent
  Elem = 3 # error: Type variable `Elem` needs to be declared as `= type_member(SOMETHING)`
end
