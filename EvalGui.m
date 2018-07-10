classdef EvalGui < handle
  properties
    fig;
    mtree;
    StatusQueue=struct([]);
    Interface=struct();
    Log=fullfile(pwd,'AutoTipTrack_log.txt');
  end
  methods
    
    %% queue handling
    
    
    function E=addTree(E,folder,varargin)
      if nargin>0
        % create a new GUI window
        disp('creating GUI');
        E.fig=figure('DockControls','off','IntegerHandle','off','MenuBar','none','Name',...
          'evaluateManyExperiments - Status','NumberTitle','off','Tag','hEvalGui');
        fPlaceFig(E.fig,'big');
        set(E.fig,'Units','pixels');
        warning('off','MATLAB:uitreenode:DeprecatedFunction');
        if ischar(folder)
          %we assume folder is a path and need to make sure folder ends
          %with a filesep otherwise uitree cannot expand subdirectories
          if ~strendswith(folder,filesep)
            folder=[folder filesep];
          end
        end
        %create the uitree either from the folder node or from the path
        E.mtree = uitree('v0', 'Root', folder);
        E.mtree.expand(E.mtree.Root)
        drawnow;
        if nargin < 3
          p=get(E.fig,'pos');
          E.mtree.Position(3)=p(3);
        else
          E.Interface = varargin;
          E.mtree.NodeSelectedCallback=@(mtree,value)EvalGui.selectNode(mtree,value,E);
          E.mtree.setSelectedNode(E.StatusQueue(1).Node)
        end
      else
      end
    end
    
    
    function t=watchProgress(E)
      disp('starting refresh timer');
      t = timer('StartDelay',0.5,'TimerFcn',@E.refreshProgress,'StopFcn',@E.timerStopped,'Period',4,'TasksToExecute', Inf,'Tag','AutoTipTrack:EvalGui:ProgressTimer',...
        'ExecutionMode','fixedRate','BusyMode','queue','UserData',E);
      start(t)
    end
    
    
    function E=enqueueStatusFolder(E,QueueEl,node)
      E.StatusQueue=[E.StatusQueue struct('QueueElement',QueueEl,'Node',node,'TotalTime',0)];
    end
    
    
    function E=refreshFolder(E,queuePos)
      status='progress';
      if exist(E.StatusQueue(queuePos).QueueElement.StatusFolder,'file')==7
        files = dir(fullfile(E.StatusQueue(queuePos).QueueElement.StatusFolder , '*.mat'));
        n=length(files);
        %if n==0 we don't have status files yet and don't have anything to do
        if n>0
          w=20; %the width of the progress bar
          [curTime, id, ~, maxNum, ~, message] = E.getInfo(files(end).name);
          notFound=true;
          %now we try to find the first file with the same id as the current file
          while notFound
            info=strsplit(files(n).name,'_','CollapseDelimiters',false);
            if ~strcmp(id,info{3})
              notFound=false;
              n=n+1;%go back to the last file that had the same id
            elseif n<2
              %if n=1 we only have one kind of status file and files(1) is
              %the first file with that id
              notFound=false;
            else
              n=n-1;
            end
          end
          %get the frequency from the first file since we sometimes change
          %the frequency to 1 for the last frame to make sure we always
          %catch the last frame
          [startTime,~,~,~,freq,~] = E.getInfo(files(n).name);
          filecount=length(files)-n+1;
          doneNum=(filecount-1)*freq;%the files are created at the start of the loop so we subtract one here.
          if doneNum>=maxNum %if we are done
            elapsed=etime(curTime,startTime);
            ETR=E.sec2timestr(elapsed);
            ETR_str='ElT:';
            bar=E.progBar(w,100);
            doneNum=maxNum;
            status='done';
            firstTime=E.getInfo(files(1).name);
            E.StatusQueue(queuePos).TotalTime=etime(curTime,firstTime);
          else
            elapsed=etime(curTime,startTime);
            timeleft = elapsed*maxNum/doneNum - elapsed;
            ETR_str='ETR:';
            percent=doneNum/maxNum*100;
            bar=E.progBar(w,percent);
            ETR=E.sec2timestr(timeleft);
          end
          msg=sprintf('%s: %s %d/%d %s %s | %s',id,bar,doneNum,maxNum,ETR_str,ETR,message);
          E.renameNode(E.StatusQueue(queuePos).Node,msg,status);
          E.mtree.reloadNode(E.StatusQueue(queuePos).Node);
        end
      else
        E.stopWatchingFolder(queuePos);
      end
    end
    
    
    function E=stopWatchingFolder(E,queuePos)
      if E.StatusQueue(queuePos).QueueElement.Success
        status='done';
        msg='Analysis finished.';
      else
        if isempty(E.StatusQueue(queuePos).QueueElement.Message)
          %if we don't have an error message, we are likely using
          %monitorProgress, let's try to figure out if tracking was already
          %successful by loading the results file
          [status,msg]=E.testSuccess(queuePos);
        else
          status='error';
          msg=['Error: ', E.StatusQueue(queuePos).QueueElement.Message];
        end
      end
      ETR=E.sec2timestr(E.StatusQueue(queuePos).TotalTime);
      msg=sprintf('Total ElT: %s. %s',ETR,msg);
      E.renameNode(E.StatusQueue(queuePos).Node,msg,status);
      E.mtree.reloadNode(E.StatusQueue(queuePos).Node);
      drawnow;
      if length(E.StatusQueue) > queuePos
        E.StatusQueue(queuePos)=[];
      end
    end
    
    
    function [status,msg]=testSuccess(E,queuePos)
      if ~E.StatusQueue(queuePos).QueueElement.reloadResults ...
          && E.StatusQueue(queuePos).QueueElement.Config.Tasks.Connect...
          || ~E.StatusQueue(queuePos).QueueElement.reloadResults('Objects')...
          && E.StatusQueue(queuePos).QueueElement.Config.Tasks.Track
        status='error';
        msg='Warning: No tracks found. An error may have occurred, check the log files.';
      else
        status='done';
        msg='Analysis finished.';
      end
    end
    
    function E=setRootNode(E,rootNode)
      E.mtree.setRoot(rootNode)
    end
    
    
    function E=addUitree(E,rootNode)
      E.mtree = uitree('v0', 'Root', rootNode);
    end
    
    
    function expandAllNodes(E,node)
      if nargin<2
        node=E.mtree.getRoot;
      end
      if ~node.isLeafNode
        E.mtree.expand(node);
        for n=1:node.getChildCount
          child=node.getChildAt(n-1);
          E.expandAllNodes(child);
        end
      end
    end
    
    
    function [found,node]=findNode(E,path,node)
      if nargin<3
        node=E.mtree.getRoot;
      end
      found=false;
      nodePath=node.getValue;
      % a filesep at the end of either path does not matter. Make sure we
      % match the node even if one has a fielesep at the end and the other
      % does not.
      if strendswith(path,filesep)
        path=path(1:end-1);
      end
      if strendswith(nodePath,filesep)
        nodePath=nodePath(1:end-1);
      end
      %if the paths match, we have found our node
      if strcmp(path,nodePath)
        found=true;
        return;
      end
      %if node is not a leafnode, we recursively search through the child
      %nodes
      if ~node.isLeafNode
        for n=1:node.getChildCount
          child=node.getChildAt(n-1);
          [found,child]=E.findNode(path,child);
          if found
            node=child;
            return;
          end
        end
      end
    end
    
    
    function queuePos=findQueuePos(E,path)
      queuePos=[];
      for n=1:length(E.StatusQueue)
        if strcmp(E.StatusQueue(n).Node.getValue,path)
          queuePos=n;
        end
      end
    end
    
    
    function E=reenqueueForRefresh(E,QueueEl,path)
      [found,node]=findNode(E,path);
      if ~found
        error('MATLAB:AutoTipTrack:EvalGui:reenqueuePath','No node found that corresponds to path: %s',path)
      end
      E.enqueueStatusFolder(QueueEl,node);
    end
    
    
    function E=refresh(E)
      %go through the status queue in reverse order because some queue
      %elements might be deleted by refreshFolder.
      for n=length(E.StatusQueue):-1:1
        E.refreshFolder(n);
      end
      drawnow;
    end
    
    
    %% closing UI
    function close(E,~,~)
      if ishandle(E.fig)
        close(E.fig);
      end
      E.mtree.NodeSelectedCallback=@(mtree,value)true; %need to reset the callback to avoid a circular dependency between EvalGui and mtree;
      clear('E');
    end
    
    
    function closeFig(E,~,~)
      close(E.fig);
    end
    
    
  end
  methods (Static)

    
    function renameNode(node, msg,status)
      persistent progressnum;
      switch status
        case 'done'
          color='green';
          jImage = java.awt.Toolkit.getDefaultToolkit.createImage(which('Done_16px.png'));
        case 'progress'
          if isempty(progressnum)||progressnum==1
            progressnum=12;
          else
            progressnum=progressnum-1;
          end
          imagename=sprintf('progress_%d.png', progressnum);
          color='orange';
          jImage = java.awt.Toolkit.getDefaultToolkit.createImage(which(imagename));
        otherwise
          color='red';
          jImage = java.awt.Toolkit.getDefaultToolkit.createImage(which('warning_16.png'));
      end
      oldname=strsplit(char(node.getName),'<html>');
      if length(oldname)>1
        nameparts=strsplit(oldname{2},'<font');
        name=nameparts{1};
      else
        name=oldname{1};
      end
      node.setName([ '<html>', name, '<font face="Courier" color="', color, '"> ', msg, '</font></html>']);
      node.setIcon(jImage);
    end
    
    
    function refreshProgress(obj, ~)
      E=get(obj,'UserData');
      if length(E.StatusQueue)<1
        drawnow;
        stop(obj);
        return;
      end
      E.refresh;
    end
    
    
    function timerStopped(obj, ~)
      delete(obj);
    end
    
    
    function bar=progBar(w,percent)
      scale=w/100;
      done=floor(percent*scale);
      todo=w-done;
      if todo==0
        sep='=';
      else
        sep='>';
      end
      bar=['[',repmat('=',1,done),sep,repmat('&nbsp;',1,todo),']'];
    end
    
    
    function [dateTime, id, curN, maxNum, freq, message] = getInfo(filename)
      info=strsplit(filename,'_','CollapseDelimiters',false);
      date=info{1};
      time=info{2};
      dateTime=datevec([date,'_', time],'yyyy-mm-dd_HH-MM-SS-FFF');
      id=info{3};
      curN=str2double(info{4});
      maxNum=str2double(info{5});
      freq=str2double(info{6});
      message=info{7};
    end
    
    
    function timestr = sec2timestr(sec)
      if isnan(sec)||isinf(sec)
        timestr='unknown  ';
      else
        h = floor(sec/3600); % Hours
        sec = sec - h*3600;
        m = floor(sec/60); % Minutes
        sec = sec - m*60;
        s = floor(sec); % Seconds
        timestr = sprintf('%02d:%02d:%02d',h,m,s);
      end
    end
    
    
    function node=createNode(path,isFolder)
      [~,name,ext]=fileparts(path);
      if isFolder
        jImage = which('folder_16.png');
      else
        jImage = which('image_16.png');
      end
      node=uitreenode('v0',path,[name ext],jImage,~isFolder);
    end
    
    
    function selectNode(mtree,~,E)
      Selected=mtree.getSelectedNodes;
      if ~isempty(Selected)
        Path=Selected(1).getValue;
        QueuePos=E.findQueuePos(Path);
        Interactive = InteractiveGUI(E.StatusQueue(QueuePos).QueueElement.Config.exportConfigStruct);
        Interactive.StatusFolder = E.StatusQueue(QueuePos).QueueElement.StatusFolder;
        Interactive.Stack = E.StatusQueue(QueuePos).QueueElement.Stack;
        Interactive.setupInteractivePanel(E.Interface{:});
        uiwait(Interactive.UIFig);
        if isempty(E.StatusQueue(QueuePos).QueueElement.Stack) && ~isempty(Interactive.Stack)
          E.StatusQueue(QueuePos).QueueElement.Stack = Interactive.Stack;
        end
        clear('Interactive');
      end
    end
    
    
  end
end
