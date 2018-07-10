function queue=enqueueManyExperiments(rootNode,config_file,hEvalGui,queue)
if nargin<2
  config_file='';
end
if nargin<3
  if ~isstruct(rootNode)
    error('MATLAB:AutoTipTrack:enqueueManyExperiments:WrongArguments','enqueueManyExperiments must be called either with a uitreenode as first argument AND a gui handle or with a path string as first argument');
  end
  hEvalGui=[];
end
if nargin<4
  queue=QueueElementClass.empty;
end
if ~isstruct(rootNode)
  %we assume that root node is a uitreenode and we have a gui
  useGUI=true;
else
  useGUI=false;
end
files=dir(rootNode.getValue);
if exist(rootNode.getValue,'file')~=2 && exist(rootNode.getValue,'file')~=7
  error('MATLAB:AutoTipTrack:enqueueManyExperiments:FileNotFound', 'File not found: "%s"',rootNode.getValue);
end
for n=1:length(files)
  fullPath=fullfile(rootNode.getValue,files(n).name);
  if useGUI
    %create the node and add it to the root node
    node=EvalGui.createNode(fullPath,true);
  else
    node.getValue=fullPath;
  end
  if files(n).isdir
    isDot=strcmp(files(n).name,{'.','..','.git','eval','ignore','eval_old','done','names'});
    isDot(end+1)=~isempty(regexp(files(n).name,'.*_mcrCache','once','start')); %#ok<AGROW>
    if ~any(isDot) %if we don't ignore the directory, check if it contains images
      children=dir(fullPath);
      foundImages=false;
      numTiffs=0;
      for i=1:length(children)
        isTiff=~cellfun(@isempty,regexpi(children(i).name,{'^(?![.]).*\.tif','^(?![.]).*\.tiff'}));
        if any(isTiff)
          info = imfinfo(fullfile(fullPath,children(i).name));
          if numel(info)>1 %if we have a multipage tiff
            specific_conf=fullfile(fullPath,'config.mat');
            if exist(specific_conf, 'file')~=2
              success=copyfile(config_file,specific_conf);
              if ~success
                specific_conf=config_file;
              end
            end
            if useGUI
              rootNode.add(node);
            end
            queue=enqueueExperiment(node,specific_conf,hEvalGui,queue);
            foundImages=true;
            break;
          else
            numTiffs=numTiffs+1;
            if numTiffs>1%make sure that there is more than one image before we start tracking
              %if we have many tiffs in a subfolder, the rootnode is
              %actually just one experiment, enqueue that one
              specific_conf=fullfile(rootNode.getValue, 'config.mat');
              if exist(specific_conf, 'file')~=2
                success=copyfile(config_file,specific_conf);
                if ~success
                  specific_conf=config_file;
                end
              end
              queue=enqueueExperiment(rootNode,specific_conf,hEvalGui,queue);
              foundImages=true;
              break;
            end
          end
        end
        isStk=~cellfun(@isempty,regexpi(children(i).name,{'^(?![.]).*\.stk','^(?![.]).*\.nd2'}));
        if any(isStk)
          specific_conf=fullfile(fullPath,'config.mat');
          if exist(specific_conf, 'file')~=2
            success=copyfile(config_file,specific_conf);
            if ~success
              specific_conf=config_file;
            end
          end
          if useGUI
            rootNode.add(node);
          end
          queue=enqueueExperiment(node,specific_conf,hEvalGui,queue);
          foundImages=true;
          break;
        end
      end
      if ~foundImages %if none of the child folders contained images recursively descend into the child folder
        if useGUI
          rootNode.add(node);
        end
        queue=enqueueManyExperiments(node, config_file, hEvalGui,queue);
      end
    end
  else %if files(n) is not a directory
    isStk=~cellfun(@isempty,regexpi(files(n).name,{'^(?![.]).*\.stk','^(?![.]).*\.nd2'}));
    isTiff=~cellfun(@isempty,regexpi(files(n).name,{'^(?![.]).*\.tif','^(?![.]).*\.tiff'}));
    if any(isTiff)
      info = imfinfo(fullPath);
      if numel(info)>1 %if we have a multipage tiff
        isStk=true;
      end
    end
    if any(isStk) %if we have stacks in the rootNode, this is actually just one experiment, enqueue that.
      queue=enqueueExperiment(rootNode,config_file,hEvalGui,queue);
      break;
    end
  end
end
end
