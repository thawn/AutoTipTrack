function r = ne( a, b )
%NE checks, if the value of a is not equal to the value of b

  r = double( a.value ) ~= double( b.value );
end
