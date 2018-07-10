function [ model, x0, dx, lb, ub ] = getParameter( model, data, fitpic )
  phi=pi/50:pi/50:2*pi;
  
  % calculate position in region of interest
  c = double( model.guess.x - data.offset );
  
  % fill in missing parameters
  if isempty( model.guess.r )
    model.guess.r(1) = 0;
  end
  
  if isempty( model.guess.w )
%     [ width, height ] = GuessObjectData( c, [0 pi/2 pi 3*pi/2], data );
%     width = 2*width^2;
%     model.guess.w = width
%     
%     if isempty( model.guess.h )
%       model.guess.h = height;
%     end
%   else
    model.guess.w = 1/5;
  else
    model.guess.w = model.guess.w*4;
  end
  if isempty( model.guess.h ) || isnan( model.guess.h )
    model.guess.h = interp2( fitpic.fit_pic, c(1), c(2), '*nearest' ) - double( data.background );
  else
    model.guess.h = model.guess.h - double( data.background );
  end
  
  if length( model.guess.r )<2
    model.guess.r(2) = (1/model.guess.w);
  end
  
  if length( model.guess.w )<2
    model.guess.w(2) = model.guess.w;
  end
  
  if length( model.guess.h )<2
    heights = interp2( fitpic.fit_pic, c(1)+model.guess.r(2)*cos(phi), c(2)+model.guess.r(2)*sin(phi), '*nearest' );
    heights(isnan(heights)) = [];
    if isempty(heights)
        model.guess.h(2) = abs(model.guess.h(1) * 0.1);
    else
        model.guess.h(2) = abs(mean( heights - double( data.background )));
    end
    
  end  

%   end

  % setup parameter array
  %    [ X  Y           Width of Gauss          Height of Gauss         Width of Ring           Height of Ring          Radius of Ring        ]
  x0 = [ c(1:2)         model.guess.w(1)        model.guess.h(1)        model.guess.w(2)        model.guess.h(2)        model.guess.r(2)      ];
  dx = [ 1  1           model.guess.w(1)/10     model.guess.h(1)/10     model.guess.w(2)/10     model.guess.h(2)/10     model.guess.r(2)/10   ];
  lb = [ 1  1           0                       model.guess.h(1)/10     0                       model.guess.h(2)/10     model.guess.r(2)/10   ];
  ub = [ data.rect(3:4) Inf                     model.guess.h(1)*10     Inf                     model.guess.h(2)*10     model.guess.r(2)*10   ];
end