function a = mod( a, v )
%MOD Modulus after division

  a.value = mod( a.value, v );
  a.error( a.error > v ) = v;
end