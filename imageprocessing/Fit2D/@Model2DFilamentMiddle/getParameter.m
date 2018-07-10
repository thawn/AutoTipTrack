function [ model, x0, dx, lb, ub ] = getParameter( model, data, fitpic )
  
  % fill in missing parameters
  if isempty( model.guess.w )
    model.guess.w = 1/5;
  end
  if isempty( model.guess.h ) || isnan( model.guess.h )
    c = double( model.guess.x - data.offset );
    model.guess.h = abs(interp2( fitpic.fit_pic, c(1), c(2), '*nearest' ) - double( data.background ));
  else
    model.guess.h = abs(model.guess.h - double( data.background ));
  end

  model.img_size = data.img_size;
  
  % calculated orientated distance from center to line
  d = (   model.guess.x(1) - data.offset(1) - model.img_size(1) / 2 - 0.5 ) * -sin( model.guess.o ) + ...
      (   model.guess.x(2) - data.offset(2) - model.img_size(2) / 2 - 0.5 ) *  cos( model.guess.o );

  % setup parameter array
  %    [ Dist    Orientation           Width             Height           ]
  x0 = [ d       model.guess.o         model.guess.w     model.guess.h    ];
  dx = [ 0.1     0.1                   model.guess.w/10  model.guess.h/10 ];
  mdist = 1.0 * max( data.rect(3:4) );
  lb = [ -mdist  model.guess.o - pi/2  0                 model.guess.h/10 ];
  ub = [  mdist  model.guess.o + pi/2  10*model.guess.w  model.guess.h*10 ];

end