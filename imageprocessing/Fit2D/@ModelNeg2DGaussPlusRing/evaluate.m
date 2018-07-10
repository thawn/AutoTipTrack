function [ f, xb ] = evaluate( model, x, fitpic )
  
  if nargout == 1 % calculate value of function
    

    f = - x(4) .* exp( -( ( fitpic.xg-x(1) ).^2 + ( fitpic.yg-x(2) ).^2 ) / x(3) )...
      + x(6) .* exp( -(  abs( ( fitpic.xg -x(1) ).^2 + ( fitpic.yg-x(2) ).^2 - x(7).^2 ) ) / x(5) );

    f = x(4) .* exp( -( ( fitpic.xg-x(1) ).^2 + ( fitpic.yg-x(2) ).^2 ) / x(3) )...
      + x(6) .* exp( -( abs( ( fitpic.xg -x(1) ).^2 + ( fitpic.yg-x(2) ).^2 - x(7).^2 ) ) / x(5) );

  
  else % calculate value of function and jacobian 'xb'
    error( 'jacobian calculation not implemented' );
%     xb = zeros( numel( fitpic.xg ), 4 ); % allocate memory
% 
%     % calculate temporary variables and value of function
%     temp =( (fitpic.xg-x(1)).^2 + (fitpic.yg-x(2)).^2 ) ./ x(3);
%     tempa = exp( -temp );
%     f =  x(4) .* tempa;
%     tempb = - ( f ./ x(3) );
%     
%     % calculate derivative
%     xb(:,1) = 2.0 .* (fitpic.xg-x(1)) .* tempb;
%     xb(:,2) = 2.0 .* (fitpic.yg-x(2)) .* tempb;
%     xb(:,3) = temp .* tempb;
%     xb(:,4) = - tempa;
  end
  
end