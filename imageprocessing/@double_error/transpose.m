function e = transpose( e )
%TRANSPOSE transposes the matrix e

  e.value = transpose( e.value );
  e.error = transpose( e.error );
end
