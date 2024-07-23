#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2021 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ

build_bottle () {
    brew install --build-bottle "$1"
    brew bottle --force-core-tap "$1"
    brew uninstall "$1"
}

# mavryk-sapling-params is used as a dependency for some of the formulas
# so we handle it separately
brew install --build-bottle ./Formula/mavryk-sapling-params.rb
brew bottle --force-core-tap ./Formula/mavryk-sapling-params.rb

# we don't bottle meta-formulas that contains only services
build_bottle ./Formula/mavryk-accuser-008-PtEdo2Zk.rb
build_bottle ./Formula/mavryk-admin-client.rb
build_bottle ./Formula/mavryk-baker-008-PtEdo2Zk.rb
build_bottle ./Formula/mavryk-client.rb
build_bottle ./Formula/mavryk-codec.rb
build_bottle ./Formula/mavryk-endorser-008-PtEdo2Zk.rb
build_bottle ./Formula/mavryk-node.rb
build_bottle ./Formula/mavryk-sandbox.rb
build_bottle ./Formula/mavryk-signer.rb

brew uninstall ./Formula/mavryk-sapling-params.rb
# https://github.com/Homebrew/brew/pull/4612#commitcomment-29995084
for bottle in ./*.bottle.*; do
    mv "$bottle" "${bottle/--/-}"
done
