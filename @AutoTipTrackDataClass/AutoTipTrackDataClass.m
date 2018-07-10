classdef AutoTipTrackDataClass < handle
  properties
    Config;
    FileName='';
    FilePath='';
    StatusFolder='';
    Debug=0;
    Stack=cell(0);
    Filament=fDefStructure([],'Filament');
    Molecule=fDefStructure([],'Molecule');
    Objects=cell(0);
    Results=struct();
    SavePath='';
  end
  methods
    
    
    function A = AutoTipTrackDataClass(Config)
      A.Config=ConfigClass;
      if nargin > 0
        if ischar(Config)
          if exist(Config , 'file')==2
            A.Config.loadConfig(Config);
            Dir = fileparts(Config);
            if ~strendswith(Dir, 'eval')
              Dir = fullfile(Dir,'eval');
            end
            A.Config.Directory = Dir;
          else
            warning('MATLAB:AutoTipTrack:AutoTipTrackDataClass','Config file not found: "%s". Using a default configuration.',Config)
          end
        elseif isa(Config,'ConfigClass')
          A.Config=Config;
        elseif isa(Config, 'AutoTipTrackDataClass') && isa(Config.Config, 'ConfigClass')
          A.Config=Config.Config;
        elseif isstruct(Config)
          A.Config.importConfigStruct(Config);
        else
          warning('MATLAB:AutoTipTrack:AutoTipTrackDataClass','The config argument must either be a string containing a path to a config file, a config object, or a config structure. Using a default configuration.');
        end
      end
      A.FileName = A.Config.StackName;
      if strendswith(A.Config.Directory, 'eval')
        A.FilePath = A.Config.Directory(1:end-5);
      else
        A.FilePath = A.Config.Directory;
      end
    end
    
    
    % external methods
    A = loadMiddleImage(A)
    A = readManyTiffs(A)
    A = readMultilayerTiff(A)
    A = readND2(A)
    A = readStack(A)
    [TiffInfo,MetaInfo,StackInfo, A] = stackRead(A)

    
    
    function A = loadFile(A)
      A.Stack=cell(0);
      if exist(fullfile(A.FilePath,A.FileName),'file')==2 %if we have a file, check if it is a metamorph stack
        if strendswith(A.FileName, '.stk')
          A.readStack;
        elseif strendswith(A.FileName, '.tif') || strendswith(A.FileName, '.tiff')
          A.readMultilayerTiff;
        elseif strendswith(A.FileName, '.nd2')
          A.readND2;
        end
      else %if we have a subfolder load tiff images inside
        A.readManyTiffs;
      end
      if A.Config.SubtractBackground.BallRadius>0
        stack=A.Stack;
        BallRadius=A.Config.SubtractBackground.BallRadius;
        Smoothe=A.Config.SubtractBackground.Smoothe;
        SFolder = A.StatusFolder;
        StackLength = length(A.Stack);
        Frequency = round(StackLength/20);
        parfor n=1:StackLength
          trackStatus(SFolder,'Processing stack','',n-1,StackLength,Frequency);
          stack{n}=flattenImage(stack{n},BallRadius,Smoothe);
        end
        A.Stack=stack;
        trackStatus(SFolder,'Processing stack','',StackLength,StackLength,1);
      end
      if isempty(A.Config.AcquisitionDate)
        %fall back to file modification date
        FileInfo=dir(fullfile(A.FilePath,A.FileName));
        A.Config.AcquisitionDate=datetime(FileInfo(1).date);
      end
    end
    
    
    function A=saveFiestaCompatibleFile(A)
      if isempty(A.SavePath)
        [~,sName,~] = fileparts(A.Config.StackName);
        SaveName=[sName '(' datestr(clock,'yyyymmddTHHMMSS') ').mat'];
        A.SavePath=fullfile(A.Config.Directory, SaveName);
      end
      Config=A.Config.exportConfigStruct(); %#ok<NASGU,PROP>
      Molecule=A.Molecule; %#ok<NASGU,PROP>
      Filament=A.Filament; %#ok<NASGU,PROP>
      Objects=A.Objects; %#ok<NASGU,PROP>
      Results=A.Results; %#ok<PROP,NASGU>
      try
        save(A.SavePath,'-v6','Config','Molecule','Filament','Objects','Results');
      catch ME
        ME.getReport
      end
    end
    
    
    function ClassData = exportData(A)
      Fields=fieldnames(A);
      ClassData=struct();
      for i=1:numel(Fields)
        ClassData.(Fields{i})=A.(Fields{i});
      end
    end
      

    function A = importData(A,Data)
      DataFields=fieldnames(Data);
      for i=1:numel(DataFields)
        if isprop(A,DataFields{i})
          A.(DataFields{i})=Data.(DataFields{i});
        else
          warning('MATLAB:AutoTipTrack:AutoTipTrackDataClass:importData',...
            'Could not import data field %s, the class %s does not have the respective property.',DataFields{i},class(A));
        end
      end
    end
    
    
    function saveData(A,Folder,Filename)
      if nargin<3
        Filename=[class(A) '_data.mat'];
      end
      ClassData = A.exportData; %#ok<NASGU>
      Filename = fullfile(Folder,Filename);
      save(Filename,'ClassData')
    end


    function loadData(A,File)
      load(File);
      A.importData(ClassData);
    end


    function [found, A]=reloadResults(A,target)
      % Reload results from saved files
      %
      % Reloads results from files. Files are searched in the directory
      % stored in the Config property.
      % If the file contains variables named Config, Objects, Molecules,
      % Filaments or Results, the respective properties of the
      % AutoTipTrackDataClass are overwritten.
      % If the name of one of these variables is given in the string
      % parameter 'target', then reloadResults loads files until it finds
      % one that contains a variable of that name. If the target variable
      % was loaded, reloadResults returns true, otherwise it returns false.
      % By default reloadResults searches for a variable named Molecule.
      %
      % Syntax:
      % found=reloadResults('target')
      %
      % Parameters:
      % target: string containing the name of the variable that should be
      % found.
      %
      % Output:
      % found: boolean; true if the target variable was found, false if
      % not.
      %
      
      if nargin <2
        target='Molecule';
      end
      if ~isa(A.Config,'ConfigClass')
        error('MATLAB:AutoTipTrack:AutoTipTrackDataClass','No valid configuration found. Config was: %s',A.Config);
      end
      resultFiles=dir(fullfile(A.Config.Directory, '*.mat'));
      numFiles=length(resultFiles);
      found=false;
      [~,sName,~] = fileparts(A.Config.StackName);
      [~,fName,~] = fileparts(A.Config.FileName);
      if exist(fullfile(A.Config.Directory(1:end-5),A.Config.StackName),'file')==7 %if the StackName is a directory, we are dealing with numbered tiff files
        regSearch=['^(' regexptranslate('escape',sName(1:end-3)) '|' regexptranslate('escape',fName(1:end-3)) ').*?' '\([\dT]*\)\.mat'];
      else
        regSearch=['^(' regexptranslate('escape',sName) ').*?' '\([\dT]*\)\.mat'];
      end
      for n=numFiles:-1:1
        %go through the file list in reverse order so that we always start with the most recent file
        %if we are dealing with numbered tiff files, get rid of the last three
        %digits for the search
        if regexp(resultFiles(n).name,regSearch)
          try
            results=load(fullfile(A.Config.Directory, resultFiles(n).name));
          catch ME
            ME.getReport
            results=struct([]);
          end
          %handle old results storage methods
          if isfield(results, 'MolIds')
            results.Results.MolIds=results.MolIds;
          end
          if isfield(results, 'speed')
            if isstruct(results.speed)
              results.Results.Speed=results.speed.speeds;
              results.Results.MolIds=results.speed.MoleculeIds;
            else
              results.Results.Speed=results.speed;
            end
          end
          if isfield(results,target) && ~isempty(results.(target))
            found=true;
            A.Config.reloadConfig(fullfile(A.Config.Directory, resultFiles(n).name));
            A.Objects=results.Objects;
            A.Molecule=results.Molecule;
            A.Filament=results.Filament;
            if isfield(results, 'Results')
              A.Results=results.Results;
            end
            break % use te first matlab file that contains tracked data
          end
        end
      end
    end
    
    
    function deleteDuplicateResults(A)
      % Delete redundant saved files
      %
      
      if ~isa(A.Config,'ConfigClass')
        error('MATLAB:AutoTipTrack:AutoTipTrackDataClass','No valid configuration found. Config was: %s',A.Config);
      end
      resultFiles=dir(fullfile(A.Config.Directory, '*.mat'));
      numFiles=length(resultFiles);
      [~,sName,~] = fileparts(A.Config.StackName);
      [~,fName,~] = fileparts(A.Config.FileName);
      for n=numFiles:-1:2
        %go through the file list in reverse order so that we always start with the most recent file
        %if we are dealing with numbered tiff files, get rid of the last three
        %digits for the search
        if exist(A.Config.StackName,'file')==7 %if the StackName is a directory, we are dealing with numbered tiff files
          regSearch=['(' regexptranslate('escape',sName(1:end-3)) '|' regexptranslate('escape',fName(1:end-3)) ').*?' '\([\dT]*\)\.mat'];
        else
          regSearch=['(' regexptranslate('escape',sName) ').*?' '\([\dT]*\)\.mat'];
        end
        if regexp(resultFiles(n).name,regSearch)
          oldFile=fullfile(A.Config.Directory, resultFiles(n-1).name);
          try
            olderResults=load(oldFile);
          catch
            %just to be sure let's wait 30 s and try again
            pause(30);
            try
              olderResults=load(oldFile);
            catch ME
              delete(oldFile);
              fprintf('Deleted: %s (file is corrupt)\n',oldFile)
              resultFiles(n-1)=[];
              ME.getReport
              continue;
            end
          end
          currentFile=fullfile(A.Config.Directory, resultFiles(n).name);
          try
            results=load(currentFile);
          catch
            %just to be sure let's wait 30 s and try again
            pause(30);
            try
              results=load(currentFile);
            catch ME
              delete(currentFile);
              fprintf('Deleted: %s (file is corrupt)\n',currentFile)
              resultFiles(n)=[];
              ME.getReport
              continue;
            end
          end
          if isequaln(olderResults, results)
            delete(fullfile(A.Config.Directory, resultFiles(n).name));
            fprintf('Deleted: %s\n',fullfile(A.Config.Directory, resultFiles(n).name))
          end
        end
      end
    end
    
    
  end
  methods (Static)
    [tempCalib,Times]=readMMTiffMeta(TiffMeta, tempCalib)
    [tempCalib, Times, Date]=readNikonTiffMeta(TiffMeta, tempCalib, UseChannel)
    [tempCalib, Times,Channels,Date]=readImageJTiffMeta(fullpath,tempCalib)
  end
end
