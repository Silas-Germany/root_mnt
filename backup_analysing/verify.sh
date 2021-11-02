#!/bin/bash

[ -d explanations ] || cd ..
[ -d explanations ] || exit 1

if [ -n "$1" ]; then
  cd explanations
  echo
  echo START
  for f in *; do
    echo
    echo \# "$f":
    cat "$f"
  done
  exit
fi

if [ -t 1 ];then
  out=less
else
  out=cat
fi

(grep -vE "^$(cat explanations/* | grep -vE "^ *#|^$" | tr '\n' '|' | sed 's/|/$|^/g' | sed 's/|$//')$" file_changes || echo Nothing Missing) | $out
