function s = plus( a, b )
%PLUS adds the two values a and b

  a = double_error( a );
  b = double_error( b );
  s = double_error( a.value + b.value, a.error + b.error );
end