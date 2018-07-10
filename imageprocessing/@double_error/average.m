function y = average( x, dim )
%AVERAGE  Average or mean value, while the error will be determined using the
%standard deviation instead of just averiging the error values, as would be the
%case with mean()
  
  if nargin==1
    y = double_error( mean(x.value), std(x.value) );
  else
    y = double_error( mean( x.value, dim ), std( x.value, 0, dim ) );
  end
end