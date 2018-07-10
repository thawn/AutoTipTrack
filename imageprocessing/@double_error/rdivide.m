function s = rdivide( a, b )
%RDIVIDE divides a by b

  a = double_error( a );
  b = double_error( b );
  s = double_error( a.value ./ b.value );
  s.error = abs( a.error ./ b.value ) + abs( b.error .* s.value ./ b.value );
end