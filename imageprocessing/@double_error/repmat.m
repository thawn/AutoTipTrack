function r = repmat( a, M, N )
%REPMAT replicates and tiles an array
  
  if nargin == 3
    r = double_error( repmat( a.value, M, N ), repmat( a.error, M, N ) );
  else
    r = double_error( repmat( a.value, M ), repmat( a.error, M ) );
  end
end