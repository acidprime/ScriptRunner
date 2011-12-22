#!/bin/bash
# Check root
[ "$EUID" != 0 ] &&
        printf "%s\n" "This script requires root access!" && exit 1

# Commands used by this script
declare -x plutil='/usr/bin/plutil'
declare -x touch='/usr/bin/touch'
declare -x sleep='/bin/sleep'
declare -x find='/usr/bin/find'
declare -x whoami='/usr/bin/whoami'
declare -x xargs='/usr/bin/xargs'

# Standard Script Variables
declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"
declare -x ProjectName='ScriptRunner'

echo "RunDirectory=$RunDirectory"

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

# Change IFS to handle spaces in the name
OLD_IFS="$IFS"
IFS=$'\n'
echo "Script recieved arguments: $@"
echo "whoami: $($whoami)"
echo "Script effective UID: $EUID"

OLDIFS="$IFS"
declare -a FILES=(${LIST_DIRECTORY:="/"}*)
StatusMSG $FUNCNAME "Found ${#FILES[@]} paths at /" uistatus

# This logic does not work above 100 items, but that is unlikely in this example
# Example of how to use the second tick mark `printf %02i $((80 % 100))`
declare -i TICK_MARK="$((100 / ${#FILES[@]}))"
IFS=$'\n'
# Loop through the top level
for (( N = 0 ; N <="${#FILES[@]}"; N++ )) ; do
	if [ ${PROGRESS:-0} -eq 0 ] ; then
		# Start the progress bar a little early for the first folder 
		declare -i PROGRESS="$TICK_MARK"
		setInstallPercentage $PROGRESS.00
	else
		declare -i PROGRESS="$((${PROGRESS:-0} + $TICK_MARK))"
	fi
	declare FOLDER="${FILES[$N]}"
	
	# Skip over symlinks
	[ -L "$FOLDER" ] && continue
	
	# Run Through the excluded list
	StatusMSG $FUNCNAME "Processing: $FOLDER" uistatus
	if  [ "$FOLDER" != '/Volumes' ] &&
	[ "$FOLDER" != '/Network' ] &&
	[ "$FOLDER" != '/Recycled' ] &&
	[ "$FOLDER" != '/cores' ] &&
	[ "$FOLDER" != '/dev' ] &&
	[ "$FOLDER" != '/net' ]
	then
	$find "$FOLDER" \
	-not -path "/private/var/tmp*" \
	-not -path "/private/var/run*" \
	-type f \
	-depth 3 \
	-name "*.plist" \
	-print0 | $xargs -0 $plutil 
	setInstallPercentage $PROGRESS.00
	fi
done
IFS="$OLDIFS"
setInstallPercentage 99.00
die 0
