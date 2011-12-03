#!/bin/bash
###############################################################################################
# 		NAME: 			genReport.sh
#
# 		DESCRIPTION: This script is used to generate a diagnostic report for Mac AD util 
#               
###############################################################################################
#		HISTORY:
#						- created by Zack Smith (zsmith@318.com) 12/1/2011
###############################################################################################
# Uncomment to Set Debug
#set -x
# Enable Job Control in script
set -m
# Check root
[ "$EUID" != 0 ] &&
        printf "%s\n" "This script requires root access!" && exit 1

declare -x Script="${0##*/}" ; ScriptName="${Script%%\.*}"
declare -x ScriptPath="$0" RunDirectory="${0%/*}"

source "$RunDirectory/.macauth.conf"
source "$RunDirectory/common.sh"

# The files we wish to copy to our save directory
declare -xa COPY_FILE[0]='/var/log/system.log'
declare -xa COPY_FILE[1]='/var/log/centrifydc.log'
declare -xa COPY_FILE[2]='/var/centrifydc/centrify_client.log'
# The directories we wish to copy to our save directory
declare -xa COPY_DIRECTORY[0]='/Library/Logs/DiagnosticReports'
declare -xa COPY_DIRECTORY[1]='/Library/Logs/Genentech'


showUsage(){
  printf "%s\n\t" "USAGE:"
  printf "%s\n\t" 
  printf "%s\n\t" " OUTPUT:"
  printf "%s\n\t" " -d </path/to/save/directory>"
  printf "%s\n\t" " -w </path/to/save/file.dmg"
  printf "%s\n\t"
  printf "%s\n\t" " EXAMPLE SYNTAX:"
  printf "%s\n\t" " sudo $0 -d /tmp/Report_2011_12_1 -w /Users/Shared/Report_2011_12_1.dmg -i en1"
  printf "%s\n"
  exit 1 
}


if [ $# = 0 ] ; then
  showUsage
  FatalError "No arguments Given, but required for $ScriptName"
fi

# Check script options
while getopts i:w:d:h SWITCH ; do
  case $SWITCH in
    i ) export INF="${OPTARG}";;
    d ) export SaveDirectory="${OPTARG}" ;;
    w ) export WriteFile="${OPTARG}";;
    h ) showUsage ;;
  esac
done # END while

echo "Copying Log Files..."
	
# Commands used by this script
declare -x awk='/usr/bin/awk'
declare -x cp='/bin/cp'
declare -x date='/bin/date'
declare -x dscl='/usr/bin/dscl'
declare -x du='/usr/bin/du'
declare -x dirname='/usr/bin/dirname'
declare -x grep='/usr/bin/grep'
declare -x killall="/usr/bin/killall"
declare -x hdiutil='/usr/bin/hdiutil'
declare -x id='/usr/bin/id'
declare -x mkdir='/bin/mkdir'
declare -x mv="/bin/mv"
declare -x ps='/bin/ps'
declare -x scutil="/usr/sbin/scutil"
declare -x system_profiler='/usr/sbin/system_profiler'
declare -x tcpdump="/usr/sbin/tcpdump"
declare -x who='/usr/bin/who'

# Main Functions
checkFileExists(){
  declare CheckExists="$1"
  if [ -e "${CheckExists:?}" ] ; then
    echo "CheckExists : ($CheckExists) exists"
    return 0
  else
    echo "CheckExists : ($CheckExists) does not exist"
    return 1 
  fi 
}

copyFSObject(){
  declare FROM="$1"
  declare TO="$2"
  # Recreate the structure of the file we have been asked to copy
  declare BASE_PATH="${TO:?}/$($dirname "${FROM:?}")"
  echo "Copying $FROM to $BASE_PATH"
  # Check if the base path exists
  if [ ! -d "$BASE_PATH" ] ; then
    echo "Creating path at ($BASE_PATH)"
    $mkdir -p "$BASE_PATH" &&
      echo "Created Directory $BASE_PATH"
  fi 
  $cp -Rvf "$FROM" "$BASE_PATH" &&
    echo "Copied file $FROM to $BASE_PATH" 
}

createDMG(){
  declare -x DATE="$($date +%Y-%m-%d_%H%M%S)"
  $mv "$WriteFile" "${WriteFile%%.dmg}_$DATE.dmg" &>/dev/null 
  $hdiutil create -srcFolder "$SaveDirectory" "$WriteFile"
  $mv "$SaveDirectory" "${SaveDirectory}_${DATE}"
}

tcpDump(){
  $tcpdump -i "${INF:?}" -vvv -s 1500 -w "$SaveDirectory/$INF.389.636.53.464.pcap" port 389 or port 636 or port 53 or port 464 & 
  echo "Capturing Network Traffic..."
  until [ $x -gt 60 ] ; do
    let x++
    printf "%s" .
    sleep 1
  done
  printf "\n"
  $killall 'tcpdump'
}


# MAIN
if [ -d "${SaveDirectory:?}" ] ; then
	echo "SaveDirectory already exists : ($SaveDirectory)"
	$mkdir -p "$SaveDirectory" &&
		echo "Created SaveDirectory:  ($SaveDirectory)"
fi

echo "Copying Log Files..."
# Copy files
for FILE in "${COPY_FILE[@]}" ; do
  echo "Processing file (${FILE})"
  if checkFileExists "$FILE" ; then 
    copyFSObject "$FILE" "$SaveDirectory"
  fi 
done

echo "Copying Log Directories..."
# Copy directory
for DIRECTORY in "${COPY_DIRECTORY[@]}" ; do
  echo "Processing directory (${DIRECTORY})"
  if checkFileExists "$DIRECTORY" ; then
    copyFSObject "$DIRECTORY" "$SaveDirectory"
  fi 
done
declare -x COMPUTER_NAME="$($scutil --get ComputerName)"
echo "Generating System Profile Report..."
$system_profiler -xml > "$SaveDirectory/$COMPUTER_NAME.spx" &


echo "Running Commands..."
declare -x CONSOLE_USER="$($who | $awk '/console/{print $1}')"
declare -x COMMANDS_DIR="$SaveDirectory/Commands"
[ -d "$COMMANDS_DIR" ] || $mkdir -p "$COMMANDS_DIR"
# dscl
$dscl /Search -read "/Users/$CONSOLE_USER" &>"$COMMANDS_DIR/dscl.read.$CONSOLE_USER.txt" &
# id
$id &>"$COMMANDS_DIR/id.$CONSOLE_USER.txt" &
# ps
$ps -axwwrvf &>"$COMMANDS_DIR/ps.axwwrf.txt" &
# We do this as we don't know how hund the system is

until [ "$(jobs)" = '' ] ; do
  let n++
  echo "Waiting for jobs to complete"
  jobs
  sleep 1
  if [ $n -gt 30 ] ; then
    echo "Timed out waiting for all jobs"
    break
  fi
done
tcpDump
createDMG
exit 0
