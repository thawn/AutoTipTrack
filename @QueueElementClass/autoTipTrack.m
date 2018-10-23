function Q=autoTipTrack(Q)
warning off MATLAB:MKDIR:DirectoryExists;
mkdir(Q.Config.Directory);
warning on MATLAB:MKDIR:DirectoryExists;
params.workdir=Q.Config.Directory;
params.display = Q.Debug;
params.maxObjects=Q.Config.maxObjects;
params.creation_time_vector = (Q.Config.Times-Q.Config.Times(1));
if isfield(Q.Config.Threshold,'MinFilamentLength')
  params.minFilamentLength=Q.Config.Threshold.MinFilamentLength;
else
  params.minFilamentLength=3;
end
if ~isdeployed
  addpath('imageprocessing');
  addpath(['imageprocessing' filesep 'Fit2D']);
  if params.display>1
    addpath(['imageprocessing' filesep 'debug']);
  end
end
params.error_events = ErrorEvents();
warning off MATLAB:DELETE:FileNotFound;
file =fullfile(Q.Config.Directory, Q.Config.StackName);
threshFile=[file '_thresh.tif'];
delete(threshFile);
warning on MATLAB:DELETE:FileNotFound;
params.bead_model=Q.Config.Model;
params.max_beads_per_region=Q.Config.MaxFunc;
params.scale=Q.Config.PixSize;
params.ridge_model = 'quadratic';
params.find_molecules=1;
params.find_beads=1;
params.area_threshold=Q.Config.Threshold.Area;
params.height_threshold=Q.Config.Threshold.Height;
params.fwhm_estimate=Q.Config.Threshold.FWHM;
if isempty(Q.Config.BorderMargin)
  params.border_margin = 2 * Q.Config.Threshold.FWHM / params.scale / (2*sqrt(2*log(2)));
else
  params.border_margin = Q.Config.BorderMargin;
end
if params.border_margin > 0
  params.farbordery=Q.Config.Height + 1 - params.border_margin;
  params.farborderx=Q.Config.Width + 1 - params.border_margin;
  params.thresh_border_margin=params.border_margin+round(Q.Config.Threshold.FWHM/Q.Config.PixSize); %try to correct for thinning
  params.thresh_farbordery=Q.Config.Height + 1 - params.thresh_border_margin;
  params.thresh_farborderx=Q.Config.Width + 1 - params.thresh_border_margin;
end
if isempty(Q.Config.ReduceFitBox)
  params.reduce_fit_box = 1;
else
  params.reduce_fit_box = Q.Config.ReduceFitBox;
end
params.focus_correction = Q.Config.FilFocus;
params.min_cod=Q.Config.Threshold.Fit;
params.binary_image_processing=Q.Config.Threshold.Filter;
params.options = optimset( 'Display', 'off','UseParallel','always');
params.options.MaxFunEvals = [];
params.options.MaxIter = [];
params.options.TolFun = [];
params.options.TolX = [];
%check wether imaging was done during change of date
k = params.creation_time_vector<0;
params.creation_time_vector(k) = params.creation_time_vector(k) + 24*60*60;
if isinf(Q.Config.LastFrame)
  Q.Config.LastFrame = length(Q.Stack);
end
params.subtract_background=Q.Config.SubtractBackground;
params.threshold=Q.calculateThreshold(Q.Config,Q.Stack);
if params.display > 0
  params.logger = Logger('logfile.txt');
end
ThresholdFile = fullfile(Q.Config.Directory,[Q.Config.StackName '_Threshold.tif']);
params.LoadThreshold = false;
if exist(ThresholdFile,'file') == 2
  %if there is already a threshold stack
  params.LoadThreshold = true;
  params.ThresholdFile = ThresholdFile;
  params.ThreshTiffMeta=imfinfo(ThresholdFile);
  params.ThreshPlanesUsed = Q.Config.FirstTFrame:Q.Config.LastFrame;
end
Q.Objects = cell(size(Q.Stack));
thresholdStack=cell(size(Q.Stack));
% Check if there is a parallel pool available and if we should use
% it.
if ~isempty(gcp('nocreate')) && Q.Config.UseParpool && Q.TrackParallel && params.display<1
  try
    lastF=min([Q.Config.LastFrame length(Q.Stack)]);
    %we need to copy some variables out of the handle class Q so that
    %parfor can slice them properly.
    tempStack=Q.Stack;
    tempObj=Q.Objects;
    StatusFolder=Q.StatusFolder;
    firstF=Q.Config.FirstTFrame;
    numF=lastF-firstF+1;
    trackStatus(StatusFolder,'Tracking','',0,numF,1);
    parfor n=firstF:lastF
      [tempObj{n}, thresholdStack{n}]=ScanImage(tempStack{n},params,n);
      if ~isempty(tempObj{n})
        message=sprintf('%d Objects found',length(tempObj{n}.center_x));
      else
        message=sprintf('%d Objects found.',0);
      end
      trackStatus(StatusFolder,'Tracking',message,n-firstF+1,numF,1);
    end
    Q.Objects=tempObj;
  catch ME
    disp(ME.getReport);
    %save(fData,'-append','-v6','Objects','ME');
  end
else %Otherwise use a classic for loop.
  numF = min([Q.Config.LastFrame length(Q.Stack)])-Q.Config.FirstTFrame+1;
  trackStatus(Q.StatusFolder,'Tracking','',0,numF,1);
  for n=Q.Config.FirstTFrame:min([Q.Config.LastFrame length(Q.Stack)])
    if params.display>0
      params.logger.Log(sprintf('Analysing frame %d',n),params.display);
    end
    try
      [Q.Objects{n}, thresholdStack{n}]=ScanImage(Q.Stack{n},params,n);
      if ~isempty(Q.Objects{n})
        message=sprintf('%d Objects found',length(Q.Objects{n}.center_x));
      else
        message=sprintf('%d Objects found.',0);
      end
      trackStatus(Q.StatusFolder,'Tracking',message,n-Q.Config.FirstTFrame+1,numF,1);
    catch ME
      disp(ME.getReport);
      %save(fData,'-append','-v6','Objects','ME');
      break;
    end
  end
  disp(params.error_events)
end
for n=1:length(thresholdStack)
  if ~isempty(thresholdStack{n})
    imwrite(thresholdStack{n}, threshFile, 'writemode', 'append', 'Compression', 'none');
  end
end
%clean up
if ~isdeployed
  rmpath('imageprocessing');
  rmpath(['imageprocessing' filesep 'Fit2D']);
  if params.display>1
    rmpath(['imageprocessing' filesep 'debug']);
  end
end
end
