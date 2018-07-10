function model = Model2DFilamentMiddle( guess )
  
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
  if numel( guess.x ) < 2 || numel( guess.o ) < 1
    error( 'MPICBG:FIESTA:notEnoughParameters', ...
           'A position and an orientation have to be given for a filament-middle model.' );
  end
  
  model = struct( 'guess', {guess}, 'img_size', NaN(1,2) );

  model = class( model, 'Model2DFilamentMiddle' );
end