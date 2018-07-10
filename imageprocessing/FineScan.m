function objects = FineScan( objects, params )
%FINESCAN processes the rough data of objects with the help of fitting. It tries
%to increase the accuracy of the parameters determined in the previous step
%while also determing some new properties and estimating errors
%
% arguments:
%   objects   the objects array
%   params    the parameter struct
% results:
%   objects   the extended objects array
 
   narginchk( 2, 2 ) ;
  
  if params.display > 1 % debug output
    params.fig1 = figure();
    imshow( params.pic.pic, [] );

%     for k = 1:numel( objects )
%       PlotOrientations( objects(k).p, 'y' );
%     end
  end
  
  %%----------------------------------------------------------------------------
  %% FIT OF COMPLICATED PARTS
  %%----------------------------------------------------------------------------

  FIT_AREA_FACTOR = 4 * params.reduce_fit_box; %<< factor determining the size of the area used for fitting
  params.fit_size = FIT_AREA_FACTOR * params.object_width;
  
  % process clusters 
  [objects, deleteObjects] = fitComplicatedParts( objects, params ); 
  
  %remove false points (post process analysis) from objects
  objects(deleteObjects)=[];
  params.objectIDs.IDs(deleteObjects)=[];
  %%----------------------------------------------------------------------------
  %% FIT REMAINING EASY POINTS
  %%----------------------------------------------------------------------------
  if params.display>0
    params.logger.Log( 'fit remaining intermediate points', params.display );
  end
  % process the remaining easy points
  objects = fitRemainingPoints( objects, params );
  
%   if params.display > 1 % debug output
%      for k = 1:numel( objects )
%        PlotOrientations( objects(k).p, {'r','g'}, 7 );
%      end
%   end
  
  %%----------------------------------------------------------------------------
  %% PLAUSIBILITY CHECK
  %%----------------------------------------------------------------------------
  
  % determine standard deviation of background
  b = [];
  for i = 1 : numel( objects )
    b = [ b double( [ objects(i).p.b ] ) ];
  end
  height_thresh = params.height_threshold * std( b );
  
  % delete very dark objects
  i = 1;
  for i = numel( objects ):-1:1
    nPoints = numel(objects(i).p);
    heights = zeros(nPoints,1);
    pos=zeros(nPoints,1);
    for n = 1:nPoints
      heights(n) = double( objects(i).p(n).h(1) );
      px=double(objects(i).p(n).x);
      pos(n) = any(px<=params.thresh_border_margin | [ (px(1) >= params.farborderx) (px(2) >= params.farbordery)]);
    end
    d = find(pos);
    k = find(heights < height_thresh);
    if any(ismember([1 nPoints],k)) || any(ismember([1 nPoints],d))
      if params.display > 1 % debug output
        figure( params.fig1 );
        hold on
        plot( px(1), px(2), 'rx', 'MarkerSize', 5, 'LineWidth',1 );
        hold off
      end
      objects(i) = [];
      params.objectIDs.IDs(i)=[];
      if any(ismember([1 nPoints],k))
        params.error_events.object_too_dark = params.error_events.object_too_dark + 1;
      else
        params.error_events.touching_border = params.error_events.touching_border + 1;
      end
    else
      if params.display > 1 % debug output
        figure( params.fig1 );
        hold on
        plot( px(1), px(2), 'g+', 'MarkerSize', 5, 'LineWidth',1 );
        hold off
      end
      objects(i).p( heights < height_thresh ) = [];
     end
  end
  
end

