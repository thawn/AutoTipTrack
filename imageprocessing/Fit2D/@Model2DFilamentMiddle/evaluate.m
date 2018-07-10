 function [ f, xb ] = evaluate( model, x, fitpic )

  p = model.img_size / 2 + 0.5 + x(1) * [ -sin( x(2) ) cos( x(2) ) ];
  if nargout == 1 % calculate value of function
    
    f = x(4) * GaussianStrip( [ p(1:2) x(2:3) ], fitpic );
    
  else % calculate value of function and jacobian 'xb'
    
    xb = zeros( prod( model.img_size ), 4 ); % allocate memory

    [ img, pb ] = GaussianStrip( [ p(1:2) x(2:3) ], fitpic );
    f = x(4) .* img;
    pb = x(4) .* pb;
    
    xb(:,1) = pb(:,1) .* sin(x(2)) - pb(:,2) .* cos(x(2));
    xb(:,2) = pb(:,3) + (  pb(:,2)  .* sin(x(2)) +  pb(:,1)  .* cos(x(2)) ) .* x(1);
    xb(:,3) = pb(:,4);
    xb(:,4) = - img;
    
  end
end