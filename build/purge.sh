#!/bin/bash

REPOSITORY_DIR="$1"

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

if  [ "${REPOSITORY_DIR}" = "" ]; then
    REPOSITORY_DIR="$SCRIPT_PARENT_DIR"
fi

if ! [ -d "${REPOSITORY_DIR}" ]; then
    echo "*** Directory {REPOSITORY_DIR} does not exist"
    exit 1
fi

### Start the purge
echo "*** Purging ${REPOSITORY_DIR}"

find "${REPOSITORY_DIR}" -depth -name "bin" -type d -exec rm -rf "{}" \;
find "${REPOSITORY_DIR}" -depth -name "obj" -type d -exec rm -rf "{}" \;
find "${REPOSITORY_DIR}" -depth -name "TestResults" -type d -exec rm -rf "{}" \;

find "${SCRIPT_DIR}" -maxdepth 1 -name "reports" -type d -exec rm -rf "{}" \;
find "${SCRIPT_DIR}" -maxdepth 1 -name "fake" -type d -exec rm -rf "{}" \;
find "${SCRIPT_DIR}" -maxdepth 1 -name ".fake" -type d -exec rm -rf "{}" \;
find "${SCRIPT_DIR}" -maxdepth 1 -name "build.fsx.lock" -type f -exec rm -f "{}" \;
