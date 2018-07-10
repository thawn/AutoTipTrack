function makePlotSet(concentrations,allSpeeds,allLengths,numMTs,savePath,varargin)

makePlot(concentrations,allLengths,'yLabel',sprintf('microtubule length (%sm)',181),varargin{:});
saveas(gcf,fullfile(savePath,'MT_length.pdf'));
makePlot(concentrations,allSpeeds,'YLim',[0 1000],varargin{:});
saveas(gcf,fullfile(savePath,'MT_velocities.pdf'));
makePlot(concentrations,num2cell(numMTs),'yLabel','microtubule #','YLim',[0 200],varargin{:});
saveas(gcf,fullfile(savePath,'MT_num.pdf'));