function a = tan( a )
%TAN calculates the tangens of a with an error estimation

  a.value = tan( a.value );
  a.error = abs( ( 1 + a.value.^2 ) .* a.error );
end