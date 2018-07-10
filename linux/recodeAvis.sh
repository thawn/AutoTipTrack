#!/bin/bash
IFS='
'
directory="${1%/}"
for file in $(ls -c1 ${directory}/*.avi); do
  bsub -q short -W 1:00 -J "avirecode" -o "${file%avi}log" /sw/users/korten/ffmpeg/ffmpeg -i "$file" -c:v libx264 -preset slower -crf 24 -pix_fmt yuv420p -c:a copy "${file%avi}mp4"
done
