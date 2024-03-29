#!/bin/bash

set -euo pipefail

# USAGE: $0 <version> [tags...]
# * version is the full PHP version (major, minor, and patch)
# * tag is an extra tag to use (e.g., 7.2 or latest)

# Required environment variables: XDEBUG_VERSION
# * XDEBUG_VERSION is either a full version or the string 'stable'

repository=forumone/drupal8

# This is the full PHP version, as mentioned above in the USAGE block.
version="$1"
shift

# Tags other than the full PHP version to apply to this build - typically just the minor
# version (e.g., 7.2) but may include the major version or "latest".
extra_tags=("$@")

# Used by build() function - we have two sets of variable arguments passed to build,
# so one of them has to get passed laterally.
#
# It's easier to use the tags array because its size depends on the arguments to this script,
# so we will have to do a loop over the array regardless of whether it gets passed as $@,
# whereas there is a fixed number of build args, making it easier to simply write them out
# in the function call.
declare -a tags

# Usage: should-push
#
# This function determines if the built images should be pushed up to the Docker Hub.
# There are a few conditions:
#   1. This must not be a local build,
#   2. This must not be triggered by a pull request, and
#   3. The branch being built must be master.
should-push() {
  test "$BUILDKITE_PIPELINE_PROVIDER" != local &&
    test "$BUILDKITE_PULL_REQUEST" == false &&
    test "$BUILDKITE_BRANCH" == master
}

# Usage:
#
#   # Set up the tags array variable before calling
#   tags=([tag-name...])
#   build <target> [build-arg...]
#
# * target is either 'base' or 'xdebug' (see the Dockerfile)
# * build-arg is of the form ARG_NAME=value, as expected by --build-arg
# * tag-name is
#
# NB. This function reads from the tags variable as well as its own arguments.
build() {
  local target="$1"
  shift

  local build_args=("$@")

  # Holds arguments to docker build
  local docker_args=()

  for tag in "${tags[@]}"; do
    docker_args+=(--tag "$tag")
  done

  for arg in "${build_args[@]}"; do
    docker_args+=(--build-arg "$arg")
  done

  docker build . \
    --target "$target" \
    --pull \
    "${docker_args[@]}"
}

# Start by building the base image
echo "--- Build"
tags=()
for tag in "$version" "${extra_tags[@]}"; do
  tags+=("$repository:$tag")
done

build base PHP_VERSION="$version"

# See comments in the Dockerfile for why we build XDebug specially
echo "--- Build XDebug"
tags=()
for tag in "$version" "${extra_tags[@]}"; do
  xdebug="$tag-xdebug"
  tags+=("$repository:${xdebug#latest-}")
done

build xdebug PHP_VERSION="$version" XDEBUG_VERSION="$XDEBUG_VERSION"

if should-push; then
  echo "--- Push"
  docker push --all-tags "$repository"
fi
