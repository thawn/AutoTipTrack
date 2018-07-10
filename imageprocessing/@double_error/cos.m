function a = cos( a )
%COS returns the cosine value of the double_error variable with estimated errors

  a.value = cos( a.value );
  a.error = abs( sin( a.value ) .* a.error );
  a.error( a.error > 2 ) = 2;
end