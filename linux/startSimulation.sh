#!/bin/bash
if [ "x$1" == "x" ]; then
  echo "usage: $0 <path/to/dir/that/contains/your/data>"
else
  source /etc/profile
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
  oldIFS=$IFS
  IFS='
'
  if [ "x$2" == "x" ]; then
    queue=short
  else
    queue=$2
  fi
  numCores=1
  rootdir=${1%/}
  rm ${rootdir}/._*.mat
  filenames=$( ls -d1 ${rootdir}/*.mat )
  cleanup=/sw/users/korten/cleanupSimulation.sh
  echo "---"
  echo "Submitting jobs"
  echo "---"
  counter=1
  for file in $filenames; do
    if grep -q "arguments.mat" <<< "$file"; then
      echo "ignoring $file"
    else
      jobname="simulate_$(printf %04d $counter)"
      counter=$(( $counter + 1 ))
      jobExecutable="${rootdir}/$jobname"
      cp simulateOnServer "$jobExecutable"
      mcrCache="${jobExecutable}_mcrCache"
      mkdir "$mcrCache"
      MCR_CACHE_ROOT="$mcrCache"
      export MCR_CACHE_ROOT;
      bsub -q $queue -J "$jobname" -o "${jobExecutable}.log" -n $numCores -R "span[hosts=1]" -Ep "$cleanup $jobExecutable $file>${jobExecutable}_cleanup.log" "\"$jobExecutable\"" "$file"
      #sleep 6 #necessary to avoid that the matlab runtime cannot create a parpool
    fi
  done
fi

