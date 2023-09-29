# file: sacrypt.sh

# requirements: 

# check for repeated initialization
[ ! -z "${SACRYPT_ISLOADED}" ] && core_FatalExit "sacrypt module already loaded (namespace ${SACRYPT_NAMESPACE})" 1

# module configuration

# immutable options
SACRYPT_NAMESPACE="${SACRYPT_NAMESPACE:=_Sacrypt_}"
SACRYPT_LIB_DIRECTORY=$(readlink -f -- "${LIB_DIRECTORY}/sacrypt")

# encrypted temp dir
SACRYPT_TEMPD=""

# requirements
SACRYPT_REQUIREMENTS="openssl gzip gunzip"

# paths to executables
SACRYPT_ENCRYPT_EXE="sshcrypt-agent-encrypt"
SACRYPT_DECRYPT_EXE="sshcrypt-agent-decrypt"

# file extensions
SACRYPT_DEC_EXT="dec" # decrypted data
SACRYPT_ENC_EXT="sae" # encrypted data
SACRYPT_KEY_EXT="sak" # key hash
SACRYPT_CHK_EXT="sac" # raw data checksum 

# default aes keys
SACRYPT_AES_KEY="${SACRYPT_AES_KEY:=jTx8I33DeeSuwIbwizOvXzwep7hZu8Fq4qR1eSnLgiUXPHPwnmxMPiouFi8ey0sXsap}"
SACRYPT_HEADER_KEY="${SACRYPT_HEADER_KEY:=JktNcY8VuYDseLDaOKfd7hhMKuCuKsfbX20NLcxPAkbofCmTEu69cVAy2JUtkYba}"

# mutable options

# initialize library

# checks

# check for lib directory
[ -z "${LIB_DIRECTORY}" ] && echo -e "FATAL ERROR sacrypt module ($(basename $0)): LIB_DIRECTORY is not defined" >&2 && exit 1

# check for core module
[ ! -f "${LIB_DIRECTORY}/core.sh" ] && echo -e "FATAL ERROR sacrypt module ($(basename $0)): core.sh not found in \"${LIB_DIRECTORY}\"" >&2 && exit 1
# load core module (if not already loaded)
[ -z "${CORE_ISLOADED}" ] && source "${LIB_DIRECTORY}/core.sh"

# check module directory
[ ! -e "${SACRYPT_LIB_DIRECTORY}" ] && core_FatalExit "sacrypt lib directory \"${SACRYPT_LIB_DIRECTORY}\" does not exist" 1

# load additional library files

# load other required modules

# global variables

# global constants

# private functions

__sacrypt_Requirements () {
    core_CheckBinaries ${SACRYPT_REQUIREMENTS}; ec=$?; local missing=${retval}
    [ ! $ec -eq 0 ] && core_ErrorMsg "the following binaries are missing: ${missing}" && exit 1
    core_DebugMsg "requirements \"${SACRYPT_REQUIREMENTS}\" ok"
}

__sacrypt_CheckBinaries () {
    local Arch=$(uname -m)
    local CDir="${SACRYPT_LIB_DIRECTORY}/exec/${Arch}"
    SACRYPT_ENCRYPT_EXE="${CDir}/${SACRYPT_ENCRYPT_EXE}"
    SACRYPT_DECRYPT_EXE="${CDir}/${SACRYPT_DECRYPT_EXE}"
    [ ! -e "${SACRYPT_ENCRYPT_EXE}" ] && core_ErrorMsg "exec file \"${SACRYPT_ENCRYPT_EXE}\" not found" && exit 1
    [ ! -e "${SACRYPT_DECRYPT_EXE}" ] && core_ErrorMsg "exec file \"${SACRYPT_DECRYPT_EXE}\" not found" && exit 1
    core_DebugMsg "exec files \"${SACRYPT_ENCRYPT_EXE}\", \"${SACRYPT_DECRYPT_EXE}\" ok"
}

__sacrypt_CreateTempDir () {
    core_CreateEncryptedTempDir; local ec=$?; SACRYPT_TEMPD=$retval
    [ ! $ec -eq 0 ] &&  core_ErrorMsg "${errval}" && exit 1
    core_DebugMsg "created temporary directory \"${SACRYPT_TEMPD}\""
}

