# !/bin/bash
# Spike Re-Signer by Miguel Kennedy
# Re-signs Spike's ipa file with free or paid Apple accounts
# Maintains the same bundle id.

export LC_ALL=C
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m'
SCRIPT_DIR=$(pwd)
MOBILE_PROVISION_FILES_DIR="mobileprovisionfiles"
MOBILEDEVICE_PROVISIONING_PROFILES_FOLDER="${HOME}/Library/MobileDevice/Provisioning Profiles"
TEMP_DIR="Temp"
IS_FREE="true"
SHOULD_DOWNLOAD="false"
SELECTED_IPA_FILE=""
SHOULD_CLEAR_XCODE_CACHE="false"

# Banner
echo "                                                                                                         "
echo "███████╗██████╗ ██╗██╗  ██╗███████╗    ██████╗ ███████╗    ███████╗██╗ ██████╗ ███╗   ██╗███████╗██████╗ "
echo "██╔════╝██╔══██╗██║██║ ██╔╝██╔════╝    ██╔══██╗██╔════╝    ██╔════╝██║██╔════╝ ████╗  ██║██╔════╝██╔══██╗"
echo "███████╗██████╔╝██║█████╔╝ █████╗      ██████╔╝█████╗█████╗███████╗██║██║  ███╗██╔██╗ ██║█████╗  ██████╔╝"
echo "╚════██║██╔═══╝ ██║██╔═██╗ ██╔══╝      ██╔══██╗██╔══╝╚════╝╚════██║██║██║   ██║██║╚██╗██║██╔══╝  ██╔══██╗"
echo "███████║██║     ██║██║  ██╗███████╗    ██║  ██║███████╗    ███████║██║╚██████╔╝██║ ╚████║███████╗██║  ██║"
echo "╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚══════╝    ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝"
echo "                                                                                                         "

#Helper Functions
cleanup () {
    if [ $1 = true ]; then
        echo -e "Cleaning up...${NC}"
    fi

    if [ -d "$MOBILE_PROVISION_FILES_DIR" ]; then
        rm -rf  $MOBILE_PROVISION_FILES_DIR
    fi

    if [ "$SHOULD_DOWNLOAD" = "true" ]; then
        rm "$SELECTED_IPA_FILE" 2> /dev/null
    fi

    if [ $1 = true ]; then
        echo -e "Done!\n\nNote: To install the resigned Spike IPA file connect your device via USB to your computer, open Xcode, press the upper \"Window\" menu, select \"Devices and Simulators\", select your device from the left list and pres the + button under your installed apps list to browse and install this newly created Spike ipa. \n\n${GREEN}Have a great day!${NC}\n"
    fi
}

#Prompt for Xcode cache clearance
echo -e "\nDo you want me to clear all previous Spike certificates from your Xcode cache? This is needed if you want to renew the expiration date of your currently installed Spike. If you're signing Spike for the first time or just updating to a new Spike version using a paid Apple Developer Account you can choose \"NO\"."
options=("YES" "NO" "CANCEL")
select opt in "${options[@]}"
do
    case $opt in
        "YES")
            SHOULD_CLEAR_XCODE_CACHE="true";
            break
            ;;
        "NO")
            SHOULD_CLEAR_XCODE_CACHE="false";
            break
            ;;
        "CANCEL")
            echo -e "\n${RED}User cancelled!${NC}";
            exit 0
            break
            ;;
        *) 
    esac
done

