function [varargout] = max( a, b, dim )
%MAX is the equivalent to the standard MatLab 'max' function

  if nargin == 1
    [varargout{1:nargout}] = max( a.value );
  elseif nargin == 2
    [varargout{1:nargout}] = max( a.value, b.value );
  elseif nargin == 3
    [varargout{1:nargout}] = max( a.value, [], dim );
  end
end
