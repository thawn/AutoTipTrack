function p = mtimes( a, b )
%MTIMES calculates the Matrix product of a and b

  a = double_error( a );
  b = double_error( b );
  p = double_error( a.value * b.value, ...
        abs( b.value * a.error ) + abs( a.value * b.error ) );
end