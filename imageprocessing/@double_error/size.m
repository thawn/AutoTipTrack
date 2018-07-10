function s = size( a, dim )
%SIZE returnes the size of a
  
  if nargin > 1
    s = size( a.value, dim );
  else
    s = size( a.value );
  end
end