#!/bin/bash
#Sync and/or move some dirs to another location using rsync
#By Apie, jan 2013
#Feb 2015, added option to sync exthdd to exthdd2

source $(dirname $0)/sync_exthdd.conf

set_vars() {
  if [ $dryrun -eq 1 ]
  then
   echo "Dry Run! No changes will be written to disk."
   dry_run="--dry-run"
  else
   dry_run=""
  fi
}
get_remote_dir() { ##All dirs you want to sync need to be in a subfolder of $syncroot. Can reside anywhere on the system and multiples are also possible
  echo $1 |sed "s%^.*$syncroot%$mountdir/$syncroot%"
}

do_syncdir() { # from, to
   echo $1
   rsync -zrv --partial --progress --delete $1/ $2/ $dry_run --size-only #use this last flag if external disk is vfat
}

do_movedir() { # from, to
   echo $1
   rsync -zrv --partial --progress --remove-source-files $1/ $2/ $dry_run --size-only #use this last flag if external disk is vfat
   #remove empty dirs
   find $1/ -mindepth 1 -type d -empty -delete
}

check_dir_exists() { # dir 
  if [ ! -d $1 ]
  then
    echo "Dir $1 does not exist!"
    echo "Exiting.."
    exit 1
  fi
}

check_files() { # files
  checkdirs=$*
  for dir in $checkdirs
  do
   #dest is FAT32 so we need to check for big files
   bigfiles=$( find "$dir" -size +4G)
   numbigfiles=$(echo "$bigfiles"|wc -c)
   if [ $numbigfiles -gt 1 ]
   then
    echo "Big file(s) encountered:"
    echo $bigfiles
    echo
    echo "Exiting.."
    exit 1
   fi
   #we also need to check for files ending in special chars
   strangefiles=$(find "$dir" -regex "^.*[ ]\.[a-z]+$" -type f)
   numstrangefiles=$(echo "$strangefiles"|wc -c)
   if [ $numstrangefiles -gt 1 ]
   then
    echo "Wrong filename(s) encountered:"
    echo $strangefiles
    echo
    echo "Exiting.."
    exit 1
   fi
   #and dirs
   strangedirs=$(find "$dir" -name "*[ .,?']" -type d)
   numstrangedirs=$(echo "$strangedirs"|wc -c)
   if [ $numstrangedirs -gt 1 ]
   then
    echo "Wrong dirname(s) encountered:"
    echo $strangedirs
    echo
    echo "Exiting.."
    exit 1
   fi   
  done
}

check_free_space() { #dir1, dir2
  if [ $( du -s $1 | cut -f1 ) -gt $( df --output=avail $2 |grep [0-9] ) ]
  then
    echo $1 '->' $2
    echo 'Insufficient space on target device!'
    echo 'Exiting'
    exit 1
  fi
}

handle_dirs() { # type, dirs
  type=$1
  shift
  for localdir in $*
  do
    remotedir=$( get_remote_dir $localdir )
    check_dir_exists $remotedir
    check_free_space $localdir $remotedir
    if [ $type == "sync" ]
    then
     do_syncdir $localdir $remotedir
    elif [ $type == "move" ]
    then
     do_movedir $localdir $remotedir
    else
     echo "Unknown command in 'handle_dirs'"
     echo "Exiting.."
     exit 1
    fi
  done
}

sync_hdd1to2 () {
   echo 'Syncing exthdd -> exthdd2'
   rsync -zrv --partial --progress --delete $mountdir/$syncroot/ $mountdir'2'/$syncroot $dry_run --size-only #use this last flag if external disk is vfat
}

main() {
  set_vars
  #ext4 so no checks necessary anymore
  #check_files $movedirs $syncdirs
  
  check_dir_exists $mountdir/$syncroot
  
  handle_dirs sync $syncdirs
  handle_dirs move $movedirs
  
  if [[ -d $mountdir/$syncroot ]] && [[ -d $mountdir'2'/$syncroot ]]
  then
    sync_hdd1to2
  fi
}

main
