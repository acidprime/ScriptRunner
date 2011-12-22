#!/bin/bash

# Commands Required by these functions
export awk='/usr/bin/awk'
export date='/bin/date'
export defaults='/usr/bin/defaults'
export mkdir='/bin/mkdir'
export rm='/bin/rm'
export tee='/usr/bin/tee'
		
export LOG_DIRECTORY='/Library/Logs/ScriptRunner/'

		
# Check our log directory is present
[ -d "${LOG_DIRECTORY:?}" ] ||
		$mkdir -p "$LOG_DIRECTORY"

settings(){
  declare KEY="$1"
  declare PLIST="$RunDirectory/settings.plist"
  declare VALUE="$($defaults read "${PLIST%%.plist}" "$KEY")"
  printf "%s\n" "$VALUE"
}

deleteBridgeFiles(){
	[ -f "$InstallProgressTxt" ] &&
		$rm "$InstallProgressTxt" &>/dev/null
	[ -f "$InstallPhaseTxt" ] &&
		$rm "$InstallPhaseTxt" &>/dev/null
	[ -f "$InstallProgressFile" ] && 
		$rm "$InstallProgressFile" &>/dev/null
}

begin(){
	# Note the difference in the case of the names
	StatusMSG $FUNCNAME "BEGINNING: $ScriptName - $ProjectName" header
	export InstallProgressTxt="$(settings 'installProgressTxt')"
	StatusMSG $FUNCNAME "InstallProgressTxt=$InstallProgressTxt"
	
	export InstallPhaseTxt="$(settings 'installPhaseTxt')"
	StatusMSG $FUNCNAME "InstallPhaseTxt=$InstallPhaseTxt"
	
	export InstallProgressFile="$(settings 'installProgressFile')"
	StatusMSG $FUNCNAME "InstallProgressFile=$InstallProgressFile"

	deleteBridgeFiles
}

# Generates log status message
StatusMSG(){ # Status message function with type and now color!
  declare FunctionName="$1" StatusMessage="$2" MessageType="$3" CustomDelay="$4"
  # Set the Date Per Function Call
  declare DATE="$($date)"
  if [ "$EnableColor" = "YES"  ] ; then
	# Background Color
	declare REDBG="41"		WHITEBG="47"	BLACKBG="40"
	declare YELLOWBG="43"	BLUEBG="44"		GREENBG="42"
	# Foreground Color
	declare BLACKFG="30"	WHITEFG="37" YELLOWFG="33"
	declare BLUEFG="36"		REDFG="31"
	declare BOLD="1"		NOTBOLD="0"
	declare format='\033[%s;%s;%sm%s\033[0m\n'
	# "Bold" "Background" "Forground" "Status message"
	printf '\033[0m' # Clean up any previous color in the prompt
else
	declare format='%s\n'
fi
case "${MessageType:-"progress"}" in
	uiphase ) \
		printf $format $NOTBOLD $WHITEBG $BLACKFG "$ScriptName:($FunctionName) Displaying UI Message - $StatusMessage"  | $tee -a "${SCRIPT_LOG%%.log}.log" ;		
		printf "%s\n" "$StatusMessage" > "$InstallPhaseTxt" ;
		sleep ${CustomDelay:=1} ;;
	uistatus ) \
		printf $format $NOTBOLD $WHITEBG $BLACKFG "$ScriptName:($FunctionName) Displaying UI Message - $StatusMessage"  | $tee -a "${SCRIPT_LOG%%.log}.log" ;		
		printf "%s\n" "$StatusMessage" > "$InstallProgressTxt" ;
		sleep ${CustomDelay:=1} ;;
	progress) \
		printf $format $NOTBOLD $WHITEBG $BLACKFG "$ScriptName:($FunctionName) - $StatusMessage"  | $tee -a "${SCRIPT_LOG%%.log}.log" ;		
		printf "%s\n" "$DATE $ScriptName:($FunctionName) - $StatusMessage" >> "${SCRIPT_LOG:?}" ;;
		# Used for general progress messages, always viewable

	notice) \
		printf $format $NOTBOLD $YELLOWBG $BLACKFG "$ScriptName:($FunctionName) - $StatusMessage" | $tee -a "${SCRIPT_LOG%%.log}.log" ;
		printf "%s\n" "$DATE $ScriptName:($FunctionName) - $StatusMessage" >> "${SCRIPT_LOG:?}" ;;
		# Notifications of non-fatal errors , always viewable

	error) \
		printf "%s\n\a" "$DATE $ScriptName:($FunctionName) - $StatusMessage" >> "${SCRIPT_LOG:?}" | $tee -a "${SCRIPT_LOG%%.log}.log";
		printf "%s\n\a" "$DATE $ScriptName:($FunctionName) - $StatusMessage" >> "${SCRIPT_LOG%%.log}.error.log" ;
		printf $format $NOTBOLD $REDBG $YELLOWFG "$ScriptName:($FunctionName) - $StatusMessage"  ;;
		# Errors , always viewable

	verbose) \
		printf "%s\n" "$DATE $ScriptName:($FunctionName) - $StatusMessage" >> "${SCRIPT_LOG:?}" ;
		printf $format $NOTBOLD $WHITEBG $BLACKFG "$ScriptName:($FunctionName) - $StatusMessage"  | $tee -a "${SCRIPT_LOG%%.log}.log" ;;
		# All verbose output

	header) \
		printf $format $NOTBOLD $BLUEBG $BLUEFG "$ScriptName:($FunctionName) - $StatusMessage"  | $tee -a "${SCRIPT_LOG%%.log}.log" ;
		printf "%s\n" "$DATE $ScriptName:($FunctionName) - $StatusMessage" >> "${SCRIPT_LOG:?}" ;;
		# Function and section headers for the script

	passed) \
		printf $format $NOTBOLD $GREENBG $BLACKFG "$ScriptName:($FunctionName) - $StatusMessage" | $tee -a "${SCRIPT_LOG%%.log}.log";
		printf "%s\n" "$DATE $ScriptName:($FunctionName) - $StatusMessage" >> "${SCRIPT_LOG:?}" ;;
		# Sanity checks and "good" information
	*) \
		printf $format $NOTBOLD $WHITEBG $BLACKFG "$ScriptName:($FunctionName) - $StatusMessage" | $tee -a "${SCRIPT_LOG%%.log}.log";
		printf "%s\n" "$DATE $ScriptName:($FunctionName) - $StatusMessage" >> "${SCRIPT_LOG:?}" ;;
		# Used for general progress messages, always viewable
esac
return 0
} # END StatusMSG()

setInstallPercentage(){
	declare InstallPercentage="$1"
	echo "$InstallPercentage" >> "$InstallProgressFile"
	export CurrentPercentage="$InstallPercentage"
}


die(){
	StatusMSG $FUNCNAME "END: $ScriptName - $ProjectName" header
	setInstallPercentage 99.00
	StatusMSG $FUNCNAME "Script Complete" uistatus 0.5
	deleteBridgeFiles
	unset CurrentPercentage
	exec 2>&- # Reset the error redirects
	exit $1
}

FatalError() {
	StatusMSG $FUNCNAME "BEGIN: Beginning $ScriptName:$FUNCNAME"
	declare ErrorMessage="$1"
	StatusMSG $FUNCNAME "$ErrorMessage" error
	exit 1
}