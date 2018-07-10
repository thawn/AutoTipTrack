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
  jobExecutable="$1"
  dir="$2"
  echo file: "$dir"
  echo executable: "$jobExecutable"
  if [ -x "$jobExecutable" ]; then
    queue=medium
    if [ -w "${jobExecutable}_redo.txt" ]; then
      count=$( cat "${jobExecutable}_redo.txt" )
      if [ $count -lt 4 ]; then
        queue=medium
        echo $(( $count + 1 ))>"${jobExecutable}_redo.txt"
        sleep $(( 60 * $count)) #wait between retries
      else
        echo "too many retries, something is seriously wrong!"
        exit 1
      fi
    else
      echo 1 >"${jobExecutable}_redo.txt"
    fi
    jobname=$(basename "$jobExecutable")
    maindir=$(dirname "$jobExecutable")
    numCores=1
    echo main dir: $maindir
    mcrCache="${jobExecutable}_mcrCache"
    if grep -q "All done!" "${jobExecutable}.log" || grep -q Success! "${jobExecutable}.log" || grep -q "TERM_OWNER: job killed by owner." "${jobExecutable}.log"; then
      echo "Processing of $dir was successful! Deleting $jobExecutable and $mcrCache"
      rm "$jobExecutable"
      rm -rf "$mcrCache"
    else
      cleanup=/sw/users/korten/cleanupSimulation.sh
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
      bsub -q $queue -J "$jobname" -o "${jobExecutable}.log" -n $numCores -R "span[hosts=1]" -Ep "$cleanup $jobExecutable $dir" "\"$jobExecutable\"" "$dir"
    fi
  else
    echo $usage
    if [ ! -x "$jobExecutable" ]; then
      echo "Error: $jobExecutable must be executable!"
    fi
    if [ ! -d "$( dirname $dir)" ]; then
      echo "Error: $dir must be a directory!"
    fi
    exit 1
  fi
fi
