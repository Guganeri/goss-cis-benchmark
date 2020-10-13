#!/bin/bash
#
# 6.2.9 Ensure no users have .netrc files (Automated)
#
# Description:
# The .netrc file contains data for logging into a remote host for
# file transfers via FTP.
#
# Rationale:
# The .netrc file presents a significant security risk since it stores passwords
# in unencrypted form. Even if FTP is disabled, user accounts may have brought
# over .netrc files from other systems which could pose a risk to those systems.

set -o errexit
set -o nounset

declare dir=""
declare line=""
declare status="0"
declare stderr="0"
declare user=""
declare vars=""

while read line; do

    vars=$(
            echo ${line} | \
            egrep -v '^(root|halt|sync|shutdown)' | \
            awk -F: '($7 != "/usr/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }'
          ) || status=1

    if [ ${status} = "0" -a "${vars}x" != "x" ]; then
        set -- ${vars}
        user=${1-} && dir=${2-}
        if [ ! -d ${dir} ]; then
            echo "The home directory (${dir}) of user ${user} does not exist."
            stderr="1"
        else
            if [ ! -h "${dir}/.netrc" -a -f "${dir}/.netrc" ]; then
                echo ".netrc file ${dir}/.netrc exists"
                stderr="1"
           fi
        fi
    fi

done < /etc/passwd

if [ ${stderr} != "0" ]; then
    exit 1
fi
