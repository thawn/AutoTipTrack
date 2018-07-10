function PlotOrientations( p, c, l )
%PLOTORIENTATIONS plots the points 'p' with ther orientation to the current graph
% arguments:
%   p   an n-by-3 vector of point-coordinates and orientations
%   c   an optional color string

  if nargin < 2
    c{1} = 'g';
    c{2} = 'r';
  end
  
  if nargin < 3
    l = 10;
  end
  
  if numel( p ) > 0
    hold on
    for i = 1:numel(p)
      if numel(p)>1
        if i == numel(p) || numel(p)==2
          plot( [0 l/2] * double( cos(p(i).o+pi) ) + double( p(i).x(1) ), ...
                [0 l/2] * double( sin(p(i).o+pi) ) + double( p(i).x(2) ), [ c{1} '-' ],'LineWidth',1 );
        elseif i == 1
          plot( [0 l/2] * double( cos(p(i).o) ) + double( p(i).x(1) ), ...
                [0 l/2] * double( sin(p(i).o) ) + double( p(i).x(2) ), [ c{1} '-' ],'LineWidth',1 );  
        else
          plot( [-l/2 +l/2] * double( cos(p(i).o+pi) ) + double( p(i).x(1) ), ...
                [-l/2 +l/2] * double( sin(p(i).o+pi) ) + double( p(i).x(2) ), [ c{1} '-' ],'LineWidth',1 );
        end
        plot( double( p(i).x(1) ), double( p(i).x(2) ), [ c{2} 'x' ], 'MarkerSize', 5, 'LineWidth',1 );
      else
        plot( double( p(i).x(1) ), double( p(i).x(2) ), [ c{2} '+' ], 'MarkerSize', 5, 'LineWidth',1 );
      end
    end
    hold off
  end
end