# filename.${SACRYPT_ENC_EXT}::KEYSPEC::PASS describes an sa-encrypted
# file filename.${SACRYPT_ENC_EXT} with the key specified by ${KEYSPEC} 
# and aes-password ${PASS}; KEYSPEC and PASS can be empty

# returns 1 if 
# - $filespec does not match the required pattern
# - if the file filename.${SACRYPT_ENC_EXT} does not exist
#
# returns 0 otherwise; in that case
# - retval=filename.${SACRYPT_ENC_EXT}
# - retval1=KEYSPEC
# - retval2=PASS

__sacrypt_ParseSAEFileSpec () {

    local filespec=$1

    local FileName
    local KeySpec
    local Password

    retval=""; retval1=""; retval2=""

    if [[ "${filespec}" =~ ^([^:]*${SACRYPT_ENC_EXT})(::)?([^:]*)(::)?([^:]*).*$ ]]; then
        FileName="${BASH_REMATCH[1]}"
        KeySpec="${BASH_REMATCH[3]}"
        Password="${BASH_REMATCH[5]}"

        [ ! -e "${FileName}" ] && WarnMsg "file specification refers to non-existent ${SACRYPT_ENC_EXT}-file \"${FileName}\"" && return 1
	    
	DebugMsg 3 "${SACRYPT_ENC_EXT}-file \"${FileName}\" specified with key spec \"${KeySpec}\" and password \"${Password}\""

	retval=${FileName}
	retval1=${KeySpec}
	retval2=${Password}
	return 0
    fi

    return 1
}

# public functions

sacrypt_SourceSAEFile () {
    local filespec=$1

    # no script file specified 
    [ "${filespec}" == "" ] && return 0

    __sacrypt_ParseSAEFileSpec "${filespec}"; ec=$?

    if [ $ec -eq 0 ]; then
        local FileName=$retval
	local KeySpec=$retval1
        local Password=$retval2

	DebugMsg 3 "reading script from ${SACRYPT_ENC_EXT}-file \"${FileName}\" with keyspec \"${KeySpec}\" and password \"${Password}\""

        local ScriptFile=$(mktemp -p ${SACRYPT_TEMPD})
        [ ! -e "${ScriptFile}" ] && retval="failed to create temp script file" && return 1
        DebugMsg 3 "using \"${ScriptFile}\" as temp script file"

        sacrypt_DecryptFile "${FileName}" "${ScriptFile}" "${KeySpec}" "${Password}"; ec=$?
        [ ! $ec -eq 0 ] && ErrorMsg "$retval" && exit $ec
	DebugMsg 3 "script file decryption ok"
    
	[ ! -e "${ScriptFile}" ] && retval="script file \"${ScriptFile}\"does not exist" && return 1
        source "${ScriptFile}"
    else 
        WarnMsg "script file specification \"${filespec}\" malformed" && return 1
    fi

    return 0
}

sacrypt_DeterminePassword () {
    local pwspec=$1

    # no pw specified 
    [ "${pwspec}" == "" ] && retval="" && return 0

    DebugMsg 1 "parsing pw spec"

    __sacrypt_ParseSAEFileSpec "${pwspec}"; ec=$?

    if [ $ec -eq 0 ]; then
        local FileName=$retval
	local KeySpec=$retval1
        local Password=$retval2

	DebugMsg 3 "reading password from ${SACRYPT_ENC_EXT}-file \"${FileName}\" with keyspec \"${KeySpec}\" and password \"${Password}\""

        local PWFile=$(mktemp -p ${SACRYPT_TEMPD})
        [ ! -e "${PWFile}" ] && retval="failed to create temp password file" && return 1
        DebugMsg 3 "using \"${PWFile}\" as temp password file"

	# decrypt the keyfile 
        sacrypt_DecryptFile "${FileName}" "${PWFile}" "${KeySpec}" "${Password}"; ec=$?
        [ ! $ec -eq 0 ] && ErrorMsg "$retval" && exit $ec
        DebugMsg 3 "password decryption ok"
    
	[ ! -e "${PWFile}" ] && retval="key file \"${PWFile}\"does not exist" && return 1
	retval="$(cat ${PWFile})"
	return 0
    fi

    # pw specified is a string
    if [ ! -e "${pwspec}" ]; then
        DebugMsg 1 "pw spec is not a file, using spec as pw"
	retval="${pwspec}"
	return 0
    fi

    # pw spec designates a file
    DebugMsg 3 "reading pw from \"${pwspec}\" (clear text)"
    retval=$(cat ${pwspec})

    return 0
}

