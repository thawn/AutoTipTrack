function model = ModelNeg2DGaussPlusRing( guess )
  
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
  if ~isfield( guess, 'r' )
    guess(1).r = [];
  end

  % check guesses
  if numel( guess.x ) < 2
    error( 'MPICBG:FIESTA:notEnoughParameters', ...
           'A Position has to be given for a point-like object.' );
  end
  
  model = struct( 'guess', {guess} );

  model = class( model, 'ModelNeg2DGaussPlusRing' );
end