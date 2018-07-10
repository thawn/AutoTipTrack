function trackStatus(StatusFolder,id,message,n,nmax,frequency)
  %make sure id & message are o.k.
  if length(id)>20
    warning('MATLAB:AutoTipTrack:trackStatus','Id "%s" is too long. It will be shortened to 20 characters',id);
    id=id(1:20);
  end
  if strfind(id,'_')
    warning('MATLAB:AutoTipTrack:trackStatus','Id "%s" cannot contain the "_" character. It will be replaced with a "-" character',id);
    id=strrep(id,'_','-');
  end
  if length(message)>20
    warning('MATLAB:AutoTipTrack:trackStatus','Message "%s" is too long. It will be shortened to 20 characters',message);
    message=message(1:20);
  end
  if strfind(message,'_')
    warning('MATLAB:AutoTipTrack:trackStatus','Message "%s" cannot contain the "_" character. It will be replaced with a "-" character',message);
    message=strrep(message,'_','-');
  end
  % generate the filename and save the status file
  if mod(n,frequency)==0
    timestamp=datestr(clock,'yyyy-mm-dd_HH-MM-SS-FFF');
    filename=fullfile(StatusFolder,[timestamp '_' id '_' num2str(n) '_' num2str(nmax) '_' num2str(frequency) '_'  message '_' '.mat' ]);
    try %we don't want trackStatus tracking to be able to stop the whole program
    save(filename,'n')
    catch
    end
  end
end
