#!/bin/bash
start=1
for num in $@; do
  if [ $start -eq 11 ] || [ $start -eq 12 ]; then
    mkdir $( printf "%02d" $start )\#_ATP_1
    (( start++ ))
    mkdir $( printf "%02d" $start )\#_ATP_2
    (( start++ ))
  fi
  mkdir $( printf "%02d" $start )\#_0${num}_1
  (( start++ ))
  mkdir $( printf "%02d" $start )\#_0${num}_2
  (( start++ ))
done