function [objects,delete] = fitComplicatedParts( objects, params )
%FITCOMPLICATEDPARTS processes parts of the image, where objects are close to
%each other. This is achieved by fitting several points in one step using a
%compound model.
%
% arguments:
%   objects   the objects array
%   params    the parameter struct
% results:
%   objects   the extended objects array

   narginchk( 2, 2 ) ;
  
  MAX_DISTANCE_FACTOR = 4; %<< factor determining when objects are considered as "close"
  MAX_CLUSTER_VOLUME_FACTOR = 15; %<< factor determining the maximum size of clusters
  cluster_dist = MAX_DISTANCE_FACTOR * params.object_width;
  cluster_volume = MAX_CLUSTER_VOLUME_FACTOR * cluster_dist^2;
  
  delete=[];  %stores the objects that have been delete in postprocessing
    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % CLUSTER ANALYSIS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % determine bound of each object
  object_rects = zeros( numel(objects), 4 );
  for obj = 1 : numel( objects )
    p =  transpose( reshape( [ objects(obj).p.x ], 2, [] ) );
    object_rects(obj,1) = min( p(:,1) ) - params.fit_size/2;
    object_rects(obj,2) = min( p(:,2) ) - params.fit_size/2;
    object_rects(obj,3) = max( p(:,1) ) + params.fit_size/2;
    object_rects(obj,4) = max( p(:,2) ) + params.fit_size/2;
  end
  object_rects(:,3:4) = object_rects(:,3:4) - object_rects(:,1:2);

  dist = []; dist_id = [];
  % build up matrix of distances between objects
  % x,y run through objects

  xypairs=findInterjectingFitboxes(object_rects);
  for m=1:length(xypairs(:,1))
%   for x = 1 : numel(objects)
%     for y = 1 : x-1
      if params.error_events.abort == 1
        if params.display>0
          params.logger.Log('Fine scan aborted by user.',params.display);
        end
        return;
      end
      
      x=xypairs(m,1);
      y=xypairs(m,2);

      % check if objects are even close
