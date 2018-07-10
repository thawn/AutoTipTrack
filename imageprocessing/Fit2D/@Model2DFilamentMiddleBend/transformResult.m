function value = transformResult( model, x, xe, data )
  value.x = double_error( x(1) * [ -sin( x(2) ) cos( x(2) ) ] + ...
                            + model.img_size / 2 + 0.5 + data.offset, ...
                          abs( [ sin( x(2) ) cos( x(2) ) ] ) * xe(1) );
  value.o = double_error( mod( x(2), 2*pi ), xe(2) );
  value.w = sqrt( 2.77258872223978 ./ double_error( x(4), xe(4) ) ); % 2.77.. = 4*log(2)
  value.h = double_error( x(5), xe(5) );
  value.r = double_error( [] );  
  % the curvature is ignored!
  value.b = data.background;
end
  