function [varargout] = min( a, b, dim )
%MIN is the equivalent to the standard MatLab 'min' function

  if nargin == 1
    [varargout{1:nargout}] = min( a.value );
  elseif nargin == 2
    [varargout{1:nargout}] = min( a.value, b.value );
  elseif nargin == 3
    [varargout{1:nargout}] = min( a.value, [], dim );
  end
end
