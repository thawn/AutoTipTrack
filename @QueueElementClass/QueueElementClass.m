classdef QueueElementClass < AutoTipTrackDataClass
  properties
    Aborted=false;
    HEvalGui;
    MakeAviLater=false;
    Message='';
    Reevaluate=false;
    Success=false;
    TrackParallel=false;
    UseGui=false;
  end
  methods
    
    
    function Q = QueueElementClass(fullpath,config_file,UseGui,reevaluate)
      if nargin < 2
        config_file = ConfigClass;
      end
      Q@AutoTipTrackDataClass(config_file)
      if nargin>0
        if strendswith(fullpath,filesep)
          fullpath=fullpath(1:end-1);
        end
        if exist(fullpath,'file')~=2 && exist(fullpath,'file')~=7
          error('MATLAB:AutoTipTrack:QueueElementClass:FileNotFound', 'File not found: "%s"',fullpath);
        end
        [Q.FilePath, name, ext]=fileparts(fullpath);
        Q.FileName=[name ext];
        Q.Config.StackName=Q.FileName;
        Q.Config.Directory=fullfile(Q.FilePath, 'eval');
      end
      if nargin>1
        file_specific_conf=fullfile(Q.FilePath, [Q.FileName '_conf.mat']);
        if exist(file_specific_conf, 'file')==2
          Q.Config.loadConfig(file_specific_conf);
        end
        Q.Config.StackName=Q.FileName;
        Q.Config.Directory=fullfile(Q.FilePath, 'eval');
        if exist(Q.Config.Directory,'file')~=7
          mkdir(Q.Config.Directory)
        end
        Q.StatusFolder=fullfile(Q.Config.Directory,[Q.FileName '_status']);
        if exist(Q.StatusFolder,'file')~=7
          mkdir(Q.StatusFolder)
        end
      end
      if nargin>2
        Q.UseGui=UseGui;
      end
      if nargin>3
        Q.Reevaluate=reevaluate;
      end
    end
    
    
    % external methods
    Q = autoTipTrack(Q)
    Q = connectTracks(Q)
    [DataEvaluator,Q]=evaluateData(Q,varargin)
    [MolTrack,FilTrack] = featureConnect(Q)
    Q = fitPathsToTracks(Q)
    Q = generatePaths(Q)
    Q = trackTips(Q)
    
    
    function Q=finish(Q)
      Q.abort;
    end
    
    
    function Q=abort(Q,message)
      if nargin < 2
        Q.Success=true;
      else
        Q.Success=false;
        Q.Message=message;
      end
      Q.Aborted=true;
      try
        rmdir(Q.StatusFolder, 's');
      catch ME
        ME.getReport;
      end
    end
    
    
%     function delete(Q)
%       try
%         rmdir(Q.StatusFolder, 's');
%       catch
%       end
%     end
    
    
  end
  methods (Static)
    [X,Y,Dis,Side]=averagePath(Results,DisRegion)
    Threshold=calculateThreshold(Config,Stack)
    [X,Y,Dis,Side,Resnorm]=fitPath(Results)
  end
end
