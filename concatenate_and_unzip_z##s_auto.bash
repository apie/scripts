#!/bin/bash
#author: apie
#description: Script to automatically find, concatenate, unzip and move partial zip-archives of the format z01,z02,z0(n-1),zip.
#v0.1 2012-10-01 initial
#v0.2 2012-12-31 handle spaces correctly, better check for archives
#v0.3 2013-01-07 better handling of dots in filenames
#v0.4 2013-03-08 check for olddir existance, determine scriptdir
#v0.5 2017-07-14 fix code indenting, fix changelog dates

main(){
  scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  cd $scriptdir
  olddir="0old"
  #search for a partfile
  partfiles=$(find . -maxdepth 1 -name '*.z01')
  if [ $? -ne '0' ]
  then 
    echo No archive files found.
    exit 1
  fi
  #autodetermine the file (limit to 1 file to prevent failing if there are multiple zipped files in the current dir
  partfile=$(echo "$partfiles"|cut -d' ' -f1|sed 's/\.\///')
  basepartfiles=$(echo "$partfiles"|sed 's/.z01//')
  concatfile="$basepartfiles"".concatenated.zip" 
  
  checkfiles
  concat
  unzipfunc
  cleanup
}

checkfiles(){
  numfiles=$(ls "$basepartfiles".z*|wc -l)
  lastnumfile=$(expr $(($numfiles-1)) )
  if [ ! -f "$basepartfiles".z0$lastnumfile ] && [ ! -f "$basepartfiles".z$lastnumfile ]
  then
    echo lastfile doesnt exist!
    exit 1
  fi
  if [ ! -f "$basepartfiles".zip ]
  then
    echo zip doesnt exist!
    exit 1
  fi
  if [ -f "$concatfile" ]
  then
    echo concatenated file already exists!
    exit 1
  fi
  if [ ! -d "$olddir" ]
  then
    echo "$olddir" does not exist! Creating..
    mkdir "$olddir"
  fi	
}

concat(){ 
  for partfile in "$basepartfiles"'.z'*
  do
    echo "$partfile"
    cat "$partfile" >> "$concatfile"
  done
}

unzipfunc(){
  unzip "$concatfile"
}

cleanup(){
  mv "$basepartfiles".z* "$olddir"
  mv "$concatfile" "$olddir"
}

main
