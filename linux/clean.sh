#!/bin/bash
if [ "x$1" -eq "x" ]; then
  echo "usage: $0 <dir/you/need/to/clean>"
else
  find $1 -name eval -type d -exec rm -rf \{\} \;
fi
