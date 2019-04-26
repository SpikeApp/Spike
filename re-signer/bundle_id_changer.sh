# !/bin/bash
# Spike Bundle ID Changer by Miguel Kennedy
# Changes the bundle id of all apps and extensions inside an ipa file

NEW_BUNDLE_ID="com.spike-app.spike"
OLD_BUNDLE_ID=""

# List of plist keys used for reference to and from nested apps and extensions
NESTED_APP_REFERENCE_KEYS=(":WKCompanionAppBundleIdentifier" ":NSExtension:NSExtensionAttributes:WKAppBundleIdentifier")
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m'
ORIGINAL_FILE=""
NEW_FILE=""
TEMP_DIR="temp"
OUTPUT_DIR="ReBundled"

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

#Housekeeping. Let's remove any leftovers, just in case.
rm -rf "$TEMP_DIR" > /dev/null 2>&1

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

ORIGINAL_FILE="$SELECTED_IPA_FILE"
NEW_FILE="$SELECTED_IPA_FILE"

# Unzip the old ipa quietly
unzip -q "$ORIGINAL_FILE" -d $TEMP_DIR
checkStatus

# Set the app name
# In Payload directory may be another file except .app file, such as StoreKit folder.
# Search the first .app file within the Payload directory
# shellcheck disable=SC2010
APP_NAME=$(ls "$TEMP_DIR/Payload/" | grep ".app$" | head -1)

# Make sure that PATH includes the location of the PlistBuddy helper tool as its location is not standard
export PATH=$PATH:/usr/libexec

#Change bundle if of the given application
function change_bundle_id 
{
    local APP_PATH="$1"
    local NESTED="$2"
    local BUNDLE_IDENTIFIER=""

    # Make sure that the Info.plist file is where we expect it
    if [ ! -e "$APP_PATH/Info.plist" ]; then
        error "Expected file does not exist: '$APP_PATH/Info.plist'"
    fi

    # Make a copy of old Info.plist, it will come handy later to extract some old values
    cp -f "$APP_PATH/Info.plist" "$TEMP_DIR/oldInfo.plist"

    # Read in current values from the app
    local CURRENT_BUNDLE_IDENTIFIER=$(PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")

    #Get old bundle id from main app
    if [ "$NESTED" != NESTED ]; then
        OLD_BUNDLE_ID="$CURRENT_BUNDLE_IDENTIFIER"
    fi 

    BUNDLE_IDENTIFIER="${CURRENT_BUNDLE_IDENTIFIER/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID}"

    #if the current bundle identifier is different from the new one in the provisioning profile, then change it.
    if [ "$CURRENT_BUNDLE_IDENTIFIER" != "$BUNDLE_IDENTIFIER" ]; then
        log "Updating the bundle identifier from '$CURRENT_BUNDLE_IDENTIFIER' to '$BUNDLE_IDENTIFIER'"
        PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_IDENTIFIER" "$APP_PATH/Info.plist"
        checkStatus
    fi

    # Check for and update bundle identifiers for extensions and associated nested apps
    log "Fixing nested app and extension references"
    for key in "${NESTED_APP_REFERENCE_KEYS[@]}"; do
        # Check if Info.plist has a reference to another app or extension
        REF_BUNDLE_ID=$(PlistBuddy -c "Print ${key}" "$APP_PATH/Info.plist" 2>/dev/null)
        if [ -n "$REF_BUNDLE_ID" ]; then
            # Found a reference bundle id, update it to the new id.
            NEW_REF_BUNDLE_ID="${REF_BUNDLE_ID/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID}"
            if [[ "$REF_BUNDLE_ID" != "$NEW_REF_BUNDLE_ID" ]] && ! [[ "$NEW_REF_BUNDLE_ID" =~ \* ]]; then
                log "Updating nested app or extension reference for ${key} key from ${REF_BUNDLE_ID} to ${NEW_REF_BUNDLE_ID}"
                PlistBuddy -c "Set ${key} $NEW_REF_BUNDLE_ID" "$APP_PATH/Info.plist"
            fi
        fi
    done

    if [ "$NESTED" != NESTED ]; then
        local CURRENT_BUNDLE_URL_NAME=$(PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLName" "$APP_PATH/Info.plist")
        local NEW_BUNDLE_URL_NAME="${CURRENT_BUNDLE_URL_NAME/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID}"

        PlistBuddy -c "Set :CFBundleURLTypes:0:CFBundleURLName $NEW_BUNDLE_URL_NAME" "$APP_PATH/Info.plist"
        checkStatus
    fi 

    # Remove the temporary files if they were created before generating ipa
    rm -f "$TEMP_DIR/oldInfo.plist"
}

# Change bundle id of main application
change_bundle_id "$TEMP_DIR/Payload/$APP_NAME"

# Change bundle id of nested applications and app extensions
while IFS= read -d '' -r app;
do
    log "Changing bundle if of nested application: '$app'"
    change_bundle_id "$app" NESTED
done < <(find "$TEMP_DIR/Payload/$APP_NAME" -d -mindepth 1 \( -name "*.app" -or -name "*.appex" \) -print0)

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

#Create output dir if doesn't exists
mkdir -p "$OUTPUT_DIR"

# Move the resulting ipa to the target destination
mv "$TEMP_DIR.ipa" "$OUTPUT_DIR/$NEW_FILE"

# Remove the temp directory
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Process complete${NC}"