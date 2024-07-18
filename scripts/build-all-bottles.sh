#! /usr/bin/env bash
# shellcheck shell=bash

# SPDX-FileCopyrightText: 2022 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

if [ -z "$1" ] ; then
    echo "Please call this script with the name of the OS for which to build the bottles."
    exit 1
fi

set -euo pipefail

# We keep track of an exit code to return instead of failing immediately.
# This is so that if a bottle (or more) can't be built or uploaded to GH we
# still try to handle the other ones.
# Because the script checks for existing bottles, in case of a failure this can
# be re-run without unnecessary rebuilds.
retval="0"

# we don't bottle meta-formulas that contain only services
formulae=("mavryk-smart-rollup-wasm-debugger" "mavryk-smart-rollup-node" "mavryk-dac-client" "mavryk-dac-node" "mavryk-dal-node" "mavryk-signer" "mavryk-codec" "mavryk-client" "mavryk-admin-client" "mavryk-node" "mavryk-accuser-PtBoreas" "mavryk-baker-PtBoreas")

# mavryk-sapling-params is used as a dependency for some of the formulas
# so we handle it separately.
# We don't build the bottle for it because it is never updated over time.
brew install --formula ./Formula/mavryk-sapling-params.rb

for f in "${formulae[@]}"; do
  # check if the formula doesn't already have a bottle in its respective release
  if ./scripts/check-bottle-built.sh "$f" "$1"; then
    # build a bottle
    if ./scripts/build-one-bottle.sh "$f"; then
      # upload the bottle to its respective release
      FORMULA_TAG="$(sed -E -n 's/^[[:space:]]+version "(.*)"/\1/p' "./Formula/$f.rb")"
      if ! gh release upload "$FORMULA_TAG" "$f"*.bottle.*; then
        # we want a non-0 exit code if any of the bottles couldn't be uploaded
        retval="1";
        >&2 echo "Bottle for $f couldn't be uploaded to $FORMULA_TAG release."
      fi
    else
      # we want a non-0 exit code if any of the bottles couldn't be built
      retval="1";
      >&2 echo "Bottle for $f couldn't be built."
    fi
  fi
done

brew uninstall mavryk-sapling-params.rb

exit "$retval"
