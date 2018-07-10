function output = subsref( model, S )
  switch S.type
    case '.'
      switch S.subs
        case 'bounds'
          output = [ model.guess.x model.guess.x ];
        case 'dim'
          output = 5;
        case 'supportsDerivative'
          output = true;
       end
  end
end