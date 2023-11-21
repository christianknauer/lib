#!/bin/env bash

export PATH=${PATH}:.

ENCRYPT=saencrypt
DECRYPT=sadecrypt

# -----------------------------------------------------------------

set -x 
debug="-d 1"
logfile="-L test.log"
export LOGGING_TIMESTAMP=echo
#export CORE_DEBUG=1
export CORE_LOGFILE=/dev/null
#debug=""

# -----------------------------------------------------------------
CreateTestData () {
    local PREFIX=$1
    local LEN=$2
    cat /dev/urandom | tr -dc '[:alnum:]' | head -c $LEN > "${PREFIX}${LEN}.txt"
}

# -----------------------------------------------------------------
RunTests () {
    local LEN=$1
    local KEYFILE=$2

    local filename="data${LEN}.txt"

    # no password
    ${ENCRYPT} ${debug} ${logfile} -i ${filename} -k ${KEYFILE} 
    ${DECRYPT} ${debug} ${logfile} -i ${filename}.sae 
    diff ${filename} ${filename}.sae.dec

    # password
    ${ENCRYPT} ${debug} ${logfile} -i ${filename} -k ${KEYFILE} -p ${passwrd}
    ${DECRYPT} ${debug} ${logfile} -i ${filename}.sae -p ${passwrd}
    diff ${filename} ${filename}.sae.dec
 
    # raw password file
    ${ENCRYPT} ${debug} ${logfile} -i ${filename} -k ${KEYFILE} -p ${passfile}
    ${DECRYPT} ${debug} ${logfile} -i ${filename}.sae -p ${passfile}
    diff ${filename} ${filename}.sae.dec

    # sae password file
    ${ENCRYPT} ${debug} ${logfile} -i ${filename} -k ${KEYFILE} -p ${encpassfile}
    ${DECRYPT} ${debug} ${logfile} -i ${filename}.sae -p ${encpassfile}
    diff ${filename} ${filename}.sae.dec

    # sae password file
    ${ENCRYPT} ${debug} ${logfile} -i ${filename} -k ${KEYFILE} -p ${encpassfile}:
    ${DECRYPT} ${debug} ${logfile} -i ${filename}.sae -p ${encpassfile}::${keyssh}
    diff ${filename} ${filename}.sae.dec

    # sae password file
    ${ENCRYPT} ${debug} ${logfile} -i ${filename} -k ${KEYFILE} -p $(cat $passfile)
    ${DECRYPT} ${debug} ${logfile} -i ${filename}.sae -p ${encpassfilewithpw}::::${passwrd}
    diff ${filename} ${filename}.sae.dec

}

# -----------------------------------------------------------------

CreateTestData pw   64

CreateTestData data 64
CreateTestData data 128
CreateTestData data 256 
CreateTestData data 1024
CreateTestData data 8192

keyssh="key.ssh"
keyhash="key.sak"
#keyfile=$keyssh
passwrd="12345"

passfile="pw64.txt"
encpassfile="${passfile}.sae"
encpassfilewithpw="${passfile}-with-pw.sae"

${ENCRYPT} ${debug} ${logfile} -i ${passfile} -k ${keyssh}
${DECRYPT} ${debug} ${logfile} -i ${encpassfile}
diff ${passfile} ${encpassfile}.dec

${ENCRYPT} ${debug} ${logfile} -i ${passfile} -o ${encpassfilewithpw} -k ${keyssh} -p ${passwrd}
${DECRYPT} ${debug} ${logfile} -i ${encpassfilewithpw} -o ${encpassfilewithpw}.dec  -p ${passwrd}
diff ${passfile} ${encpassfilewithpw}.dec

# -----------------------------------------------------------------


# -----------------------------------------------------------------

RunTests 64 $keyssh
RunTests 64 $keyhash

RunTests 128 $keyssh
RunTests 128 $keyhash

RunTests 256 $keyssh
RunTests 256 $keyhash

RunTests 1024 $keyssh
RunTests 1024 $keyhash

RunTests 8192 $keyssh
RunTests 8192 $keyhash

rm -f data*.* ${passfile}*

exit 0

# EOF
