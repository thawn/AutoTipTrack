#!/bin/bash
if [ "x$1" == "x" ]; then
  echo "usage: $0 <dir/you/need/to/sort> [number of files per node]"
else
  oldIFS=$IFS
  IFS='
'
  set=6
  dirs=( bac_glass ins_gold ins_border ins_glass bac_gold bac_border )
  counter=1
  dirnum=0
  rootdir=${1%/}
  for file in $( find $rootdir -type f -name "*.nd2" -o -name "*.stk" -o -name "*.tif" | sort ); do
    kind=$(( counter % $set ))
    case $kind in
    1)
      curdir="${rootdir}/${dirs[1]}"
      ;;
    2)
      curdir="${rootdir}/${dirs[2]}"
      ;;
    3)
      curdir="${rootdir}/${dirs[3]}"
      ;;
    4)
      curdir="${rootdir}/${dirs[4]}"
      ;;
    5)
      curdir="${rootdir}/${dirs[5]}"
      ;;
    0)
      curdir="${rootdir}/${dirs[0]}"
      ;;
    esac
    if [ ! -d "$curdir" ]; then
      mkdir "$curdir"
    fi
    echo "$curdir"
    if [ -e "${rootdir}/config.mat" ]; then
      cp "${rootdir}/config.mat" "${curdir}/"
    fi
    mv "$file" "${curdir}/$( basename $file )"
    counter=$(( $counter + 1 ))
  done
fi

