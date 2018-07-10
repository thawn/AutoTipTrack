% FIT2D finds the best parameters to minimize the difference between an image and a given model.
% ==============================================================================
% 
% @author: David Zwicker, MPI CBG Dresden
% @modified: 2007-09-04
%
% @remarks:
%   all coordinates should use the spatial coordinate system used by the MatLab
%   image functions. Integer values refer to the center of pixels, where 1
%   denotes the first pixel.
% ==============================================================================

function [ value, CoD, region ] = Fit2D( modelstr, guess, params, bw_id )
%FIT2D tries to fit a given model to a region of the global image 'pic'. The
%used model is determined by 'modelstr' and the region is choosed by giving
%suitable 'guess'-values.
%
% arguments:
%   model       a string denoting which model should be used
%   guess       an array where each entry is an array with guesses for
%               parameters. The number of cells must be the same as the length
%               of the 'model' string
%   params      a struct containing useful information like the estimated
%               background level and the size of the region used for scanning
%               (optional)
%   bw_id       index of the area in the binary image (optional)
% result:
%   value       an array with the values and the errors determined by fitting
%   CoD         coefficient of determination (CoD <= 0 if fit was unsuccessful)
%               http://en.wikipedia.org/wiki/Coefficient_of_determination
%   region      the region of the image that has been used for fitting

   narginchk( 2, 4 ) ;
  
  % init arguments
  if nargin < 4
    bw_id = 0;
  end
  
  % check parameters array
  if ~isfield( params, 'max_iter' )
    params.max_iter = 400; % maximum number of iterations
  end
  
  % check, if enough points are given
  num_points = numel( modelstr );
  if numel( guess ) < num_points
    error( 'MPICBG:FIESTA:notEnoughParameters', ...
           'The "guess" array has less entries than requested by the given model in Fit2D()' );
  end

  % setup models
  fit_model = cell(1,num_points); %<< cell array containing the models used for fitting
  ids = zeros( 1, num_points+1 ); %<< array containing the indices for the first slot for each model in the parameter array
  ids(1) = 2;
  supportsDerivative = true; %<< check, if all models support the jacobian calculation
  for i = 1:num_points
    switch modelstr(i)
      % point-like objects
      case 'p'
        fit_model{i} = Model2DGaussSymmetric( guess(i) );
      case 'b'
        fit_model{i} = Model2DGaussStreched( guess(i) );
      case 'r'
        fit_model{i} = Model2DGaussPlusRing( guess(i) );
      case 'f'
        fit_model{i} = Model2DGaussPlus2Rings( guess(i) );        
      case 'n'        
        fit_model{i} = ModelNeg2DGaussPlusRing( guess(i) );                
        
      % elongated objects
      case 'e'
        fit_model{i} = Model2DFilamentEnd( guess(i) );
      case 'm'
        if strcmp( params.ridge_model, 'quadratic' )
          fit_model{i} = Model2DFilamentMiddleBend( guess(i) );
        else % fall back to linear model
          fit_model{i} = Model2DFilamentMiddle( guess(i) );
        end
      case 't'
        fit_model{i} = Model2DShortFilament( guess(i) );
      % other cases
      otherwise
        error( 'MPICBG:FIESTA:unknownModel', 'Model "%s" is not known to Fit2D()', modelstr(i) );
    end
    ids(i+1) = ids(i) + fit_model{i}.dim;
    supportsDerivative = supportsDerivative & fit_model{i}.supportsDerivative;
  end
  
  % images are stored in handle objects params.pic and params.bw
  
  % get bounds of guessed positions (integer values should refer to the center
  % of pixels!) to estimate the fitting region
  tl = [  Inf  Inf ];  % top left point
  br = [ -Inf -Inf ];  % bottom right point
  for i = 1:num_points
    bounds = fit_model{i}.bounds;
    tl = min( [ tl ; bounds(1:2) ] );
    br = max( [ br ; bounds(3:4) ] );
  end

  % check given parameter fit_size
  if ~isfield( params, 'fit_size' ) || params.fit_size <= 0
    error( 'MPICBG:FIESTA:notEnoughParameters', ...
           'Fit2D() can not determine size of region of interest. Please pass it as a parameter to the function.' );
  end

  % add (possible real valued) fit_size to bounds to make sure necessary data
  % for fitting is inside the region of interest (ROI)
  tl = tl - params.fit_size;
  br = br + params.fit_size;
  
  % confine ROI to image (integer values should refer to the center of pixels)
  tl( tl < 1 ) = 1; % top and left side
  if br(1) > size( params.pic.pic, 2 ) % bottom side
    br(1) = size( params.pic.pic, 2 );
  end
  if br(2) > size( params.pic.pic, 1 ) % right side
    br(2) = size( params.pic.pic, 1 );
  end

  % save information about region of interest in a struct to pass it to the models. 
  % round the rectangle, because we need interger values for cropping
  data = struct( 'rect', [ round(tl)  round(br)-round(tl) ] ); 
  data.offset = data.rect(1:2) - 1; %<< offset between the original and the cropped image

  % crop image and store it in the params.fitpic handle object. this
  % creates the params.fitpic.fit_pic as well as the params.fitpic.xg and
  % yg properties
  params.fitpic = FitPic( params, data.rect ); %<< create cropped image

  data.img_size = [ size( params.fitpic.fit_pic, 2 ), size( params.fitpic.fit_pic, 1 ) ];
  
  % estimate background level if necessary
  if isfield( params, 'background' ) % take given background level
    data.background = params.background;
  else
    data.background = mean( [ params.fitpic.fit_pic(1,:) params.fitpic.fit_pic(end,:) transpose( params.fitpic.fit_pic(:,1) ) transpose( params.fitpic.fit_pic(:,end) ) ] );
  end

  % if bw_id is set, remove objects with other id, which might be nearby
  if bw_id > 0
    fit_bw = imcrop( params.bw.bw, data.rect ); % create cropped image
    fit_bw = double( fit_bw == 0 | fit_bw == bw_id );
    params.fitpic.fit_pic = params.fitpic.fit_pic .* fit_bw + data.background * ( 1 - fit_bw );
  end

  % init fitting parameters for varying the model
  [ x0, dx, lb, ub ] = deal( zeros( 1, ids(end)-1 ) ); %<< preallocation
  x0(1) = data.background;       %<< array containing estimates for all parameters to fit
  dx(1) = data.background / 20;  %<< magnitude of the first step for each parameter
  lb(1) = 0.0;                   %<< lower bound for each parameter
  ub(1) = Inf;                   %<< upper bound for each parameter

  for i = 1:num_points % run through all models
    % get model parameters
    [ fit_model{i}, x0_m, dx_m, lb_m, ub_m ] = getParameter( fit_model{i}, data, params.fitpic );
    % add them to the lists
    x0(ids(i):ids(i+1)-1) = x0_m;
    dx(ids(i):ids(i+1)-1) = dx_m;
    lb(ids(i):ids(i+1)-1) = lb_m;
    ub(ids(i):ids(i+1)-1) = ub_m;
  end

  % linearize data for easier jacobian calculation
  params.fitpic.xg = params.fitpic.xg(:);
  params.fitpic.yg = params.fitpic.yg(:);
  params.fitpic.fit_pic = params.fitpic.fit_pic(:);

  resnorm = Inf(1,2); %<< array containing the deviation of the fits using the two different methods
  
  % do the fit using the large scale approach
  [ x(1,:), dev, residual{1}, exitflag, output, lambda, jacobian{1} ] = invokeFitting( true )  ;

  resnorm(1) = dev;

  % check, if it was successful
  if exitflag <=0
    % repeat fitting with different methode
    % do the fit using a medium scale approach
    [ x(2,:), dev, residual{2}, exitflag, output, lambda, jacobian{2} ] = invokeFitting( false );
    
    % check, if fitting went well
    resnorm(2) = dev;
  end

  % determine best fit (using the one with the smaller residual)
  [ minimum, idx ] = min( resnorm );
  
  if  minimum < Inf % at least one fit went well
    x = x(idx,:);
    if all( x >= lb ) && all( x <= ub ) % parameters are not allowed to be at their bounds or beyond
      residual = residual{idx};
      % determine coefficient of determination - http://en.wikipedia.org/wiki/Coefficient_of_determination
      CoD = 1 - sum( residual(:).^2 ) / sum( ( params.fitpic.fit_pic(:) - mean( params.fitpic.fit_pic(:) ) ).^2 );

      % determine reduced chi squared
      reduced_chi = resnorm(idx) / ( numel(params.fitpic.xg) - numel(x0) );

      % calculate errors with suppressed warnings
      warning_state1 = warning( 'off', 'MATLAB:singularMatrix' );
      warning_state2 = warning( 'off', 'MATLAB:nearlySingularMatrix' );

      % calculate error (jacobian is a sparse matrix)
      xe = sqrt( diag( inv( jacobian{idx}' * jacobian{idx} ) ) * reduced_chi );
      xe = full( xe' ); % transformation to normal matrix

      % reset warning states
      warning( warning_state1 );
      warning( warning_state2 );
    else % parameters out of bounds
      params.error_events.fit_hit_bounds = params.error_events.fit_hit_bounds + 1;
      CoD = -10;
    end 
  else % no fit went well
    switch exitflag
      case -2
        params.error_events.fit_hit_bounds = params.error_events.fit_hit_bounds + 1;
      case -4
        params.error_events.fit_impossible = params.error_events.fit_impossible + 1;
    end
    % pass abort information and shift by -100 to avoid confusion with negative
    % CoD-Values, which are rare, but possible.
    CoD = exitflag - 100; 
  end

  if CoD <= -1 % fitting went wrong
    x = x0; % set initial values
    xe = Inf( size( x0 ) ); % set errors to infinity
  end

  % construct points out of parameters array
  value = struct( 'x', {}, 'o', {}, 'w', {}, 'h', {}, 'r', {} ,'b', {} );
  data.background = double_error( x(1), xe(1) );  % save background
  for i = 1:num_points
    value(i) = transformResult( fit_model{i}, x(ids(i):ids(i+1)-1), xe(ids(i):ids(i+1)-1), data );
  end
  
  % save region used for fitting
  region = [ data.rect(2) data.rect(1) data.rect(2)+data.rect(4) data.rect(1)+data.rect(3) ];

  % debug output
  if params.display > 1
    hold on;
    plot( [data.rect(1) data.rect(1) data.rect(1)+data.rect(3) data.rect(1)+data.rect(3) data.rect(1)], ...
          [data.rect(2) data.rect(2)+data.rect(4) data.rect(2)+data.rect(4) data.rect(2) data.rect(2)], 'y' );
    hold off;
  end

%  if true %rect(3) ~= rect(4) && CoD > 0.95% CoD > 0 && CoD < 0.5
%    CoD
%    figure( 'Name', 'Residual', 'NumberTitle', 'off' );
%    surf( reshape( residual, data.rect([4 3])+1 ) );
%    figure( 'Name', 'Data', 'NumberTitle', 'off' );
%    surf( reshape( double(params.fitpic.fit_pic), data.rect([4 3])+1 ) );
%    figure( 'Name', 'Fit', 'NumberTitle', 'off' );
%    surf( reshape( params.fitpic.fit_pic - FitError( x ), data.rect([4 3])+1 ) );
%    figure( 'Name', 'Estimate', 'NumberTitle', 'off' );
%    surf( reshape( params.fitpic.fit_pic - FitError( x0 ), data.rect([4 3])+1 ) );
%    pause
%  end

  % delete handles to clean up
  clear params.fitpic;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% SUBFUNCTION: ERROR FUNCTION
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  function [ rx, rdev, rresidual, rexitflag, routput, rlambda, rjacobian ] = invokeFitting( largescale )
  %INVOKEFITTING invokes the fitting process with the rigth options set.
  % arguments:
  %  largescale  boolean value denoting if the largescale method should be used
  % results: this function just passes the results of 'lsqnonlin'
  
    % set options for fitting
    options = params.options;

    options.TypcialX = dx;
    
    % set used methode
    if largescale
      options.Algorithm = 'trust-region-reflective';
    else
      options.Algorithm = 'levenberg-marquardt';
    end
    
    % do actual fitting
    if supportsDerivative % models may calculate derivatives
      options.Jacobian = 'on';
      options.DerivativeCheck = 'off';
      % disable warning, that might occur durring fitting
      warning_state = warning( 'off', 'MATLAB:singularMatrix' );
      try
        if largescale
          [ rx, rdev, rresidual, rexitflag, routput, rlambda, rjacobian ] = ...
            lsqnonlin( @FitErrorDerivative, x0, lb, ub, options );
        else
          [ rx, rdev, rresidual, rexitflag, routput, rlambda, rjacobian ] = ...
            lsqnonlin( @FitErrorDerivative, x0, [], [], options );
        end
      catch
        err = lasterror();
        % set standard results
        rx = x0;
        rdev = Inf;
        rexitflag = -1;
        rresidual = Inf( size( params.fitpic.fit_pic ) );
        routput = [];
        rlambda = [];
        rjacobian = zeros( numel( params.fitpic.fit_pic ), numel( x0 ) );
        % check error
        if strcmp( err.identifier, 'optim:lsqncommon:InvalidFUN' )
          % most propably the Model2DShortFilament model returned a degenerated filament
          rexitflag = -11;
        else
          rethrow( err );
        end
      end
      warning( warning_state );
    else % fitting without provided jacobians
      options.Jacobian = 'off';
      warning_state = warning( 'off', 'MATLAB:singularMatrix' );
      try
        if largescale
            [ rx, rdev, rresidual, rexitflag, routput, rlambda, rjacobian ] = ...
              lsqnonlin( @FitErrorDerivative, x0, lb, ub, options );
        else
            [ rx, rdev, rresidual, rexitflag, routput, rlambda, rjacobian ] = ...
              lsqnonlin( @FitErrorDerivative, x0, [], [], options );
        end
      catch
        err = lasterror();
        % set standard results
        rx = x0;
        rdev = Inf;
        rexitflag = -1;
        rresidual = Inf( size( params.fitpic.fit_pic ) );
        routput = [];
        rlambda = [];
        rjacobian = zeros( numel( params.fitpic.fit_pic ), numel( x0 ) );
        % check error
        if strcmp( err.identifier, 'optim:lsqncommon:InvalidFUN' )
          % most propably the Model2DShortFilament model returned a degenerated filament
          rexitflag = -11;
        else
          rethrow( err );
        end
      end
      warning( warning_state );
    end 
    if isempty(rdev)
        rdev = Inf;
    end
    
  end % of subfunction invokeFitting
  
  function f = FitError( x )
  %FITERROR calculates the difference between the data in the image 'params.fitpic.fit_pic' and
  %the theoretical model given in 'fit_model' using the coefficients 'x'
  % arguments:
  %   x   a one dimensional array containing the coefficients
  % results:
  %   f   the difference of each point of the picture to the model

    f = params.fitpic.fit_pic - x(1); % first subtract background

    % than subtract contribution of each model
    for i_m = 1:numel(fit_model)
      f = f - evaluate( fit_model{i_m}, x(ids(i_m):ids(i_m+1)-1), params.fitpic );
    end
  end % of subfunction FitError

  function [ f, xb ] = FitErrorDerivative( x )
  %FITERRORDERIVATIVE calculates the difference between the data in the image 
  %'params.fitpic.fit_pic' and the theoretical model given in 'fit_model' using the 
  %coefficients 'x' with additionally calculating the jacobian 'xb'.
  % arguments:
  %   x   a one dimensional array containing the coefficients
  % results:
  %   f   the difference of each point of the picture to the model
  %   xb  the jacobian of 'f' with respect to 'x'
    if numel(fit_model)>1
        w = zeros([numel(params.fitpic.fit_pic) numel(fit_model)]);
        for i_m = 1:numel(fit_model)
            for j_m = 1:numel(fit_model)
                if  guess(i_m).obj == guess(j_m).obj && i_m~=j_m
                    if guess(i_m).model=='m'
                        x1 = data.img_size(1) / 2 + 0.5 + x(ids(i_m)) * -sin( x(ids(i_m)+1) );
                        y1 = data.img_size(2) / 2 + 0.5 + x(ids(i_m)) *  cos( x(ids(i_m)+1) );
                    else
                        x1 = x(ids(i_m));
                        y1 = x(ids(i_m)+1);
                    end
                    if guess(j_m).model=='m'
                        x2 = data.img_size(1) / 2 + 0.5 + x(ids(j_m)) * -sin( x(ids(j_m)+1) );
                        y2 = data.img_size(2) / 2 + 0.5 + x(ids(j_m)) *  cos( x(ids(j_m)+1) );
                    else
                        x2 = x(ids(j_m));
                        y2 = x(ids(j_m)+1);                        
                    end
                    a = atan2( y2 - y1, x2 - x1 );
                    temp = ( params.fitpic.xg - x1 ) * cos(a) + (  params.fitpic.yg - y1  ) * sin(a);
                    temp = temp / norm([x2-x1 y2-y1]);
                    temp( temp > 1 ) = 1;
                    temp( temp < 0 ) = 0;
                    w(:,i_m) = w(:,i_m) + (1-temp);
                else
                    w(:,i_m) = w(:,i_m) + ones(size(params.fitpic.fit_pic));
                end
            end
        end
        if min(min(w))~=max(max(w))
            w = w-min(min(w));
        end
        w = w/max(max(w));
    else
        w = ones(size(params.fitpic.fit_pic));
    end
    if nargout == 1 % only function value requested
      
      f = params.fitpic.fit_pic - x(1); % first subtract background

      % than subtract contribution of each model
      for i_m = 1:numel(fit_model)
        f = f - w(:,i_m).*evaluate( fit_model{i_m}, x(ids(i_m):ids(i_m+1)-1), params.fitpic );
      end
      
    else % function value and jacobian requested
      
      xb = zeros( numel(params.fitpic.xg), numel(x) ); % allocate memory for jacobian
      f = params.fitpic.fit_pic - x(1); % first subtract background
      xb(:,1) = -1.0; % derivative with respect to background

      % than subtract contribution of each model and get jacobian
      for i_m = 1:numel(fit_model)
        try
            [ df, xb( :, ids(i_m):ids(i_m+1)-1 ) ] = ...
              evaluate( fit_model{i_m}, x(ids(i_m):ids(i_m+1)-1), params.fitpic );
        catch
            df = evaluate( fit_model{i_m}, x(ids(i_m):ids(i_m+1)-1), params.fitpic);
        end
        f = f - w(:,i_m).*df;
      end
    end
  end % of subfunction FitErrorDerivative

end % of main function Fit2D
