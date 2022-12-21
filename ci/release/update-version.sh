#!/bin/bash
# Copyright (c) 2020, NVIDIA CORPORATION.
################################################################################
# dask-cuda version updater
################################################################################

## Usage
# bash update-version.sh <new_version>


# Format is YY.MM.PP - no leading 'v' or trailing 'a'
NEXT_FULL_TAG=$1

# Get current version
CURRENT_TAG=$(git tag --merged HEAD | grep -xE '^v.*' | sort --version-sort | tail -n 1 | tr -d 'v')
CURRENT_MAJOR=$(echo $CURRENT_TAG | awk '{split($0, a, "."); print a[1]}')
CURRENT_MINOR=$(echo $CURRENT_TAG | awk '{split($0, a, "."); print a[2]}')
CURRENT_PATCH=$(echo $CURRENT_TAG | awk '{split($0, a, "."); print a[3]}')
CURRENT_SHORT_TAG=${CURRENT_MAJOR}.${CURRENT_MINOR}

#Get <major>.<minor> for next version
NEXT_MAJOR=$(echo $NEXT_FULL_TAG | awk '{split($0, a, "."); print a[1]}')
NEXT_MINOR=$(echo $NEXT_FULL_TAG | awk '{split($0, a, "."); print a[2]}')
NEXT_SHORT_TAG=${NEXT_MAJOR}.${NEXT_MINOR}
NEXT_UCXPY_VERSION="$(curl -s https://version.gpuci.io/rapids/${NEXT_SHORT_TAG}).*"

echo "Preparing release $CURRENT_TAG => $NEXT_FULL_TAG"

# Inplace sed replace; workaround for Linux and Mac
function sed_runner() {
    sed -i.bak ''"$1"'' $2 && rm -f ${2}.bak
}

# Update UCX-Py version
sed_runner "s/export UCXPY_VERSION=.*/export UCXPY_VERSION="${NEXT_UCXPY_VERSION}"/g" ci/gpu/build.sh

# Bump cudf and dask-cudf testing dependencies
sed_runner "s/cudf=${CURRENT_SHORT_TAG}/cudf=${NEXT_SHORT_TAG}/g" dependencies.yaml
sed_runner "s/dask-cudf=${CURRENT_SHORT_TAG}/dask-cudf=${NEXT_SHORT_TAG}/g" dependencies.yaml
