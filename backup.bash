#!/bin/bash
#By DenickM, 04 Jan 2013, 19 jan 2014, 06 sept 2015, 17 march 2019.
#Script to backup local folders to another local path using duplicity. full|incremental can be specified using the commandline. A configurable number of full backups are preserved.
#A log file will be written. This file will be copied to the destination as well.
#If a remote host is needed, mount it using sshfs.

source $(dirname $0)/backup.conf
#Example contents of file backup.conf:
#############################################################
#verbosity=2
#numfullpreserve=2
#localrootdir='/home/user'
#remoterootdir='/home/user/backup/daily'
#usepassphrase='true'
#gpgpassfile=$localrootdir'/backup/.gpg-passphrase'
#gpgkey='KEY'
#logfiledir=$localrootdir'/backup/log'
#logfilename='backuplog.txt'
#logsummaryfilename='backuplogsummary.txt'

# $backuptargets is an Array of targets. Each containing the following three strings separated by a '+'
# Targetdir/name
# Sourcedir
# Options to pass to duplicity

#Example:
#backuptargets=(
#'backupmap'\
#'+'\
#$localrootdir'/backup/backupmap'\
#'+'\
#'options'
#''
#)
#############################################################

source ~/.backenvrc
#Example contents of file .backenvrc:
#############################################################
#export SSH_AGENT_PID=
#export SSH_AUTH_SOCK=
#export GPG_AGENT_INFO=
#export GPGKEY=KEY
#############################################################


set -o nounset


invalid(){
 echo "Invalid arguments."
 echo "Should be inc|full"
 echo "Exiting"
 exit 1
}

##### CHECKS
if [ ! -d $localrootdir ] #root dir exists
then
  echo "Dir does not exist! "$localrootdir
  exit 1
fi
if [ ! -r $logfiledir ] #logfiledirectory writable
then
	echo "Dir not writable! "$logfiledir
  exit 1
fi
if [ ! -r $remoterootdir ] #remoterootdir writable
then
  echo "Dir not writable! "$remoterootdir
  exit 1
fi

if [ ! -f /usr/bin/duplicity ]
then
  echo "Duplicity not found."
  exit 1
fi

if [ $# -ne 1 ]
then
 invalid
fi
##### 

##### FUNCTIONS

duplicitycommand(){
	srcdir=$1
	dstdir=$2
  options=''
	if [ $# -gt 2 ]
	then
		shift 2
		options=$* #options may contain spaces
	fi
	echo 'srcdir '$srcdir
	echo 'dstdir '$dstdir
	echo 'options '$options

	if [ ! -d $srcdir ]
	then
		echo "Dir does not exist! "$srcdir
		exit 1
	fi

	if [ $usepassphrase == "false" ]
	then
		options+=' --use-agent'
  fi
#--dry-run
  options+=' --allow-source-mismatch'\
' --verbosity '$verbosity\
' --asynchronous-upload'\
' --sign-key '$gpgkey\
' --encrypt-key '$gpgkey\
' --file-prefix '$dstdir'_ '

  commandd='/usr/bin/duplicity '$full' '$options' '$srcdir' file://'$remoterootdir'/'$dstdir'/'
	$commandd
}

writelines(){
  dirname=$1
  echo -e "\n-> $dirname"
  echo -e "\n-> $dirname" >> "$logfiledir"/"$logfilename"
}

removeold(){
  dirname=$1
  writelines $dirname
  echo "Removing old backup sets.."
  duplicity remove-all-but-n-full $numfullpreserve --force \
  --file-prefix $dirname'_' \
  file://$remoterootdir/$dirname/
}

generatesummary(){
  dirname=$1
  writelines $dirname
  echo "Generating summary.."
  duplicity collection-status \
  --file-prefix $dirname'_' \
  file://$remoterootdir/$dirname >> "$logfiledir"/"$logfilename"
}

handlelog(){
  echo
  echo "Copying backup log.."
  cp "$logfiledir"/"$logfilename" $remoterootdir
  echo "Generating summary of backup log.."
  "$logfiledir"/parselog.bash "$logfiledir"/"$logfilename" > "$logfiledir"/$logsummaryfilename
  echo "Copying summary of backup log.."
  cp "$logfiledir"/"$logsummaryfilename" $remoterootdir
}

dobackup(){
	if [ $# -lt 2 ]
	then
	  echo "Need at least 2 arguments to dobackup()"
		exit 1
	fi
	srcdir=$1
  dstdir=$2
  shift 2
	options=$* #options may contain spaces

  writelines $dstdir
  duplicitycommand $srcdir $dstdir $options
  removeold $dstdir
  generatesummary $dstdir
}

startbackup(){
	if [ $usepassphrase == "true" ]
	then
    export PASSPHRASE=$(tr 'a-zA-Z' 'n-za-mN-ZA-N' < $gpgpassfile)
	fi

	echo '' > "$logfiledir"/"$logfilename"

  for (( i=0; i<${#backuptargets[@]}; i++ ));
  do
    IFS='+'
		read -r dstdir srcdir options <<< "${backuptargets[$i]}"
    IFS=' '
    dobackup $srcdir $dstdir $options
  done

  #---
  if [ $usepassphrase == "true" ]
  then
    unset PASSPHRASE
  fi

  handlelog
}


if [ "$1" = "full" ]
  then
  echo "Full backup"
  full=full
elif [ "$1" = "inc" ]
then
  echo "Incremental backup"
  full=""
else
  invalid
fi

startbackup
