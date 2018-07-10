function s = times( a, b )
%TIMES calculates the product of a and b

  a = double_error( a );
  b = double_error( b );
  s = double_error( a.value .* b.value, ...
        abs( b.value .* a.error ) + abs( a.value .* b.error ) );
end