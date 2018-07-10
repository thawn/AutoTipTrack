function e = floor( e )
%FLOOR returns the rounded value of the double_error variable with integer error
  
  e.value = floor( e.value );
  e.error = ceil( e.error );
end
