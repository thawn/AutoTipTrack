function [ f, xb ] = evaluate( model, x , fitpic)
  
  a = atan2( x(4) - x(2), x(3) - x(1) ); % angle of line between points
  
  if nargout == 1 % calculate value of function

    w1 = HalfPlane( [ x(1:2)  a + pi/2 ], fitpic );
    w2 = HalfPlane( [ x(3:4)  a - pi/2 ], fitpic );
    g = GaussianStrip( [ x(1:2)  a  x(5) ], fitpic );
    f = x(6) .* ( ...
      w1 .* exp( -( (fitpic.xg-x(1)).^2 + (fitpic.yg-x(2)).^2 ) * x(5) ) + ...
      w2 .* exp( -( (fitpic.xg-x(3)).^2 + (fitpic.yg-x(4)).^2 ) * x(5) ) + ...
      ( 1 - w1 ) .* ( 1 - w2 ) .* g );
    
  else % calculate value of function and jacobian 'xb'
    
    xb = zeros( numel( fitpic.xg ), 6 ); % allocate memory
    
    % call subfunctions
    [ w1, wb1 ] = HalfPlane( [ x(1:2)  a + pi/2 ], fitpic );
    [ w2, wb2 ] = HalfPlane( [ x(3:4)  a - pi/2 ], fitpic );
    [ g, gb ] = GaussianStrip( [ x(1:2)  a  x(5) ], fitpic );
    
    % forward calculation
    temp = ( fitpic.xg-x(3) ).^2 + ( fitpic.yg-x(4) ).^2 ;
    temp3 = exp( -x(5) * temp );
    temp0 = ( fitpic.xg-x(1) ).^2 + ( fitpic.yg-x(2) ).^2 ;
    temp1 = exp( -x(5) * temp0 );
    
    % backward calculation
    temp0b = -( w1 .* temp1 .* x(6) .* x(5) );
    tempb =  -( w2 .* temp3 .* x(6) .* x(5) );
    w1b = ( temp1 - (1.0-w2) .* g ) .* x(6);
    w2b = ( temp3 - (1.0-w1) .* g ) .* x(6);
    
    % calculate contribution of subfunctions to -jacobian
    gb = gb .* repmat( (1.0-w2) .* (1.0-w1) .* x(6), 1, 4 );
    wb1 = wb1 .* repmat( w1b, 1, 3 );
    wb2 = wb2 .* repmat( w2b, 1, 3 );
    
    % atan2 handeling
    q = ( (x(4)-x(2)).^2 + (x(3)-x(1)).^2 );
    if q == 0 % points are directly on top of each other
      % we have to raise an error, because otherwise the jacobian is not defined
      error( 'MPICBG:FIESTA:DegeneratedFilament', 'Both end points of the filament lie exactly on top of each other' );
    end
    ab = wb1(:,3) + wb2(:,3) + gb(:,3);
    tempb0 =  ( x(3) - x(1) ) .* ab ./ q;
    tempb1 = -( x(4) - x(2) ) .* ab ./ q;

    % add contributions to -jacobian
    xb(:,1) = 2.0 .* (fitpic.xg-x(1)) .* temp0b - gb(:,1) - wb1(:,1) + tempb1;
    xb(:,2) = 2.0 .* (fitpic.yg-x(2)) .* temp0b - gb(:,2) - wb1(:,2) + tempb0;
    xb(:,3) = 2.0 .* (fitpic.xg-x(3)) .* tempb - wb2(:,1) - tempb1;
    xb(:,4) = 2.0 .* (fitpic.yg-x(4)) .* tempb - wb2(:,2) - tempb0;
    xb(:,5) = temp0 .* temp1 .* w1 .* x(6) + temp .* temp3 .* w2 .* x(6) + gb(:,4);
    xb(:,6) = - w1 .* temp1 - w2 .* temp3 - (1.0-w1) .* g .* (1.0-w2);

    f = -x(6) .* xb(:,6);
    
  end
  
end