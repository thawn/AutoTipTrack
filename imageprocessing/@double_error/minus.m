function s = minus( a, b )
%MINUS calculates the difference between two values 

  a = double_error( a );
  b = double_error( b );
  s = double_error( a.value - b.value, a.error + b.error );
end