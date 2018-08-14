#!/bin/bash

#Parse build script parameters
TARGET="FullBuild"
CONFIGURATION="Release"
RUNTIME="linux-x64"

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -t|--target)
    TARGET="$2"
    shift # past argument
    ;;
    -c|--configuration)
    CONFIGURATION="$2"
    shift # past argument
    ;;
    -r|--runtime)
    RUNTIME="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

### Directory of this script
pushd . > /dev/null
SCRIPT_DIR="${BASH_SOURCE[0]}"
while([ -h "${SCRIPT_DIR}" ]); do
    cd "`dirname "${SCRIPT_DIR}"`"
    SCRIPT_DIR="$(readlink "`basename "${SCRIPT_DIR}"`")"
done
cd "`dirname "${SCRIPT_DIR}"`" > /dev/null
SCRIPT_DIR="`pwd`"
popd  > /dev/null

### Variables
buildDir="${SCRIPT_DIR}"
buildScript="${buildDir}/build.fsx"
repositoryDir=`realpath "${buildDir}/.."`
fakeDir="${buildDir}/fake"

FAKE="${fakeDir}/fake"

### Purge target requires special treatment
if [ "${TARGET}" = "Purge" ]; then
    "${buildDir}/purge.sh" "$repositoryDir"
    if [ $? -ne 0 ]; then
        echo "*** Target Purge failed"
        exit 1
    fi
    exit 0
fi

### Check if .NET CLI is available
dotnet_version=`dotnet --version 2>/dev/null`
if [ $? -ne 0 ]; then
    echo "*** 'dotnet' is not available. Install .NET Core from https://www.microsoft.com/net/download"
    exit 1
fi

### Make sure FAKE CLI is available
fakeCandidates=`find "${fakeDir}" -maxdepth 1 -name "fake*" -type f 2>/dev/null`
if [ "${fakeCandidates}" = "" ]; then
    echo "***    Installing FAKE CLI"
    dotnet tool install fake-cli --tool-path "$fakeDir"
    if [ $? -ne 0 ]; then
        echo "*** Failed to install FAKE CLI"
        exit 1
    fi
fi

### FAKE it!
echo "-------------------------"
echo "Building ${repositoryDir}"
echo "TARGET        = ${TARGET}"
echo "CONFIGURATION = ${CONFIGURATION}"
echo "RUNTIME       = ${RUNTIME}"
echo "-------------------------"

Build_RepositoryDir="${repositoryDir}" \
Build_Configuration="${CONFIGURATION}" \
Build_Runtime="${RUNTIME}" \
FAKE_ALLOW_NO_DEPENDENCIES="true" \
"${FAKE}" run "${buildScript}" --target "${TARGET}"
