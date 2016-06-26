#!/bin/bash

#===== sshup ==================================================================#
#                                                                              #
# FILE:         sshupV1.sh                                                     #
#                                                                              #
# USAGE:        sshupV1.sh [-o | --host <host>] [-d | --debug] [-h | --help]   #
#               [-q | --quiet] [-v | --verbose] [-w | --wait] [-c | --connect] #
#               [-u | --wakeup] [-t | --timeout <timeout>]"                    #
#                                                                              #
#               (see sshup.usage for details)                                  #
#                                                                              #
# DESCRIPTION:  Check host availability, and optionally connect via ssh to     #
#               specified host.  All options can be set from the command line  #
#               (see sshup.usage for details.), from ~/.sshup.conf. or from    #
#               /etc/sshup.conf.                                               #
#                                                                              #
#               Command line options overide ~/.sshup.conf, which in turn      #
#               overides /etc/sshup.conf.                                      #
#                                                                              #
# OPTIONS:      See the ’sshup.usage’ file for details.                        #
#                                                                              #
# REQUIREMENTS: openssh-client, ping, gawk                                     #
#                                                                              #
# BUGS:         Report all bugs and/or sugestions to bugs@1stcallhelp.co.uk    #
#                                                                              #
# AUTHOR:       <Carl McAlwane>carl@1stcallhelp.co.uk                          #
#                                                                              #
# COMPANY:      1stcallhelp.co.uk                                              #
#                                                                              #
# VERSION:      1.0                                                            #
#                                                                              #
# CREATED:      11.05.2016                                                     #
#                                                                              #
# REVISION:     1.0.0.2016                                                     #
#                                                                              #
# COPYRIGHT:    (C)2000-2016 1st Call Group.  All rights reserved.             #
#                                                                              #
# TODO:         1. Comment code.                                               #
#               2. Standardised variable names and comments.                   #
#               3. Move standard functions and constants to sshup.shinc.       #
#               4. Format email in html.  Maybe use ansi2html.sh ??            #
#               5. Perhaps add an option to format email as plain text.        #
#               6. Incorparate wakeup scripts.                                 #
#               7. Standardise how ouput is sent to fnOutput.  (probably using #
#                   printf 2>&1 | fnOutput but maybe echo -e 2>&1 | fnOutput)  #
#                                                                              #
#               8. Standardise comments.                                       #
#               9. Impliment a ${optLogFile} for logging.                      # 
#                                                                              #
#==============================================================================#

#
#=== FUNCTION =================================================================#
# NAME: fnGetScripsDir                                                         #
# DESCRIPTION: Function to get the current script directory                    #
# PARAMETERS: none                                                             #
#==============================================================================#
declare -fx fnGetScripsDir

declare BASHREMATCH=""
declare -a new_varables=()
declare -a values_now=()
declare -a initial_variables=()

initial_variables="$( compgen -v )"

#
# Set default options
#
declare optHost="**UNSET!!**"
declare optHelp=false
declare optQuiet=false
declare optVerbose=false
declare optWait=false
declare optConnect=false
declare optWakeup=false
declare -i optTimeout=30
declare -i optDebug=0
declare optLogFile=/home/carl/sshup.log

#=== FUNCTION =================================================================#
# NAME: fnGetScripsDir                                                         #
# DESCRIPTION: Function to get the current script directory                    #
# PARAMETERS: none                                                             #
#==============================================================================#

if ! declare -F fnGetScripsDir ; then
    fnGetScripsDir () 
    {
        local ZBINDIR="${BASH_SOURCE%/*}"
        if [[ ! -d "${ZBINDIR}" ]]; then 
            ZBINDIR="${PWD}"
        fi
    
        echo "${ZBINDIR}"
    }
fi

if [ -z ${BINDIR+x} ] ; then
    declare -r BINDIR=$(fnGetScripsDir)           # Get current script directory $BINDIR.
fi
if ! declare -F fnIsHostReachable ; then
    . "${BINDIR}/sshup.shinc"                      # Source sshup.shinc
fi
if ! declare -F read_ini ; then
    . "${BINDIR}/read_ini.sh"                      # Source read_ini.sh
fi
if ! declare -F getopts_long ; then
    set +u
    . "${BINDIR}/getopts_long.sh"                  # Source getopts_long.sh
    set -u
fi

fnSetShellOptions                              # Set default bash options.

declare -rx GSETFILE=$(fnGetGlobalSettingFile) # Get Global Settings Filename.
declare -rx USETFILE=$(fnGetUserSettingFile)   # Get User Settings Filename.

