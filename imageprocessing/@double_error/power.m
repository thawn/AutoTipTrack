function a = power( b, q )
%POWER calculates the value b to the power of c
  
  a = double_error( power( b.value, q ) );
  a.error = abs( q .* a.value ./ b.value .* b.error );
end
