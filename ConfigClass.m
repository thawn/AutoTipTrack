classdef ConfigClass < handle
  properties
    Version = 2.03;
    TrackingServer = '';
    PixSize = 266.7;
    Time = 1000;
    FileName = '';
    StackName = '';
    Directory = '';
    StackType = 'TIFF';
    FirstCFrame = 1;
    FirstTFrame = 1;
    LastFrame = 1;
    FilFocus = 0;
    OnlyTrack = struct('MolFull', 0, 'FilFull', 1, 'MolLeft', 0,...
      'FilLeft', 0, 'MolRight', 0, 'FilRight', 0);
    Threshold = struct('Area', 30, 'Mode', 'relative','Height', 2,...
      'Fit', 0, 'FWHM', 534, 'Filter', 'average',...
      'Value', 0.0000e+00 + 1.6000e+02i, 'MinFilamentLength', 3)
    BorderMargin = 2
    Connect = struct('MaxVelocity', 1500, 'Position', 0.4,...
      'Direction', 0.4, 'Speed', 0.2, 'IntensityOrLength', 0,...
      'UseIntensity', 0, 'MinLength', 4, 'MaxBreak', 5, 'MaxAngle', 45,...
      'NumberVerification', 2, 'ReEval', 0);
    ConnectMol = struct('MaxVelocity', 1500, 'Position', 0.4,...
      'Direction', 0.4, 'Speed', 0.2, 'IntensityOrLength', 0,...
      'UseIntensity', 0, 'MinLength', 4, 'MaxBreak', 5, 'MaxAngle', 45,...
      'NumberVerification', 2, 'ReEval', 0);
    MaxFunc = 4
    Model = 'GaussSymmetric'
    ConnectFil = struct('MaxVelocity', 1000, 'Position', 0.3,...
      'Direction', 0.3, 'Speed', 0.2, 'IntensityOrLength', 0.2,...
      'DisregardEdge', 1,'MinLength', 4, 'MaxBreak', 5, 'MaxAngle', 45,...
      'NumberVerification', 2, 'ReEval', 0);
    RefPoint = 'start';
    ReduceFitBox = 1;
    maxObjects = 1000;
    Times = [];
    Avi = struct('BarSize', 25, 'mPosBar', 4, 'mPosTime', 1,...
      'mFontSize', 0.06, 'Make', 0);
    Path = struct('Generate', 1, 'Method', 'Fit', 'Status', 'TBD');
    Width = 512;
    Height = 512;
    UseParpool=true;
    UseChannel = 1;
    UseGui=true;
    SubtractBackground=struct('BallRadius',30,'Smoothe',1);
    PreferStackPixSize=true;
    EvaluationClassName='SpeedEvaluation2Class'
    AcquisitionDate='';
    Evaluation=struct('EvalClassNo',2,...
      'EvalClassNames',{{...
      'SpeedEvaluationClass',...
      'SpeedEvaluation2Class',...
      'BundlingEvaluationClass',...
      'Speed2TempEvaluationClass',...
      'SpeedJannesEvaluationClass',...
      'MakeMovieEvaluationClass',...
      'BioCompEvaluationClass',...
      'DilutionSeriesEvaluationClass',...
      'AngleEvaluationClass'}},...
      'TasksNeeded',{{...
      struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true,'Avi',false),...
      struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true,'Avi',false),...
      struct('Track',true,'Connect',false,'Fit',false,'Evaluate',true,'Overview',true,'Avi',false),...
      struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true,'Avi',false),...
      struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true,'Avi',false),...
      struct('Track',false,'Connect',false,'Fit',false,'Evaluate',true,'Overview',false,'Avi',true),...
      struct('Track',true,'Connect',true,'Fit',false,'Evaluate',true,'Overview',true,'Avi',false),...
      struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true,'Avi',false),...
      struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true,'Avi',false)}},...
      'ImagesNeeded',{{1,1,inf,1,1,inf,inf,1,1}});
    Tasks=struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true,'Avi',false);
    ImageScaling = struct('Modes',{{'auto','manual'}},'ModeNo',1,'Black',0,'White',0);
    LegacyData = false;
  end
  methods
    
    
    function C=ConfigClass(varargin)
      if ~isempty(varargin)
        p=inputParser;
        p.addParameter('Path','',@ischar);
        p.addParameter('ConfigStructure',struct([]),@isstruct);
        p.parse(varargin{:})
        if ~isempty(p.Results.Path)
          C.loadConfig(p.Results.Path);
        end
        if ~isempty(p.Results.ConfigStructure)
          C.importConfigStruct(p.Results.ConfigStructure);
        end
      end
    end
    
    
    function C=loadConfig(C,path)
      load(path,'Config');
      C.importConfigStruct(Config);
    end
    
    
    function C=reloadConfig(C,path)
      load(path,'Config');
      %always use the path from the current config file not from the
      %config that came with the data (in case the data was moved)
      if ~isempty(C.Directory)
        Config.Directory=C.Directory;
      end
      %update the path configuration if it has changed
      if isfield(Config, 'Path') && (~strcmp(Config.Path.Method,C.Path.Method))
        Config.Path.Method=C.Path.Method;
        Config.Path.Status='TBD';
      end
      %Always use the evaluation configuration from the current config to
      %allow changing the evaluation method after tracking the data
      if isfield(Config, 'Evaluation')
        Config.EvaluationClassName=C.EvaluationClassName;
        Config.Evaluation=C.Evaluation;
        Config = ConfigClass.upgradeNeedsWholeStack(Config);
      end
      C.importConfigStruct(Config);
    end
    
    
    function C=importConfigStruct(C,Config)
      Config=ConfigClass.validate(C,Config);
      %now that we are sure that the config structure contains the same
      %elements as the ConfigClass properties, we can just copy them over
      fields=fieldnames(Config);
      for i=1:numel(fields)
        C.(fields{i})=Config.(fields{i});
      end
    end
    
    
    function Config=exportConfigStruct(C)
      fields=fieldnames(C);
      Config=struct();
      for i=1:numel(fields)
        Config.(fields{i})=C.(fields{i});
      end
    end
    
    
    function save(C,config_file)
      Config=C.exportConfigStruct(); %#ok<NASGU>
      save(config_file,'-v6','Config');
    end
    
    
  end
  methods(Static)
    
    
    function Config=upgrade(Config)
      if Config.Version < 1.0
        warning('MATLAB:AutoTipTrack:ConfigClass:upgrade','incompatible version: %f',Config.Version)
      end
      if Config.Version < 1.1
        %these fields were added because they are assigned later in the
        %code and generated errors because they cannot be dynamically
        %created for the class
        if ~isfield (Config,'Width')
          Config.Width = 512;
        end
        if ~isfield (Config,'Height')
          Config.Height = 512;
        end
        if ~isfield (Config,'Connect')
          Config.Connect = struct('MaxVelocity', 1500, 'Position', 0.4,...
            'Direction', 0.4, 'Speed', 0.2, 'IntensityOrLength', 0,...
            'UseIntensity', 0, 'MinLength', 4, 'MaxBreak', 2, 'MaxAngle', 45,...
            'NumberVerification', 2, 'ReEval', 0);
        end
        Config.Version=1.1;
      end
      if Config.Version<1.2
        %Add a parameter to control whether we are going to use a parallel
        %pool
        if ~isfield (Config,'UseParpool')
          Config.UseParpool=true;
        end
        Config.Version=1.2;
      end
      if Config.Version<1.3
        %Add a parameter to control which channel of a multi color
        %stack we want to use.
        if ~isfield (Config,'UseChannel')
          Config.UseChannel=1;
        end
        %Add a parameter to control whether we want a GUI
        if ~isfield (Config,'UseGui')
          Config.UseGui=true;
        end
        Config.Version=1.3;
      end
      if Config.Version<1.4
        %Add a parameter to control background subtraction
        if ~isfield (Config,'SubtractBackground')
          Config.SubtractBackground=struct('BallRadius',30,'Smoothe',1);
        end
        Config.Version=1.4;
      end
      if Config.Version<1.6
        %change the default value for MaxBreak
        if Config.Connect.MaxBreak==2
          Config.Connect.MaxBreak=5;
        end
        if Config.ConnectMol.MaxBreak==2
          Config.ConnectMol.MaxBreak=5;
        end
        if Config.ConnectFil.MaxBreak==2
          Config.ConnectFil.MaxBreak=5;
        end
        %Add a parameter to choose whether to use the pixsize stored in the
        %stack
        if ~isfield(Config, 'PreferStackPixSize')
          Config.PreferStackPixSize=true;
        end
        Config.Version=1.6;
      end
      if Config.Version<1.8
        if Config.Avi.Make
          Config.Avi.Make=false;
        end
        % Add a parameter to configure which class to use for evaluation
        if ~isfield(Config, 'EvaluationClassName')
          Config.EvaluationClassName='SpeedEvaluation2Class';
        end
        % change the default values for SubtractBackground
        if Config.SubtractBackground.BallRadius==20
          Config.SubtractBackground=struct('BallRadius',30,'Smoothe',1);
        end
        Config.Version=1.8;
      end
      if Config.Version<1.9
        %Add a parameter that stores when the stack was imaged
        if ~isfield(Config, 'AcquisitionDate')
          Config.AcquisitionDate='';
        end
        Config.Version=1.9;
      end
      if Config.Version<1.914
        %Add a parameter that stores info about evaluation
        if ~isfield(Config, 'Evaluation')
          Config.Evaluation=struct('EvalClassNo',2,...
            'EvalClassNames',{{...
            'SpeedEvaluationClass',...
            'SpeedEvaluation2Class',...
            'BundlingEvaluationClass'}});
        end
        Config.Version=1.914;
      end
      if Config.Version<1.915
        %Add a parameter that stores info about evaluation
        if ~isfield(Config.Evaluation, 'TasksNeeded')
          Config.Evaluation.TasksNeeded={...
            struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true),...
            struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true),...
            struct('Track',true,'Connect',false,'Fit',false,'Evaluate',true,'Overview',true)};
        end
        if ~isfield(Config.Evaluation, 'NeedsWholeStack')
          Config.Evaluation.NeedsWholeStack={false,false,true};
        end
        if ~isfield(Config, 'Tasks')
          Config.Tasks=Config.Evaluation.TasksNeeded{Config.Evaluation.EvalClassNo};
        end
        Config.Version=1.915;
      end
      if Config.Version<1.916
        %Add a evaluation class for velocity to temperature evaluation
        Config.Evaluation.EvalClassNames=[Config.Evaluation.EvalClassNames,...
          'Speed2TempEvaluationClass'];
        Config.Evaluation.TasksNeeded=[Config.Evaluation.TasksNeeded,...
          struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true)];
        Config.Evaluation.NeedsWholeStack=[Config.Evaluation.NeedsWholeStack,false];
        Config.Version=1.916;
      end
      if Config.Version<1.917
        %Add a evaluation class for Screening evaluation
        Config.Evaluation.EvalClassNames=[Config.Evaluation.EvalClassNames,...
          'SpeedJannesEvaluationClass'];
        Config.Evaluation.TasksNeeded=[Config.Evaluation.TasksNeeded,...
          struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true)];
        Config.Evaluation.NeedsWholeStack=[Config.Evaluation.NeedsWholeStack,false];
        Config.Version=1.917;
      end
      if Config.Version<1.918
        %Add a evaluation class for movie evaluation
        Config.Evaluation.EvalClassNames=[Config.Evaluation.EvalClassNames,...
          'MakeMovieEvaluationClass'];
        for n=1:length(Config.Evaluation.TasksNeeded)
          Config.Evaluation.TasksNeeded{n}.Avi=false;
        end
        Config.Evaluation.TasksNeeded{end+1}=...
          struct('Track',false,'Connect',false,'Fit',false,'Evaluate',true,'Overview',false,'Avi',true);
        Config.Evaluation.NeedsWholeStack=[Config.Evaluation.NeedsWholeStack,true];
        Config.Tasks=Config.Evaluation.TasksNeeded{Config.Evaluation.EvalClassNo};
        Config.ImageScaling = struct('Modes',{{'auto','manual'}},'ModeNo',1,'Black',0,'White',0);
        Config.Version=1.918;
      end
      if Config.Version<2.0
        Config.LegacyData = true;
        %Add a evaluation class for biocomputation junction evaluation
        Config.Evaluation.EvalClassNames=[Config.Evaluation.EvalClassNames,...
          'BioCompEvaluationClass'];
        Config.Evaluation.TasksNeeded=[Config.Evaluation.TasksNeeded,...
          struct('Track',true,'Connect',true,'Fit',false,'Evaluate',true,'Overview',true,'Avi',false)];
        Config.Evaluation.NeedsWholeStack=[Config.Evaluation.NeedsWholeStack,true];
        Config.Version=2.0;
      end
      if Config.Version < 2.01
        Config = ConfigClass.upgradeNeedsWholeStack(Config);
        Config.Version = 2.01;
      end
      if Config.Version < 2.02
        Config.LegacyData = true;
        %Add a evaluation class for dilution series evaluation
        Config.Evaluation.EvalClassNames=[Config.Evaluation.EvalClassNames,...
          'DilutionSeriesEvaluationClass'];
        Config.Evaluation.TasksNeeded=[Config.Evaluation.TasksNeeded,...
          struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true,'Avi',false)];
        Config.Evaluation.ImagesNeeded=[Config.Evaluation.ImagesNeeded,true];
        Config.Version=2.02;
      end
      if Config.Version < 2.03
        Config.LegacyData = true;
        %Add a evaluation class for dilution series evaluation
        Config.Evaluation.EvalClassNames=[Config.Evaluation.EvalClassNames,...
          'AngleEvaluationClass'];
        Config.Evaluation.TasksNeeded=[Config.Evaluation.TasksNeeded,...
          struct('Track',true,'Connect',true,'Fit',true,'Evaluate',true,'Overview',true,'Avi',false)];
        Config.Evaluation.ImagesNeeded=[Config.Evaluation.ImagesNeeded,true];
        Config.Version=2.03;
      end
      
    end
    
    
    function Config = upgradeNeedsWholeStack(Config)
      if isfield(Config.Evaluation, 'NeedsWholeStack')
        for n = 1:length(Config.Evaluation.NeedsWholeStack)
          if Config.Evaluation.NeedsWholeStack{n}
            Config.Evaluation.ImagesNeeded{n} = Inf;
          else
            Config.Evaluation.ImagesNeeded{n} = 1;
          end
        end
        Config.Evaluation.ImagesNeeded{7} = inf;
        Config.Evaluation = rmfield(Config.Evaluation, 'NeedsWholeStack');
      end
    end
    
    
    function Config=validate(C,Config)
      if isstruct(Config)
        if isfield(Config,'Version')
          %use the proper upgrade routine if we know the version of the
          %configuration
          Config=ConfigClass.upgrade(Config);
        elseif isfield(Config,'StackType') && strcmpi(Config.StackType,'TIFF') ...
            && isempty(Config.FileName) && ~isempty(Config.Directory)
          %for old configs, we need to fix the stack name for many tiff
          %files
          Config.FileName=Config.StackName;
          separators=strfind(Config.Directory,'/');
          if isempty(separators) %if the directory was saved under windows
            separators=strfind(Config.Directory,'\');
          end
          Config.StackName=Config.Directory(separators(end-2)+1:separators(end-1)-1);
        end
        %check the two Config structures for consistency
        try
          equal=strcmp(fieldnames(Config),fieldnames(C));
        catch
          equal=false;
        end
        if ~all(equal)
          notInConfig=setdiff(fieldnames(C),fieldnames(Config));
          notInC=setdiff(fieldnames(Config),fieldnames(C));
          if ~isempty(notInConfig)
            if ~iscell(notInConfig)
              notInConfig={notInConfig};
            end
            fprintf('The field(s) "%s" appear(s) in the config object but not in the imported configuration. Using default value(s).\n',strjoin(notInConfig, ', '));
            for j=1:length(notInConfig)
              Config.(notInConfig{j})=C.(notInConfig{j});
            end
          end
          if ~isempty(notInC)
            if ~iscell(notInC)
              notInC={notInC};
            end
            fprintf('The field(s) "%s" appears in the imported configuration but not in the config object. The extra fields will be ignored. This can happen when you are importing a config from a newer version or from FIESTA.\n',strjoin(notInC,', '));
            for j=1:length(notInC)
              Config.(notInC{j})=[];
            end
          end
        end
        %recursively check substructures
        fields=fieldnames(Config);
        for i=1:numel(fields)
          if isstruct(Config.(fields{i}))
            Config.(fields{i})=ConfigClass.validate(C.(fields{i}),Config.(fields{i}));
          end
        end
      else
        error('AutoTipTrack:ConfigClass:validate:TypeError','Config parameter must be a structure.');
      end
    end
    
    
  end
end