sacrypt_DetermineKey () {
    local keyspec=$1

    # no key specified 
    [ "${keyspec}" == "" ] && retval="" && return 0

    # key specified is a hash
    if [ ! -e "${keyspec}" ]; then
        DebugMsg 1 "key spec \"${keyspec}\" is not a file"
	retval=${keyspec}
	return 0
    fi

    # key specified is a file
    DebugMsg 3 "reading key from \"${keyspec}\""

    # file contains hash of key
    if [[ "${keyspec}" == *.${SACRYPT_KEY_EXT} ]]; then
	DebugMsg 3 "using hash file format"
	retval=$(cat ${keyspec})
	return 0
    fi

    # file contains key
    DebugMsg 3 "using ssh file format"

    # read first line of file
    local KeyType 
    local RestOfLine 
    read KeyType RestOfLine < ${keyspec} 
    local Key=${RestOfLine%% *}
    local KeyHash=$(sacrypt_StringHash ${Key})
    if [[ ${KeyType} = ssh-rsa ]]; then
        DebugMsg 3 "using ssh-rsa public key ${KeyHash}"
        retval=${KeyHash}
	return 0
    else 
        retval="key (${KeyHash}) is not an RSA key" 
	return 1
    fi
}

sacrypt_AESEncryptFile () {
    local infile=$1
    local password=$2
    local filter=$3

    # use compression by default
    # (specify "tee" as filter to disable)
    filter="${filter:=gzip}"

    retval=""

    [ ! -e "${infile}" ] && retval="input file \"${infile}\" does not exist" && return 1

    local Outfile=$(mktemp -p ${SACRYPT_TEMPD})
    [ ! -e "${Outfile}" ] && retval="failed to create temp aes enc file" && return 1
    DebugMsg 3 "using \"${Outfile}\" as temp aes enc file (${filter} filter)"

    cat "${infile}" | ${filter} | \
	    openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 600000 -salt \
	                -pass pass:${password} > "${Outfile}" 2> /dev/null; local ec=$?
    [ ! $ec -eq 0 ] && retval="AES encryption failed ($ec)" && return $ec
    [ ! -e "${Outfile}" ] && retval="AES encryption file \"${Outfile}\" could not be created" && return 1

    retval="${Outfile}"
    return 0
}

sacrypt_AESDecryptFile () {
    local infile=$1
    local password=$2
    local filter=$3

    # use compression by default 
    # (specify "tee" as filter to disable)
    filter="${filter:=gunzip}"

    retval=""

    [ ! -e "${infile}" ] && retval="input file does not exist" && return 1

    local Outfile=$(mktemp -p ${SACRYPT_TEMPD})
    [ ! -e "${Outfile}" ] && retval="failed to create temp aes dec file" && return 1
    DebugMsg 3 "using \"${Outfile}\" as temp aes dec file (${filter} filter)"

    cat "${infile}" | \
	    openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 600000 -salt \
	                -pass pass:${password} 2> /dev/null | ${filter} > "${Outfile}" 2> /dev/null; local ec=$?
    [ ! $ec -eq 0 ] && retval="AES decryption failed, check password ($ec)" && return $ec
    [ ! -e "${Outfile}" ] && retval="AES decryption file \"${Outfile}\" could not be created" && return 1

    retval="${Outfile}"
    return 0
}

# compute hashes

sacrypt_StringHash () {
    echo -n "$1" | openssl dgst -sha256 | cut -f 2 -d ' '
}

sacrypt_FileHash () {
    openssl dgst -sha256 < "$1" | cut -f 2 -d ' '
}

# checksums

