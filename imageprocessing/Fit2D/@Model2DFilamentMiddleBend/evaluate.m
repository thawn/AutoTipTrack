function [ f, xb ] = evaluate( model, x, fitpic )

  p = model.img_size / 2 + 0.5 + x(1) * [ -sin( x(2) ) cos( x(2) ) ];
  
  % calculate distance on ray
  t = ( p(1) - fitpic.xg ) .* cos(x(2)) - ( fitpic.yg - p(2) ) .* sin(x(2));

  % calculate orientated distance to ray
  d = ( p(1) - fitpic.xg ) .* sin(x(2)) + ( fitpic.yg - p(2) ) .* cos(x(2)) + ...
      x(3) .* t.^2; % the last term provides the quadratic nature

  if nargout == 1 % calculate value of function

    f = x(5) * exp( - d.^2 * x(4) );
  
  else % calculate value of function and jacobian 'xb'
    
    % allocate memory
    xb = zeros( prod( model.img_size ), 5 ); 

    [ img, pb ] = GaussianStripBend( [ p(1:2) x(2:4) ], fitpic );
    f = x(5) .* img;
    pb = x(5) .* pb;
    
    xb(:,1) = pb(:,1) .* sin(x(2)) - pb(:,2) .* cos(x(2));
    xb(:,2) = pb(:,3) + (  pb(:,2)  .* sin(x(2)) +  pb(:,1)  .* cos(x(2)) ) .* x(1);
    xb(:,3) = pb(:,4);
    xb(:,4) = pb(:,5);
    xb(:,5) = -img;
    
  end
end