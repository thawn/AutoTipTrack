function A = readMultilayerTiff(A)
fullpath=fullfile(A.FilePath,A.FileName);
trackStatus(A.StatusFolder,'Reading metadata','',0,2,1)
Channels=1;
A.Config.StackType='TIF';
tempCalib=struct('x',[],'y',[],'unit','');
TiffMeta=imfinfo(fullpath);
trackStatus(A.StatusFolder,'Reading metadata','',1,2,1)
numF=numel(TiffMeta);
if isfield(TiffMeta(1),'XResolution') && ~isempty(TiffMeta(1).XResolution)
  tempCalib.x=1./TiffMeta(1).XResolution;
end
if isfield(TiffMeta(1),'YResolution') && ~isempty(TiffMeta(1).YResolution)
  tempCalib.y=1./TiffMeta(1).YResolution;
end
if isfield(TiffMeta(1),'ResolutionUnit') && ~isempty(TiffMeta(1).ResolutionUnit)
  tempCalib.unit=TiffMeta(1).ResolutionUnit;
end
if isfield(TiffMeta(1), 'ImageDescription')
  if strstartswith(TiffMeta(1).ImageDescription,'<MetaData>')
    %we have a metamorph tiff
    try
      [tempCalib, A.Config.Times]=A.readMMTiffMeta(TiffMeta, tempCalib);
      A.Config.AcquisitionDate=datetime(A.Config.Times(1)/(3600*24), 'ConvertFrom', 'datenum');
    catch ME
      ME.getReport
    end
  elseif strstartswith(TiffMeta(1).ImageDescription,'<?xml version') && ...
      ~isempty(strfind(TiffMeta(1).ImageDescription,'<OME xmlns'))
    %we have a nikon tiff
    try
      [tempCalib, A.Config.Times,A.Config.AcquisitionDate]=A.readNikonTiffMeta(TiffMeta, tempCalib, A.Config.UseChannel);
    catch ME
      ME.getReport
    end
  elseif strstartswith(TiffMeta(1).ImageDescription,'ImageJ')
    %we have an imagej tiff, try to get the metadata
    try
      [tempCalib, A.Config.Times,Channels,A.Config.AcquisitionDate]=A.readImageJTiffMeta(fullpath,tempCalib);
    catch ME
      ME.getReport
    end
    if isempty(A.Config.AcquisitionDate)
      %try to extract the AcquisitionDate from the imagej info data
      %instead of the bioformats metadata
      if isfield(TiffMeta,'ImageDescription') && strstartswith(TiffMeta(1).ImageDescription, 'ImageJ')
        ImageJDescription = TiffMeta(1).ImageDescription;
      elseif isfield(TiffMeta,UnknownTags)
        ImageJDescription = char(TiffMeta(1).UnknownTags(2).Value);
      else
        ImageJDescription = '';
      end
      ImageJDescription(ImageJDescription==char(0))=[];
      ImageJDescription=strsplit(ImageJDescription,char(10));
      DateTimePattern=char('DateTime: ');
      Found=cellfun(@(x) ~isempty(x),strfind(ImageJDescription,DateTimePattern));
      if any(Found)
      DateTimeField=ImageJDescription{Found};
      DateTimeStr=strcat(DateTimeField(length(DateTimePattern)+1:end));
      if ~isempty(DateTimeStr)
        A.Config.AcquisitionDate=datetime(DateTimeStr,'InputFormat','yyyy:MM:dd HH:mm:ss');
      end
      end
    end
  end
elseif isfield(TiffMeta(1), 'UnknownTags') && isfield(TiffMeta(1).UnknownTags, 'Value') && ...
    isnumeric(TiffMeta(1).UnknownTags(1).Value) && ...
    numF>1 && TiffMeta(2).UnknownTags(1).Value>0 && ...
    isnumeric(TiffMeta(1).UnknownTags(2).Value) && TiffMeta(1).UnknownTags(2).Value > 0 && TiffMeta(1).UnknownTags(2).Value < 1
  %we are likely dealing with a nikon tiff stack, let's use the pixel
  %size and timestamp info in the unknown tags
  tempCalib.x=TiffMeta(1).UnknownTags(2).Value;
  tempCalib.unit='um';
  for n=1:numF
    A.Config.Times(n)=TiffMeta(n).UnknownTags(1).Value/1000;
  end
