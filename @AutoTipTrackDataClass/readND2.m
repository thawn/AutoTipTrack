function A = readND2(A)
fullpath=fullfile(A.FilePath,A.FileName);

if ~isdeployed
  addpath('bfmatlab');
end
reader = bfGetReader(fullpath);

%extract the planes and the metadata from the cell array
meta=reader.getMetadataStore();

Channels=meta.getChannelCount(0);
numPlanes=meta.getPlaneCount(0);

%save the acquisitiondate in the configuration
globalmeta=reader.getGlobalMetadata;
julianAcquisitionDate=str2double(globalmeta.get('ModifiedAtJDN'));
if julianAcquisitionDate>0
  A.Config.AcquisitionDate=datetime(julianAcquisitionDate,'ConvertFrom','juliandate');
else
  %this only gives the file creation date:
  A.Config.AcquisitionDate=datetime(char(meta.getImageAcquisitionDate(0)),'InputFormat','yyyy-MM-dd''T''HH:mm:ss');
end

if Channels > 1
  if A.Config.UseChannel>meta.getChannelCount()
    error('Config.UseChannel must be an integer between 1 and the number of color Channels in your file');
  end
  planesUsed=A.Config.UseChannel:Channels:numPlanes;
else
  planesUsed=1:numPlanes;
end
if A.Config.LastFrame>1
  l=length(planesUsed);
  if A.Config.LastFrame>l %make sure that lastFrame is smaller or equal to the stack length
    A.Config.LastFrame=l;
  end
  stackLength=A.Config.LastFrame-A.Config.FirstTFrame+1;
  planesUsed=planesUsed(A.Config.FirstTFrame:A.Config.LastFrame);%cut planesUsed down to only the part we need
else
  stackLength=length(planesUsed);
  A.Config.FirstTFrame=1;
  A.Config.LastFrame=stackLength;
end
A.Config.Times=zeros(1,stackLength);
A.Stack=cell(1,stackLength);
frequency=ceil(stackLength/5);
for i=1:stackLength
  trackStatus(A.StatusFolder,'Loading stack','',i-1,stackLength,frequency)
  DeltaT=meta.getPlaneDeltaT(0,planesUsed(i)-1); %Java numbering starts at 0 therefore we need to deduct one from the plane indices
  A.Config.Times(i)=DeltaT.value.doubleValue;
  A.Stack{i}=bfGetPlane(reader, planesUsed(i));
end
trackStatus(A.StatusFolder,'Loading stack','',stackLength,stackLength,1)
A.Config.Times=A.Config.Times-A.Config.Times(1);
A.Config.FirstTFrame=1;
A.Config.LastFrame=stackLength;

A.Config.StackType='ND2';
if A.Config.PreferStackPixSize
  PixS=meta.getPixelsPhysicalSizeX(0);
  A.Config.PixSize=PixS.value.doubleValue*1000;
end
A.Config.Width=size(A.Stack{1}, 2);
A.Config.Height=size(A.Stack{1}, 1);

if exist(A.Config.Directory,'file')~=7
  mkdir(A.Config.Directory);
end
clear('meta');
clear('reader');
if ~isdeployed
  rmpath('bfmatlab');
end
