function appendLog(log,message,useGUI)
if nargin<3
  useGUI=true;
end
if ~useGUI
  fprintf('%s %s\n',datestr(now,'yyyy-mm-dd HH:MM'),message);
end
logfile=fopen(log, 'a');
fprintf(logfile,'%s %s\n',datestr(now,'yyyy-mm-dd HH:MM'),message);
fclose(logfile);