function [ f, xb ] = GaussianStrip( x,fitpic )
%GAUSSIANSTRIP creates an image with a gaussian wall of height 1.0 and
%same dimensions as the grids 'xg' and 'yg'
% arguments:
%   x     input variables for the ray describing the gaussian:
%            1  x-position of the start point of the ray
%            2  y-position of the start point of the ray
%            3  angle between this ray and the x-axis
%            4  width of the gaussian 
% results:
%   f     the returned grey image
%   xb        the jacobian of the image with respect to the input variable x
%             this is optional and only calculated, if requested

  %fitpic xg yg; % load roi grids from fitpic handle object

  % calculate orientated distance to ray
  d = ( fitpic.yg - x(2) ) .* cos(x(3)) + ( x(1) - fitpic.xg ) .* sin(x(3));
  if nargout == 1
    % use this for gaussian
    f = exp( - d.^2 * x(4) );
  else
    xb = zeros( numel(fitpic.xg), 4 ); % preallocate memory
    
    % calculate intermediate variables and value of function  
    temp = d.^2 * x(4);
    f = exp( -temp );
    db = - 2 * x(4) .* d .* f ;
    
    % calculate jacobian
    xb(:,1) = sin(x(3)) .* db;
    xb(:,2) = - cos(x(3)) .* db;
    xb(:,3) = ( (fitpic.yg-x(2)) .* sin(x(3)) - (x(1)-fitpic.xg) .* cos(x(3)) ) .* db;
    xb(:,4) = f .* d.^2;
  end
end