end
if Channels>1
  if A.Config.UseChannel>Channels
    error('MATMATLAB:AutoTipTrack:QueueElementClass:readMultilayerTiff','Config.UseChannel must be an integer between 1 and the number of color Channels in your file. Found %d Channels. You configured Channel %d',Channels,A.Config.UseChannel);
  end
  planesUsed=A.Config.UseChannel:Channels:numF;
else
  planesUsed=1:numF;
end
if length(A.Config.Times)>length(planesUsed)
  A.Config.Times = A.Config.Times(1:length(planesUsed));
end
if isempty(A.Config.Times)||length(A.Config.Times)<length(planesUsed)||all(A.Config.Times==0)
  A.Config.Times=(1:length(planesUsed)).*(A.Config.Time/1000);
end
if A.Config.LastFrame>1
  l=length(planesUsed);
  if A.Config.LastFrame>l %make sure that lastFrame is smaller or equal to the stack length
    A.Config.LastFrame=l;
  end
  stackLength=A.Config.LastFrame-A.Config.FirstTFrame+1;
  planesUsed=planesUsed(A.Config.FirstTFrame:A.Config.LastFrame);%cut planesUsed down to only the part we need
  A.Config.Times=A.Config.Times(A.Config.FirstTFrame:A.Config.LastFrame);
else
  stackLength=length(planesUsed);
  A.Config.FirstTFrame=1;
  A.Config.LastFrame=stackLength;
end
trackStatus(A.StatusFolder,'Reading metadata','',2,2,1)
A.Stack=cell(1,stackLength);
frequency=ceil(stackLength/5);
if strcmp(TiffMeta(1).ColorType,'truecolor')
  if A.Config.UseChannel<1||A.Config.UseChannel>3
    error('MATMATLAB:AutoTipTrack:QueueElementClass:readMultilayerTiff','For RGB Tiffs, Config.UseChannel must be an integer between 1 and 3.You entered %d',A.Config.UseChannel);
  end
  for i=1:stackLength
    trackStatus(A.StatusFolder,'Loading stack','',i-1,stackLength,frequency)
    im=imread(fullpath,'tif','Info',TiffMeta,'Index',planesUsed(i));
    A.Stack{i}=im(:,:,A.Config.UseChannel);
  end
else
  for i=1:stackLength
    trackStatus(A.StatusFolder,'Loading stack','',i-1,stackLength,frequency)
    A.Stack{i}=imread(fullpath,'tif','Info',TiffMeta,'Index',planesUsed(i));
  end
end
trackStatus(A.StatusFolder,'Loading stack','',stackLength,stackLength,1)
A.Config.Times=A.Config.Times-A.Config.Times(1);
A.Config.FirstCFrame=A.Config.FirstTFrame;
A.Config.FirstTFrame=1;
A.Config.LastFrame=stackLength;

if A.Config.PreferStackPixSize
  if strcmpi(tempCalib.unit,'nm')
    A.Config.PixSize=tempCalib.x;
  elseif strcmpi(tempCalib.unit,'um') || ...
      strcmpi(tempCalib.unit,sprintf('%cm',181)) ||...
      strcmp(tempCalib.unit,'\u00B5m')
    A.Config.PixSize=tempCalib.x*1000;
  else
    warning('MATLAB:AutoTipTrack:QueueElementClass:readStack','Could not read pixel size from stack %s because I did not recognize the pixel unit: %s. Using pixel size from configuration: %gnm',A.FileName,tempCalib.unit,A.Config.PixSize);
  end
end
A.Config.Width=size(A.Stack{1}, 2);
A.Config.Height=size(A.Stack{1}, 1);

if exist(A.Config.Directory,'file')~=7
  mkdir(A.Config.Directory);
end
end
