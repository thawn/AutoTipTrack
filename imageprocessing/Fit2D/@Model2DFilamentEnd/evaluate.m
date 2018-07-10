function [ f, xb ] = evaluate( model, x ,fitpic)
  
  if nargout == 1 % calculate value of function
    
    w = HalfPlane( [ x(1:2) x(3) - pi/2 ], fitpic );
    f = x(5) * ( w .* ( exp( -x(4) * ( (fitpic.xg-x(1)).^2 + (fitpic.yg-x(2)).^2 )  ) ) + ...
               ( 1 - w ) .* GaussianStrip( x(1:4), fitpic ) );
  
  else % calculate value of function and jacobian 'xb'

    xb = zeros( numel( fitpic.xg ), 5 ); % allocate memory
    
    % call subfunctions
    [ w, wb ] = HalfPlane( [ x(1:2) x(3) - pi/2 ], fitpic );
    [ g, gb ] = GaussianStrip( x(1:4), fitpic );

    % forward calculation
    temp = ( fitpic.xg-x(1) ).^2 + ( fitpic.yg-x(2) ).^2 ;
    temp0 = exp( -x(4) * temp );
    tempb = -( w .* temp0 .* x(5) * x(4) );

    % calculate contribution of subfunctions to -jacobian
    gb = gb .* repmat( (1-w) .* x(5), 1, 4 );
    wb = wb .* repmat( ( temp0 - g ) .* x(5), 1, 3 );
    
    % add contributions to -jacobian
    xb(:,1) = 2.0 .* (fitpic.xg-x(1)) .* tempb - gb(:,1) - wb(:,1);
    xb(:,2) = 2.0 .* (fitpic.yg-x(2)) .* tempb - gb(:,2) - wb(:,2);
    xb(:,3) = + gb(:,3) - wb(:,3);
    xb(:,4) = temp .* temp0 .* w * x(5) + gb(:,4);
    xb(:,5) = - ( w .* temp0 + (1-w) .* g );
    % calculation of function value
    f = - x(5) .* xb(:,5);
    
  end

end