#----------------------------------------------------------------------------------
# If global settings file found, process it
#
if [ "${GSETFILE}" != "**NOTREADABLE**" ] ; then
    read_ini "${GSETFILE}" sshup --booleans 0 --prefix opt --nosect
fi
#----------------------------------------------------------------------------------


#----------------------------------------------------------------------------------
# If user settings file found, process it
#
if [ "${USETFILE}" != "**NOTREADABLE**" ] ; then
    read_ini "${USETFILE}" sshup --booleans 0 --prefix opt --nosect
fi
#----------------------------------------------------------------------------------


#----------------------------------------------------------------------------------
# Process any commandline options.
#
fnGetOpsSshupV2 "$@"
#----------------------------------------------------------------------------------

if [[ ${optDebug} -ge ${DBG_LVL_ALL} ]] ; then echo "debug -  $(basename "$(test -L "$0" && readlink "$0" || echo "$0")") - lineno = $LINENO" >&2 ; fi
echo "DBG_LVL_ALL" | fnDebug ${DBG_LVL_ALL} ${LINENO} true
exit ${E_DEBUG_BREAKPOINT}

#----------------------------------------------------------------------------------
# Display usage information if host is not set.
#
if [[ ${optHelp} == false ]] ; then
    if [[ "${optHost}" = "**UNSET!!**" ]]  ; then
        printf "\n${BRIGHT}option -o or --host is required if host is not set in %s or %s${NORMAL}\n\n\n" "${GSETFILE}" "${USETFILE}" 1>&2  | fnOutput false true ${optQuiet} ${optVerbose} /home/carl/sshup.log
        optHelp=true
    fi
fi
#----------------------------------------------------------------------------------

if [[ ${optDebug} -ge ${DBG_LVL_ALL} ]] ; then echo "debug -  $(basename "$(test -L "$0" && readlink "$0" || echo "$0")") - lineno = $LINENO" >&2 ; fi

#----------------------------------------------------------------------------------
# Display usage information if option is set.
#
if [ $optHelp = true ] ; then
    fnsshupV2Help "$@" # | fnOutput false true ${optQuiet} ${optVerbose} /home/carl/sshup.log
    exit 0
fi
#----------------------------------------------------------------------------------

if [[ ${optDebug} -ge ${DBG_LVL_ALL} ]] ; then echo "debug -  $(basename "$(test -L "$0" && readlink "$0" || echo "$0")") - lineno = $LINENO" >&2 ; fi

#----------------------------------------------------------------------------------
# And finally the main Code.
#
if [[ ${optDebug} -ge ${DBG_LVL_ALL} ]] ; then echo "debug -  $(basename "$(test -L "$0" && readlink "$0" || echo "$0")") - lineno = $LINENO" >&2 ; fi
declare isHostReachable=$(fnIsHostReachable "${optHost}")
if [[ ${optDebug} -ge ${DBG_LVL_ALL} ]] ; then echo "debug -  $(basename "$(test -L "$0" && readlink "$0" || echo "$0")") - lineno = $LINENO" >&2 ; fi

if [[ ${isHostReachable} == true ]] ; then
    declare isHostConnectable=$(fnIsHostConnectable "${optHost}")
    if [ ${isHostConnectable} == true ] ; then
        ssh ${optHost}
        printf "%s isHostReachable = %s - isHostConnectable = %s\n" "${optHost}" "${isHostReachable}" "${isHostConnectable}" | fnOutput false true ${optQuiet} ${optVerbose} /home/carl/sshup.log
    else
        printf "%s isHostReachable = %s - isHostConnectable = %s\n" "${optHost}" "${isHostReachable}" "${isHostConnectable}" | fnOutput false true ${optQuiet} ${optVerbose} /home/carl/sshup.log
    fi
else
    printf "%s isHostReachable = %s\n" "${optHost}" "${isHostReachable}" | fnOutput false true ${optQuiet} ${optVerbose} "/home/carl/sshup.log"
fi

if [[ ${optDebug} -ge ${DBG_LVL_ALL} ]] ; then echo "debug -  $(basename "$(test -L "$0" && readlink "$0" || echo "$0")") - lineno = $LINENO" >&2 ; fi
#----------------------------------------------------------------------------------
# Display debug information if option is set.
#
if [ ${optDebug} -ge ${DBG_LVL_LOW} ] ; then
    if [[ ${optDebug} -ge ${DBG_LVL_LOW} ]] ; then echo "debug -  $(basename "$(test -L "$0" && readlink "$0" || echo "$0")") - lineno = $LINENO" >&2 ; fi
    fnDisplayDebugInfo
fi
#----------------------------------------------------------------------------------