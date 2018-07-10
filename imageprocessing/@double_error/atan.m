function a = atan( a )
%ATAN calculates the arc tangens of a with an error estimation

  a.value = atan( a.value );
  a.error = abs( 1/( 1 + a.value.^2 ) .* a.error );
end