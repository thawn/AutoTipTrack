function r = eq( a, b )
%EQ checks, if the values of a and b are identically

  a = double_error( a );
  b = double_error( b );
  r = ( a.value == b.value );
end
