function e = double_error( value, error )
%DOUBLE_ERROR creates a new variable of type 'double_error'.
%The data type is used to compute values and their errors using an error
%estimation known as "Propagation of uncertainty" assuming that the errors are
%uncorrelated. The contributions of each input variables are not summed up by
%taking the square root of the sum of the squares, but by directly adding the
%contributions, thus leading to a slightly larger error and much faster calculation.

  if nargin == 0
    e.value = [];
    e.error = [];
    e = class( e, 'double_error' );
  elseif nargin == 1
    if isa( value, 'double_error' )
      e = value;
    else
      e.value = value;
      e.error = zeros( size( value ), class( value ) );
      e = class( e, 'double_error' );
    end
  elseif nargin == 2
    if any( size( value ) ~= size( error ) )
      error( 'MPICBG:FIESTA:wrongDimensions', ...
             'The value and the error matrix have to have the same shape.' );
    end
    e.value = value;
    e.error = abs( error );
    e = class( e, 'double_error' );
  end
end