function e = round( e )
%ROUND returns the rounded value of the double_error variable with integer error

  e.value = round( e.value );
  e.error = ceil( e.error );
end