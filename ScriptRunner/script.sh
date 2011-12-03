#!/bin/bash
# Check root
[ "$EUID" != 0 ] &&
        printf "%s\n" "This script requires root access!" && exit 1

# Commands used by this script
declare -x ls='/bin/ls'
declare -x touch='/usr/bin/touch'
declare -x sleep='/bin/sleep'
declare -x whoami='/usr/bin/whoami'

# Standard Script Variables
declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"


#Check Log Directory for current Script
export SCRIPT_LOG="$LOG_DIRECTORY/$ScriptName.log"

# Our Common file
export COMMON_FILE="$RunDirectory/common.sh"
if [ -f "${COMMON_FILE:?}" ]; then
  source "$COMMON_FILE"
else
  printf "%s\n" "$COMMON_FILE missing"
  exit 1  
fi

$touch "$SCRIPT_LOG"
# If the log file is not writable then use the users directory instead
if [ ! -w "$LOG_FILE" ] ;then
	# If our main location is not writable then redirect to our home
	[ -d  "$HOME/$LOG_DIRECTORY" ] ||
		$mkdir -p "$HOME/$LOG_DIRECTORY"
	
	export LOG_DIRECTORY="$HOME/$LOG_DIRECTORY"
	export SCRIPT_LOG="$LOG_DIRECTORY/$ScriptName.log"
else
	exec 2>>"${SCRIPT_LOG:?}" # Redirect standard error to log file
fi

showUsage(){
  printf "%s\n\t" "USAGE:"
  printf "%s\n\t" 
  printf "%s\n\t" " OUTPUT:"
  printf "%s\n\t" " -d </path/to/list/directory>"
  printf "%s\n\t"
  printf "%s\n\t" " EXAMPLE SYNTAX:"
  printf "%s\n\t" " sudo $0 -d /"
  printf "%s\n"
  exit 1 
}


if [ $# = 0 ] ; then
  showUsage
  FatalError "No arguments Given, but required for $ScriptName"
fi

# Check script options
while getopts d:h SWITCH ; do
  case $SWITCH in
    d ) export LIST_DIRECTORY="${OPTARG}" ;;
    h ) showUsage ;;
  esac
done # END while



# MAIN

begin

# Start the Progress Bar Off
setInstallPercentage 10.00

# Change IFS to handle spaces in the name
OLD_IFS="$IFS"
IFS=$'\n'
echo "Script recieved arguments: $@"
echo "whoami: $($whoami)"
echo "Script effective UID: $EUID"
for DIRECTORY in $($ls -l "$LIST_DIRECTORY") ; do
  echo "$DIRECTORY"
  # artificial sleep here to show you the now buffered IO
  $sleep 1
done
setInstallPercentage 99.00
die 0
