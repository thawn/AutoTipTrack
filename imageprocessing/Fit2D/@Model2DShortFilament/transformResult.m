function value = transformResult( model, x, xe, data )
  value.x(1:2,1:2) = double_error( ...
    [ x(1:2) + data.offset ; x(3:4) + data.offset ], ...
    [ xe(1:2)              ; xe(3:4)              ] ...
  );
  % error calculation done by overloaded atan2 of class double_error!
  value.o = atan2( value.x(1,2) - value.x(2,2), value.x(1,1) - value.x(2,1) );
  value.w = sqrt( 2.77258872223978  ./ double_error( x(5), xe(5) ) ); % 2.77.. = 4*log(2)
  value.h = double_error( x(6), xe(6) );
  value.r = double_error( [] );
  value.b = data.background;
end