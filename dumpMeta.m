function dumpMeta(meta,filename)
file=fopen(filename,'w');
fprintf(file,'%s',char(meta.toString));
fclose(file);
