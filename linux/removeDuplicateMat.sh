#!/bin/bash
if [ "x$1" == "x" ]; then
  echo "usage: $0 <dir/you/need/to/sort> [number of files per node]"
else
  oldIFS=$IFS
  IFS='
'
  lastdel=""
  rootdir="${1%/}"
  for mat in $(find "$rootdir" -name "*.mat" | sort); do 
    if [ "${lastdel//(*)/}" == "${mat//(*)/}" ]; then
      if [ $(ls -s "$lastdel" | awk '{print $1}') -lt $(ls -s "$mat" | awk '{print $1}') ]; then
        echo deleting $(ls -sh "$lastdel")
        if [ "x$2" != "xdebug" ]; then
          rm "$lastdel"
        fi
        echo keeping $(ls -sh "$mat")
        lastdel="$mat"
      else
        echo deleting $(ls -sh "$mat")
        if [ "x$2" != "xdebug" ]; then
          rm "$mat"
        fi
      fi
    else
      lastdel="$mat"
      echo keeping $(ls -sh "$mat")
    fi
  done
fi
