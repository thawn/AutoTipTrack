function [ model, x0, dx, lb, ub ] = getParameter( model, data, fitpic )
  phi=pi/50:pi/50:2*pi;
  % calculate position in region of interest
  c = double( model.guess.x - data.offset );
  
  if isempty( model.guess.r )
    model.guess.r = 0;
  end  
  
  % fill in missing parameters
  if isempty( model.guess.w )
%     [ width, height ] = GuessObjectData( c, [0 pi/2 pi 3*pi/2], data );
%     width = 2*width^2;
%     model.guess.w = width
%     
%     if isempty( model.guess.h )
%       model.guess.h = height;
%     end
%   else
    model.guess.w = 5.0;
  end

  if isempty( model.guess.h )
    model.guess.h = abs(interp2( fitpic.fit_pic, c(1), c(2), '*nearest' ) - min(min(fitpic.fit_pic))+1);
  end

  if length( model.guess.r )<2
    model.guess.r(2) = sqrt(model.guess.w(1))*2;
  end
  
  if length( model.guess.w )<2
    model.guess.w(2) = model.guess.w(1)^2;
  end
  
  if length( model.guess.h )<2
    model.guess.h(2) = abs(mean( interp2( fitpic.fit_pic, c(1)+model.guess.r(2)*cos(phi), c(2)+model.guess.r(2)*cos(phi), '*nearest' ) - double( data.background )));
  end  
  
  if length( model.guess.r )<3
    model.guess.r(3) = sqrt(model.guess.w(1))*4;
  end
  
  if length( model.guess.w )<3
    model.guess.w(3) = model.guess.w(1)^2;
  end
  
  if length( model.guess.h )<3
    model.guess.h(3) = abs(mean( interp2( fitpic.fit_pic, c(1)+model.guess.r(3)*cos(phi), c(2)+model.guess.r(3)*sin(phi), '*nearest' ) - double( data.background )));
  end  
%   end

  % setup parameter array
  %    [ X  Y           Width of Gauss          Height of Gauss         Width of Ring1          Height of Ring1         Radius of Ring1         Width of Ring2          Height of Ring2         Radius of Ring2    ]
  x0 = [ c(1:2)         model.guess.w(1)        model.guess.h(1)        model.guess.w(2)        model.guess.h(2)        model.guess.r(2)        model.guess.w(3)        model.guess.h(3)        model.guess.r(3)      ];
  dx = [ 1  1           model.guess.w(1)/10     model.guess.h(1)/10     model.guess.w(2)/10     model.guess.h(2)/10     model.guess.r(2)/10     model.guess.w(3)/10     model.guess.h(3)/10     model.guess.r(3)/10   ];
  lb = [ 1  1           0                       model.guess.h(1)/10     0                       model.guess.h(2)/10     model.guess.r(2)/10     0                       model.guess.h(3)/10     model.guess.r(3)/10   ];
  ub = [ data.rect(3:4) Inf                     model.guess.h(1)*10     Inf                     model.guess.h(2)*10     model.guess.r(2)*10     Inf                     model.guess.h(3)*10     model.guess.r(3)*10   ];
%  ub( ub == 0 ) = 0.01;
end