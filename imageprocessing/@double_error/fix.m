function e = fix( e )
%FIX returns the rounded value of the double_error variable with integer error

  e.value = fix( e.value );
  e.error = ceil( e.error );
end
