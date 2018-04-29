#!/bin/sh
pushd /Volumes/Data\ HD/Development/GitHub/Spike/bin-debug/
unzip Spike.ipa
pushd /Volumes/Data\ HD/Development/GitHub/Spike/bin-debug/Payload/Spike.app/
cp -r * "${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/"
pushd /Volumes/Data\ HD/Development/GitHub/Spike/bin-debug/
rm -r Payload
pushd "${CONFIGURATION_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/"
if [ -d CodeResources ]; then
    rm CodeResources
    ln -s _CodeSignature/CodeResources CodeResources
fi
popd
