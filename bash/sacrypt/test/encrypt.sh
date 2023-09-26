#!/usr/bin/env bash

# file: test.sh

# initialize 

LIB_DIRECTORY="../.."
LIB_DIRECTORY=$(readlink -f -- "${LIB_DIRECTORY}")
[ ! -e "${LIB_DIRECTORY}" ] && echo "$0 (sa-crypt lib) ERROR: lib directory \"${LIB_DIRECTORY}\" does not exist" && exit 1

# load options module (use default namespace "Options.")
source "${LIB_DIRECTORY}/options.sh"

# handle command options
USAGE="[-i INFILE -o OUTFILE -k PUBKEYFILE -c CHKFILE -p PASSWORD -I INITFILE -d LOGGING_DEBUG_LEVEL -L LOGGING_LOGFILE  -D CORE_DEBUG]"
Options.ParseOptions "${USAGE}" ${@}
# log library errors to app log file

# load logging module (use global namespace)
LOGGING_LIB_DIRECTORY="${LIB_DIRECTORY}/logging"
[ ! -e "${LOGGING_LIB_DIRECTORY}" ] && echo "$0: ERROR: logging lib directory \"${LOGGING_LIB_DIRECTORY}\" does not exist" && exit 1
LOGGING_NAMESPACE="." source "${LOGGING_LIB_DIRECTORY}/logging.sh"; ec=$?
[ ! $ec -eq 0 ] &&  echo "$0: ERROR: failed to initialize logging lib" && exit $ec
DebugLoggingConfig 9

CORE_LOGFILE="${LOGGING_LOGFILE}"

# load sacrypt module (use global namespace)
SACRYPT_LIB_DIRECTORY="${LIB_DIRECTORY}/sacrypt"
[ ! -e "${SACRYPT_LIB_DIRECTORY}" ] && echo "$0: ERROR: sacrypt lib directory \"${SACRYPT_LIB_DIRECTORY}\" does not exist" && exit 1
source "${SACRYPT_LIB_DIRECTORY}/sacrypt.sh"; ec=$?
[ ! $ec -eq 0 ] &&  echo "$0: ERROR: failed to initialize sacrypt lib" && exit $ec

# main

[ "${INFILE}" == "" ] && INFILE="/dev/stdin"
[ ! "${INFILE}" == "/dev/stdin" ] && [ "${OUTFILE}" == "" ] && OUTFILE="$INFILE.${SACRYPT_ENC_EXT}"
[ ! "${INFILE}" == "/dev/stdin" ] && [ "${CHKFILE}" == "" ] && CHKFILE="$INFILE.${SACRYPT_CHK_EXT}"
[ ! "${INFILE}" == "/dev/stdin" ] && [ "${PKHFILE}" == "" ] && PKHFILE="$INFILE.${SACRYPT_KEY_EXT}"
#[ ! "${INFILE}" == "/dev/stdin" ] && [ "${AESHFILE}" == "" ] && AESHFILE="$INFILE.${SACRYPT_AES_EXT}"
[ ! "${INFILE}" == "/dev/stdin" ] && [ "${PKGFILE}" == "" ] && PKGFILE="$INFILE.${SACRYPT_PKG_EXT}"
[ "${CHKFILE}" == "" ] && CHKFILE="message.${SACRYPT_CHK_EXT}"
[ "${PKHFILE}" == "" ] && PKHFILE="message.${SACRYPT_KEY_EXT}"
[ "${PKGFILE}" == "" ] && PKGFILE="message.${SACRYPT_PKG_EXT}"

DebugMsg 3 "reading raw data from \"$INFILE\""
DebugMsg 3 "writing encrypted data to \"$OUTFILE\""
DebugMsg 3 "writing checksum to \"$CHKFILE\""
DebugMsg 3 "writing public key hash to \"$PKHFILE\""

# create temp files

RAWFILE=$(mktemp -p ${SACRYPT_TEMPD})
[ ! -e "$RAWFILE" ] && ErrorMsg "failed to create temp raw file" && exit 1
DebugMsg 3 "using \"$RAWFILE\" as temp raw file"

ENCFILE=$(mktemp -p ${SACRYPT_TEMPD})
[ ! -e "$ENCFILE" ] && ErrorMsg "failed to create temp enc file" && exit 1
DebugMsg 3 "using \"$ENCFILE\" as temp enc file"

# determine password
sacrypt_DeterminePassword "${PASSWORD}"; ec=$?; PASSWORD=$retval
[ ! $ec -eq 0 ] &&  ErrorMsg "$retval" && exit $ec
 
# determine encryption key specification
sacrypt_DetermineKey "${PUBKEYFILE}"; ec=$?; KEYSPEC=$retval
[ ! $ec -eq 0 ] &&  ErrorMsg "$retval" && exit $ec

# read input file 
[ ! -e "$INFILE" ] && ErrorMsg "input file \"$INFILE\" cannot be opened" && exit 1
cat "${INFILE}" > "${RAWFILE}"

# encrypt the file
sacrypt_EncryptFile "${RAWFILE}" "${ENCFILE}" "${KEYSPEC}" "${PASSWORD}"; ec=$?; KEYHASH=$retval
[ ! $ec -eq 0 ] && ErrorMsg "$retval" && exit $ec

DebugMsg 1 "encryption ok"

# create output
if [ "${OUTFILE}" == "" ]; then
    cat "${ENCFILE}" 
    DebugMsg 1 "output sent to STDOUT"
else
    cp "${ENCFILE}" "${OUTFILE}"
    DebugMsg 1 "output written to \"${OUTFILE}\""
fi

exit 0

# create checksum file
sacrypt_ComputeHashOfFile "${RAWFILE}" > "${CHKFILE}"
DebugMsg 1 "checksum written to \"${CHKFILE}\""

# create key file
echo -n "${KEYHASH}" > "${PKHFILE}"
DebugMsg 1 "key hash written to \"${PKHFILE}\""



# EOF
