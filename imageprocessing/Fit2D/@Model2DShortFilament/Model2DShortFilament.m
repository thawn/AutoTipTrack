function model = Model2DShortFilament( guess )
  
  if ~isfield( guess, 'x' )
    guess(1).x = [];
  end
  if ~isfield( guess, 'w' )
    guess(1).w = [];
  end
  if ~isfield( guess, 'h' )
    guess(1).h = [];
  end
  if ~isfield( guess, 'b' )
    guess(1).b = [];
  end

  % check guesses
  if numel( guess.x ) < 4
    error( 'MPICBG:FIESTA:notEnoughParameters', ...
           'Two positions have to be given for a whole filament model.' );
  end
  
  model = struct( 'guess', {guess} );

  model = class( model, 'Model2DShortFilament' );
end