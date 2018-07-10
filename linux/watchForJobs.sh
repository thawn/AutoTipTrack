#!/bin/bash
#WORKDIR is where we look for the 'go' file and where the folders containing the data are
WORKDIR="/projects/nanodata/"
#WORKDIR="/scratch/users/korten/" #for testing
#LOCKFILE prevents the script from being run multiple times. In order to prevent permanent lockup in case of a crash the lockfile is deleted by a cronjob every night
LOCKFILE="/tmp/autotiptrack.lock"
#LOG keeps track of the output when we run as a cron job
LOG="${HOME}/autotiptrack.log"

oldifs=$IFS
IFS='
'
#firstly we search for go files in the user directories
userdirs=$( ls -1 "$WORKDIR"*/go 2>/dev/null)
for userdir in $userdirs; do
  userdir=$( dirname "$userdir" )
  username=$( basename "$userdir" )
  lock="${LOCKFILE}_${username}"
	if test `find "$lock" -mmin -120 2>/dev/null`; then
    echo "Another instance of $0 for user $username is running wait till it finishes or delete $lock."
  else
    touch "$lock"
    echo "enqueuing jobs for $username"
    #check the size of the logfile and clear it if it gets too big
    if [ $(du -m "$LOG" | awk '{print $1}') -gt 2 ]; then #if the log file is bigger than 2 megs delete it.
      rm "$LOG"
    fi
    date
    #we store the directories that have already been processed in this file in my home directory
    done="${HOME}/autotiptrack_done_${username}.list"
    # $done.new stores the new directory list. we clear it before we use it
    if [ -z "${done}.new" ]; then rm "${done}.new"; fi
    #now we look for all subdirectories in the WORKDIR
    directories=$( ls -d1 "${userdir}"/*/ )
    echo "$directories"
    for dir in $directories; do
      if grep -q "$dir" $done; then
        #if the directory is in our $done list, we ignore it
        echo "Directory has already been queued before. Ignoring: $dir"
        echo "$dir" >> ${done}.new
      elif grep -q "_mcrCache" <<< "$dir"; then
	#if the directory is a matlab runtime cache directory, we ignore it
        echo "Directory is a matlab cache directory. Ignoring: $dir"
        echo "$dir" >> ${done}.new
      elif grep -q "ignore" <<< "$dir"; then
	#if the directory is called ignore, we ignore it
        echo "Directory is called ignore, Ignoring: $dir"
        echo "$dir" >> ${done}.new
      else
        #if the directory is NOT in our $done list, we submit its contents to the HPC queue
        echo "enqueuing $dir"
        echo "$dir" >> ${done}.new
        #startJob creates an environment for matlab and submits each subdirectory of $dir as a job to the HPC queue
        /sw/users/korten/startJob.sh "${dir}/"
      fi
    done
    #now we are done and can clean up
    mv "${done}.new" "$done"
    rm -f "$lock"
		rm -f "${userdir}/go"
	fi
done
IFS=$oldifs
