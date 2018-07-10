function [ f, xb ] = evaluate( model, x, fitpic )
  
  if nargout == 1 % calculate value of function
    f = x(6) * exp( - ( x(3) * (fitpic.xg-x(1)).^2 +...
                        x(4) * (fitpic.xg-x(1)) .* (fitpic.yg-x(2)) +...
                        x(5) * (fitpic.yg-x(2)).^2 ) );  
                
  else % calculate value of function and jacobian 'xb'
    xb = zeros( numel( fitpic.xg ), 6 ); % allocate memory
    
    % calculate temporary variables and value of function in ...
    % ... forward direction
    tempx = (fitpic.xg-x(1));
    tempy = (fitpic.yg-x(2));
    
    temp = x(3) * tempx.^2 + x(4) * tempx .* tempy + x(5) * tempy.^2;
    % ... backward direction
    tempb = exp(-temp);
    f = x(6) .* tempb;
    
    % calculate derivative
    xb(:,1) = - (2 * tempx * x(3) + x(4) * tempy) .* f;
    xb(:,2) = - (2 * tempy * x(5) + x(4) * tempx) .* f;
    xb(:,3) = tempx.^2 .* f;
    xb(:,4) = tempy .* tempy .* f;
    xb(:,5) = tempy.^2 .* f;
    xb(:,6) = - tempb;
  end
  
end