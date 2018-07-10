function idx = getClusters( p, dist, norm, max_area, has_object_data )
%GETCLUSTERS takes points of the array 'p' and puts them in clusters, if they
%are closer than 'dist'.
%WARNING: This function produces strange results, if many points have the same
%distance. In this case, clusters tend to be smaller than they should be.
%
% Arguments:
%  p          an array with n rows containing at least 2 columns holding the x 
%             and y coordinates of the n points to process.
%  dist       the threshold distances. Points closer than 'dist' are regarded to
%             lie in the same cluster.
%  norm       defines the norm used for defining the distance. Allowed values 
%             are any positive numbers p for defining the p-norm and the special
%             strings 'max', denoting the maximum norm
%  max_area   the maximum area allowed to be covered by one region. If a
%             cluster is larger the distance is decreased until the cluste size
%             is below max_area.
%  has_object_data  determines if there is a thrid column with object indices
%                   such that the algorithm may ignore distances between points
%                   one the same object.
% Results:
%  idx        a list with n entries containing indices, where points in the same
%             cluster have the same index

  narginchk( 2, 5);
  
  % initialize default values, if necessary
  if nargin < 3 || isempty( norm ) % set default norm to euclidean
    norm = 2;
  end
  if nargin < 4 % area threshold is ignored by default
    max_area = Inf;
  end
  if nargin < 5 % default setting
    has_object_data = false;
  end
  
  % trivial case
  if max_area <= 1 % no clusters at all, because their area would be too small
    idx = 1:size(p,1);
    return
  end

  % calculate distance between all points
  n = size(p,1);

  if isnumeric( norm )
    if norm > 0
      d = abs( repmat( p(:,1)', n, 1 ) - repmat( p(:,1), 1, n ) ).^norm + ...
          abs( repmat( p(:,2)', n, 1 ) - repmat( p(:,2), 1, n ) ).^norm;
      dist = dist .^ norm; % redefine required distance, such that we dont have to take the root in the line above
    else
      error( 'MPICBG:FIESTA:positiveNumberRequired', 'The norm needs a positive number' );
    end
  elseif strcmp( norm, 'max' )
    d = max( abs( repmat( p(:,1)', n, 1 ) - repmat( p(:,1), 1, n ) ), ...
             abs( repmat( p(:,2)', n, 1 ) - repmat( p(:,2), 1, n ) ) );
  else
    error( 'MPICBG:FIESTA:undefinedNorm', 'The norm "%s" is undefined', norm );
  end

  if has_object_data % set distance between points of same object_id to Inf
    d( repmat( p(:,3)', n, 1 ) == repmat( p(:,3), 1, n ) ) = Inf;
  end
  
  % add points to cluster list, until everything is finished
  idx = zeros(1,n);
  while true
    i = find( idx == 0, 1, 'first' ); % get one unprocessed point
    if isempty(i) % no points left => finished
      break;
    end
    % recursively add points
    add_idx = addToCluster( i, dist, i );
    % calculate cluster area
    area = ( max(p(add_idx,1)) - min(p(add_idx,1)) + 1 ) * ...
           ( max(p(add_idx,2)) - min(p(add_idx,2)) + 1 );
    rdist = dist; 
    while area > max_area % cluster too large!
      % find next smaller distance
      rdist = min( d( i, d(i,:) < rdist & d(i,:) > 0 ) );
      % produce clusters again
      add_idx = addToCluster( i, rdist, i );
      % calculate cluster area
      area = ( max(p(add_idx,1)) - min(p(add_idx,1)) + 1 ) * ...
             ( max(p(add_idx,2)) - min(p(add_idx,2)) + 1 );
    end
    
    % set all points in one cluster to same index
    idx(add_idx) = max(idx) + 1;
  end % of loop running through all clusters
  
  % recursive subfunction:
  function indices = addToCluster( index, di, indices )
    % get all points close to current one
    cluster = find( d(index,:) < di );
    % find all unprocessed ones of them
    f = cluster( idx(cluster) == 0 );
    f = setdiff( f, indices );
    % add new points
    indices = [ indices f ];
    % process them recursively
    for f_i = f
      indices = addToCluster( f_i, di, indices );
    end
  end

end