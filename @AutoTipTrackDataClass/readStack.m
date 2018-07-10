function A = readStack(A)
[~,MetaInfo,~] = A.stackRead;

A.Config.AcquisitionDate=datetime([MetaInfo.CreationDate{1} ' ' MetaInfo.CreationTimeStr{1}],'InputFormat','MM-dd-yyyy HH:mm:ss:SSS');
A.Config.StackType='STK';
tempCalib=struct('x',[],'y',[],'unit','');
if ~isempty(MetaInfo)
  A.Config.Times=(MetaInfo.CreationTime-MetaInfo.CreationTime(1))./1000;
  tempCalib.x=MetaInfo.XCalibration;
  tempCalib.y=MetaInfo.YCalibration;
  tempCalib.unit=MetaInfo.CalibrationUnits(1:2);
else
  warning('MATLAB:AutoTipTrack:QueueElementClass:readStack','Could not read metadata from stack: %s',A.FileName);
end
if A.Config.PreferStackPixSize && ~isempty(tempCalib.x) && tempCalib.x>0
  if strcmpi(tempCalib.unit,'nm')
    A.Config.PixSize=tempCalib.x;
  elseif strcmpi(tempCalib.unit,'um')||strcmpi(tempCalib.unit,sprintf('%cm',181))
    A.Config.PixSize=tempCalib.x*1000;
  else
    warning('MATLAB:AutoTipTrack:QueueElementClass:readStack','Could not read pixel size from stack %s because I did not recognize the pixel unit: %s. Using pixel size from configuration: %gnm',A.FileName,tempCalib.unit,A.Config.PixSize);
  end
end
if A.Config.LastFrame>1
  A.Config.Times=A.Config.Times(A.Config.FirstTFrame:A.Config.LastFrame);
end
A.Config.FirstCFrame=A.Config.FirstTFrame;
A.Config.FirstTFrame=1;
A.Config.LastFrame=length(A.Stack);
A.Config.Times=A.Config.Times-A.Config.Times(1);
A.Config.Width=size(A.Stack{1}, 2);
A.Config.Height=size(A.Stack{1}, 1);

if exist(A.Config.Directory,'file')~=7
  mkdir(A.Config.Directory);
end
if exist(A.Config.Directory,'file')~=7
  mkdir(A.Config.Directory);
end
end
