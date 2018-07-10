function s = sum( a, dim )
%SUM computes the sum of double_error values
  if nargin == 1
    s = double_error( sum( a.value ), sum( a.error ) );
  else
    s = double_error( sum( a.value, dim ), sum( a.error, dim ) );
  end
end
  