function PlotTubules( objects )
  colors = [ 'r' 'g' 'b' 'c' 'm' 'y' ];
  color_idx = 1;
  hold on;
  h1 = 4; h2=5; h3=6;
  for i = 1:size( objects, 2 )
    o = objects(i);
    
    % debug plot
    plot( [ o.data.x ], [ o.data.y ], colors( color_idx ) );
    color_idx = mod( color_idx, numel( colors ) ) + 1;
    text( double( o.center_x ), double( o.center_y ), sprintf( '\\leftarrow %d', i ), 'Color', 'w', 'FontSize', 9 );
    
%     if numel( o.p ) == 1
%       plot( double( o.p(1).x(1) ), double( o.p(1).x(2) ), 'g+', 'MarkerSize', 10 );
%     else
%       for k = 1:numel(o.p)
%         plot( double( o.p(k).x(1) ), double( o.p(k).x(2) ), 'kx' );
%       end
%     end

    if numel( o.data ) == 1
      plot( double( o.data(1).x ), double( o.data(1).y ), 'g+', 'MarkerSize', 10 );
    else
      for k = 1:numel(o.data)
        plot( double( o.data(k).x ), double( o.data(k).y ), 'kx' );
      end
    end
    
%     % nice plot
%     plot( [ o.data.x ], [ o.data.y ], 'r', 'LineWidth', 2 );
%     if numel( o.p ) == 1
%       plot( double( o.p(1).x(1) ), double( o.p(1).x(2) ), 'g+', 'MarkerSize', 10 );
%     else
%     end
    
    
    % 
%     plot( double( o.com_x ), double( o.com_y ), 'wx', 'MarkerSize', 20 ); %com
    
%     h1 = figure(h1);
%     plot( o.points(:,3) );
%     h2 = figure(h2);
%     plot( o.points(:,4) );
%     h3 = figure(h3);
%     plot( o.points(:,5) );
%     pause

%     plot( objects(i).center(1), objects(i).center(2), 'cx', 'MarkerSize', 15 );
  end
  hold off;
end