function y = mean(x,dim)
%MEAN   Average or mean value.

  if nargin==1
    % Determine which dimension SUM will use
    dim = find(size(x)~=1, 1 );
    if isempty(dim), dim = 1; end

    y = sum(x) ./ size(x,dim);
  else
    y = sum(x,dim) ./ size(x,dim);
  end
end