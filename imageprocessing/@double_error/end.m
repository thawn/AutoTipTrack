function e = end( a, k, n )
%END is used for colon statements

  if n == 1
    e = numel( a.value );
  else
    e = size( a.value, k );
  end
end