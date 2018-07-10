function output = subsref( model, S )
  switch S.type
    case '.'
      switch S.subs
        case 'bounds'
          output = [ min( model.guess.x ) max( model.guess.x ) ];
        case 'dim'
          output = 6;
        case 'supportsDerivative'
          output = true;
       end
  end
end