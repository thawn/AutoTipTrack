function A = readManyTiffs(A)
tiff_path=fullfile(A.FilePath,A.FileName);
%hack to get rid of mac os ._*.tif hidden files which contain extended attributes
fake_tifs=[tiff_path filesep '._*.tif'];
files=dir(fake_tifs);
if ~isempty(files)
  for n=1:length(files)
    delete([tiff_path filesep files(n).name]);
  end
end
%now we can safely load all tifs
tiff_path_name=[tiff_path filesep '*.tif'];
files=dir(tiff_path_name);
if isempty(files)
  error(['No tif files found in: ' tiff_path_name]);
end
if A.Config.LastFrame>1
  files=files(A.Config.FirstTFrame:A.Config.LastFrame);
end
A.Config.FirstCFrame=A.Config.FirstTFrame;
A.Config.FirstTFrame=1;
A.Config.LastFrame=length(files);
infoFiles=dir(fullfile(tiff_path,'*.txt'));
if ~isempty(infoFiles)
  infoFile=fopen(fullfile(tiff_path,infoFiles(1).name));
  infoText=fscanf(infoFile,'Date%s%s%s%s%s%s');
  A.Config.AcquisitionDate=datetime(infoText,'InputFormat','eeee,MMMMdd,yyyy,hh:mm:ssa');
end
Stack=cell(1,A.Config.LastFrame);
Times=zeros(1,A.Config.LastFrame);
frequency=ceil(A.Config.LastFrame/5);
StatusFolder=A.StatusFolder;
Time=A.Config.Time;
numF=A.Config.LastFrame;
parfor n=1:numF
  trackStatus(StatusFolder,'Loading stack','',n-1,numF,frequency)
  Stack{n}=imread(fullfile(tiff_path, files(n).name));
  Times(n)=(n-1)*Time/1000;
end
A.Stack=Stack;
A.Config.Times=Times;
trackStatus(A.StatusFolder,'Loading stack','',A.Config.LastFrame,A.Config.LastFrame,1)
A.Config.Width=size(A.Stack{1}, 2);
A.Config.Height=size(A.Stack{1}, 1);
A.Config.Directory=fullfile(A.FilePath, 'eval');
if ~(exist(A.Config.Directory,'file')==7) %create the eval tiff_path if it does not exist yet
  mkdir(A.Config.Directory)
end
A.Config.StackName=A.FileName;
A.Config.FileName=files(1).name;
% Config.Time=1600;
A.Config.StackType='TIFF';
warning off MATLAB:DELETE:FileNotFound;
file =fullfile(A.Config.Directory, A.Config.StackName);
if ~strendswith(file,'.tif')
  file=[file '.tif'];
end
delete(file);

for n=1:length(A.Stack)
  imwrite(A.Stack{n}, file, 'writemode', 'append', 'Compression', 'none');
end
warning on MATLAB:DELETE:FileNotFound;

