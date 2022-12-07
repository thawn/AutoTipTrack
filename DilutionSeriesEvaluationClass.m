classdef DilutionSeriesEvaluationClass < SpeedEvaluation2Class
  properties
  end
  methods
    %constructor
    function S=DilutionSeriesEvaluationClass(varargin)
      S@SpeedEvaluation2Class(varargin{:})
    end
  end
  methods (Static)
    
    function makeOverviewFigure(SpeedEvaluationClasses,folder)
      if ~isempty(SpeedEvaluationClasses)
        numFiles=length(SpeedEvaluationClasses);
        slowresults=NaN(numFiles,2);
        fastresults=NaN(numFiles,2);
        meanresults=NaN(numFiles,2);
        numMTs=NaN(numFiles,1);
        lengthMTs=NaN(numFiles,4);
        labels=cell(numFiles,1);
        fileNames=cell(numFiles,1);
        allSpeeds=cell(numFiles,1);
        allLengths=cell(numFiles,1);
        acquisitionDates=[];
        for n=1:numFiles
          if isa(SpeedEvaluationClasses{n}.Config, 'ConfigClass')
            slowresults(n,:)=SpeedEvaluationClasses{n}.slowresult;
            fastresults(n,:)=SpeedEvaluationClasses{n}.fastresult;
            meanresults(n,:)=SpeedEvaluationClasses{n}.meanresult;
            numMTs(n)=SpeedEvaluationClasses{n}.numMT;
            lengthMTs(n,:)=SpeedEvaluationClasses{n}.lengthMT;
            labels{n}=ellipsize(SpeedEvaluationClasses{n}.Config.StackName,20);
            fileNames{n}=SpeedEvaluationClasses{n}.Config.StackName;
            acquisitionDates=[acquisitionDates; SpeedEvaluationClasses{n}.Config.AcquisitionDate]; %#ok<AGROW>
            if isfield(SpeedEvaluationClasses{n}.Results, 'Speed')
              allSpeeds{n}=SpeedEvaluationClasses{n}.Results.Speed;
            end
            if isfield(SpeedEvaluationClasses{n}.Results, 'Length')
              allLengths{n}=SpeedEvaluationClasses{n}.Results.Length;
            end
          end
        end
        [concentrations,fileNameParts] = DilutionSeriesEvaluationClass.analyzeFileNames(fileNames);
        try
          save(fullfile(folder,'Dilution_series_summary.mat'),'folder','meanresults','slowresults','fastresults','numMTs','lengthMTs','labels','fileNames','concentrations','acquisitionDates','allSpeeds','allLengths','SpeedEvaluationClasses');
        catch ME
          ME.getReport
        end
      end
      SpeedLimit = cellfun(@(X) prctile(nanmedian(X),75),allSpeeds);
      LenLimit = cellfun(@(X) prctile(nanmedian(X),75),allLengths) ./ 1000;
      CompoundNames = cellfun(@(X) X{1},fileNameParts,'Uni',false);
      DifferentCompounds = unique(CompoundNames);
      Stats = struct();
      for n = 1:length(DifferentCompounds)
        CompoundIndex = strcmp(CompoundNames,DifferentCompounds{n});
        CompoundIndex(concentrations == 0) = true; %combines all controls
        XPadding = (max(concentrations(CompoundIndex)) - min(concentrations(CompoundIndex))) / 50;
        if XPadding == 0
          XPadding = 0.5;
        end
        Stats.(['S_' regexprep(DifferentCompounds{n},'[^0-9a-zA-Z]','')]) = makePlotSetFigure(concentrations(CompoundIndex),allSpeeds(CompoundIndex),allLengths(CompoundIndex), num2cell(numMTs(CompoundIndex)),folder,'NumLim',[0 max(numMTs)], 'SpeedLim', [0 max(SpeedLimit)], 'LengthLim', [0 max(LenLimit)], 'FileName', sprintf('%s_graphs',DifferentCompounds{n}), 'binInterval', max(concentrations) / 50000, 'XPadding', XPadding, 'xLabel', sprintf('[%s] (%sM)', DifferentCompounds{n}, 181));
      end
      ControlIndex = concentrations == 0;
      NumControls = sum(ControlIndex);
      ControlX = 1:NumControls;
      Stats.CombinedControls = makePlotSetFigure(ControlX,allSpeeds(ControlIndex),allLengths(ControlIndex), num2cell(numMTs(ControlIndex)),folder,'NumLim',[0 max(numMTs)], 'SpeedLim', [0 max(SpeedLimit)], 'LengthLim', [0 max(LenLimit)], 'FileName', sprintf('%s_graphs','CombinedControls'), 'XPadding', NumControls / 50 , 'xLabel', 'Control Well #');   %#ok<STRNU>
      try
        save(fullfile(folder,'Dilution_series_Stats.mat'),'Stats');
      catch ME
        ME.getReport
      end
    end
    
    
    function [Conc, FileNameParts] = analyzeFileNames(FileNames)
      FileNameParts = cellfun(@(X) strsplit(X, '_'),FileNames, 'Uniform', false);
      Conc = cellfun(@(X) str2double(X{7}),FileNameParts); %change X{7} here to get the correct part of the file
      if any(isnan(Conc))
        warning('Warning some filenames could not be parsed properly, you may need to change the part of the file that is exatracted in the code')
        Conc(isnan(Conc)) = 0;
      end
    end
    
    
  end
end
