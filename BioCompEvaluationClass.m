classdef BioCompEvaluationClass < DataEvaluationClass
  %BioCompEvaluationClass evaluates biocomputation devices. Calculates
  %splitting ratios and error rates of split- and pass-junctions.
  
  properties (Access = private, Constant = true)
    PathA2 = [false false false true; false true false false]; %Define the path enter left, exit right: [enter top, enter right, enter bottom, enter left; exit top, exit right, exit bottom, exit left].
    PathA1 = [false false false true; false false true false]; %Define the path enter left, exit bottom: [enter top, enter right, enter bottom, enter left; exit top, exit right, exit bottom, exit left].
    PathB2 = [true false false false; false true false false]; %Define the path enter top, exit right: [enter top, enter right, enter bottom, enter left; exit top, exit right, exit bottom, exit left].
    PathB1 = [true false false false; false false true false]; %Define the path enter top, exit bottom: [enter top, enter right, enter bottom, enter left; exit top, exit right, exit bottom, exit left].
    PathAB = [false false false true; true false false false]; %Define the path enter left, exit top: [enter top, enter right, enter bottom, enter left; exit top, exit right, exit bottom, exit left].
    PathBA = [true false false false; false false false true]; %Define the path enter top, exit left: [enter top, enter right, enter bottom, enter left; exit top, exit right, exit bottom, exit left].
    LowerAngleBound = 0;
    UpperAngleBound = 2.25;
  end
  properties
    Rotation = 0;
    Flip = false;
    FlatStack;
    Rect;
  end
  
  methods
    %constructor
    function B=BioCompEvaluationClass(varargin)
      B@DataEvaluationClass(varargin{:})
      B.MergeDimensions = [B.MergeDimensions;...
        {'RectPos', 1;...
        'RectSize', 0;...
        'Rotation', 0;...
        'Flip', 0;...
        'FlatStack', 3;...
        }];
    end
    
    
    function B = evaluate(B)
      NSteps = 11;
      trackStatus(B.StatusFolder,'Evaluating data','Calculating...',1,NSteps,1);
      B.calculateResults;
      trackStatus(B.StatusFolder,'Evaluating data','Filtering...',2,NSteps,1);
      B.filterResults;
      trackStatus(B.StatusFolder,'Evaluating data','Making figure...',3,NSteps,1);
      if B.Manual
        B.manuallyEvaluate;
      end
      B.makeFigure;
      trackStatus(B.StatusFolder,'Evaluating data','Saving file...',10,NSteps,1);
      B.saveFiestaCompatibleFile;
      trackStatus(B.StatusFolder,'Evaluating data','Done',NSteps,NSteps,1);
    end
    
    
    function B=calculateResults(B)
      % calculateResults calculate main direction, directionality
      % variance and distance moved for each molecule track.
      %
      
      
      if isempty(B.Molecule)
        %try to load Molecules from file
        B.reloadResults('Molecule');
      end
      if ~isfield(B.Results, 'Direction')
        B.reloadResults('Results');
      end
      if ~isempty(B.Molecule) && ( ~isfield(B.Results, 'Direction') || isempty(B.Results.Direction) || ~isfield(B.Results, 'AllT') )
        B.calculateDirections;
      end
    end
    
    %% junction performance
    function B = calculateDirections(B)
      AngleWindow = 3;
      NMolecules = length(B.Molecule);
      Delete = false(1, NMolecules);
      B.Results.Direction = NaN(1, NMolecules);
      B.Results.Angles = cell(1,NMolecules);
      B.Results.DirStd = NaN(1, NMolecules);
      B.Results.Velocity = NaN(1, NMolecules);
      B.Results.AllX = NaN(B.Config.LastFrame,NMolecules);
      B.Results.AllY = NaN(B.Config.LastFrame,NMolecules);
      B.Results.AllT = NaN(B.Config.LastFrame,NMolecules);
      for n = 1:NMolecules
        TrackLen = size(B.Molecule(n).Results,1);
        if TrackLen > 9
          B.Results.AllT(1:TrackLen,n) = B.Molecule(n).Results(:,1) .* (B.Molecule(n).Results(2,2) / (B.Molecule(n).Results(2,1) - B.Molecule(n).Results(1,1)));
          B.Results.AllX(1:TrackLen,n) = B.Molecule(n).Results(:,3);
          B.Results.AllY(1:TrackLen,n) = B.Molecule(n).Results(:,4);
          Diff = B.Molecule(n).Results(1+AngleWindow:end,3:4) - B.Molecule(n).Results(1:end-AngleWindow,3:4);
          B.Results.Angles{n} = mod(atan2(Diff(:,2),Diff(:,1)), 2 * pi());
          NStd = length(B.Results.Angles{n})-2;
          Std = zeros(1,NStd);
          for k = 1:NStd
            Std(k) = std(B.Results.Angles{n}(k:k+2));
          end
          B.Results.Velocity(n) = pdist(B.Molecule(n).Results([1 end],3:4)) /...
            (B.Molecule(n).Results(end,2) - B.Molecule(n).Results(1,2));
          B.Results.Direction(n) = mod(median(B.Results.Angles{n}), 2 * pi());
          B.Results.DirStd(n) = median(Std);
        else
          Delete(n) = true;
        end
      end
      B.Molecule(Delete)=[];
      B.Results.AllX(:,Delete)=[];
      B.Results.AllY(:,Delete)=[];
      B.Results.AllT(:,Delete)=[];
      B.Results.Angles(Delete)=[];
      B.Results.Velocity(Delete)=[];
      B.Results.Direction(Delete)=[];
      B.Results.DirStd(Delete)=[];
    end
    
    
    function B=filterDirection(B)
      % filterResults filter out molecules that have too high variance or
      % that are moving in the wrong direction
      
      [Lower, Upper] = B.rotateDirectionBounds;
      Delete = B.Results.DirStd > 0.3 | B.Results.Velocity < 400;
      if Lower < Upper
        Delete = Delete | B.Results.Direction < Lower | B.Results.Direction > Upper;
      else
        Delete = Delete | (B.Results.Direction < Lower & B.Results.Direction > Upper);
      end
      B.Molecule(Delete)=[];
      B.Results.AllX(:,Delete)=[];
      B.Results.AllY(:,Delete)=[];
      B.Results.AllT(:,Delete)=[];
      B.Results.Angles(Delete)=[];
      B.Results.Velocity(Delete)=[];
      B.Results.Direction(Delete)=[];
      B.Results.DirStd(Delete)=[];
    end
    
    
    function [Lower, Upper] = rotateDirectionBounds(B)
      Lower = B.LowerAngleBound;
      Upper = B.UpperAngleBound;
      if B.Flip
        Lower1 = Lower;
        Lower = -Upper;
        Upper = -Lower1;
      end
      Lower = Lower + (B.Rotation / 180 * pi());
      Upper = Upper + (B.Rotation / 180 * pi());
      Lower = mod(Lower, 2 * pi());
      Upper = mod(Upper, 2 * pi());
    end
    
    
    function B=manuallyEvaluate(B)
      % manuallyEvaluate lets user identify junctions and assigns areas to
      % junctions. Identifies from which entrance to which exit the
      % molecule passed the junction.
      
      if ~isfield(B.Results, 'RectPos') || isempty(B.Results.RectPos) || ~isfield(B.Results, 'Rotation')
        if isempty(B.Stack)
          B.loadFile;
        end
        Gui=InteractiveGUI(B.Config.exportConfigStruct);
        Gui.StatusFolder = B.StatusFolder;
        Gui.Stack = B.Stack;
        Gui.setupInteractivePanel('Threshold', false, 'Patterns', true);
        uiwait(Gui.UIFig);
        [~, B.Results.RectPos, B.Results.RectSize, B.Rotation, B.Flip, B.Results.ProjectionMethod] = Gui.eliminateOverlappingRectangles;
        B.FlatStack = Gui.Interface.PatternTab.FlatStack;
        B.Results.Image = Gui.Interface.PatternTab.MaxP;
        B.Results.ImageRotated = (B.Rotation + B.Flip) > 0;
        Gui.close;
        B.Results.Rotation = B.Rotation;
        B.Results.Flip = B.Flip;
        ImageSize = [B.Config.Width B.Config.Height];
        if B.Flip
          B.Results.RectPos(:,2) = ImageSize(2) - B.Results.RectPos(:,2) - B.Results.RectSize(2);
        end
        [B.Results.RectPos, B.Results.RectSize] = InteractiveGUI.rotateRegions(B.Results.RectPos, -B.Rotation, B.Results.RectSize, ImageSize);
        B.makeFigure('Manual',true);
      else
        B.makeFigure('Manual',true);
      end
    end
    
    
    function B = initializeResults(B)
      NRect = size(B.Results.RectPos,1);
      B.Results.Found = cell(1,NRect);
      B.Results.NEvents = zeros(1,NRect);
      B.Results.A2 = cell(1,NRect);
      B.Results.A1 = cell(1,NRect);
      B.Results.B2 = cell(1,NRect);
      B.Results.B1 = cell(1,NRect);
      B.Results.AB = cell(1,NRect);
      B.Results.BA = cell(1,NRect);
      B.Results.Other = cell(1,NRect);
      B.Results.A2Sum = zeros(1,NRect);
      B.Results.A1Sum = zeros(1,NRect);
      B.Results.B2Sum = zeros(1,NRect);
      B.Results.B1Sum = zeros(1,NRect);
      B.Results.ABSum = zeros(1,NRect);
      B.Results.BASum = zeros(1,NRect);
      B.Results.OtherSum = zeros(1,NRect);
      B.Results.Entrances = cell(1,NRect);
      B.Results.Exits = cell(1,NRect);
      B.Results.PassErrorMolecules = cell(1,NRect);
    end
    
    
    function B = makeFigure(B,varargin)
      %makeFigure creates summary charts of junction performances and
      %overview figure of where what kind of junction was found.
      
      p=inputParser;
      p.addParameter('Manual',false,@islogical);
      p.parse(varargin{:});
      if ~isfield(B.Results, 'RectPos')
        B.reloadResults('Results');
      end
      if isfield(B.Results, 'RectPos') && isfield(B.Results, 'Rotation')
        B.processJunctions;
        B.analyzeJunctions;
        if p.Results.Manual
          B.manuallyProcessJunctions;
          B.manuallyCheckErrors;
        end
        NSteps = 11;
        trackStatus(B.StatusFolder,'Evaluating data','Performance fig.',4,NSteps,1);
        B.plotJunctionPerformance;
        trackStatus(B.StatusFolder,'Evaluating data','Junction number fig.',5,NSteps,1);
        [Fig, Ax] = B.maximumProject;
        B.plotRegions(Ax,'JunctionNumbers',true,'Fig',Fig);
        saveas(Fig,fullfile(B.Config.Directory,[B.Config.StackName(1:end-4) '_j-numbers.pdf']),'pdf');
        close(Fig);
        trackStatus(B.StatusFolder,'Evaluating data','Junction traffic',6,NSteps,1);
        B.plotJunctionTraffic;
        trackStatus(B.StatusFolder,'Evaluating data','Junction fig.',7,NSteps,1);
        [Fig, Ax] = B.maximumProject;
        B.plotRegions(Ax);
        saveas(Fig,fullfile(B.Config.Directory,[B.Config.StackName(1:end-4) '_junctions.pdf']),'pdf');
        close(Fig);
        trackStatus(B.StatusFolder,'Evaluating data','Junction detail fig.',8,NSteps,1);
        [Fig, Ax] = B.maximumProject;
        B.plotRegions(Ax,'Labels',true,'Fig',Fig);
        saveas(Fig,fullfile(B.Config.Directory,[B.Config.StackName(1:end-4) '_details.pdf']),'pdf');
        close(Fig);
        if B.Debug
          DebugFig = findobj('Tag','DebugFig');
          DebugAx = findobj('Tag','DebugAx');
          B.plotRegions(DebugAx(1),'Rotate',false,'Labels',true,'Fig',DebugFig(1));
          saveas(DebugFig,fullfile(B.Config.Directory,[B.Config.StackName(1:end-4) '_debug.pdf']),'pdf');
          close(DebugFig);
        end
        if ~isempty(B.Molecule) && ( ~isfield(B.Results, 'RegionCounts') || isempty(B.Results.RegionCounts))
          trackStatus(B.StatusFolder,'Evaluating data','Region traffic',9,NSteps,1);
          B.countRegionTraffic;
        end
        if isfield(B.Results, 'RegionCounts') && isfield(B.Results.RegionCounts, 'Counts') && ~isempty(B.Results.RegionCounts.Counts)
          [Fig, Ax] = B.maximumProject;
          B.plotRegions(Ax,'RegionCounts', true, 'Fig', Fig);
          saveas(Fig,fullfile(B.Config.Directory,[B.Config.StackName(1:end-4) '_region_counts.pdf']),'pdf');
          close(Fig);
          Fig = createBasicFigure('Renderer','painters');
          Ax = axes(Fig);
          bar(Ax,B.Results.RegionCounts(1).Counts);
          errorbar(Ax, B.Results.RegionCounts(1).Counts, sqrt(B.Results.RegionCounts(1).Counts), '.k');
          saveas(Fig,fullfile(B.Config.Directory,[B.Config.StackName(1:end-4) '_counts.pdf']),'pdf');
          close(Fig);
        end
        if isfield(B.Results, 'SaveJunctionParams')
          B.saveAllJunctionImageStacks;
        end
      else
        warning('MATLAB:AutoTipTrack:BiocompEvaluationClass:makeFigure','No field "RectPos" found in "Results". You likely need to restart the evaluation with the "EvaluateManually" parameter set to "true".');
      end
    end
    
    
    function B = manuallyProcessJunctions(B)
      [Fig, Ax] = B.maximumProject;
      uicontrol(...
        'Parent',Fig,...
        'Units','normalized',...
        'String','Done',...
        'Style','pushbutton',...
        'Position',[0.9 0 0.1 0.05],...
        'Callback',@B.closeFig,...
        'Tag','Done');
      set(0, 'CurrentFigure', Fig);
      Fig.Tag = 'CheckJunctions';
      Fig.Renderer = 'opengl';
      B = B.plotRegions(Ax);
      Fig.Visible = 'on';
      ImageSize = [B.Config.Width B.Config.Height];
      while isvalid(Fig)
        try
          Tag = get(gcf, 'Tag');
          if ~strcmp(Tag, Fig.Tag)
            break;
          end
          [X, Y, Button] = ginput2(1,'Figure',Fig);
          [RPos, RSize, ~] = InteractiveGUI.rotateRegions(B.Results.RectPos, B.Rotation, B.Results.RectSize, ImageSize);
          if B.Flip
            RPos(:,2) = ImageSize(2) - RPos(:,2) - RSize(2);
          end
          Delete = RPos(:,1) < X & (RPos(:,1) + RSize(1)) > X &...
            RPos(:,2) < Y & (RPos(:,2) + RSize(2)) > Y;
          if any(Delete) && isvalid(Fig)
            if Button == 1
              B.Results.RectPos(Delete,:) = [];
              delete(B.Rect(Delete));
              B.Rect(Delete) = [];
              B.Results.Split(Delete) = [];
              B.Results.Errors(Delete) = [];
            else
              Delete(isnan(B.Results.Errors)) = false;
              if any(Delete)
                B.Results.Split(Delete) = ~B.Results.Split(Delete);
                B = B.plotRegions(Ax);
                B.Results.LockJunctions = true;
              end
            end
          end
        catch
          break;
        end
        drawnow;
      end
      fprintf('Manual processing finished.\n');
      DebugFig = findobj('Tag','DebugFig');
      close(DebugFig);
      B.processJunctions;
      B.analyzeJunctions;
    end
    
    
    function B = processJunctions(B)
      B.Rotation = B.Results.Rotation;
      B.Flip = B.Results.Flip;
      B.filterDirection;
      Pos = B.Results.RectPos * B.Config.PixSize;
      Size = B.Results.RectSize * B.Config.PixSize;
      [PA2, PA1, PB2, PB1, PAB, PBA] = rotatePaths(B);
      NRect = size(Pos,1);
      B.initializeResults;
      if B.Debug
        [DebugFig, DebugAx] = B.maximumProject('Rotate',false);
        DebugFig.Visible='on';
        DebugAx.Tag = 'DebugAx';
        DebugFig.Tag = 'DebugFig';
        Positions = [0.5 0.9 0.1 0.1; 0.9 0.4 0.1 0.1; 0.5 0 0.1 0.1; 0 0.4 0.1 0.1];
        annotation(DebugFig,'textbox',Positions(PB1(1,:),:),'String','top','FitBoxToText','on','Color', 'w');
        annotation(DebugFig,'textbox',Positions(PB2(2,:),:),'String','right','FitBoxToText','on','Color', 'w');
        annotation(DebugFig,'textbox',Positions(PB1(2,:),:),'String','bottom','FitBoxToText','on','Color', 'w');
        annotation(DebugFig,'textbox',Positions(PA1(1,:),:),'String','left','FitBoxToText','on','Color', 'w');
        hold on;
      end
      for n = 1:NRect
        [R,C] = find(B.Results.AllX > Pos(n,1) & ...
          B.Results.AllX < Pos(n,1) + Size(1) & ...
          B.Results.AllY > Pos(n,2) & ...
          B.Results.AllY < Pos(n,2) + Size(2));
        B.Results.Found{n} = [R,C];
        B.Results.NEvents(n) = length(R);
        Top = [Pos(n,1), Pos(n,1) + Size(1);...
          Pos(n,2), Pos(n,2)];
        Bottom = [Pos(n,1), Pos(n,1) + Size(1); ...
          Pos(n,2) + Size(2), Pos(n,2) + Size(2)];
        Left = [Pos(n,1), Pos(n,1);...
          Pos(n,2), Pos(n,2) + Size(2)];
        Right = [Pos(n,1) + Size(1), Pos(n,1) + Size(1);...
          Pos(n,2), Pos(n,2) + Size(2)];
        if B.Debug
          plot(DebugAx,Top(1,:)/B.Config.PixSize,Top(2,:)/B.Config.PixSize,'c');
          plot(DebugAx,Bottom(1,:)/B.Config.PixSize,Bottom(2,:)/B.Config.PixSize,'b');
          plot(DebugAx,Left(1,:)/B.Config.PixSize,Left(2,:)/B.Config.PixSize,'m');
          plot(DebugAx,Right(1,:)/B.Config.PixSize,Right(2,:)/B.Config.PixSize,'y');
        end
        if B.Results.NEvents(n) > 0
          MolN = unique(C);
          Counter = 1;
          B.Results.A2{n} = NaN(length(MolN),4);
          B.Results.A1{n} = NaN(length(MolN),4);
          B.Results.B2{n} = NaN(length(MolN),4);
          B.Results.B1{n} = NaN(length(MolN),4);
          B.Results.AB{n} = NaN(length(MolN),4);
          B.Results.BA{n} = NaN(length(MolN),4);
          B.Results.Other{n} = NaN(length(MolN),4);
          B.Results.Entrances{n} = NaN(length(MolN),3);
          B.Results.Exits{n} = NaN(length(MolN),3);
          for k = MolN'
            Rows = R(C==k);
            if ~isempty(Rows) && Rows(1) > 1 && Rows(end) < B.Config.LastFrame
              Enter = [B.Results.AllX(Rows(1) - 1, k), B.Results.AllX(Rows(1), k);...
                B.Results.AllY(Rows(1) - 1, k), B.Results.AllY(Rows(1), k)];
              Exit = [B.Results.AllX(Rows(end),k), B.Results.AllX(Rows(end) + 1, k);...
                B.Results.AllY(Rows(end), k), B.Results.AllY(Rows(end) + 1, k)];
              Path = [ ~isempty(interX(Enter,Top)), ~isempty(interX(Enter,Right)),...
                ~isempty(interX(Enter,Bottom)), ~isempty(interX(Enter,Left));...
                ~isempty(interX(Exit,Top)), ~isempty(interX(Exit,Right)),...
                ~isempty(interX(Exit,Bottom)), ~isempty(interX(Exit,Left))];
              if pdist(Enter') < 1.9 * B.Config.ConnectMol.MaxVelocity && ...
                  pdist(Exit') < 1.9 * B.Config.ConnectMol.MaxVelocity
                if B.Debug
                  plot(DebugAx,B.Results.AllX(Rows(1)-1,k)/B.Config.PixSize,B.Results.AllY(Rows(1)-1,k)/B.Config.PixSize,'*r');
                  plot(DebugAx,B.Results.AllX(Rows,k)/B.Config.PixSize,B.Results.AllY(Rows,k)/B.Config.PixSize);
                  plot(DebugAx,B.Results.AllX(Rows(end)+1,k)/B.Config.PixSize,B.Results.AllY(Rows(end)+1,k)/B.Config.PixSize,'*g');
                end
                B.Results.A2{n}(Counter,:) = [all(Path(:) == PA2(:)), k, Rows(1), Rows(end)];
                B.Results.A1{n}(Counter,:) = [all(Path(:) == PA1(:)), k, Rows(1), Rows(end)];
                B.Results.B2{n}(Counter,:) = [all(Path(:) == PB2(:)), k, Rows(1), Rows(end)];
                B.Results.B1{n}(Counter,:) = [all(Path(:) == PB1(:)), k, Rows(1), Rows(end)];
                B.Results.AB{n}(Counter,:) = [all(Path(:) == PAB(:)), k, Rows(1), Rows(end)];
                B.Results.BA{n}(Counter,:) = [all(Path(:) == PBA(:)), k, Rows(1), Rows(end)];
                B.Results.Other{n}(Counter,:) = [...
                  ~B.Results.A2{n}(Counter,1) && ~B.Results.A1{n}(Counter,1)...
                  && ~B.Results.B2{n}(Counter,1) && ~B.Results.B1{n}(Counter,1)...
                  && ~B.Results.AB{n}(Counter,1) && ~B.Results.BA{n}(Counter,1),...
                  k, Rows(1), Rows(end)];
                B.Results.Entrances{n}(Counter,:) = [all(Path(1,:) == PA1(1,:)) || all(Path(1,:) == PB1(1,:)), B.Results.AllT(Rows(1), k), k];
                B.Results.Exits{n}(Counter,:) = [all(Path(2,:) == PA1(2,:)) || all(Path(2,:) == PA2(2,:)), B.Results.AllT(Rows(end), k), k];
              end
              if pdist(Enter') < 1.9 * B.Config.ConnectMol.MaxVelocity
                B.Results.Entrances{n}(Counter,:) = [all(Path(1,:) == PA1(1,:)) || all(Path(1,:) == PB1(1,:)), B.Results.AllT(Rows(1), k), k];
              end
              if pdist(Exit') < 1.9 * B.Config.ConnectMol.MaxVelocity
                B.Results.Exits{n}(Counter,:) = [all(Path(2,:) == PA1(2,:)) || all(Path(2,:) == PA2(2,:)), B.Results.AllT(Rows(end), k), k];
              end
            end
            Counter = Counter + 1;
          end
          B.Results.A2Sum(n) = nansum(B.Results.A2{n}(:,1));
          B.Results.A1Sum(n) = nansum(B.Results.A1{n}(:,1));
          B.Results.B2Sum(n) = nansum(B.Results.B2{n}(:,1));
          B.Results.B1Sum(n) = nansum(B.Results.B1{n}(:,1));
          B.Results.ABSum(n) = nansum(B.Results.AB{n}(:,1));
          B.Results.BASum(n) = nansum(B.Results.BA{n}(:,1));
          B.Results.OtherSum(n) = nansum(B.Results.Other{n}(:,1));
          B.Results.Entrances{n}(isnan(B.Results.Entrances{n}(:,2)),:) = [];
          B.Results.Exits{n}(isnan(B.Results.Entrances{n}(:,2)),:) = [];
          B.Results.Entrances{n} = sortrows(B.Results.Entrances{n},2);
          B.Results.Exits{n} = sortrows(B.Results.Exits{n},2);
          B.Results.Entrances{n} = [cumsum(B.Results.Entrances{n}(:,1)), B.Results.Entrances{n}(:,2), B.Results.Entrances{n}(:,3)];
          B.Results.Exits{n} = [cumsum(B.Results.Exits{n}(:,1)), B.Results.Exits{n}(:,2), B.Results.Exits{n}(:,3)];
        end
      end
    end
    
    
    function B = analyzeJunctions(B)
      B.Results.A2B1 = sum([B.Results.A2Sum;B.Results.B1Sum]);
      B.Results.A1B2ABBA = sum([B.Results.A1Sum;B.Results.B2Sum;B.Results.ABSum;B.Results.BASum]);
      B.Results.AllCrossings = sum([B.Results.A2B1;B.Results.A1B2ABBA]);
      B.Results.Errors = B.Results.A1B2ABBA ./ B.Results.AllCrossings;
      B.Results.Errors(B.Results.AllCrossings<1) = NaN;
      if ~isfield(B.Results, 'LockJunctions') || ~B.Results.LockJunctions
        B.Results.Split = B.Results.Errors > 0.2;
      end
      B.Results.Pass = ~isnan(B.Results.Errors) & ~B.Results.Split;
      B.Results.PassA2 = sum(B.Results.A2Sum(B.Results.Pass));
      B.Results.PassA1 = sum(B.Results.A1Sum(B.Results.Pass));
      B.Results.PassB2 = sum(B.Results.B2Sum(B.Results.Pass));
      B.Results.PassB1 = sum(B.Results.B1Sum(B.Results.Pass));
      B.Results.PassAB = sum(B.Results.ABSum(B.Results.Pass));
      B.Results.PassBA = sum(B.Results.BASum(B.Results.Pass));
      B.Results.PassA2B1 = sum(B.Results.A2B1(B.Results.Pass));
      B.Results.PassA1B2ABBA = sum(B.Results.A1B2ABBA(B.Results.Pass));
      B.Results.PassAllCrossings = sum(B.Results.AllCrossings(B.Results.Pass));
      B.Results.PassError = B.Results.PassA1B2ABBA / B.Results.PassAllCrossings;
      B.Results.SplitA2 = sum(B.Results.A2Sum(B.Results.Split));
      B.Results.SplitA1 = sum(B.Results.A1Sum(B.Results.Split));
      B.Results.SplitB2 = sum(B.Results.B2Sum(B.Results.Split));
      B.Results.SplitB1 = sum(B.Results.B1Sum(B.Results.Split));
      B.Results.SplitAB = sum(B.Results.ABSum(B.Results.Split));
      B.Results.SplitBA = sum(B.Results.BASum(B.Results.Split));
      B.Results.SplitARatio = B.Results.SplitA2 / (B.Results.SplitA2 + B.Results.SplitA1);
      B.Results.SplitBRatio = B.Results.SplitB1 / (B.Results.SplitB2 + B.Results.SplitB1);
      B.Results.SplitAllCrossings = sum(B.Results.AllCrossings(B.Results.Split));
      B.Results.SplitError = (B.Results.SplitAB + B.Results.SplitAB) / B.Results.SplitAllCrossings;
      B.Results.A2Total = sum(B.Results.A2Sum);
      B.Results.A1Total = sum(B.Results.A1Sum);
      B.Results.B2Total = sum(B.Results.B2Sum);
      B.Results.B1Total = sum(B.Results.B1Sum);
      B.Results.ABTotal = sum(B.Results.ABSum);
      B.Results.BATotal = sum(B.Results.BASum);
      B.Results.OtherTotal = sum(B.Results.OtherSum);
      B.Results.EntrancesTotal = sum(cellfun(@B.findMaxCount,B.Results.Entrances));
      B.Results.ExitsTotal = sum(cellfun(@B.findMaxCount,B.Results.Exits));
      B.Results.JunctionTransportEfficiency = B.Results.ExitsTotal / B.Results.EntrancesTotal;
      B.findErrorMolecules;
    end
    
    
    function plotJunctionPerformance(B)
      Fig = createBasicFigure('Width',9,'Aspect',9/6,'Renderer','painters');
      Ax = axes(Fig);
      set(Ax,'FontSize',7);
      bar(Ax,[B.Results.SplitA1, B.Results.SplitA2 ,B.Results.SplitB1, B.Results.SplitB2, B.Results.SplitAB ,B.Results.SplitBA,...
        B.Results.PassA1, B.Results.PassA2 ,B.Results.PassB1, B.Results.PassB2, B.Results.PassAB ,B.Results.PassBA],0.8);
      set(Ax,'XTick',1:12,'XTickMode','manual',...
        'XTickLabel',{'SplitA1','SplitA2','SplitB1','SplitB2','SplitAB','SplitBA',...
        'PassA1','PassA2','PassB1','PassB2','PassAB','PassBA'},...
        'XTickLabelMode','manual','XTickLabelRotation',90);
      ylabel('# Junction crossings','FontSize',9);
      xlim(Ax,[0.4 12.6]);
      AnnotationText = {'Split junction:',...
        sprintf('  A->1: %s', printPercentageWithError(1 - B.Results.SplitARatio, B.Results.SplitAllCrossings)),...
        sprintf('  A->2: %s', printPercentageWithError(B.Results.SplitARatio, B.Results.SplitAllCrossings)),...
        sprintf('  B->1: %s', printPercentageWithError(B.Results.SplitBRatio, B.Results.SplitAllCrossings)),...
        sprintf('  B->2: %s', printPercentageWithError(1 - B.Results.SplitBRatio, B.Results.SplitAllCrossings)),...
        sprintf('  n: %d', B.Results.SplitAllCrossings),...
        'Pass junction:',...
        sprintf('  Correct: %s', printPercentageWithError(1 - B.Results.PassError, B.Results.PassAllCrossings)),...
        sprintf('  Error: %s', printPercentageWithError(B.Results.PassError, B.Results.PassAllCrossings)),...
        sprintf('  n: %d', B.Results.PassAllCrossings),...
        sprintf('Detaching: %s', printPercentageWithError(1 - B.Results.JunctionTransportEfficiency, B.Results.EntrancesTotal))};
      annotation(Fig, 'textbox',[0.2 0.5 0.7 0.4],'String',AnnotationText,'FitBoxToText','on','FontSize',7);
      saveas(Fig,fullfile(B.Config.Directory,[B.Config.StackName(1:end-4) '_j_perf.pdf']),'pdf');
      close(Fig);
    end
    
    
    function plotJunctionTraffic(B)
      FigRows = 4;
      FigCols = 3;
      function C = maxEntrances(Entrances)
        C = 0;
        if ~isempty(Entrances)
          C = max(Entrances(:,1));
        end
      end
      function C = maxTime(Exits)
        C = 0;
        if ~isempty(Exits)
          C = max(Exits(:,2));
        end
      end
      Count = cellfun(@maxEntrances,B.Results.Entrances);
      YMax = max(Count);
      XMax = max(cellfun(@maxTime,B.Results.Exits));
      if XMax<300000
        TimeScale = 1000;
        TimeUnit = 's';
      else
        TimeScale = 60000;
        TimeUnit = 'min';
      end
      XMax = XMax / TimeScale;
      N = find(Count>4);
      NumPlots = length(N);
      if NumPlots > 0
        NumFigs = ceil(NumPlots / (FigRows * FigCols));
        Fig1 = figure('Visible','off');
        Ax(NumPlots) = axes('Parent', Fig1);
        PlotNo = 1;
        AxProps = {};
        for n = 1:NumFigs
          Fig = createBasicFigure('Renderer','painters');
          if n == NumFigs
            NumSubPlots = mod(NumPlots, (FigRows * FigCols));
          else
            NumSubPlots = FigRows * FigCols;
          end
          for m = 1:NumSubPlots
            Ax(n) = subplot(FigRows,FigCols,m,'Parent', Fig, AxProps{:});
            hold(Ax(n), 'off');
            plot(Ax(n), B.Results.Entrances{N(PlotNo)}(:,2) ./ TimeScale, B.Results.Entrances{N(PlotNo)}(:,1));
            if ~isempty(B.Results.Exits{N(PlotNo)})
              hold(Ax(n), 'on');
              plot(Ax(n), B.Results.Exits{N(PlotNo)}(:,2) ./ TimeScale, B.Results.Exits{N(PlotNo)}(:,1));
            end
            xlabel(Ax(n), sprintf('time (%s)',TimeUnit));
            ylabel(Ax(n), 'counts');
            title(Ax(n), sprintf('Junction %d',N(PlotNo)));
            xlim(Ax(n), [0 XMax]);
            ylim(Ax(n), [0 YMax]);
            PlotNo = PlotNo + 1;
          end
          saveas(Fig,fullfile(B.Config.Directory, [B.Config.StackName(1:end-4), sprintf('_jPlot%d.pdf', n)]), 'pdf');
          close(Fig);
        end
        close(Fig1);
      end
    end
    
    
    function B = plotRegions(B, Ax, varargin)
      p=inputParser;
      p.addParameter('Rotate',true,@islogical);
      p.addParameter('Labels',false,@islogical);
      p.addParameter('JunctionNumbers',false,@islogical);
      p.addParameter('RegionCounts',false,@islogical);
      p.addParameter('Fig',[]);
      p.parse(varargin{:})
      if p.Results.Rotate
        ImageSize = [B.Config.Width B.Config.Height];
        [RPos, RSize, ~] = InteractiveGUI.rotateRegions(B.Results.RectPos, B.Rotation, B.Results.RectSize, ImageSize);
        if B.Flip
          RPos(:,2) = ImageSize(2) - RPos(:,2) - RSize(2);
        end
      else
        RPos = B.Results.RectPos;
        RSize = B.Results.RectSize;
      end
      if p.Results.Labels || p.Results.JunctionNumbers || p.Results.RegionCounts
        if isempty(p.Results.Fig)
          Fig = gcf;
        else
          Fig = p.Results.Fig;
        end
        AxDiff=[diff(Ax.XLim) diff(Ax.YLim)];
        LabelPos = (RPos - [Ax.XLim(ones(size(RPos,1),1),1) Ax.YLim(ones(size(RPos,1),1),1)])...
          ./ AxDiff(ones(size(RPos,1),1),:)...
          .* [Ax.Position(ones(size(RPos,1),1),3) Ax.Position(ones(size(RPos,1),1),4)]...
          + Ax.Position(ones(size(RPos,1),1),1:2);
        LabelSize = (RSize - [Ax.XLim(1) Ax.YLim(1)])...
          ./ AxDiff...
          .* Ax.Position(3:4)...
          + Ax.Position(1:2);
        LabelPos(:,2) = (Ax.Position(4) - Ax.Position(2)) - LabelPos(:,2) - LabelSize(2);
        LabelPos(LabelPos<0)=0;
        LabelPos(LabelPos>1)=1;
      end
      if ~isempty(B.Rect)
        try
          delete(B.Rect);
        catch
        end
        B.Rect = [];
      end
      for n = 1:size(RPos,1)
        if p.Results.Labels
          annotation(Fig,'textbox',[LabelPos(n,:) LabelSize],...
            'String', sprintf('A1: %d\n A2: %d\n B1: %d\n B2: %d',...
            B.Results.A1Sum(n),B.Results.A2Sum(n),B.Results.B1Sum(n),B.Results.B2Sum(n)),...
            'Interpreter','none','FontSize',4,'Color','w','LineStyle','none', 'Margin', 2);
        end
        if p.Results.JunctionNumbers || p.Results.RegionCounts
          String = sprintf('%d',n);
          if p.Results.RegionCounts
            String = sprintf([String ': %d'], B.Results.RegionCounts(1).Counts(n));
          end
          annotation(Fig,'textbox',[LabelPos(n,:) LabelSize],...
            'String', String,...
            'Interpreter','none','FontSize',8,'Color','w','LineStyle','none', 'Margin', 2);
        end
        if isnan(B.Results.Errors(n))
          B.Rect(n) = rectangle('Parent',Ax,...
            'Position',[RPos(n,:) RSize],'EdgeColor','w');
        elseif B.Results.Split(n)
          B.Rect(n) = rectangle('Parent',Ax,...
            'Position',[RPos(n,:) RSize],'EdgeColor','g');
        else
          B.Rect(n) = rectangle('Parent',Ax,...
            'Position',[RPos(n,:) RSize],'EdgeColor','r');
        end
      end
    end
    
    
    function [PA2, PA1, PB2, PB1, PAB, PBA] = rotatePaths(B)
      PA2 = B.PathA2;
      PA1 = B.PathA1;
      PB2 = B.PathB2;
      PB1 = B.PathB1;
      PAB = B.PathAB;
      PBA = B.PathBA;
      if B.Flip
        Transform = [3 2 1 4];
        PA2 = PA2(:,Transform);
        PA1 = PA1(:,Transform);
        PB2 = PB2(:,Transform);
        PB1 = PB1(:,Transform);
        PAB = PAB(:,Transform);
        PBA = PBA(:,Transform);
      end
      Transform = (1:4) - round(B.Rotation / 180 * 2);
      Transform(Transform > 4) = Transform(Transform > 4) - 4;
      Transform(Transform < 1) = Transform(Transform < 1) + 4;
      PA2 = PA2(:,Transform);
      PA1 = PA1(:,Transform);
      PB2 = PB2(:,Transform);
      PB1 = PB1(:,Transform);
      PAB = PAB(:,Transform);
      PBA = PBA(:,Transform);
    end
    
    
    function B = flattenStack(B,Flatten)
      if nargin < 2
        Flatten = false;
      end
      if isempty(B.FlatStack)
        B.getNeededPartOfStack;
        StackLen=length(B.Stack);
        B.FlatStack=zeros([size(B.Stack{1}),StackLen]);
        Frequency = ceil(StackLen/20);
        if Flatten
          BallRadius=B.Config.SubtractBackground.BallRadius;
          Smoothe=B.Config.SubtractBackground.Smoothe;
          Stack=B.Stack;
          FS = B.FlatStack;
          SFolder = B.StatusFolder;
          parfor n=1:StackLen
            trackStatus(SFolder,'Processing stack','',n-1,StackLen,Frequency)
            FS(:,:,n)=flattenImage(Stack{n},BallRadius,Smoothe);
          end
          B.FlatStack = FS;
        else
          for n=1:StackLen
            trackStatus(B.StatusFolder,'Processing stack','',n-1,StackLen,Frequency)
            B.FlatStack(:,:,n)=B.Stack{n};
          end
        end
        trackStatus(B.StatusFolder,'Processing stack','',StackLen,StackLen,1)
      end
    end
    
    
    function [Fig, Ax] = maximumProject(B,varargin)
      p=inputParser;
      p.addParameter('Flatten',false,@islogical);
      p.addParameter('Rotate',true,@islogical);
      p.parse(varargin{:})
      if ~isfield(B.Results, 'Image') || isempty(B.Results.Image) || ~isfield(B.Results, 'ImageRotated')
        B.flattenStack;
        if isfield(B.Results, 'ProjectionMethod')
          switch B.Results.ProjectionMethod
            case 1
              B.Results.Image=max(B.FlatStack,[],3);
            case 2
              trackStatus(B.StatusFolder,'Calculating Median','',0,1,1);
              if size(B.FlatStack,3) > 100
                B.Results.Image=median(B.FlatStack(:,:,1:100),3);
              else
                B.Results.Image=median(B.FlatStack,3);
              end
              trackStatus(B.StatusFolder,'Calculating Median','',1,1,1);
            case 3
              trackStatus(B.StatusFolder,'Calculating SD','',0,1,1);
              B.Results.Image=std(B.FlatStack,0,3);
              trackStatus(B.StatusFolder,'Calculating SD','',0,1,1);
            otherwise
              B.Results.Image=max(B.FlatStack,[],3);
          end
        else
          B.Results.Image=max(B.FlatStack,[],3);
        end
        if p.Results.Rotate
          B.rotateImage;
        end
        B.Results.ImageRotated = p.Results.Rotate;
      elseif B.Results.ImageRotated ~= p.Results.Rotate
        if B.Results.ImageRotated
          B.rotateImageBack;
        else
          B.rotateImage;
        end
        B.Results.ImageRotated = p.Results.Rotate;
      end
      [Black, White] = autoscale(B.Results.Image);
      Fig = createBasicFigure('Aspect',size(B.Results.Image,2)/size(B.Results.Image,1),'Renderer','painters');
      Ax = axes('Parent', Fig, 'Position',[0 0 1 1],...
        'Visible','off');
      imshow(B.Results.Image, [Black, White], 'Parent', Ax);
    end
    
    
    function B = rotateImage(B)
      B.Results.Image = rot90(B.Results.Image, round(B.Rotation / 90));
      if B.Flip
        B.Results.Image = flipud(B.Results.Image);
      end
    end
    
    
    function B = rotateImageBack(B)
      if B.Flip
        B.Results.Image = flipud(B.Results.Image);
      end
      B.Results.Image = rot90(B.Results.Image, -round(B.Rotation / 90));
    end
    
    
    function B = manuallyCheckErrors(B)
      if isfield(B.Results, 'PassErrorMolecules')
        ErrorPassJunctions = find(cellfun(@(X) ~isempty(X), B.Results.PassErrorMolecules));
        B.manuallyCheckJunctions(ErrorPassJunctions); %#ok<FNDSB>
      else
        warning('MATLAB:AutoTipTrack:BioCompEvaluationClass:manuallyCheckErrors', ...
          'manuallyCheckErrors cannot check errors. No field "PassErrorMolecules" found in "Results".');
      end
    end
    
    
    function B = manuallyCheckAll(B)
      if isfield(B.Results, 'Found')
        Junctions = find(cellfun(@(X) ~isempty(X), B.Results.Found));
        B.manuallyCheckJunctions(Junctions, 'Field', 'Found'); %#ok<FNDSB>
      else
        warning('MATLAB:AutoTipTrack:BioCompEvaluationClass:manuallyCheckAll', ...
          'manuallyCheckAll cannot check errors. No field "Found" found in "Results".');
      end
    end
    
    
    function B = manuallyCheckJunctions(B, Junctions, varargin)
      p=inputParser;
      p.addParameter('Field', 'PassErrorMolecules', @ischar);
      p.KeepUnmatched=true;
      p.parse(varargin{:});
      Tmp = [fieldnames(p.Unmatched),struct2cell(p.Unmatched)];
      Passthrough = reshape(Tmp', [], 1)';
      for n = Junctions
        MoleculeList = B.Results.(p.Results.Field){n}(:, 2);
        UI = B.createJunctionAnalysisUI(n, MoleculeList, Passthrough{:});
        uiwait(UI);
      end
      B.thoroughReEvaluate;
    end
    
    
    function B = thoroughReEvaluate(B)
      B.calculateDirections;
      B.processJunctions;
      B.analyzeJunctions;
    end
    
    
    function [JunctionImagePos, JunctionImageSize] = getJunctionImagePos(B, JunctionNumber, varargin)
      p=inputParser;
      p.addParameter('JunctionImageSize', [], @(x) isnumeric(x) && (isempty(x) || size(x, 2) == 2)); %Desired size of the junction image in pixels if empty, Padding is used instead
      p.addParameter('Padding', [15 15], @(x) isnumeric(x) && (isempty(x) || size(x, 2) == 2)); %Padding [left/right top/bottom] of junction in pixels
      p.addParameter('Rotate', true, @islogical);
      p.parse(varargin{:});
      % get the size and position of the junction
      ImageSize = [B.Config.Width B.Config.Height];
      if p.Results.Rotate
        [JunctionPos, JunctionSize, ImageSize] = InteractiveGUI.rotateRegions(B.Results.RectPos(JunctionNumber,:), B.Rotation, B.Results.RectSize, ImageSize);
        if B.Flip
          JunctionPos(:,2) = ImageSize(2) - JunctionPos(:,2) - JunctionSize(2);
        end
      else
        JunctionPos = B.Results.RectPos(JunctionNumber,:);
        JunctionSize = B.Results.RectSize;
      end
      if isempty(p.Results.JunctionImageSize)
        Padding = p.Results.Padding;
        JunctionImageSize = JunctionSize + (Padding * 2);
      else
        Padding = round((p.Results.JunctionImageSize - JunctionSize) ./ 2);
        JunctionImageSize = p.Results.JunctionImageSize;
      end
      JunctionImagePos = JunctionPos - Padding;
      JunctionImagePos(JunctionImagePos < 1) = 1;
      JunctionImageSize(JunctionImageSize >= ImageSize) = ImageSize(JunctionImageSize > ImageSize) - 1;
      MaxJPos = ImageSize - JunctionImageSize;
      JunctionImagePos(JunctionImagePos > MaxJPos) = MaxJPos(JunctionImagePos > MaxJPos);
    end
    
    
    function UI = createJunctionAnalysisUI(B, JunctionNumber, MoleculeList, varargin)
      p=inputParser;
      p.addParameter('Rotate', true, @islogical);
      p.addParameter('UIName', 'PassErrorMolecules', @ischar);
      p.KeepUnmatched=true;
      p.parse(varargin{:});
      Tmp = [fieldnames(p.Unmatched),struct2cell(p.Unmatched)];
      Passthrough = [{'Rotate', p.Results.Rotate} reshape(Tmp', [], 1)'];
      % get the size and position of the junction
      [JunctionImagePos,JunctionImageSize] = B.getJunctionImagePos(JunctionNumber, Passthrough{:});
      B.flattenStack;
      %create and place the UI
      UI=figure('DockControls','off','IntegerHandle','off','MenuBar','none','Name',...
        ['Analyze: ', p.Results.UIName],'NumberTitle','off','Tag','JunctionAnalysisUI');
      Units=get(0,'Units');
      set(0,'Units','pixels');
      ScreenSize=get(0,'screensize');
      set(0,'Units',Units);
      ScreenAspect = (ScreenSize(3) - 75) / ScreenSize(4);
      JunctionImageAspect = JunctionImageSize(1) / JunctionImageSize(2);
      ScreenFill = 0.7; % How much of the screen should the UI take up? Should be a number between 0 and 0.95
      ControlWidth = 115; % width of controls in pixels
      FrameSliderWidth = 25;
      ButtonWidth = 75;
      if ScreenAspect > JunctionImageAspect
        FigHeigth = round(ScreenSize(4) * ScreenFill);
        FigWidth = round(FigHeigth * JunctionImageAspect + ControlWidth);
      else
        FigWidth = round((ScreenSize(3) - ControlWidth) * ScreenFill + ControlWidth);
        FigHeigth = round((FigWidth - ControlWidth) / JunctionImageAspect);
      end
      set(UI, 'Position', [1 1 FigWidth FigHeigth], 'Visible', 'on');
      NormalizedControlWidth = ControlWidth / FigWidth;
      UserData = struct();
      UserData.JunctionNumber = JunctionNumber;
      UserData.MoleculeList = MoleculeList;
      UserData.CurrentMolecule = 1;
      UserData.ImageAxes = axes(UI,'Position', [0, 0, 1 - NormalizedControlWidth, 1],...
        'DataAspectRatioMode', 'manual', 'DataAspectRatio', [1 1 1]);
      UserData.Rotate = p.Results.Rotate;
      UserData.JunctionImagePos = round(JunctionImagePos);
      UserData.JunctionImageSize = round(JunctionImageSize);
      UserData.XLim = [JunctionImagePos(1), JunctionImagePos(1) + JunctionImageSize(1)];
      UserData.YLim = [JunctionImagePos(2), JunctionImagePos(2) + JunctionImageSize(2)];
      Frames = size(B.Molecule(MoleculeList(UserData.CurrentMolecule)).Results,1);
      UserData.FrameSlider = uicontrol(...
        'Parent',UI,...
        'Units','normalized',...
        'Max', Frames,...
        'Min',1,...
        'Value',1,...
        'String','Frame',...
        'Style','slider',...
        'Position',[1 - ((ControlWidth - 5) / FigWidth), 0, FrameSliderWidth / FigWidth, 1],...
        'Callback',@B.updateJunctionImage,...
        'Tag','FrameSlider');
      ButtonXPos = 1 - ((ButtonWidth + 5) / FigWidth);
      NormalizedButtonWidth = ButtonWidth / FigWidth;
      UserData.SaveButton = uicontrol(...
        'Parent',UI,...
        'Units','normalized',...
        'String','Save Stack',...
        'Style','pushbutton',...
        'Position',[ButtonXPos 0.88 NormalizedButtonWidth 0.1],...
        'Callback',@B.saveJunctionImageStack,...
        'Tag','SaveButton',...
        'Enable', 'on');
      UserData.DeleteButton = uicontrol(...
        'Parent',UI,...
        'Units','normalized',...
        'String','Delete Current Frame',...
        'Style','pushbutton',...
        'Position',[ButtonXPos 0.62 NormalizedButtonWidth 0.1],...
        'Callback',@B.deleteCurrentFrame,...
        'Tag','DeleteButton',...
        'Enable', 'on');
      UserData.SplitButton = uicontrol(...
        'Parent',UI,...
        'Units','normalized',...
        'String','Split Path Here',...
        'Style','pushbutton',...
        'Position',[ButtonXPos 0.5 NormalizedButtonWidth 0.1],...
        'Callback',@B.splitMoleculePathHere,...
        'Tag','SplitButton',...
        'Enable', 'on');
      UserData.PrevButton = uicontrol(...
        'Parent',UI,...
        'Units','normalized',...
        'String','Previous Molecule',...
        'Style','pushbutton',...
        'Position',[ButtonXPos 0.26 NormalizedButtonWidth 0.1],...
        'Callback',@B.analyzePrevMolecule,...
        'Tag','PrevButton',...
        'Enable', 'off');
      UserData.NextButton = uicontrol(...
        'Parent',UI,...
        'Units','normalized',...
        'String','Next Molecule',...
        'Style','pushbutton',...
        'Position',[ButtonXPos 0.14 NormalizedButtonWidth 0.1],...
        'Callback',@B.analyzeNextMolecule,...
        'Tag','NextButton',...
        'Enable', 'on');
      UserData.DoneButton = uicontrol(...
        'Parent',UI,...
        'Units','normalized',...
        'String','Done',...
        'Style','pushbutton',...
        'Position',[ButtonXPos 0.02 NormalizedButtonWidth 0.1],...
        'Callback',@B.closeJunctionAnalysisUI,...
        'Tag','DoneButton',...
        'Enable', 'on');
      UI.UserData = UserData;
      UI = B.setupSlider(UI, Frames);
      UI = B.switchMolecule(UI);
      B.playMolecule(UI);
    end
    
    
    function saveJunctionImageStack(B, hObj, ~)
      UI = hObj.Parent;
      MoleculeNo = UI.UserData.MoleculeList(UI.UserData.CurrentMolecule);
      FileName = fullfile(B.Config.Directory, ...
        [B.Config.StackName(1:end-4) sprintf('_%s_junction-%d.tif', B.Molecule(MoleculeNo).Name, UI.UserData.JunctionNumber)]);
      BioCompEvaluationClass.saveImageStack(UI.UserData.Stack, FileName);
    end
    
    
    function analyzeNextMolecule(B, hObj, ~)
      UI = hObj.Parent;
      UI.UserData.CurrentMolecule = UI.UserData.CurrentMolecule + 1;
      B.switchMolecule(UI);
      B.playMolecule(UI);
    end
    
    
    function analyzePrevMolecule(B, hObj, ~)
      UI = hObj.Parent;
      UI.UserData.CurrentMolecule = UI.UserData.CurrentMolecule - 1;
      B.switchMolecule(UI);
      B.playMolecule(UI);
    end
    
    function playMolecule(B, UI)
      for n = 1:UI.UserData.FrameSlider.Max
        UI.UserData.FrameSlider.Value = n;
        B.updateJunctionImage(UI.UserData.FrameSlider);
        drawnow;
        pause(1/30);
      end
      UI.UserData.FrameSlider.Value = 1;
      B.updateJunctionImage(UI.UserData.FrameSlider);
      drawnow;
    end
    
    
    function UI = switchMolecule(B, UI)
      if UI.UserData.CurrentMolecule > length(UI.UserData.MoleculeList)
        UI.UserData.CurrentMolecule = length(UI.UserData.MoleculeList);
      end
      if UI.UserData.CurrentMolecule < 1
        UI.UserData.CurrentMolecule = 1;
      end
      if UI.UserData.CurrentMolecule < length(UI.UserData.MoleculeList)
        UI.UserData.NextButton.Callback = @B.analyzeNextMolecule;
      else
        UI.UserData.NextButton.Callback = @B.closeJunctionAnalysisUI;
      end
      if UI.UserData.CurrentMolecule > 1
        UI.UserData.PrevButton.Enable = 'on';
      else
        UI.UserData.PrevButton.Enable = 'off';
      end
      UI = B.addMoleculeData(UI);
    end
    
    
    function [JStack, Frames, Path] = getJunctionStack(B, JunctionImagePos, JunctionImageSize, Rotate, MoleculeNo, TempPadding)
      if nargin < 6
        TempPadding = 0;
      end
      Frames = B.Molecule(MoleculeNo).Results(:,1);
      NFrames = size(Frames, 1);
      if Rotate
        Path = InteractiveGUI.rotateCoordinates(B.Molecule(MoleculeNo).Results(:,3:4), B.Rotation, [B.Config.Width B.Config.Height] .* B.Config.PixSize);
        if B.Flip
          Path(:,2) = (B.Config.Height * B.Config.PixSize) - Path(:,2);
        end
      else
        Path = B.Molecule(MoleculeNo).Results(:,3:4);
      end
      Path = Path / B.Config.PixSize;
      Shift = JunctionImagePos - 1;
      Path = Path - Shift(ones(NFrames,1),:);
      Delete = Path(:,1) < 0 | Path(:,1) > JunctionImageSize(1) |...
        Path(:,2) < 0 | Path(:,2) > JunctionImageSize(2);
      if sum(Delete) < NFrames
        Frames(Delete) = [];
        Path(Delete,:) = [];
      else
        warning('MATLAB:AutoTipTrack:BioCompEvaluationClass:addMoleculeData',...
          'Something is wrong with molecule number %d (name: %s).\nIt appears that the path is entirely outside the junction but it is reported as an error.\nIt is recommended to check it with fiesta and delete or fix it manually.', MoleculeNo, B.Molecule(MoleculeNo).Name);
      end
      Path = [Path Frames];
      Frames = (min(Frames) - TempPadding : max(Frames) + TempPadding)';
      Frames(Frames < 1) = [];
      Frames(Frames > size(B.FlatStack, 3)) = [];
      if Rotate
        JStack = rot90(B.FlatStack(:, :, Frames), round(B.Rotation / 90));
        if B.Flip
          JStack = flipud(JStack);
        end
        JStack = JStack(JunctionImagePos(2):JunctionImagePos(2) + JunctionImageSize(2) - 1, ...
          JunctionImagePos(1):JunctionImagePos(1) + JunctionImageSize(1) - 1, :);
      else
        JStack = B.FlatStack(JunctionImagePos(2):JunctionImagePos(2) + JunctionImageSize(2) - 1, ...
          JunctionImagePos(1):JunctionImagePos(1) + JunctionImageSize(1) - 1,...
          Frames);
      end
    end
    
    
    function UI = addMoleculeData(B, UI)
      MoleculeNo = UI.UserData.MoleculeList(UI.UserData.CurrentMolecule);
      [UI.UserData.Stack, UI.UserData.Frames, UI.UserData.Path] = getJunctionStack(B, UI.UserData.JunctionImagePos, UI.UserData.JunctionImageSize, UI.UserData.Rotate, MoleculeNo);
      NFrames = size(UI.UserData.Frames, 1);
      UI = B.setupSlider(UI, NFrames);
      B.updateJunctionImage(UI.UserData.FrameSlider);
    end
    
    
    function B = findErrorMolecules(B)
      JunctionsA = find(B.Results.Pass & (B.Results.A1Sum | B.Results.ABSum));
      JunctionsB = find(B.Results.Pass & (B.Results.B2Sum | B.Results.BASum));
      MolIDs = false(1,length(B.Molecule));
      for n = JunctionsA
        WrongTurnsRight = B.Results.A1{n}(:,1) > 0;
        WrongTurnsLeft = B.Results.AB{n}(:,1) > 0;
        B.Results.PassErrorMolecules{n} = [B.Results.PassErrorMolecules{n}; ...
          B.Results.A1{n}(WrongTurnsRight, :);...
          B.Results.AB{n}(WrongTurnsLeft, :)];
        MolIDs(B.Results.PassErrorMolecules{n}) = true;
      end
      for n = JunctionsB
        WrongTurnsRight = B.Results.BA{n}(:,1) > 0;
        WrongTurnsLeft = B.Results.B2{n}(:,1) > 0;
        B.Results.PassErrorMolecules{n} = [B.Results.PassErrorMolecules{n}; ...
          B.Results.BA{n}(WrongTurnsRight, :);...
          B.Results.B2{n}(WrongTurnsLeft, :)];
        MolIDs(B.Results.PassErrorMolecules{n}(:, 2)) = true;
      end
      B.Results.PassErrorMoleculeNames = {B.Molecule(MolIDs).Name};
      B.Results.PassErrorMoleculeIDs = MolIDs;
    end
    
    
    function B = splitMoleculePathHere(B, hObj, ~)
      UI = hObj.Parent;
      B.splitMolecule(UI.UserData.MoleculeList(UI.UserData.CurrentMolecule),...
        UI.UserData.Frames(round(UI.UserData.FrameSlider.Value)));
      B.switchMolecule(UI);
    end
    
    
    function B = splitMolecule(B,MolID,Frame)
      MolNum = strsplit(B.Molecule(end).Name,' ');
      MolNum = str2double(MolNum{2});
      B.Molecule(end+1)=B.Molecule(MolID);
      B.Molecule(MolID).Results(B.Molecule(MolID).Results(:,1) > Frame, :) = [];
      B.Molecule(end).Name = num2str(MolNum+1,'Molecule %d');
      B.Molecule(end).Results(B.Molecule(end).Results(:,1) <= Frame, :) = [];
      B.Results.Direction = []; %make sure the data is properly reevaluated
    end
    
    
    function B = deleteCurrentFrame(B, hObj, ~)
      UI = hObj.Parent;
      B.deleteFrames(UI.UserData.MoleculeList(UI.UserData.CurrentMolecule),...
        UI.UserData.Frames(round(UI.UserData.FrameSlider.Value)));
      B.switchMolecule(UI);
    end
    
    
    function B = deleteFrames(B,MolID,Frames)
      for n = 1: length(Frames)
        B.Molecule(MolID).Results(B.Molecule(MolID).Results(:,1) == Frames(n), :) = [];
      end
    end
    
    
    function saveAllJunctionImageStacks(B)
      p=inputParser;
      p.addParameter('JunctionImageSize', [128 128], @(x) isnumeric(x) && (isempty(x) || size(x, 2) == 2)); %Desired size of the junction image in pixels if empty, Padding is used instead
      p.addParameter('Padding', [15 15], @(x) isnumeric(x) && (isempty(x) || size(x, 2) == 2)); %Padding [left/right top/bottom] of junction in pixels
      p.addParameter('Rotate', false, @islogical);
      p.addParameter('Flatten',false,@islogical);
      p.addParameter('JunctionType', {'PassErrorMolecules'}, @iscellstr);
      p.addParameter('TempPadding', 0, @isnumeric);
      p.parse(B.Results.SaveJunctionParams{:});
      Passthrough = {'JunctionImageSize', p.Results.JunctionImageSize, 'Padding', p.Results.Padding, 'Rotate', p.Results.Rotate, 'TempPadding', p.Results.TempPadding};
      BallRadius = B.Config.SubtractBackground.BallRadius;
      if ~p.Results.Flatten
        B.Config.SubtractBackground.BallRadius = 0;
      end
      B.flattenStack(p.Results.Flatten);
      B.Config.SubtractBackground.BallRadius = BallRadius;
      ResultsFields = p.Results.JunctionType;
      if any(strcmpi(p.Results.JunctionType, 'PassErrorMolecules')) && isfield(B.Results, 'PassErrorMolecules')
        Junctions = find(cellfun(@(X) ~isempty(X), B.Results.PassErrorMolecules));
        B.saveManyJunctionImageStacks(Junctions, 'PassErrorMolecules', Passthrough{:}); %#ok<FNDSB>
        ResultsFields(strcmpi(ResultsFields, 'PassErrorMolecules')) = [];
      elseif any(strcmpi(p.Results.JunctionType, 'Split')) && isfield(B.Results, 'Found') && isfield(B.Results, 'Split')
        Junctions = find(cellfun(@(X) ~isempty(X), B.Results.Found) & B.Results.Split);
        B.saveManyJunctionImageStacks(Junctions, 'Found', 'Name', 'Split', Passthrough{:}); %#ok<FNDSB>
        ResultsFields(strcmpi(ResultsFields, 'Split')) = [];
      elseif any(strcmpi(p.Results.JunctionType, 'Pass')) && isfield(B.Results, 'Found') && isfield(B.Results, 'Pass')
        Junctions = find(cellfun(@(X) ~isempty(X), B.Results.Found) & B.Results.Pass);
        B.saveManyJunctionImageStacks(Junctions, 'Found', 'Name', 'Pass', Passthrough{:}); %#ok<FNDSB>
        ResultsFields(strcmpi(ResultsFields, 'Pass')) = [];
      elseif any(strcmpi(p.Results.JunctionType, 'All'))
        ResultsFields = {'A1', 'A2', 'B1', 'B2', 'AB', 'BA', 'Other'};
      end
      for n = 1:length(ResultsFields)
        if isfield(B.Results, ResultsFields{n}) && iscell(B.Results.(ResultsFields{n}))
          Junctions = find(cellfun(@(X) ~isempty(X), B.Results.(ResultsFields{n})));
          B.saveManyJunctionImageStacks(Junctions, ResultsFields{n}, Passthrough{:}); %#ok<FNDSB>
        end
      end
      if B.Manual
        B.thoroughReEvaluate;
      end
    end
    
    
    function saveManyJunctionImageStacks(B, Junctions, ResultsField, varargin)
      p=inputParser;
      p.addParameter('Name', ResultsField, @ischar);
      p.addParameter('Rotate', false, @islogical);
      p.addParameter('TempPadding', 0, @isnumeric);
      p.KeepUnmatched=true;
      p.parse(varargin{:});
      Tmp = [fieldnames(p.Unmatched),struct2cell(p.Unmatched)];
      Passthrough = [{'Rotate', p.Results.Rotate} reshape(Tmp', [], 1)'];
      for JunctionNo = Junctions
        [JunctionImagePos, JunctionImageSize] = B.getJunctionImagePos(JunctionNo, Passthrough{:});
        MoleculeList = B.getMoleculesAtJunction(JunctionNo, ResultsField);
        if ~isempty(MoleculeList)
          if B.Manual
            UI = B.createJunctionAnalysisUI(JunctionNo, MoleculeList', 'UIName', ResultsField, Passthrough{:});
            uiwait(UI);
          else
            for MoleculeNo = MoleculeList'
              [JStack, Frames] = B.getJunctionStack(round(JunctionImagePos), JunctionImageSize, p.Results.Rotate, MoleculeNo, p.Results.TempPadding);
              FileName = fullfile(B.Config.Directory, ...
                [B.Config.StackName(1:end-4) sprintf('_%s_%s_junction-%d_Frames_%d-%d.tif', p.Results.Name, B.Molecule(MoleculeNo).Name, JunctionNo, min(Frames), max(Frames))]);
              BioCompEvaluationClass.saveImageStack(JStack, FileName);
            end
          end
        end
      end
    end
    
    
    function MoleculeList = getMoleculesAtJunction(B, JunctionNo, ResultsField)
      if nargin < 3
        ResultsField = 'Found';
      end
      UseMolecules = B.Results.(ResultsField){JunctionNo}(:,1) > 0;
      MoleculeList = unique(B.Results.(ResultsField){JunctionNo}(UseMolecules,2));
      MoleculeList(isnan(MoleculeList)) = [];
    end
    
    %% region counting
    function B = countRegionTraffic(B)
      if isempty(B.Stack)
        B.loadFile;
      end
      B.Results.RegionCounts = struct([]);
      NRect = size(B.Results.RectPos, 1);
      B.Results.RegionCounts(1).Counts = zeros(NRect,1);
      Coords = round(B.Results.RectPos);
      Coords(:, 3:4) = Coords + repmat(round(B.Results.RectSize), NRect, 1);
      Coords(Coords < 1) = 1;
      Outside = Coords(:,1) > B.Config.Width;
      Coords(Outside, 1) = B.Config.Width;
      Outside = Coords(:,3) > B.Config.Width;
      Coords(Outside, 3) = B.Config.Width;
      Outside = Coords(:,2) > B.Config.Height;
      Coords(Outside, 2) = B.Config.Height;
      Outside = Coords(:,4) > B.Config.Height;
      Coords(Outside, 4) = B.Config.Height;
      AllInt = vertcat(B.Molecule.Results);
      AllInt = AllInt(:,7);
      Threshold = median(AllInt);
      for n=2:length(B.Stack)
        Diff = B.Stack{n} - B.Stack{n-1};
        Events = Diff > Threshold;
        for k = 1:NRect
          if any(any(Events(Coords(k,1):Coords(k,3),Coords(k,2):Coords(k,4))))
            B.Results.RegionCounts(1).Counts(k) = B.Results.RegionCounts(1).Counts(k) + 1;
          end
        end
      end
    end
    
    
  end
  methods (Static)
    
    
    function makeOverviewFigure(EvaluationClasses,folder)
      if ~isempty(EvaluationClasses)
        try
          numFiles=length(EvaluationClasses);
          MergedResults = BioCompEvaluationClass;
          for n=1:numFiles
            MergedResults.merge(EvaluationClasses{n});
            MergedResults.Stack = [];
            MergedResults.FlatStack = [];
          end
          if isfield(MergedResults.Results, 'RectPos') && isfield(MergedResults.Results, 'Rotation') && isfield(MergedResults.Results, 'A2Sum')
            MergedResults.Config.Directory = folder;
            MergedResults.Config.StackName = 'BioCompEvaluation';
            MergedResults.analyzeJunctions;
            MergedResults.plotJunctionPerformance;
            save(fullfile(folder,'BioComp_summary.mat'),'MergedResults');
          end
        catch ME
          ME.getReport
        end
      end
    end
    
    
    function updateJunctionImage(hObj, ~)
      UI = hObj.Parent;
      Frame = round(UI.UserData.FrameSlider.Value);
      Stack = UI.UserData.Stack(:,:,Frame);
      [black, white] = autoscale(Stack);
      hold(UI.UserData.ImageAxes, 'off');
      imshow(Stack, [black, white], 'Parent', UI.UserData.ImageAxes);
      hold(UI.UserData.ImageAxes, 'on');
      plot(UI.UserData.ImageAxes, UI.UserData.Path(:, 1), UI.UserData.Path(:, 2),'b');
      TrackFrame = UI.UserData.Path(:,3) == Frame + UI.UserData.Path(1,3) - 1;
      if any(TrackFrame)
        UI.UserData.DeleteButton.Enable = 'on';
        UI.UserData.SplitButton.Enable = 'on';
        plot(UI.UserData.ImageAxes, UI.UserData.Path(TrackFrame,1), UI.UserData.Path(TrackFrame,2),'bd','MarkerSize',8);
      else
        UI.UserData.DeleteButton.Enable = 'off';
        UI.UserData.SplitButton.Enable = 'off';
      end
    end
    
    
    function closeJunctionAnalysisUI(hObj, ~)
      close(hObj.Parent);
    end
    
    
    function MaxCount = findMaxCount(CellData)
      MaxCount = 0;
      if ~isempty(CellData)
        Max = nanmax(CellData(:,1));
        if ~isnan(Max)
          MaxIndex = find(CellData(:,1) == Max);
          MaxCount = (CellData(MaxIndex(1),1));
        end
      end
    end
    
    
    function Count = summarizePath(Path)
      if isempty(Path)
        Count = 0;
      else
        Count = nansum(Path(:,1));
      end
    end
    
    
    function closeFig(hObj, ~)
      close(hObj.Parent);
      drawnow;
    end
    
    
    function UI = setupSlider(UI, NFrames)
      if NFrames > 1
        UI.UserData.FrameSlider.Enable = 'on';
        UI.UserData.FrameSlider.Value = 1;
        UI.UserData.FrameSlider.Max = NFrames;
        Step = [1/(NFrames - 1), 5/(NFrames - 1)];
        Step(Step > 1) = 1;
        UI.UserData.FrameSlider.SliderStep = Step;
      else
        UI.UserData.FrameSlider.Enable = 'off';
        UI.UserData.FrameSlider.Value = 1;
      end
    end
    
    
    function saveImageStack(Stack, FileName)
      imwrite(uint16(Stack(:,:,1)), FileName, 'tif', 'Compression', 'none');
      NFrames = size(Stack,3);
      if NFrames > 1
        for n = 2:NFrames
          imwrite(uint16(Stack(:,:,n)), FileName, 'tif', 'Compression', 'none', 'WriteMode', 'append');
        end
      end
    end
    
    
  end
  
end