if [ "$SHOULD_CLEAR_XCODE_CACHE" = "true" ]; then
    rm -rfv "$MOBILEDEVICE_PROVISIONING_PROFILES_FOLDER"/* > /dev/null 2>&1

    echo ""
    read -n 1 -s -r -p "I've just cleared the old Spike certificates from your Xcode cache! Please open the Spike Xcode template project and keep it open for at least 10-15 seconds to allow enough time for Xcode to download new certificates. You don't need to do anything, xCode downloads the new certificates automatically. Afterwards, close Xcode, come back here and press any key to continue."
    echo ""
fi

# Prompt for ipa download or selection
echo -e '\nDo you want me to download the lastest available Spike version?'
options=("YES" "NO, I've already added my own Spike IPA file to the folder" "CANCEL")
select opt in "${options[@]}"
do
    case $opt in
        "YES")
            SHOULD_DOWNLOAD="true";
            break
            ;;
        "NO, I've already added my own Spike IPA file to the folder")
            SHOULD_DOWNLOAD="false";
            break
            ;;
        "CANCEL")
            echo -e "\n${RED}User cancelled!${NC}";
            exit 0
            break
            ;;
        *) 
    esac
done

if [ $SHOULD_DOWNLOAD = "true" ]; then
    echo -e '\nPlease select which version you wish to download:'
    options=("iPhone/iPodTouch" "iPad" "CANCEL")
    select opt in "${options[@]}"
    do
        case $opt in
            "iPhone/iPodTouch")
                echo -e "\nDownloading latest Spike iPhone/iPodTouch version...";
                curl -o "Spike-iPhone-iPodTouch.ipa" --progress-bar "https://spike-app.com/releases/latest/Spike-iPhone-iPodTouch.ipa";
                SELECTED_IPA_FILE="Spike-iPhone-iPodTouch.ipa"
                break
                ;;
            "iPad")
                echo -e "\nDownloading latest Spike iPad version...";
                curl -o "Spike-iPad.ipa" --progress-bar "https://spike-app.com/releases/latest/Spike-iPad.ipa";
                SELECTED_IPA_FILE="Spike-iPad.ipa"
                break
                ;;
             "CANCEL")
                echo -e "\n${RED}User cancelled!${NC}";
                exit 0
                break
                ;;
            *) 
        esac
    done
else
    #Find IPA files and save them in a comma sepparated list
    IPA_FILES_LIST=""

    EXT=ipa
    for i in *; do
        if [ "${i}" != "${i%.${EXT}}" ];then
            #Found IPA file, add it to the list
            IPA_FILES_LIST="$IPA_FILES_LIST$i,"
        fi
    done

    if [ -z "$IPA_FILES_LIST" ]; then
        cleanup false
        echo -e "${RED}Error: You need to place the original Spike's IPA file in the same folder as this script. Aborting!${NC}"
        exit 0
    fi

    #Remove last comma from the list
    IPA_FILES_LIST=`echo "$IPA_FILES_LIST" | sed 's/,$//'`
    IPA_FILES_LIST="$IPA_FILES_LIST,CANCEL"

    #Present dialog with list of IPA files and let user pick one.
    echo -e "\nPlease select an IPA file:"

    oldIFS=$IFS
    IFS=$','
    choices=( $IPA_FILES_LIST )
    IFS=$oldIFS
    select answer in "${choices[@]}"; do
        for item in "${choices[@]}"; do
            if [[ $item == $answer ]]; then
                break 2
            fi
        done
    done

    SELECTED_IPA_FILE="$answer"

    if [ "$SELECTED_IPA_FILE" = "" ]; then
        cleanup false
        echo -e "\n${RED}User cancelled!${NC}"
        exit 0
    fi

    if [ "$SELECTED_IPA_FILE" = "CANCEL" ]; then
        cleanup false
        echo -e "\n${RED}User cancelled!${NC}"
        exit 0
    fi

    if [ -z "$SELECTED_IPA_FILE" ]; then
        cleanup false
        echo -e "\n${RED}No IPA file selected. Aborting!${NC}"
        exit 0
    fi

    echo -e "\n${GREEN}Selected IPA file -> $SELECTED_IPA_FILE${NC}"
fi

if [ "$SELECTED_IPA_FILE" = "" ]; then
    echo -e "\n${RED}No IPA file has been selected. Aborting!${NC}"
    cleanup false
    exit 0
fi

#Check file structure and create required dirs
echo -e "\nPreparing file structure..."
mkdir -p $MOBILE_PROVISION_FILES_DIR
rm -rfv "$MOBILE_PROVISION_FILES_DIR"/* > /dev/null 2>&1
rm -rf "$TEMP_DIR" > /dev/null 2>&1

# Get all the user's code signing identities. Filter the response to get a neat list of quoted strings:
SIGNING_IDENTITIES_LIST=`security find-identity -v -p codesigning | egrep -oE '"[^"]+"'`

if [ -z "$SIGNING_IDENTITIES_LIST" ]; then
    cleanup false
    echo -e "${RED}Error: Can't find any code signing identities in your keychain. Please make sure you performed all Xcode steps correctly. Aborting!${NC}"
    exit 0
fi

# Replace the newline characters in the list with commas and remove the last comma:
SIGNING_IDENTITIES_COMMA_SEPARATED_LIST=`echo "$SIGNING_IDENTITIES_LIST" | tr '\n' ',' | sed 's/,$//'`
SIGNING_IDENTITIES_COMMA_SEPARATED_LIST=${SIGNING_IDENTITIES_COMMA_SEPARATED_LIST//\"/}
SIGNING_IDENTITIES_COMMA_SEPARATED_LIST="$SIGNING_IDENTITIES_COMMA_SEPARATED_LIST,CANCEL"

# Present dialog with list of code signing identites and let the user pick one. The identity that from the build settings is selected by default.
echo -e "\nPlease select a code signing identity:"

oldIFS=$IFS
IFS=$','
choices=( $SIGNING_IDENTITIES_COMMA_SEPARATED_LIST )
IFS=$oldIFS
select answer in "${choices[@]}"; do
    for item in "${choices[@]}"; do
        if [[ $item == $answer ]]; then
            break 2
        fi
    done
done
    
CODE_SIGN_IDENTITY="$answer"

if [ "$CODE_SIGN_IDENTITY" = "" ]; then
    cleanup false
    echo -e "\n${RED}User cancelled!${NC}"
    exit 0
fi

if [ "$CODE_SIGN_IDENTITY" = "CANCEL" ]; then
    cleanup false
    echo -e "\n${RED}User cancelled!${NC}"
    exit 0
fi

if [ -z "$CODE_SIGN_IDENTITY" ]; then
    cleanup false
    echo -e "\n${RED}No code signing identity selected. Aborting!${NC}"
    exit 0
fi

echo -e "\n${GREEN}Selected code signing identity -> $CODE_SIGN_IDENTITY${NC}"

 # Now onto the provisioning profiles...
TEMP_MOBILEPROVISION_PLIST_PATH=/tmp/mobileprovision.plist
TEMP_CERTIFICATE_PATH=/tmp/certificate.cer
FOUND_SPIKE_MOBILEPROVISION=false
FOUND_CHART_WIDGET_MOBILEPROVISION=false
FOUND_FS_WIDGET_MOBILEPROVISION=false
FOUND_WATCH_APP_MOBILEPROVISION=false
FOUND_WATCH_EXTENSION_MOBILEPROVISION=false

#Parse all Xcode provisioning profiles
cd "$MOBILEDEVICE_PROVISIONING_PROFILES_FOLDER"

for MOBILEPROVISION_FILENAME in *.mobileprovision
do
	# Use sed to rid the signature data that is padding the plist and store clean plist to temp file:
    sed -n '/<!DOCTYPE plist/,/<\/plist>/ p' \
        < "$MOBILEPROVISION_FILENAME" \
        > "$TEMP_MOBILEPROVISION_PLIST_PATH"
    # The plist root dict contains an array called 'DeveloperCertificates'. It seems to contain one element with the certificate data. Dump to temp file:
    /usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' $TEMP_MOBILEPROVISION_PLIST_PATH > $TEMP_CERTIFICATE_PATH
    # Get the common name (CN) from the certificate (regex capture between 'CN=' and '/OU'):
    MOBILEPROVISION_IDENTITY_NAME=`openssl x509 -inform DER -in $TEMP_CERTIFICATE_PATH -subject -noout | perl -n -e '/CN=(.+)\/OU/ && print "$1"'`
		
	if [ "$CODE_SIGN_IDENTITY" = "$MOBILEPROVISION_IDENTITY_NAME" ]; then
        # Yay, this mobile provisioning profile matches up with the selected signing identity, let's continue...
        # Get the name of the provisioning profile:
        MOBILEPROVISION_PROFILE_NAME=`/usr/libexec/PlistBuddy -c 'Print Name' $TEMP_MOBILEPROVISION_PLIST_PATH`			
        
        #Find corresponding app/extension
       	if echo "$MOBILEPROVISION_PROFILE_NAME" | grep -q "watchkitextension"; then
            FOUND_WATCH_EXTENSION_MOBILEPROVISION=true 
            cp $MOBILEPROVISION_FILENAME "${SCRIPT_DIR}/${MOBILE_PROVISION_FILES_DIR}/watchkitextension.mobileprovision"
		elif echo "$MOBILEPROVISION_PROFILE_NAME" | grep -q "watchkitapp"; then
            FOUND_WATCH_APP_MOBILEPROVISION=true
            cp $MOBILEPROVISION_FILENAME "${SCRIPT_DIR}/${MOBILE_PROVISION_FILES_DIR}/watchkitapp.mobileprovision"
        elif echo "$MOBILEPROVISION_PROFILE_NAME" | grep -q "fswidget"; then
            FOUND_FS_WIDGET_MOBILEPROVISION=true
            cp $MOBILEPROVISION_FILENAME "${SCRIPT_DIR}/${MOBILE_PROVISION_FILES_DIR}/fswidget.mobileprovision"
        elif echo "$MOBILEPROVISION_PROFILE_NAME" | grep -q "widget"; then
            FOUND_CHART_WIDGET_MOBILEPROVISION=true
            cp $MOBILEPROVISION_FILENAME "${SCRIPT_DIR}/${MOBILE_PROVISION_FILES_DIR}/widget.mobileprovision"
        elif echo "$MOBILEPROVISION_PROFILE_NAME" | grep -q "spike"; then
            FOUND_SPIKE_MOBILEPROVISION=true
            cp $MOBILEPROVISION_FILENAME "${SCRIPT_DIR}/${MOBILE_PROVISION_FILES_DIR}/spike.mobileprovision"

            #Detect if user is using a free or paid dev account
            CERTFICATE_TIME_TO_LIVE=`/usr/libexec/PlistBuddy -c 'Print TimeToLive' $TEMP_MOBILEPROVISION_PLIST_PATH`
            if [ -n "$CERTFICATE_TIME_TO_LIVE" ]; then
                if (( $CERTFICATE_TIME_TO_LIVE > 7 )); then
                    IS_FREE="false"
                fi
            fi
		fi
    fi
done

#Verify that all mobile provisioning files have been found
if [ $FOUND_WATCH_EXTENSION_MOBILEPROVISION = false ]; then
    echo -e "${RED}Can't find watch extension's mobileprovision file. Please make sure you performed all Xcode steps correctly. Aborting!${NC}"
    cleanup false
    exit 0
fi

if [ $FOUND_WATCH_APP_MOBILEPROVISION = false ]; then
    echo -e "${RED}Can't find watch's mobileprovision file. Please make sure you performed all Xcode steps correctly. Aborting!${NC}"
    cleanup false
    exit 0
fi

if [ $FOUND_FS_WIDGET_MOBILEPROVISION = false ]; then
    echo -e "${RED}Can't find fullscreen widget's mobileprovision file. Please make sure you performed all Xcode steps correctly. Aborting!${NC}"
    cleanup false
    exit 0
fi

if [ $FOUND_CHART_WIDGET_MOBILEPROVISION = false ]; then
    echo -e "${RED}Can't find chart widget's mobileprovision file. Please make sure you performed all Xcode steps correctly. Aborting!${NC}"
    cleanup false
    exit 0
fi

if [ $FOUND_SPIKE_MOBILEPROVISION = false ]; then
    echo -e "${RED}Can't find Spike's mobileprovision file. Please make sure you performed all Xcode steps correctly. Aborting!${NC}"
    cleanup false
    exit 0
fi

#Output account type
if [ $IS_FREE = "true" ]; then
    echo -e "${GREEN}Detected account type -> Free Apple Account${NC}";
else
    echo -e "${GREEN}Detected account type -> Paid Developer Account${NC}";
fi

#Return to originl dir
cd "$SCRIPT_DIR"

###########################
# Resign script starts here
###########################

# Logging functions

log() {
    # Make sure it returns 0 code even when verose mode is off (test 1)
    # To use like [[ condition ]] && log "x" && something
    if [[ -n "$VERBOSE" ]]; then echo -e "$@"; else test 1; fi
}

error() {
    echo -e "${RED}$@${NC}" >&2
    rm -rf "$TEMP_DIR" > /dev/null 2>&1
    exit 1
}

warning() {
    echo -e "${PURPLE}$@${NC}" >&2
}

function checkStatus {
    # shellcheck disable=SC2181
    if [ $? -ne 0 ]; then
        rm -rf "$TEMP_DIR" > /dev/null 2>&1
        error "Encountered an error, aborting!"
    fi
}

ORIGINAL_FILE="$SELECTED_IPA_FILE"
NEW_FILE=""
CERTIFICATE="$CODE_SIGN_IDENTITY"
BUNDLE_IDENTIFIER=""
KEYCHAIN=""
KEYCHAIN_PATH=
RAW_PROVISIONS=()
PROVISIONS_BY_ID=()
DEFAULT_PROVISION=""
XCODE_VERSION=$(defaults read /Applications/Xcode.app/Contents/Info.plist CFBundleShortVersionString)

# List of plist keys used for reference to and from nested apps and extensions
NESTED_APP_REFERENCE_KEYS=(":WKCompanionAppBundleIdentifier" ":NSExtension:NSExtensionAttributes:WKAppBundleIdentifier")

KEYCHAIN_FLAG=
if [ -n "$KEYCHAIN_PATH" ]; then
    KEYCHAIN_FLAG="--keychain $KEYCHAIN_PATH"
fi

log "Original file: '$ORIGINAL_FILE'"
log "Certificate: '$CERTIFICATE'"
[[ -n "${BUNDLE_IDENTIFIER}" ]] && log "Specified bundle identifier: '$BUNDLE_IDENTIFIER'"
[[ -n "${KEYCHAIN}" ]] && log "Specified keychain to use: '$KEYCHAIN'"
[[ -n "${KEYCHAIN_FLAG}" ]] && log "Specified keychain to use: '$KEYCHAIN_PATH'"

# Check for and remove the temporary directory if it already exists
if [ -d "$TEMP_DIR" ]; then
    log "Removing previous temporary directory: '$TEMP_DIR'"
    rm -Rf "$TEMP_DIR"
fi

filename=$(basename "$ORIGINAL_FILE")
extension="${filename##*.}"
filename="${filename%.*}"

# Check if the supplied file is an ipa or an app file
if [ "${extension}" = "ipa" ]; then
    # Unzip the old ipa quietly
    unzip -q "$ORIGINAL_FILE" -d $TEMP_DIR
    checkStatus
elif [ "${extension}" = "app" ]; then
    # Copy the app file into an ipa-like structure
    mkdir -p "$TEMP_DIR/Payload"
    cp -Rf "${ORIGINAL_FILE}" "$TEMP_DIR/Payload/${filename}.app"
    checkStatus
else
    error "Error: Only can resign .app files and .ipa files."
fi

# check the keychain
if [ "${KEYCHAIN}" != "" ]; then
    security list-keychains -s "$KEYCHAIN"
    security unlock "$KEYCHAIN"
    security default-keychain -s "$KEYCHAIN"
fi

# Set the app name
# In Payload directory may be another file except .app file, such as StoreKit folder.
# Search the first .app file within the Payload directory
# shellcheck disable=SC2010
APP_NAME=$(ls "$TEMP_DIR/Payload/" | grep ".app$" | head -1)

# Make sure that PATH includes the location of the PlistBuddy helper tool as its location is not standard
export PATH=$PATH:/usr/libexec


function get_bundle_identifier
{
    local APP_PATH="$1"

    # Make sure that the Info.plist file is where we expect it
    if [ ! -e "$APP_PATH/Info.plist" ]; then
        error "Expected file does not exist: '$APP_PATH/Info.plist'"
    fi

    # Read current bundle identifier
    local BUNDLE_IDENTIFIER=$(PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")

    echo "$BUNDLE_IDENTIFIER"
}

function get_app_version
{
    local APP_PATH="$1"

    # Make sure that the Info.plist file is where we expect it
    if [ ! -e "$APP_PATH/Info.plist" ]; then
        error "Expected file does not exist: '$APP_PATH/Info.plist'"
    fi

    # Read current bundle identifier
    local APP_VERSION=$(PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Info.plist")

    echo "$APP_VERSION"
}

function get_device_version
{
    local APP_PATH="$1"

    # Make sure that the Info.plist file is where we expect it
    if [ ! -e "$APP_PATH/Info.plist" ]; then
        error "Expected file does not exist: '$APP_PATH/Info.plist'"
    fi

    # Read current bundle identifier
    local BUNDLE_IDENTIFIER=$(PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")
    local DEVICE_VERSION=""

    # Parse device version
    if echo "$BUNDLE_IDENTIFIER" | grep -q "spikeipad"; then
        DEVICE_VERSION="iPad"
    else
        DEVICE_VERSION="iPhone-iPodTouch"
    fi

    echo "$DEVICE_VERSION"
}

# Get main bundle identifier
MAIN_BUNDLE_IDENTIFIER=$( get_bundle_identifier "$TEMP_DIR/Payload/$APP_NAME" )

# Map provision files to bundle ids
RAW_PROVISIONS+=("$MAIN_BUNDLE_IDENTIFIER=${MOBILE_PROVISION_FILES_DIR}/spike.mobileprovision")
RAW_PROVISIONS+=("$MAIN_BUNDLE_IDENTIFIER.todaywidget=${MOBILE_PROVISION_FILES_DIR}/widget.mobileprovision")
RAW_PROVISIONS+=("$MAIN_BUNDLE_IDENTIFIER.fswidget=${MOBILE_PROVISION_FILES_DIR}/fswidget.mobileprovision")
RAW_PROVISIONS+=("$MAIN_BUNDLE_IDENTIFIER.watchkitapp=${MOBILE_PROVISION_FILES_DIR}/watchkitapp.mobileprovision")
RAW_PROVISIONS+=("$MAIN_BUNDLE_IDENTIFIER.watchkitapp.watchkitextension=${MOBILE_PROVISION_FILES_DIR}/watchkitextension.mobileprovision")

# Log the options
for provision in "${RAW_PROVISIONS[@]}"; do
    if [[ "$provision" =~ .+=.+ ]]; then
        log "Specified provisioning profile: '${provision#*=}' for bundle identifier: '${provision%%=*}'"
    else
        log "Specified provisioning profile: '$provision'"
    fi
done

if [[ "${#RAW_PROVISIONS[*]}" == "0" ]]; then
    error "'xxxx.mobileprovision' parameter is required"
fi

# Parse Spike's version
MAIN_APP_VERSION=$( get_app_version "$TEMP_DIR/Payload/$APP_NAME" )
echo -e "${GREEN}Spike version -> $MAIN_APP_VERSION${NC}\n"

# Define resigned file name
SPIKE_DEVICE_VERSION=$( get_device_version "$TEMP_DIR/Payload/$APP_NAME" )
NEW_FILE="Spike.$SPIKE_DEVICE_VERSION.$MAIN_APP_VERSION-Resigned.ipa"

# Test whether two bundle identifiers match
# The first one may contain the wildcard character '*', in which case pattern matching will be used unless the third parameter is "STRICT"
function does_bundle_id_match {

    # shellcheck disable=SC2049
    if [[ "$1" == "$2" ]]; then
        return 0
    elif [[ "$3" != STRICT && "$1" =~ \* ]]; then
        local PATTERN0="${1//\./\\.}"       # com.example.*     -> com\.example\.*
        local PATTERN1="${PATTERN0//\*/.*}" # com\.example\.*   -> com\.example\..*
        if [[ "$2" =~ ^$PATTERN1$ ]]; then
            return 0
        fi
    fi

    return 1
}