%       if rectint( object_rects(x,:), object_rects(y,:) ) == 0
%         continue;
%       end
      % build up point list for these two objects
      nx = numel( objects(x).p );
      ny = numel( objects(y).p );
      p = zeros( nx + ny, 4 );
      for k = 1 : nx
        p(k,1:4) = [ objects(x).p(k).x(1:2), 1, k ];
      end
      for k = 1 : ny
        p(nx+k,1:4) = [ objects(y).p(k).x(1:2), 2, k ];
      end

      % locate clusters of points between these two objects - this is neccessary,
      % because two object may have several regions, where they are close to
      % ecah other
      clusters = getClusters( p, cluster_dist, 'max', Inf, true );
      for k = unique( clusters )
        f_k = find( clusters == k );
        if numel(f_k) > 1 % close points found!
          % determine distance of the clusters
          px = p( f_k( p(f_k,3) == 1 ), 1:2 );
          py = p( f_k( p(f_k,3) == 2 ), 1:2 );

          % build distance matrix
          % colums denote points on px
          % rows denote points on py
          d = ( repmat( px(:,1)', size(py,1), 1 ) - repmat( py(:,1), 1, size(px,1) ) ).^2 + ...
              ( repmat( px(:,2)', size(py,1), 1 ) - repmat( py(:,2), 1, size(px,1) ) ).^2;

          if size(py,1) == 1 % simple case, where d is just a vector
            r = 1;
            [ min_dist, c ] = min( d );
          else % more complex matrix case
            % find minimal row for each colum 
            [ min_dist, r ]  =  min( d );
            % find minimal colum
            [ min_dist, c ] = min( min_dist );
            c = c(1);
            r = r(c);
          end
          min_dist = sqrt( min_dist );

          % add center of cluster and the ids of the involved objects to the
          % array containing the data to process
          dist( end+1, 1:5 ) = [ min_dist px(c,1:2) py(r,1:2) ];
          %dist( end+1, 1:5 ) = [ min_dist min( p(f_k,1:2) ) max( p(f_k,1:2) ) ];
          dist_id( end+1, 1:2 ) = [ x y ];
        end
      end % of run through clusters between two objects

%    end % of run through objects
  end % of run through objects

  % we now have all points, where two objects come close to each other

  % check if the list is empty
  if isempty( dist )
    return
  end
  
  % sort rows in order to handle most urgent clusters first
  [ dist, index ] = sortrows( dist, 1 );
  dist_id = dist_id( index, : );

  % determine cluster rectangles and their similarity
  cluster_rects = [ min( dist(:,2), dist(:,4) )-params.fit_size, min( dist(:,3), dist(:,5) )-params.fit_size , ...
                    max( dist(:,2), dist(:,4) )+params.fit_size, max( dist(:,3), dist(:,5) )+params.fit_size ];
  cluster_rects(:,3:4) = cluster_rects(:,3:4) - cluster_rects(:,1:2);
  areas = prod( cluster_rects(:,3:4), 2 ); % the area of each cluster

  % similarity of rectangles
  rects_sim = rectint( cluster_rects, cluster_rects );
  rects_sim = rects_sim ./ repmat( areas', size( cluster_rects, 1 ), 1 );
  % => rect_sim \in [0,1]

  % run through all rects and determine if possibly some are close to
  % each other
  fit_regions = []; %<< stores the regions, which were fitted

  while true
    k = find( dist(:,1) < Inf, 1 ); % find cluster
    if isempty(k)
      break; % no more clusters to handle => process finished
    end

    % search for other clusters, which might be close
    dims = [ cluster_rects( k, 1:2 ) cluster_rects( k, 1:2 ) + cluster_rects( k, 3:4 ) ];
    j = k;
    cluster_ids = [];
    while prod( dims(3:4)-dims(1:2) ) * numel(cluster_ids) < cluster_volume % check area of cluster
      cluster_ids(end+1) = j;
      rects_sim( :, j ) = 0;
      [ void, j ] = max( rects_sim( k, k+1:end ) ); % find other cluster with maximum similarity
      if isempty( void ) || void == 0 
        break;
      end
      j = j + k;
%         dims(1:2)
%         cluster_rects(j,1:2)
      dims(1:2) = min( dims(1:2), cluster_rects(j,1:2) );
      dims(3:4) = max( dims(3:4), cluster_rects(j,1:2) + cluster_rects(j,3:4) );
    end

    if isempty( cluster_ids )
      warning( 'MPICBG:FIESTA:wrongParameterRange', 'The value of the parameter ''cluster_volume'' might be too low.' );
    end

    % find clusters, which have to be disregarded
    disregard_clusters = find( rects_sim( k, k+1:end ) > 0 ) + k;
    dist( disregard_clusters, 1 ) = Inf;
    rects_sim( :, disregard_clusters ) = 0;

    % make sure, we dont take these clusters once again
    dist(cluster_ids,1) = Inf;

    % we now have regions which are close to each other and now only have to
    % fit the objects, that lie inside

    % get all objects involved in the cluster
    obj_ids = unique( [ dist_id( cluster_ids, 1 )' dist_id( cluster_ids, 2 )' ] );
    if params.display>0
      params.logger.Log( sprintf( 'process cluster of %d objects', numel(obj_ids) ), params.display );
    end
    % get region of the cluster
    region = [ Inf Inf -Inf -Inf ];
    for j = cluster_ids
      cluster_center = 0.5 * ( dist(j,2:3) + dist(j,4:5) );
      region(1) = min( [region(1), cluster_center(1)-params.fit_size, dist( j, 2 ), dist( j, 4 )] );
      region(2) = min( [region(2), cluster_center(2)-params.fit_size, dist( j, 3 ), dist( j, 5 )] );
      region(3) = max( [region(3), cluster_center(1)+params.fit_size, dist( j, 2 ), dist( j, 4 )] );
      region(4) = max( [region(4), cluster_center(2)+params.fit_size, dist( j, 3 ), dist( j, 5 )] );
    end
    region_center = 0.5 * ( region(1:2) + region(3:4) );
    %region = [ region(1:2) region(3:4) - region(1:2) ];
    if params.display > 1 % debug output
      PlotRect( [ region(1:2) region(3:4) - region(1:2) ], 'r' );
    end

    % determine the model to use for each object in the region
    guess = struct( 'model', {}, 'obj', {}, 'idx', {}, 'x', {}, 'o', {} );
    for obj = obj_ids
        guess(end+1).obj = obj;
        if numel( objects(obj).p ) == 1 % check, if it is a point-like object
            guess(end).model = 'e';
            guess(end).idx = 1;
            guess(end).x = double(objects(obj).p(1).x);
            guess(end).w = double(objects(obj).p(1).w);
            guess(end).o = double(objects(obj).p(1).o + pi); 
            guess(end).h = double(objects(obj).p(1).h);
        end % of choice of length of the object
    end % 'obj' of run through all objects in cluster
  
    % make sure we have a cluster, otherwise just go on
    if numel( guess ) < 2
      break;
    end

%     [ guess.model ]
%     [ guess.x ]
    abort=0;
    while ~abort
       % fit the region with our determined model
      [ data, CoD, fit_region ] = Fit2D( [ guess.model ], guess, params );
    
       %     double( [ data.x ] )

       if params.display > 1
          PlotRect( [ fit_region(2:-1:1) fit_region(4:-1:3) - fit_region(2:-1:1) ], 'g' );
       end
       %if  more than one object, post process cluster to disregard false objects 
       [guess,delete,abort]=postProcessFit2D(data,guess,delete);
    end
    % check if fitting went well
    if CoD < params.min_cod % bad fit result
      params.error_events.cluster_cod_low = params.error_events.cluster_cod_low + 1;
      continue;
    end
    
    % add region to list (have to exchange x and y variables!)
    fit_regions(end+1,1:4) = fit_region( [ 2 1 4 3 ] );

    % store results
    for obj = 1:numel( guess )
      switch guess(obj).model
        case { 'p', 'b', 'r', 'e', 'm' } % single points
          objects( guess(obj).obj ).p( guess(obj).idx ) = data(obj);
          if guess(obj).model == 'm' || (guess(obj).model == 'e' &&  guess(obj).idx == 1)
            objects( guess(obj).obj ).p( guess(obj).idx ).o = objects( guess(obj).obj ).p( guess(obj).idx ).o - pi;
          end
        case 't' % full Filament
          objects( guess(obj).obj ).p(1) = data(obj);
          objects( guess(obj).obj ).p(1).x = data(obj).x(1,1:2);
          objects( guess(obj).obj ).p(2) = data(obj);
          objects( guess(obj).obj ).p(2).x = data(obj).x(2,1:2);
          objects( guess(obj).obj ).p(2).o = mod( data(obj).o + pi, 2*pi );
          objects( guess(obj).obj ).p(3:end) = []; % delete possible additional points
        otherwise
          error( 'MPICBG:FIESTA:modelUnknown', 'Model "%s" is not defined', guess(obj).model );
      end
    end
    % all points in cluster fitted
  end % 'k' of run through found clusters

  
    
  % delete non-fitted points, which are in the fitted region
  % but only if they are no end points
  for obj = 1:numel(objects) % run through all objects
    k = 2; % exclude start points
    % run through all points in object
    while k < numel( objects(obj).p ) % exclude end points
      % check if not fitted            and in fit_region
      if isempty( objects(obj).p(k).b ) && any( inRectangle( double( objects(obj).p(k).x ), fit_regions ) )
        objects(obj).p(k) = [];
      else
        k = k + 1;
      end
    end
  end

end


function objects = fitRemainingPoints( objects, params )
%FITREMAININGPOINTS processes unfitted parts of the obejcts
% arguments:
%   objects   the objects array
%   params    the parameter struct
% results:
%   objects   the extended objects array

   narginchk( 2, 2 ) ;

  
  k = 1;
  while k <= numel(objects) % run through all objects
    if params.display>0
      params.logger.Log( sprintf( 'process object %d of %d with %d points', k, numel(objects), numel( objects(k).p ) ), params.display );
    end
    if params.error_events.abort == 1
      if params.display>0
        params.logger.Log('Fine scan aborted by user.',params.display);
      end
      return;
    end

    % determine which kind of object we have
    if numel( objects(k).p ) == 1 % single point
      if isnan( double(objects(k).p(1).b) ) % has not been fitted
        guess = struct( 'model', {}, 'obj', {}, 'idx', {}, 'x', {}, 'o', {} );
        guess(1).model = 'e';
        guess(1).idx = 1;
        guess(1).x = double(objects(k).p(1).x);
        guess(1).w = double(objects(k).p(1).w);
        guess(1).o = double(objects(k).p(1).o + pi); 
        guess(1).h = double(objects(k).p(1).h);
        
        [ data, CoD ] = Fit2D( 'e', guess, params );
        if CoD > params.min_cod % fit went well
          data.o = data.o - pi;
          objects(k).p(1) = data;
        else % bad fit result
          if params.display>0
            params.logger.Log( [ 'Point has been disregarded: ' CoD2String( CoD ) ], params.display );
          end
          params.error_events.endpoint_cod_low = params.error_events.endpoint_cod_low + 1;
          objects(k) = [];
          params.objectIDs.IDs(k)=[];
          %k = k + 1;
          continue;
        end
  
      end
    end
    
    % delete empty objects!
    if isempty( objects(k).p )
      objects(k) = [];
      params.objectIDs.IDs(k)=[];
      params.error_events.empty_object = params.error_events.empty_object + 1;
    else
      k = k + 1; % step to next object
    end
  end % of run through all objects
end

function inside = inRectangle( points, rect )
%INRECTANGLE checks, if a point lies in a (list of) rectangle(s)
% arguments:
%  point    the coordinates of the point
%  rect     a n-by-4 array of rectangles in (topleft bottomright) notation
% results:
%  inside   a 1-by-n logical-array, where true means, the point is inside that
%           rectangle
  if isempty( rect )
    inside = false;
  else
    inside = (points(:,1) >= rect(1))  & (points(:,2) >= rect(2)) & (points(:,1) <= rect(3)) & (points(:,2) <= rect(4));
  end
end


function [guess,delete,abort]=postProcessFit2D( data, guess, delete)
%POSTPROCESS checks, if tracked points are too closed together or are not bright enough
% arguments:
%   data    an array with the values and the errors determined by fitting    
%   guess   an array where each entry is an array with guesses for parameters.
% results:
%   guess   an array where points too close together are combined and objects too dim are removed
  

  p=1;
  pairs=[];
  %create matrix of features between two points
  for obj1 = 1:numel( data )
    for obj2 = obj1+1:numel( data )
      if (guess(obj1).model=='p')&&(guess(obj2).model=='p')
          pairs(p,1)=obj1;
          pairs(p,2)=obj2;
          %distance between points
          pairs(p,3)=sqrt( (data(obj1).x(1).value-data(obj2).x(1).value)^2 + (data(obj1).x(2).value-data(obj2).x(2).value)^2);
          %radial erroes of the 2 points added
          pairs(p,4)=sqrt(data(obj1).x(1).error^2+data(obj1).x(2).error^2) + sqrt(data(obj2).x(1).error^2+data(obj2).x(2).error^2);
          %radial sigma of the 2 points added
          pairs(p,5)=0.5*(data(obj1).w.value+data(obj2).w.value);
          %ratio between amplitudes of objects
          int=[data(obj1).h.value data(obj2).h.value];
          pairs(p,6)=int(1)/sum(int);
          p=p+1;
      end
    end
  end
  abort=1;
  if ~isempty(pairs)
    obj=[];
    %sort pairs by distance between centers
    pairs=sortrows(pairs,3);
    if ~isempty(find(pairs(:,3)-pairs(:,4)<0|pairs(:,4)==Inf,1,'first'))
      %find if the radial error of the two points is bigger than their distance between them 
      k=find(pairs(:,3)-pairs(:,4)<0,1,'first');
      obj=pairs(k,2);
    elseif ~isempty(find(pairs(:,3)-pairs(:,5)<0,1,'first'))
      %find if the average sigma of the two points is bigger than their distance between them
      k=find(pairs(:,3)-pairs(:,5)<0,1,'first');
      obj=pairs(k,2);
    elseif ~isempty(find(pairs(:,6)<0.1,1,'first'))
      %find if the intensity ratio between the two points is smaller than 0.1
      k=find(pairs(:,6)<0.1,1,'first');
      obj=pairs(k,1);
    elseif ~isempty(find(pairs(:,6)>0.9,1,'first'))
      %find if the intensity ratio between the two points is smaller than 0.1
      k=find(pairs(:,6)>0.9,1,'first');
      obj=pairs(k,2);
    end
    if ~isempty(obj)
      %delete object from guess and retrack cluster
      delete=[delete guess(obj).obj];
      guess(obj)=[];
      abort=0; 
    end
  end
end