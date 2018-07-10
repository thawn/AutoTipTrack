#!/bin/bash

word=$1

lword=$(tr '[:upper:]' '[:lower:]' <<< ${1:0:1})${1:1}

echo "$word -> $lword"

grep -Rl --null --binary-files=without-match $word * |xargs -0 -p sed -i -e "s/${word}/${lword}/g"

if [ -e "${word}.m" ]; then
  mv ${word}.m ${lword}.m
fi