# Find the provisioning profile for a given bundle identifier
function provision_for_bundle_id {

    for ARG in "${PROVISIONS_BY_ID[@]}"; do
        if does_bundle_id_match "${ARG%%=*}" "$1" "$2"; then
            echo "${ARG#*=}"
            break
        fi
    done
}

# Find the bundle identifier contained inside a provisioning profile
function bundle_id_for_provison {

    local FULL_BUNDLE_ID=$(PlistBuddy -c 'Print :Entitlements:application-identifier' /dev/stdin <<< "$(security cms -D -i "$1")")
    checkStatus
    echo "${FULL_BUNDLE_ID#*.}"
}

# Add given provisioning profile and bundle identifier to the search list
function add_provision_for_bundle_id {

    local PROVISION="$1"
    local BUNDLE_ID="$2"

    local CURRENT_PROVISION=$(provision_for_bundle_id "$BUNDLE_ID" STRICT)

    if [[ "$CURRENT_PROVISION" != "" && "$CURRENT_PROVISION" != "$PROVISION" ]]; then
        error "Conflicting provisioning profiles '$PROVISION' and '$CURRENT_PROVISION' for bundle identifier '$BUNDLE_ID'."
    fi

    PROVISIONS_BY_ID+=("$BUNDLE_ID=$PROVISION")
}

