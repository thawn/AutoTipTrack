function value = transformResult( model, x, xe, data )
  value.x = double_error( x(1:2) + data.offset, xe(1:2) );
  value.o = double_error( [] );
  
  % rearrange width parameters
  value.w(1:3) = double_error( zeros(1,3) ); % init width values
  
  A = double_error( x(3), xe(3) );
  B = double_error( x(4), xe(4) );
  C = double_error( x(5), xe(5) );
  
  tempd1 = A+C;
  tempd2 = sqrt(B.^2+(A-C).^2);
  tempn =  A.*C - B.^2./4;
  
  value.w(1) = 0.5 * sqrt( (tempd1+tempd2)./tempn) * 2*sqrt(2*log(2));
  value.w(2) = 0.5 * sqrt( (tempd1-tempd2)./tempn) * 2*sqrt(2*log(2));
  
  if x(3) < x(5)
    value.w(3) = 0.5*atan(B./(A-C)); 
  elseif x(3) == x(5)
    value.w(2) = []; 
  else
     value.w(3) = 0.5*atan(B./(A-C)) + pi/2; 
  end
  
  value.h = double_error( x(6), xe(6) );
  value.r = double_error( [] );  
  value.b = data.background;
end