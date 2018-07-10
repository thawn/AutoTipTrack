#!/bin/bash
if [ "x$1" == "x" ]; then
  echo "usage: $0 <dir/you/need/to/sort> [number of files per node]"
else
  oldIFS=$IFS
  IFS='
'
  numfiles=6
  if [ "x$2" != "x" ]; then
    numfiles=$2
  fi
  counter=0
  dirnum=0
  rootdir=${1%/}
  for file in $( find $rootdir -type f -name "*.nd2" -o -name "*.stk" -o -name "*.tif" | sort ); do
    if [ $counter -lt 1 ]; then
      dirnum=$(( $dirnum + 1 ))
      curdir="${rootdir}/node$(printf %03d $dirnum)"
      mkdir "$curdir"
      echo "$curdir"
      counter=$numfiles
      if [ -e "${rootdir}/config.mat" ]; then
        cp "${rootdir}/config.mat" "${curdir}/"
      fi
    fi
    mv "$file" "${curdir}/$( basename $file )"
    counter=$(( $counter - 1 ))
  done
fi

