#!/bin/bash
#first get rid of obsolete matlab crash dumps
rm /sw/users/korten/core.*
rm /home/korten/matlab_crash_dump*
#now get to work
usage="usage: $0 </path/to/executable> </projects/path/to/data>"
if [ "x$1" == "x" ] || [ "x$2" == "x" ]; then
  echo $usage
else
  oldIFS=$IFS
  IFS='
'
  foundexec=false
  founddir=false
  jobExecutable=""
  dir=""
  for var in $@; do
    dirn=$( dirname "$var" )
    dirn=$( cd "$dirn" 2>/dev/null && pwd )
    if [ "x${dirn#/}" != "x$dirn" ] && [ $foundexec == false ] && [ $founddir == false ]; then
      foundexec=true
      jobExecutable="$var"
    elif [ "x${dirn#/projects}" != "x$dirn" ] && [ $foundexec == true ] && [ $founddir == false ]; then
      founddir=true 
      dir="$var"
    elif [ $foundexec == true ] && [ $founddir == false ]; then
      jobExecutable="$jobExecutable"\ "$var"
    elif [ $foundexec == true ] && [ $founddir == true ]; then
      dir="$dir"\ "$var"
    else
      echo $usage
      exit 1
    fi
  done
  echo dir: "$dir"
  echo executable: "$jobExecutable"
  if [ -x "$jobExecutable" ] && [ -d "$dir" ]; then
    dir="${dir%/}"
    queue=medium
    if [ -w "$dir/redo.txt" ]; then
      count=$( cat "$dir/redo.txt" )
      if [ $count -lt 4 ]; then
        queue=medium
        echo $(( $count + 1 ))>"$dir/redo.txt"
        sleep $(( 60 * $count)) #wait between retries
      else
        echo "too many retries, something is seriously wrong!"
        exit 1
      fi
    else
      echo 1 >"$dir/redo.txt"
    fi
    jobname=$(basename "$dir")
    maindir=$(dirname "$dir")
    numCores=12
    echo main dir: $maindir
    mcrCache="$maindir/${jobname}_mcrCache"
    if grep -q "All done!" "$maindir/${jobname}/AutoTipTrack_log.txt" || grep -q "All done!" "$maindir/${jobname}.log" || grep -q Success! "$maindir/${jobname}.log" || grep -q "TERM_OWNER: job killed by owner." "$maindir/${jobname}.log"; then
      echo "Job $dir was successful! Deleting $jobExecutable."
      rm "$jobExecutable"
      rm -rf "$mcrCache"
    else
      cleanup=/sw/users/korten/cleanup.sh
      #source /etc/profile
      cd /sw/users/korten/
      MCRROOT="/sw/apps/mcr/r2014b/"
      echo "------------------------------------------"
      echo Setting up environment variables
      echo ---
      LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64;
      export LD_LIBRARY_PATH;
      echo LD_LIBRARY_PATH is ${LD_LIBRARY_PATH};
      rm -rf "$mcrCache"
      mkdir "$mcrCache"
      MCR_CACHE_ROOT="$mcrCache"
      export MCR_CACHE_ROOT;
      bsub -q $queue -J "$jobname" -o "${dir}.log" -n $numCores -R "span[hosts=1]" -Ep "$cleanup $jobExecutable $dir" "\"$jobExecutable\"" "$dir" false 11
    fi
  else
    echo $usage
    if [ ! -x "$jobExecutable" ]; then
      echo "Error: $jobExecutable must be executable!"
    fi
    if [ ! -d "$dir" ]; then
      echo "Error: $dir must be a directory!"
    fi
    exit 1
  fi
fi
