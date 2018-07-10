function a = sin( a )
%SIN returns the sine value of the double_error variable with estimated errors

  a.value = sin( a.value );
  a.error = abs( cos( a.value ) .* a.error );
  a.error( a.error > 2 ) = 2;
end