#!/bin/bash

#By DenickM 26-09-2015.
#Parse backuplog.txt to quickly get overview of backup status on target.
if [ $# -ne 1 ]
then
  echo "Give logfile as argument!"
  exit 1
fi
logfilename=$1

set -o nounset

comparedates() { #$1=name $1+=datestring
  name=$1
  shift
  datestring=$*
  date=$(date +%s --date="$datestring")
  yesterday=$(date +%s --date="yesterday 1900")
  if [ $date -lt $yesterday ]
  then
    message="Backup $name OUDER DAN 1 DAG"
  else
    message="Backup $name OK"
  fi
  echo $message
}

info=''
primary=''
while read line
do
  #If info is not yet found and this line is the info line, parse it.
  if [ -z "$info" ]
  then
    info=$(echo $line|grep "\->" | sed 's/\-> //' )
  fi
  #If this line is the date line, parse it.
  dateline=$(echo $line|grep "Chain end time"  )
  #If primary is not yet found and this line is the primary line, parse it.
  if [ -z "$primary" ]
  then
    primary=$(echo $line|grep "Found primary backup chain")
  fi
  #If this line is the date line, and primary was found, show it.
  if [[ ! -z "$dateline" ]] && [[ ! -z "$primary" ]]
  then
    comparedates $info $(echo "$dateline" | sed 's/.*: //') #get date from line
    #Reset info and primary for next info.
    info=''
    primary=''
  fi

  dateline=''
done < "$logfilename"

