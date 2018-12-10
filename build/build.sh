#!/bin/bash

#Parse build script parameters
TARGET="FullBuild"
CONFIGURATION="Release"
RUNTIME="linux-x64"
REQUIRED_DOTNET_VERSION="2.1"

USAGE_HELP="""USAGE:
    build.sh [-t|--target <TargetName>]
             [-c|--configuration <ConfigurationName>]
             [-r|--runtime <RuntimeId>]
"""

while [ $# -gt 0 ]
do
    key="$1"; shift
    if [ $# -gt 0 ]; then value="$1"; shift; else value=""; fi

    case $key in
        -t|--target)
            TARGET="$value"
            ;;
        -c|--configuration)
            CONFIGURATION="$value"
            ;;
        -r|--runtime)
            RUNTIME="$value"
            ;;
        *)
            echo "*** Option $key is not supported"
            echo $USAGE_HELP
            exit 1
            ;;
    esac

    if [ -z "$value" ]; then
        echo $USAGE_HELP
        exit 1
    fi
done

### Directory of this script
# https://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"

pushd . > /dev/null
cd "${SCRIPT_DIR}/.."
SCRIPT_PARENT_DIR=`pwd`
popd > /dev/null

### Variables
buildDir="${SCRIPT_DIR}"
buildScript="${buildDir}/build.fsx"
repositoryDir="$SCRIPT_PARENT_DIR"
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
ver_lt() {
    [  "$1" = "`echo -e "$1\n$2" | sort -n | head -n1`" ]
}

ver_lte() {
    [ "$1" = "$2" ] && return 1 || ver_lt $1 $2
}

dotnet_version=`dotnet --version 2>/dev/null`
if [ $? -ne 0 ]; then
    echo "*** 'dotnet' is not available. Install .NET Core from https://www.microsoft.com/net/download"
    exit 1
fi

ver_lt "$dotnet_version" "$REQUIRED_DOTNET_VERSION"
if [ $? -eq 0 ]; then
    echo "*** Required 'dotnet' version $REQUIRED_DOTNET_VERSION or higher. Install .NET Core from https://www.microsoft.com/net/download"
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
