#! /usr/bin/env bash

# SPDX-FileCopyrightText: 2020 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ

# This script builds native binary or source ubuntu or fedora packages
# with tezos binaries. Target OS is defined in the first passed argument.
# Package type can be defined in the second argument, 'source' and 'binary'
# types are supported.
set -euo pipefail

if [[ "${USE_PODMAN-}" == "True" ]]; then
    virtualisation_engine="podman"
else
    virtualisation_engine="docker"
fi

args=()

while true;
do
    arg="${1-}"
    if [[ -z "$arg" ]];
    then
        break
    fi
    case $arg in
        --os )
            args+=("$arg" "$2")
            target_os="$2"
            shift 2
            ;;
        --sources )
            source_archive="$2"
            source_archive_name="$(basename "$2")"
            args+=("$arg" "$source_archive_name")
            shift 2
            ;;
        * )
            args+=("$arg")
            shift
            ;;
    esac
done

"$virtualisation_engine" build -t mavryk-"$target_os" -f docker/package/Dockerfile-"$target_os" .
set +e
if [[ -z ${source_archive-} ]]; then
    container_id="$("$virtualisation_engine" create --env MAVRYK_VERSION="$MAVRYK_VERSION" --env OPAMSOLVERTIMEOUT=900 -t mavryk-"$target_os" "${args[@]}")"
else
    container_id="$("$virtualisation_engine" create -v "$PWD/$source_archive:/mavryk-packaging/docker/$source_archive_name" \
     --env MAVRYK_VERSION="$MAVRYK_VERSION" --env OPAMSOLVERTIMEOUT=900 -t mavryk-"$target_os" "${args[@]}")"
fi
"$virtualisation_engine" start -a "$container_id"
exit_code="$?"
"$virtualisation_engine" cp "$container_id":/mavryk-packaging/docker/out .
set -e
"$virtualisation_engine" rm -v "$container_id"
exit "$exit_code"
