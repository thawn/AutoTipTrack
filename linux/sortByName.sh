#!/bin/bash
for name in $@; do
  if [ "$name" == "Controls" ]; then
    mkdir -p ${name}/eval
    mv */*_A?P*.nd2 ${name}/
    mv */eval/*_A?P* ${name}/eval/
  else
    mkdir -p ${name}/eval
    mv */*${name}*.nd2 ${name}/
    mv */eval/*${name}* ${name}/eval/
  fi
done