sacrypt_VerifyFileChecksum () {
    local infile=$1
    local chksumfile=$2

    retval="checksum verification passed"

    [ ! -e "${infile}" ] && retval="input file \"${infile}\"does not exist" && return 1
    [ ! -e "${chksumfile}" ] && retval="checksum file \"${chksumfile}\"does not exist" && return 1

    local TempChkSumFile=$(mktemp -p ${SACRYPT_TEMPD})
    [ ! -e "${TempChkSumFile}" ] && retval="failed to create temp chksum file" && return 1
    DebugMsg 3 "using \"${TempChkSumFile}\" as temp chksum file"

    sacrypt_FileHash "${infile}" > "${TempChkSumFile}"
    cmp -s "${chksumfile}" "${TempChkSumFile}"; local ec=$?  
    [ ! $ec -eq 0 ] && retval="checksum verification failed ($ec)" && return $ec

    return 0
}

# decrypt a file 

sacrypt_DecryptFile () {

    local infile=$1
    local outfile=$2
    local keyspec=$3
    local password=$4

    password="${password:=${SACRYPT_AES_KEY}}"

    retval=""

    local DecryptedFile=$(mktemp -p ${SACRYPT_TEMPD})
    [ ! -e "${DecryptedFile}" ] && retval="failed to create temp ssh dec file" && return 1
    DebugMsg 3 "using \"${DecryptedFile}\" as temp ssh dec file"

    # decrypt with header key
    sacrypt_AESDecryptFile ${infile} ${SACRYPT_HEADER_KEY}; local ec=$?  
    [ ! $ec -eq 0 ] && return $ec
    #infile="${retval}" 

    # decrypt with agent
    #cat "${infile}" | ${SACRYPT_DECRYPT_EXE} > "${DecryptedFile}"; ec=$?  
    cat "${retval}" | ${SACRYPT_DECRYPT_EXE} > "${DecryptedFile}"; ec=$?  
    case $ec in
        0) DebugMsg 1 "ssh decryption successful";;
        1) retval="ssh decryption failed (key not in agent? input not an sae file?)"; return 1;;
        *) retval="ssh decryption gives unknown exit code ($ec)"; return $ec;;
    esac

    [ ! -e "${DecryptedFile}" ] && retval="ssh decrypted file \"${DecryptedFile}\" not found" && return 1

    # decrypt with password
    sacrypt_AESDecryptFile ${DecryptedFile} ${password}; local ec=$?  
    [ ! $ec -eq 0 ] && return $ec

    # copy to output
    cp "${retval}" "${outfile}"
    [ ! -e "${outfile}" ] && retval="failed to create output file \"${outfile}\"" && return 1
    chmod go-rwx "${outfile}"
    DebugMsg 3 "output written to file \"${outfile}\""

    return 0
}

# encrypt a file 

