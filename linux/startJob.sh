#!/bin/bash
if [ "x$1" == "x" ]; then
  echo "usage: $0 <dir/that/contains/your/data> [number of cores used per node]"
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
  numCores=12
  if [ "x$2" != "x" ]; then
    numCores=$2
  fi
  rootdir=${1%/}
  dirnames=$( ls -d1 ${rootdir}/*/ )
  echo "---"
  echo "Creating executables, wait 30 s"
  echo "---"
  for dir in $dirnames; do
    if grep -q "_mcrCache" <<< "$dir"; then
      #if the directory is a matlab runtime cache directory, we ignore it
      echo "Ignoring MCR cache directory: $dir"
    elif grep -q "ignore" <<< "$dir"; then
      #if the directory is called ignore, then we ignore it
      echo "Ignoring directory named ignore: $dir"
    else
      jobname=$( basename "$dir" )
      jobExecutable="${rootdir}/AutoTipTrack_${jobname}"
      cp evaluateManyExperiments "$jobExecutable"
    fi
  done
  sleep 30 #necessary to avoid that the matlab runtime cannot create a parpool
  echo "---"
  echo "Submitting jobs"
  echo "---"
  cleanup=/sw/users/korten/cleanup.sh
  for dir in $dirnames; do
    if grep -q "_mcrCache" <<< "$dir"; then
      #if the directory is a matlab runtime cache directory, we ignore it
      echo "Ignoring MCR cache directory: $dir"
    elif grep -q "ignore" <<< "$dir"; then
      #if the directory is called ignore, then we ignore it
      echo "Ignoring directory named ignore: $dir"
    else
      jobname=$( basename "$dir" )
      jobExecutable="${rootdir}/AutoTipTrack_${jobname}"
      mcrCache="${1}${jobname}_mcrCache"
      mkdir "$mcrCache"
      MCR_CACHE_ROOT="$mcrCache"
      export MCR_CACHE_ROOT;
      bsub -q short -W 1:00 -J "$jobname" -o "${1}${jobname}.log" -n $numCores -R "span[hosts=1]" -Ep "$cleanup $jobExecutable $dir" "\"$jobExecutable\"" "$dir" false 11
      sleep 6 #necessary to avoid that the matlab runtime cannot create a parpool
    fi
  done
fi

