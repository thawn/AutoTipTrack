function [tempCalib, Times,Channels,Date]=readImageJTiffMeta(fullpath,tempCalib)
if ~isdeployed
  addpath('bfmatlab');
end
reader = bfGetReader(fullpath);
meta=reader.getGlobalMetadata;
Channels=reader.getSizeC;
numTimes=reader.getSizeT;
unit=meta.get('Unit');
if ~isempty(unit)
  tempCalib.unit=unit;
end
digits=floor(log10(abs(numTimes)+1)) + 1;
pattern=cell(2,1);
pattern{1}=['timestamp #%0' num2str(digits) 'd'];
pattern{2}=['creationTime[%0' num2str(digits) 'd]'];
Times=zeros(1,numTimes);
if ~isempty(meta.get(sprintf(pattern{1},1)))
  for n=1:numTimes
    Times(n)=str2double(meta.get(sprintf(pattern{1},n)));
  end
  if strcmp(meta.get('Software'),'MetaSeries')
    Times=Times./1000;
  end
elseif ~isempty(meta.get(sprintf(pattern{2},0)))
  for n=1:numTimes
    Times(n)=datenum(meta.get(sprintf(pattern{2},n-1)),'HH:MM:SS:FFF')*(24*3500);
  end
  Times=Times-Times(1);
  %correct for the case that imaging was done across days
  deltaT=Times(2:end)-Times(1:end-1);
  indexes=find(deltaT<0);
  Times(indexes)=Times(indexes)+(24*3600);
end
datePattern=cell(2,1);
datePattern{1}='DateTime';
datePattern{2}='dTimeAbsolute';
datePattern{3}='acquisition-time-local';
Date=datetime.empty;
if ~isempty(meta.get(datePattern{1}))
  dateS=meta.get(datePattern{1});
  if strfind(dateS,'/')
    inFmt='dd/MM/yyyy HH:mm:ss:SSS';
  else
    inFmt='yyyyMMdd HH:mm:ss.SSS';
  end
  Date=datetime(dateS,'InputFormat',inFmt);
elseif ~isempty(meta.get(datePattern{2}))
  Date=datetime(str2double(meta.get(datePattern{2})),'ConvertFrom','juliandate');
elseif ~isempty(meta.get(datePattern{3}))
  Date=datetime(meta.get(datePattern{3}),'InputFormat','yyyyMMdd HH:mm:ss.SSS');
end
clear('meta');
clear('reader');
if ~isdeployed
  rmpath('bfmatlab');
end
end