sacrypt_EncryptFile () {

    local infile=$1
    local outfile=$2
    local keyspec=$3
    local password=$4

    password="${password:=${SACRYPT_AES_KEY}}"

    [ ! -e "${infile}" ] && retval="input file \"${infile}\" not found" && return 1

    local EncryptedFile=$(mktemp -p ${SACRYPT_TEMPD})
    [ ! -e "${EncryptedFile}" ] && retval="failed to create temp enc file" && return 1
    DebugMsg 3 "using \"${EncryptedFile}\" as temp enc file"

    sacrypt_FindKeyInAgent ${keyspec}; local ec=$?  
    [ ! $ec -eq 0 ] && return $ec
    local KeyIndex=$retval
    local KeyHash=$retval1
    DebugMsg 1 "key ${KeyHash} found in agent (#${KeyIndex})"

    retval=""

    # encrypt with password
    sacrypt_AESEncryptFile ${infile} ${password}; local ec=$?
    [ ! $ec -eq 0 ] && return $ec
    infile="${retval}" 

    # encrypt with all keys in agent
    cat "${infile}" | ${SACRYPT_ENCRYPT_EXE} > "${EncryptedFile}"; ec=$?  
    [ ! $ec -eq 0 ] && retval="encryption failed ($ec)" && return $ec

    # split encrypted file line by line
    local Counter=0
    while IFS='' read -r LinefromFile || [[ -n "${LinefromFile}" ]]; do
        ((Counter++))
        echo "${LinefromFile}" > "${EncryptedFile}.${Counter}"
    done < "${EncryptedFile}"
    # select the correct file
    EncryptedFile="${EncryptedFile}.${KeyIndex}"
    [ ! -e "${EncryptedFile}" ] && retval="file \"${EncryptedFile}\" not found" && return 1

#    # extract the correct file
#    local ANSWER="${EncryptedFile}.${KeyIndex}"
#    [ ! -e "${ANSWER}" ] && retval="file \"${ANSWER}\" not found" && return 1

    # verify encryption
    DebugMsg 3 "verifying encryption"

    local DecryptedFile=$(mktemp -p ${SACRYPT_TEMPD})
    [ ! -e "${DecryptedFile}" ] && retval="failed to create temp ver file" && return 1
    DebugMsg 3 "using \"${DecryptedFile}\" as temp ver file"

#    cat "${ANSWER}" | ${SACRYPT_DECRYPT_EXE} > "${DecryptedFile}"
    cat "${EncryptedFile}" | ${SACRYPT_DECRYPT_EXE} > "${DecryptedFile}"
    cmp -s "${infile}" "${DecryptedFile}" ; ec=$?  
    case $ec in
        0) DebugMsg 1 "verification ok";;
	*) retval="verification failed ($ec)" && return $ec;;
    esac

    # encrypt with header key
    #sacrypt_AESEncryptFile ${ANSWER} ${SACRYPT_HEADER_KEY}; local ec=$?  
    sacrypt_AESEncryptFile ${EncryptedFile} ${SACRYPT_HEADER_KEY}; local ec=$?  
    [ ! $ec -eq 0 ] && return $ec
    EncryptedFile="${retval}"
    [ ! -e "${EncryptedFile}" ] && retval="file \"${EncryptedFile}\" not found" && return 1

    # create output
    cp "${EncryptedFile}" "${outfile}"
    [ ! -e "${outfile}" ] && retval="failed to create output file \"${outfile}\"" && return 1

    chmod go-rwx "${outfile}"

    DebugMsg 3 "encrypted data written to \"${outfile}\""

    retval=${KeyHash}
    return 0
}

# find key in agent

sacrypt_FindKeyInAgent () {

    retval="0"
    retval1=""

    local KeyHashSpec=$1

    local KeyFile=$(mktemp -p ${SACRYPT_TEMPD})
    [ ! -e "${KeyFile}" ] && retval="failed to create temp key file" && return 1
    DebugMsg 3 "using \"${KeyFile}\" as temp key file"

    ssh-add -L > ${KeyFile} 2> /dev/null; local ec=$? 

#    local NrOfKeys=$(cat ${KeyFile} | wc -l)
    case $ec in
	0) DebugMsg 3 "agent provides $(cat ${KeyFile} | wc -l) key(s)";;
        1) retval="ssh-agent has no identities"; return 1;;
        2) retval="ssh-agent is not running"; return 2;;
        *) retval="ssh-agent gives unknown exit code ($ec)"; return $ec;;
    esac

    local Counter=0
    while IFS='' read -r LinefromFile || [[ -n "${LinefromFile}" ]]; do

        ((Counter++))

        local KeyType=${LinefromFile%% *}
        local RestOfLine=${LinefromFile#* }
        local Key=${RestOfLine%% *}
        local KeyHash=$(sacrypt_StringHash ${Key})

        DebugMsg 3 "Found ${KeyType} key (${KeyHash})"
        if [[ ${KeyType} = ssh-rsa ]]; then
            if [[ ${KeyHash} = ${KeyHashSpec}* ]]; then
		DebugMsg 3 "key ${KeyHash} (${KeyHashSpec}*) found in agent (#${Counter})"
	        retval=$Counter	
	        retval1=${KeyHash}	
		# key found
    		return 0
		break
	    else
	        DebugMsg 3 "key #${Counter} (${KeyHash}) is rejected (not the destination key)" 
	    fi
        else 
	    DebugMsg 2 "key #${Counter} (${KeyHash}) is ignored (no RSA key)"
        fi
    done < "${KeyFile}"

    # key not found
    retval="key ${KeyHashSpec} not found in agent"; return 1
}

# init code

__sacrypt_Requirements
__sacrypt_CheckBinaries
__sacrypt_CreateTempDir

# EOF
