function [ objects, params, bw ] = RoughScan( params )
%ROUGHSCAN tries to locates objects roughly. This is done using a thresholded
%(black and white) image and some image processing. The results are inaccurate
%position coordinates for points and a list of coordinates for elongated
%objects, roughly descibing the spatial configuration in the image.
%
% arguments:
%   objects   the objects array
%   params    the parameter struct
% results:
%   objects   the extended objects array

   narginchk( 1, 1 ) ;

  % images are stored in handle objects (params.pic and params.bw) for speed
  
  %%----------------------------------------------------------------------------
  %% PREPARE IMAGES
  %%-----------------------------------------------------------------------
  if params.display>0
    params.logger.Log( 'create black&white image', params.display );
  end
  
  % we only create the black and white image if it was not already loaded
  % from a file (in autoTipTrack.m)
  if ~params.LoadThreshold
    % converting imgage to black and white
    params.bw = Bw( params );
    % estimate background level
    params.background = mean( params.pic.pic( params.bw.bw == 0 ) );
  else
    % estimate background level
    bgbw = Bw( params );
    params.background = mean( params.pic.pic( bgbw.bw == 0 ) );
  end
  
  % choose regions to fit, if they are present
  if isfield( params, 'bw_regions' )
    params.bw.bw = params.bw_regions .* params.bw.bw;
  end

  % calculate estimated object width
  params.object_width = params.fwhm_estimate / (2*sqrt(2*log(2)));

  % get statistical data of the different regions
  bw_stats = regionprops( logical(params.bw.bw), 'Area', 'BoundingBox', 'Centroid', 'Image' );  
  
  % possibly debug display
  if params.display > 1
    params.fig2 = figure();
    imshow( (0 ~= params.bw.bw), [0 3] );
  end
    
  % setup struct for the final object data
  objects = struct( 'p', {} );
  params.objectIDs=ObjectIDs;
  
  %%----------------------------------------------------------------------------
  %% SCAN BLACK AND WHITE IMAGE
  %%----------------------------------------------------------------------------

  % determine which areas should be scanned
  if ~isfield( params, 'scanareas' )
    params.scanareas = 1:numel(bw_stats);
  end
  
  % run through all regionprobs areas
  for area = params.scanareas
    if params.error_events.abort == 1
      if params.display>0
        params.logger.Log('Rough scan aborted by user.',params.display);
      end
      return;
    end
    % disregard areas touching border, if requested
%     bb = round( bw_stats(area).BoundingBox );
%     if params.border_margin > 0 && ...
%         ( bb(1) <= params.border_margin || bb(2) <= params.border_margin || ...
%           bb(1) + bb(3) >= size( params.pic.pic, 2 ) + 1 - params.border_margin || ...
%           bb(2) + bb(4) >= size( params.pic.pic, 1 ) + 1 - params.border_margin )
%       params.error_events.touching_border = params.error_events.touching_border + 1;
%       continue;
%     end
    if params.display>0
      params.logger.Log( sprintf( 'scan area %d', area ), params.display );
    end
    if params.display > 1 % debug output
      figure( params.fig2 );
      text( bw_stats(area).BoundingBox(1), bw_stats(area).BoundingBox(2), ...
            sprintf( '%d \\rightarrow', area ), 'Color', 'w', 'HorizontalAlignment', 'right', 'FontSize', 9 );
%       text( bb(1)+bb(3), bb(4)+bb(2), sprintf( '\\leftarrow %d', area ), 'Color', 'w', 'HorizontalAlignment', 'left', 'FontSize', 9 );
    end

    % initialize variable containing new objects
    new_obj = [];
    
    % check, which objects are requested and try to find them
    if bw_stats(area).Area > params.area_threshold
      % take all regions into consideration!
      new_obj = FindLineObjects( bw_stats(area), params );
    end
    
    if ~isempty( new_obj ) % new objects have been found
      % add found objects to list
      params.objectIDs.IDs(end+1:end+numel(new_obj))=area;
      objects(end+1:end+numel(new_obj)) = new_obj;
    end
    
  end % of loop through all regionprob objects
  if numel(objects)>params.maxObjects
    warn=sprintf( 'too many objects found in experiment %s: %d. Aborting! Check signal to noise. Probably improper focus/bleaching. If the threshhold image looks fine and you have more than %d objects then increase Config.maxObjects.',params.workdir, numel(objects), params.maxObjects ) %#ok<NOPRT>
    if params.display>0
      params.logger.Log(warn , params.display );
    end
    error('MATLAB:autotiptrack:too_many_objects','too many objects found in experiment %s: %d. Aborting! Check signal to noise. Probably improper focus/bleaching. If the threshhold image looks fine and you have more than %d objects then increase Config.maxObjects.',params.workdir, numel(objects), params.maxObjects);
  end
    

  bw=params.bw.bw;
  % delete global variables to clean up
  clear params.bw;
  
