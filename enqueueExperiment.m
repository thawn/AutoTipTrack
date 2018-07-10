function queue=enqueueExperiment(folderNode,config_file,hEvalGui,queue,reevaluate)
if nargin<3
  hEvalGui=[];
end
if nargin<4
  queue=QueueElementClass.empty;
end
if ~isstruct(folderNode) && ~isempty(hEvalGui)
  %if the folderNode is not a structure but an actual uitreenode
  useGUI=true;
else
  useGUI=false;
end
files=dir(folderNode.getValue);
numFiles=length(files);
if nargin<5
  reevaluate=false;
  for n=1:numFiles
    if strcmp(files(n).name,'eval');
      reevaluate=true;
    end
  end
end
for n=1:numFiles
  isDot=strcmp(files(n).name,{'.','..','.git','eval','ignore','eval_old','done','names'});
  isDot(end+1)=~isempty(regexp(files(n).name,'.*_mcrCache','once','start')); %#ok<AGROW>
  isDot(end+2)=~isempty(regexp(files(n).name,'\._.*','once','start')); %#ok<AGROW>
  if (~any(isDot) && ( files(n).isdir || ...
      strendswith(files(n).name, '.stk') || strendswith(files(n).name, '.nd2') || ...
      strendswith(files(n).name, '.tif') || strendswith(files(n).name, '.tiff') ) )
    fullPath=fullfile(folderNode.getValue,files(n).name);
    if strendswith(files(n).name, '.tif') || strendswith(files(n).name, '.tiff')
      info = imfinfo(fullPath);
      if numel(info)<3 %if we have less than 3 frames
        continue;
      end
    end
    queue=[queue QueueElementClass(fullPath,config_file,useGUI,reevaluate)]; %#ok<AGROW>
    if useGUI
      %create the files(n).node and add it to the folder node
      node=hEvalGui.createNode(fullPath,false);
      folderNode.add(node)
      hEvalGui.enqueueStatusFolder(queue(end),node);
    end
  end
end
end
