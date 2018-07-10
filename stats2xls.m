function stats2xls(filename,Stats)
XlsContent={};
for n=1:length(Stats)
  Content=[{Stats(n).DisplayName} {'velocities'} num2cell(Stats(n).Stats.Speeds.numN) {'frame-to-frame velocities'};...
    {Stats(n).DisplayName} {'# microtubules'} num2cell(Stats(n).Stats.NumMT.numN) {'fields of view'};...
    {Stats(n).DisplayName} {'microtubule length'} num2cell(Stats(n).Stats.Length.numN) {'microtubules'}];
  if isfield(Stats(n).Stats.Bundling,'numN')
    Content=[Content;...
      {Stats(n).DisplayName} {'bundling ratio'} num2cell(Stats(n).Stats.Bundling.numN) {'frames'}]; %#ok<AGROW>
  end
  XlsContent = [XlsContent; Content]; %#ok<AGROW>
end
writetable(cell2table(XlsContent),filename);