# Add given provisioning profile to the search list
function add_provision {

    local PROVISION="$1"

    if [[ "$1" =~ .+=.+ ]]; then
        PROVISION="${1#*=}"
        add_provision_for_bundle_id "$PROVISION" "${1%%=*}"
    elif [[ "$DEFAULT_PROVISION" == "" ]]; then
        DEFAULT_PROVISION="$PROVISION"
    fi

    if [[ ! -e "$PROVISION" ]]; then
        error "Provisioning profile '$PROVISION' file does not exist"
    fi

    local BUNDLE_ID=$(bundle_id_for_provison "$PROVISION")
    add_provision_for_bundle_id "$PROVISION" "$BUNDLE_ID"
}

# Load bundle identifiers from provisioning profiles
for ARG in "${RAW_PROVISIONS[@]}"; do
    add_provision "$ARG"
done

# Resign the given application
function resign {

    local APP_PATH="$1"
    local NESTED="$2"
    local BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER"
    local NEW_PROVISION="$NEW_PROVISION"
    local APP_IDENTIFIER_PREFIX=""
    local TEAM_IDENTIFIER=""

    if [[ "$NESTED" == NESTED ]]; then
        # Ignore bundle identifier for nested applications
        BUNDLE_IDENTIFIER=""
    fi

    # Make sure that the Info.plist file is where we expect it
    if [ ! -e "$APP_PATH/Info.plist" ]; then
        error "Expected file does not exist: '$APP_PATH/Info.plist'"
    fi

    # Make a copy of old Info.plist, it will come handy later to extract some old values
    cp -f "$APP_PATH/Info.plist" "$TEMP_DIR/oldInfo.plist"

    # Read in current values from the app
    local CURRENT_NAME=$(PlistBuddy -c "Print :CFBundleDisplayName" "$APP_PATH/Info.plist")
    local CURRENT_BUNDLE_IDENTIFIER=$(PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")
    local NEW_PROVISION=$(provision_for_bundle_id "${BUNDLE_IDENTIFIER:-$CURRENT_BUNDLE_IDENTIFIER}")

    if [[ "$NEW_PROVISION" == "" && "$NESTED" != NESTED ]]; then
        NEW_PROVISION="$DEFAULT_PROVISION"
    fi

    if [[ "$NEW_PROVISION" == "" ]]; then
        if [[ "$NESTED" == NESTED ]]; then
            warning "No provisioning profile for nested application: '$APP_PATH' with bundle identifier '${BUNDLE_IDENTIFIER:-$CURRENT_BUNDLE_IDENTIFIER}'"
        else
            warning "No provisioning profile for application: '$APP_PATH' with bundle identifier '${BUNDLE_IDENTIFIER:-$CURRENT_BUNDLE_IDENTIFIER}'"
        fi
        error ""
    fi

    local PROVISION_BUNDLE_IDENTIFIER=$(bundle_id_for_provison "$NEW_PROVISION")

    #Maintain same bundle identifier depending on current settings
    BUNDLE_IDENTIFIER="$CURRENT_BUNDLE_IDENTIFIER"

    # Replace the embedded mobile provisioning profile
    log "Validating the new provisioning profile: $NEW_PROVISION"
    security cms -D -i "$NEW_PROVISION" > "$TEMP_DIR/profile.plist"
    checkStatus

    APP_IDENTIFIER_PREFIX=$(PlistBuddy -c "Print :Entitlements:application-identifier" "$TEMP_DIR/profile.plist" | grep -E '^[A-Z0-9]*' -o | tr -d '\n')
    if [ "$APP_IDENTIFIER_PREFIX" == "" ];
    then
        APP_IDENTIFIER_PREFIX=$(PlistBuddy -c "Print :ApplicationIdentifierPrefix:0" "$TEMP_DIR/profile.plist")
        if [ "$APP_IDENTIFIER_PREFIX" == "" ]; then
            error "Failed to extract any app identifier prefix from '$NEW_PROVISION'"
        else
            warning "WARNING: extracted an app identifier prefix '$APP_IDENTIFIER_PREFIX' from '$NEW_PROVISION', but it was not found in the profile's entitlements"
        fi
    else
        log "Profile app identifier prefix is '$APP_IDENTIFIER_PREFIX'"
    fi

    # Set new app identifer prefix if such entry exists in plist file
    PlistBuddy -c "Set :AppIdentifierPrefix $APP_IDENTIFIER_PREFIX." "$APP_PATH/Info.plist" 2>/dev/null

    TEAM_IDENTIFIER=$(PlistBuddy -c "Print :Entitlements:com.apple.developer.team-identifier" "$TEMP_DIR/profile.plist" | tr -d '\n')
    if [ "$TEAM_IDENTIFIER" == "" ]; then
        TEAM_IDENTIFIER=$(PlistBuddy -c "Print :TeamIdentifier:0" "$TEMP_DIR/profile.plist")
        if [ "$TEAM_IDENTIFIER" == "" ]; then
            warning "Failed to extract team identifier from '$NEW_PROVISION', resigned ipa may fail on iOS 8 and higher"
        else
            warning "WARNING: extracted a team identifier '$TEAM_IDENTIFIER' from '$NEW_PROVISION', but it was not found in the profile's entitlements, resigned ipa may fail on iOS 8 and higher"
        fi
    else
        log "Profile team identifier is '$TEAM_IDENTIFIER'"
    fi

    # Make a copy of old embedded provisioning profile for further use
    cp -f "$APP_PATH/embedded.mobileprovision" "$TEMP_DIR/old-embedded.mobileprovision"

    # Replace embedded provisioning profile with new file
    cp -f "$NEW_PROVISION" "$APP_PATH/embedded.mobileprovision"

    #if the current bundle identifier is different from the new one in the provisioning profile, then change it.
    if [ "$CURRENT_BUNDLE_IDENTIFIER" != "$BUNDLE_IDENTIFIER" ]; then
        log "Updating the bundle identifier from '$CURRENT_BUNDLE_IDENTIFIER' to '$BUNDLE_IDENTIFIER'"
        PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_IDENTIFIER" "$APP_PATH/Info.plist"
        checkStatus
    fi

    # Check for and resign any embedded frameworks
    FRAMEWORKS_DIR="$APP_PATH/Frameworks"
    if [ -d "$FRAMEWORKS_DIR" ]; then
        if [ "$TEAM_IDENTIFIER" == "" ]; then
            error "ERROR: embedded frameworks detected, re-signing iOS 8 (or higher) applications wihout a team identifier in the certificate/profile does not work"
        fi

        log "Resigning embedded frameworks using certificate: '$CERTIFICATE'"
        for framework in "$FRAMEWORKS_DIR"/*
        do
            if [[ "$framework" == *.framework || "$framework" == *.dylib ]]; then
                log "Resigning '$framework'"
                # Must not qote KEYCHAIN_FLAG because it needs to be unwrapped and passed to codesign with spaces
                # shellcheck disable=SC2086
                /usr/bin/codesign ${VERBOSE} ${KEYCHAIN_FLAG} -f -s "$CERTIFICATE" "$framework"
                checkStatus
            else
                log "Ignoring non-framework: $framework"
            fi
        done
    fi

    #Process entitlements & resign
    log "Extracting entitlements from provisioning profile"
    PlistBuddy -x -c "Print Entitlements" "$TEMP_DIR/profile.plist" > "$TEMP_DIR/newEntitlements"
    checkStatus

    #Patch iCloud entitlements for Spike app
    if  [[ "$NESTED" != NESTED && "$IS_FREE" == "false" ]]; then
        log "Checking iCloud entitlements"

        #Get current entitlements file
        PROVISION_ENTITLEMENTS="$TEMP_DIR/newEntitlements"

        # Check if current entitlements support iCloud
        ICLOUD_CONTAINER_KEY="com.apple.developer.icloud-container-identifiers"
        ICLOUD_CONTAINER_VALUE=$(PlistBuddy -c "Print $ICLOUD_CONTAINER_KEY" "$PROVISION_ENTITLEMENTS" | grep -E '^[A-Z0-9]*' -o | tr -d '\n')

        if [ -n "$ICLOUD_CONTAINER_VALUE" ]; then
            #Lets take care of the iCLoud services entitlements
            log "Adding missing iCloud service entitlements"

            #Define iCloud services entitlements key
            ICLOUD_SERVICES_KEY="com.apple.developer.icloud-services"
            PLUTIL_ICLOUD_SERVICES_KEY=$(echo "$ICLOUD_SERVICES_KEY" | sed 's/\./\\\./g')

            #First delete them in case they already exist
            PlistBuddy -c "Delete $ICLOUD_SERVICES_KEY" "$PROVISION_ENTITLEMENTS" 2>/dev/null
            checkStatus

            #Insert them
            plutil -insert "$PLUTIL_ICLOUD_SERVICES_KEY" -json '[ "CloudDocuments", "CloudKit"]' "$PROVISION_ENTITLEMENTS"
            checkStatus

            log "Added iCloud service entitlements"
        fi
    fi 

    log "Resigning application using certificate: '$CERTIFICATE'"
    log "and entitlements from provisioning profile: $NEW_PROVISION"
    if [[ "${XCODE_VERSION/.*/}" -lt 10 ]]; then
        log "Creating an archived-expanded-entitlements.xcent file for Xcode 9 builds or earlier"
        cp -- "$TEMP_DIR/newEntitlements" "$APP_PATH/archived-expanded-entitlements.xcent"
    fi
    # Must not qote KEYCHAIN_FLAG because it needs to be unwrapped and passed to codesign with spaces
    # shellcheck disable=SC2086
    /usr/bin/codesign ${VERBOSE} ${KEYCHAIN_FLAG} -f -s "$CERTIFICATE" --entitlements "$TEMP_DIR/newEntitlements" "$APP_PATH"
    checkStatus

    # Remove the temporary files if they were created before generating ipa
    rm -f "$TEMP_DIR/newEntitlements"
    rm -f "$PROFILE_ENTITLEMENTS"
    rm -f "$APP_ENTITLEMENTS"
    rm -f "$PATCHED_ENTITLEMENTS"
    rm -f "$PATCHED_ENTITLEMENTS.bak"
    rm -f "$TEMP_DIR/old-embedded-profile.plist"
    rm -f "$TEMP_DIR/profile.plist"
    rm -f "$TEMP_DIR/old-embedded.mobileprovision"
    rm -f "$TEMP_DIR/oldInfo.plist"
}

# Sign nested applications and app extensions
while IFS= read -d '' -r app;
do
    log "Resigning nested application: '$app'"
    resign "$app" NESTED
done < <(find "$TEMP_DIR/Payload/$APP_NAME" -d -mindepth 1 \( -name "*.app" -or -name "*.appex" \) -print0)

# Resign the application
resign "$TEMP_DIR/Payload/$APP_NAME"

# Repackage quietly
log "Repackaging as $NEW_FILE"

# Zip up the contents of the "$TEMP_DIR" folder
# Navigate to the temporary directory (sending the output to null)
# Zip all the contents, saving the zip file in the above directory
# Navigate back to the orignating directory (sending the output to null)
pushd "$TEMP_DIR" > /dev/null
# TODO: Fix shellcheck warning and remove directive
# shellcheck disable=SC2035
zip -qry "../$TEMP_DIR.ipa" *
popd > /dev/null

# Move the resulting ipa to the target destination
mv "$TEMP_DIR.ipa" "$NEW_FILE"

# Remove the temp directory
rm -rf "$TEMP_DIR"

log "Process complete"

#Clean up
cleanup true