end


function objects = FindLineObjects( region_stats, params )
%FINDMOLECULES tries to find elongated objects or beads at the given area in the
%bw image. This is achieved using thinning the binary image to estimate the
%center line of the elongated object, where each pixel may be used as a
%coordinate for the position list of the elongated object.
%
% arguments:
%   region_stats  the result of the regionprobs function for the area to be
%                 scanned
%   params        the parameters struct
% results:
%   objects       a struct with the object data
  
   narginchk( 2, 2 ) ;
  
%   colors = [ 'g' 'b' 'c' 'm' 'y' 'r' ];
%   color_idx = 1;
  
  %objects = struct( 'p', {} );
  
  EMPTY_POINT = struct( 'x', {}, 'o', {}, 'w', {}, 'h', {}, 'r', {} , 'b', {});

  bw_thin = zeros( size(region_stats.Image) + 2 );
  bw_thin(2:end-1,2:end-1) = region_stats.Image;
  image = zeros( size(region_stats.Image) + 2 );
  image(2:end-1,2:end-1) = params.pic.pic(region_stats.BoundingBox(2)+0.5:region_stats.BoundingBox(2)+region_stats.BoundingBox(4)-0.5,...
                               region_stats.BoundingBox(1)+0.5:region_stats.BoundingBox(1)+region_stats.BoundingBox(3)-0.5);
                 
  bw_thin = bwmorph(bw_thin,'thin',Inf);
  
  % count surrounding pixels for feature detection
  kernel = [ 1 1 1 ; 1 0 1 ; 1 1 1 ];
  bw_feat = bw_thin  .* conv2( double(bw_thin), kernel, 'same' );
  crossings = bw_thin  .* conv2( double(bw_feat>2), kernel, 'same' );
  bw_feat = bw_feat + double( crossings > 1 );
  
  image( crossings > 0 ) = NaN;
  image(2:end-1,2:end-1) = conv2( image(2:end-1,2:end-1) , fspecial( 'average', 3 ), 'same' );
  
  %figure; imshow( bw_feat, [] );
  
  [ ey, ex ] = find( bw_feat == 1 ); % find endpoints
  [ cy, cx ] = find( bw_feat > 1 ); % find middlepoints
  
  % disregard endpoints touching border, if requested.
  if params.border_margin > 0
    tx=ex+region_stats.BoundingBox(1) - 1.5;
    ty=ey+region_stats.BoundingBox(2) - 1.5;
    delete=(ty<=params.thresh_border_margin | tx<=params.thresh_border_margin | ty >= params.thresh_farbordery | tx >= params.thresh_farborderx);
    if any(delete)
      params.error_events.touching_border = params.error_events.touching_border + sum(delete);
    end
    ex(delete)=[];
    ey(delete)=[];
  end
   
%   for jkl=1:numel(cx)
%     PlotPoints( [cx(jkl) cy(jkl)] + region_stats.BoundingBox(1:2)-1.5, 'g' );
%   end

  % store chain information in objects struct
  objects = repmat( struct( 'p', EMPTY_POINT ), 1, length(ey) ); % init & preallocate
  if length(cy)>params.minFilamentLength-2; %only track long filaments
    for i = length(ey):-1:1 % run through chains
      objects(i).p(1).x = [ex(i) ey(i)] + region_stats.BoundingBox(1:2) - 1.5;
      objects(i).p(1).w = 2.77258872223978 / params.fwhm_estimate^2;
      objects(i).p(1).b = NaN;
      objects(i).p(1).h = image(sub2ind(size(image),round(ey(i)),round(ex(i))));
      clearc=0;
      if isempty(cx)
        cx=ex;
        cx(i)=[];
        cy=ey;
        cy(i)=[];
        clearc=1;
      end
      D=pdist2([ex(i) ey(i)],[cx cy]);
      [~,t]=min(D);
      angle=atan2(cy(t)-ey(i),cx(t)-ex(i));
      objects(i).p(1).o = angle;
      if clearc==1
        cx=[];
        cy=[];
      end
    end
  else
    objects=struct([]);
  end
end
