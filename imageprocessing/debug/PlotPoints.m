function PlotPoints( p, c )
%PLOTPOINTS plots the points 'p' to the current graph
% arguments:
%   p   an n-by-2 vector of point-coordinates
%   c   an optional color string

  if nargin == 1
    c = 'r';
  end
  if numel( p ) > 0
    hold on
    plot( p(:,1), p(:,2), [ c 'x' ], 'MarkerSize', 2 );
    hold off
  end
end

