function Q = trackTips(Q)
if ~Q.Aborted
  if Q.Reevaluate
    trackStatus(Q.StatusFolder,'Loading data','',0,1,1);
    Q.reloadResults('Objects');
    trackStatus(Q.StatusFolder,'Loading data','',1,1,1);
    if isempty(Q.Objects)
      Q.loadFile;
    end
  else
    Q.loadFile;
  end
  try
    Q.saveFiestaCompatibleFile;
  catch ME
    ME.getReport
  end
  if ~isempty(Q.Stack) && isempty(Q.Objects)
    if isempty(getCurrentTask())
      %if we are not inside a parforloop, execute the tracking in parallel if
      %a pool is available
      Q.TrackParallel=true;
    end
    Q.autoTipTrack;
  end
  Q.saveFiestaCompatibleFile;
end
end
