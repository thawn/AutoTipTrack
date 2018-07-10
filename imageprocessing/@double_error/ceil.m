function e = ceil( e )
%CEIL returns the rounded value of the double_error variable with integer error

  e.value = ceil( e.value );
  e.error = ceil( e.error );
end