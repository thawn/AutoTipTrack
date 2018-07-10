function value = transformResult( model, x, xe, data )
  value.x = double_error( x(1:2) + data.offset, xe(1:2) );
  value.o = double_error( [] );
  value.w = sqrt( 2.77258872223978 ./ double_error( x(3), xe(3) ) ); % 2.77.. = 4*log(2)
  value.h = double_error( x(4), xe(4) );
  value.r = double_error( [] );
  value.b = data.background;
end