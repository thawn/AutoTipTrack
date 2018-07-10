function value = transformResult( model, x, xe, data )
  value.x = double_error( x(1:2) + data.offset, xe(1:2) );
  value.o = double_error( [] );
  value.w(1) = sqrt( double_error( x(3), xe(3) ) * 2.77258872223978 ); % 2.77.. = 4*log(2)
  value.h(1) = double_error( x(4), xe(4) );
  value.r(1) = double_error( 0, 0);
  value.w(2) = double_error( 0, 0);
  value.h(2) = double_error( 0, 0);
  value.r(2) = double_error( 0, 0);   
  value.w(3) = sqrt( double_error( x(5), xe(5) ) * 2.77258872223978 ); % 2.77.. = 4*log(2)
  value.h(3) = double_error( x(6), xe(6) );
  value.r(3) = double_error( x(7), xe(7) ); 
  value.b = data.background;
end