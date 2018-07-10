function objects = InterpolateData( obj, params )
%INTERPOLATEDATA uses the data gained by fitting to calculate further useful
%details of the objects. The additional values are stored as new fields inside
%the 'objects' struct.img
% arguments:
%   obj       the input objects array
%   img       the original grey version of the image
%   params    the parameter struct
% results:
%   objects   the output objects array

narginchk( 2, 2 ) ;

% run through all objects
obj_id = 1;
while obj_id <= numel(obj)
  if params.error_events.abort == 1
    if params.display>0
      params.logger.Log('Interpolate data aborted by user.',params.display);
    end
    return;
  end
  
  if isempty( obj(obj_id).p ) % empty objects have to be ignored
    obj(obj_id) = [];
    params.objectIDs.IDs(obj_id)=[];
    params.error_events.empty_object = params.error_events.empty_object + 1;
    continue
  end
  if params.display>0
    params.logger.Log( sprintf( 'interpolating object %d', obj_id ), params.display );
  end
  % pass creation time given by external caller to the struct, such that it
  % migth be used later on
  objects.time = single( params.creation_time );
  
  % estimate total length, center of object and interpolate additional data
  if numel( obj(obj_id).p ) <= 1 % point object
    
    % calculate additional data
    objects.center_x(1,obj_id) = single( double(obj(obj_id).p(1).x(1)) * params.scale );
    objects.center_y(1,obj_id) = single( double(obj(obj_id).p(1).x(2)) * params.scale );
    objects.com_x(:,obj_id) = single( [obj(obj_id).p(1).x(1).value; obj(obj_id).p(1).x(1).error] * params.scale );
    objects.com_y(:,obj_id) = single( [obj(obj_id).p(1).x(2).value; obj(obj_id).p(1).x(2).error] * params.scale );
    objects.orientation(:,obj_id) = single( [0; 0]);
    %calculate lengths
    indices=find(params.objectIDs.IDs==params.objectIDs.IDs(obj_id));
    if numel(indices)==2
      %if we have just two points, we can estimate the length
      xdist=( double(obj(indices(1)).p(1).x(1)) * params.scale )-( double(obj(indices(2)).p(1).x(1)) * params.scale );
      ydist=( double(obj(indices(1)).p(1).x(2)) * params.scale )-( double(obj(indices(2)).p(1).x(2)) * params.scale );
      objects.length(:,obj_id) = single( [sqrt(xdist^2+ydist^2); 0] );
    else
      objects.length(:,obj_id) = single( [0; 0]);
    end
    
    width = single( [obj(obj_id).p(1).w(1).value; obj(obj_id).p(1).w(1).error] * params.scale );
    data = [];
    
    objects.width(:,obj_id) = width;
    objects.height(:,obj_id) = single( [obj(obj_id).p(1).h(1).value; obj(obj_id).p(1).h(1).error] );
    objects.background(:,obj_id) = single( [obj(obj_id).p(1).b(1).value; obj(obj_id).p(1).b(1).error] );
    
    % save point in final data struct
    objects.data{obj_id} = single( data );
    
    % step to the next object
    obj_id = obj_id + 1;
    
  end
end % of running through all objects
  
% make sure the structure is created, even if no object exists
if numel( obj ) == 0
  objects = struct( 'center_x', {}, 'center_y', {}, 'com_x', {}, ...
    'com_y', {}, 'height', {}, 'width', {}, 'orientation', {}, ...
    'length', {}, 'data', {}, 'time', {}, 'radius', {});
end
  
end
