function model = Model2DFilamentEnd( guess )
  if ~isfield( guess, 'x' )
    guess.x = [];
  end
  if ~isfield( guess, 'w' )
    guess.w = [];
  end
  if ~isfield( guess, 'h' )
    guess.h = [];
  end
  if ~isfield( guess, 'b' )
    guess.b = [];
  end
  
  % check guesses
  if numel( guess.x ) < 2 || numel( guess.o ) < 1
    error( 'MPICBG:FIESTA:notEnoughParameters', ...
           'A position and an orientation have to be given for a filament-end model.' );
  end

  model = struct( 'guess', {guess} );

  model = class( model, 'Model2DFilamentEnd' );
end