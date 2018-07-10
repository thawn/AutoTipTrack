function autoRenameFiles(path)
nameFolder=fullfile(path,'names');
if exist(nameFolder,'file')==7
  names=analyzeName(nameFolder,{''});
  
  files=dir(fullfile(path));
  %we are only interested in renaming files
  files=files(~[files.isdir]);
  %now we only keep files with extension we like: nd2|tif|stk
  files={files(~cellfun(@isempty,regexpi({files.name},'.*(nd2|tif|stk)'))).name};
  [~, fileNames, exts]=cellfun(@fileparts,files,'UniformOutput',false);
  %if there are numbers at the end of the filenames, copy them over.
  fileNumbers=repmat({''},1,length(names));
  [startInd, endInd]=regexp(fileNames,'\d+$');
  for n=1:length(fileNames)
    fileNumbers{n}=fileNames{n}(startInd{n}:endInd{n});
  end
  try
    names=strcat(names,fileNumbers,exts);
  catch ME
    if strcmp(ME.identifier,'MATLAB:strcat:InvalidInputSize')
      error('MATLAB:autoRenameFiles:InvalidNumberOfFiles',...
        'The number of files (%d) does not match the number of new names generated (%d). Check whether you have accounted for all files. aborting.',...
        length(files),length(names));
    else
      rethrow(ME)
    end
  end
  confirmRename(path,files,names);
end
end

function checkNames(files,names)
  uniqueNames=unique(names);
  if length(names)~=length(uniqueNames)
    dup=setdiff(sort(names),uniqueNames);
    error('MATLAB:autoRenameFiles:DuplicateNames',...
      'Your output structure created duplicate names: %s. aborting!',dup);
  end
  collision=setdiff(files,names);
  if length(collision)~=length(files)
    col=setdiff(files,collision);
    error('MATLAB:autoRenameFiles:NameCollision',...
      'Your output structure created names that already exist: %s. aborting!',[col{:}]);
  end
end

function doRename(callerHandle,~,path,files,names)
checkNames(files,names)
undoFile=fullfile(path,'undoRename.mat');
save(undoFile,'files','names');
set(callerHandle,'String','Undo Rename',...
  'Callback',{@undoRename,path,files,names});
filesDone={};
namesDone={};
for n=1:length(files)
  target=fullfile(path,names{n});
  try
    if exist(target,'file')
      error('MATLAB:autoRenameFiles:TargetFileExists',...
        'Output File already exists: %s. aborting',target);
    end
    movefile(fullfile(path,files{n}),target);
    filesDone=[filesDone files(n)]; %#ok<AGROW>
    namesDone=[namesDone names(n)]; %#ok<AGROW>
  catch ME
    save(fullfile(path,'undoPartialRename.mat'),'filesDone','namesDone');
    undoRename(callerHandle,[],path,filesDone,namesDone);
    set(callerHandle,'String','Rename Now',...
      'Callback',{@doRename,path,files,names});
    rethrow(ME);
  end
end
end

function undoRename(callerHandle,~,path,files,names)
doRename(callerHandle,[],path,names,files);
set(callerHandle,'String','Rename Now',...
  'Callback',{@doRename,path,files,names});
end

function closeCallback(~, ~, handle)
close(handle);
end

function confirmRename(path,files,names)
tableHeading={'Current Name -> New Name',''};
tabular=cellfun(@(x) sprintf('%s -> ',x),files,'UniformOutput',false);
tabular=strcat(tabular,names);
table=[tableHeading, tabular];
%textW=max(cellfun(@length,table))*10;
textH=length(table);
%set(0,'units','pixels');
%pixScrS = get(0,'screensize');
%maxWinS=pixScrS*0.9;
fig1=figure('Units','normalized','OuterPosition',[0.05 0.05 0.9 0.9]);
panel1 = uipanel('Parent',fig1,'Position',[0 0.05 1 0.95],...
  'Title','This is how the files will be renamed:');
textBox = uicontrol('Parent',panel1,'Style','edit','Units','normalized',...
  'Position',[0 0 1 1],...
  'FontSize',12,'HorizontalAlignment','left',...
  'Max',textH,...
  'String', table);
panel3 = uipanel('Parent',fig1,'Position',[0 0 1 0.05]);
okButton=uicontrol(panel3,'Style','pushbutton',...
  'Units','normalized','Position',[0.5 0 0.28 1],...
  'String','Rename Now',...
  'Callback',{@doRename,path,files,names});
undoFile=fullfile(path,'undoRename.mat');
undoPartialFile=fullfile(path,'undoPartialRename.mat');
if exist(undoPartialFile,'file')
  load(undoPartialFile);
  set(okButton,'String','Undo Partial Rename',...
  'Callback',{@undoRename,path,filesDone,namesDone});
elseif exist(undoFile,'file')==2;
  load(undoFile);
  set(okButton,'String','Undo Rename',...
  'Callback',{@undoRename,path,files,names});
end
cancelButton=uicontrol(panel3,'Style','pushbutton',...
  'Units','normalized','Position',[0.8 0 0.18 1],...
  'String','Cancel',...
  'Callback',{@closeCallback,fig1}); %#ok<NASGU>
warning('off','MATLAB:handle_graphics:exceptions:SceneNode');
set(textBox,...
  'String',table);
warning('on','MATLAB:handle_graphics:exceptions:SceneNode');
%uiwait(fig1);
end

function string=replaceLatexCharacters(string)
escapeStrings={'\','_','&','$','#'};
replaceStrings={'\textbackslash','\_','\&','\$','\#'};
for n=1:length(escapeStrings)
  string=strrep(string,escapeStrings{n},replaceStrings{n});
end
end

function slider_callback1(src,~,arg1)
val = get(src,'Value');
set(arg1,'Position',[0 -val 1 2])
end

function newNames=analyzeName(nameFolder,names)
subFolders=dir(nameFolder);
%first collect all folders
subFolders=subFolders([subFolders.isdir]);
%then remove all hidden folders starting with a dot
subFolders=subFolders(arrayfun(@(x) x.name(1), subFolders) ~= '.');

numFolders=length(subFolders);
if numFolders<1
  newNames=names;
else
  newNames={};
  for n=1:numFolders
    split=strsplit(subFolders(n).name,'#');
    if length(split)>1
      name=strjoin(split(2:end),'#');
    else
      name=split;
    end
    newNames=[newNames analyzeName(fullfile(nameFolder, subFolders(n).name),strcat(names,name))]; %#ok<AGROW>
  end
end
end
