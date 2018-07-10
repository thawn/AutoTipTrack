function r = reshape( a, varargin )
%RESHAPE reshapes an array
  
  switch numel( varargin )
    case 1
      r = double_error( reshape( a.value, varargin{1} ), ...
                        reshape( a.error, varargin{1} ) );
    case 2
      r = double_error( reshape( a.value, varargin{1}, varargin{2} ), ...
                        reshape( a.error, varargin{1}, varargin{2} ) );
    case 3
      r = double_error( reshape( a.value, varargin{1}, varargin{2}, varargin{3} ), ...
                        reshape( a.error, varargin{1}, varargin{2}, varargin{3} ) );
    otherwise
      error( 'MPICBG:FIESTA:unsupportedOpertaion', 'This reshape operation is not implemented yet' );
  end
end