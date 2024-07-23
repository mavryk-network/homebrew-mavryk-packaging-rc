<!--
   - SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
   -
   - SPDX-License-Identifier: LicenseRef-MIT-TQ
   -->

# Mavryk packaging

[![Build status](https://badge.buildkite.com/e899e9e54babcd14139e3bd4381bad39b5d680e08e7b7766d4.svg?branch=master)](https://buildkite.com/serokell/mavryk-packaging)

This repo provides various form of distribution for mavryk-related executables:
* `mavryk-client`
* `mavryk-admin-client`
* `mavryk-node`
* `mavryk-baker`
* `mavryk-accuser`
* `mavryk-endorser`
* `mavryk-signer`
* `mavryk-codec`
* `mavryk-sandbox`

Daemon binaries (as well as packages for them) have suffix that defines their target protocol,
e.g. `mavryk-baker-007-PsDELPH1` can be used only on the chain with 007 protocol.

Other binaries can be used with all protocols if they're new enough. E.g.
007 protocol is supported only from `v7.4`. `mavryk-node` can be set up to run
different networks, you can read more about this in [this article](https://tezos.gitlab.io/user/multinetwork.html).

## Table of contents

* [Static linux binaries](#static-linux)
* [Native Ubuntu packages](#ubuntu)
* [Native Fedora packages](#fedora)
* [Other linux](#linux)
* [Brew tap for macOS](#macos)
* [Systemd services for Mavryk binaries](#systemd)
* [Building instructions](#building)
* [Setting up baking instance on Ubuntu](#baking-on-ubuntu)

<a name="static-linux"></a>
## Obtain binaries from github release

Recomended way to get these binaries is to download them from assets from github release.
Go to the [latest release](https://github.com/mavryk-network/mavryk-packaging/releases/latest)
and download desired assets.

Some of the individual binaries contain protocol name to determine
with which protocol binary is compatible with. If this is not the
case, then consult release notes to check which protocols are
supported by that binary.

<a name="ubuntu"></a>
## Ubuntu Launchpad PPA with `mavryk-*` binaries

If you are using Ubuntu you can use PPA in order to install `mavryk-*` executables.
E.g, in order to do install `mavryk-client` or `mavryk-baker` run the following commands:
```
sudo add-apt-repository ppa:mavrykdynamics/mavryk && sudo apt-get update
sudo apt-get install mavryk-client
# dpkg-source prohibits uppercase in the packages names so the protocol
# name is in lowercase
sudo apt-get install mavryk-baker-007-psdelph1
```
Once you install such packages the commands `mavryk-*` will be available.

<a name="fedora"></a>
## Fedora Copr repository with `mavryk-*` binaries

If you are using Fedora you can use Copr in order to install `mavryk-*`
executables.
E.g. in order to install `mavryk-client` or `mavryk-baker` run the following commands:
```
# use dnf
sudo dnf copr enable @mavrykdynamics/mavryk
sudo dnf install mavryk-client
sudo dnf install mavryk-baker-007-PsDELPH1

# or use yum
sudo yum copr enable @mavrykdynamics/mavryk
sudo yum install mavryk-baker-007-PsDELPH1
```
Once you install such packages the commands `mavryk-*` will be available.

<a name="linux"></a>
## Other Linux distros usage

Download binaries from release assets.

### `mavryk-client` example

Make it executable:
```
chmod +x mavryk-client
```

Run `./mavryk-client` or add it to your PATH to be able to run it anywhere.

<a name="macos"></a>
## Brew tap for macOS

If you're using macOS and `brew`, you can install Mavryk binaries from the tap
provided by this repository. In order to do that run the following:
```
brew tap serokell/mavryk-packaging https://github.com/mavryk-network/mavryk-packaging.git
brew install mavryk-client
```

### Building brew bottles

It's possible to provide prebuilt macOS packages for brew called bottles. They're supposed
to be built before making the new release and included to it. In order to build all bottles run
`build-bottles.sh` script:
```
./scripts/build-bottles.sh
```

Note that this might take a while, because builds don't share common parts and for each binary
dependencies are compiled from scratch. Once the bottles are built, the corresponding sections in the
formulas should be updated. Also, bottles should be uploaded to the release artifacts.

<a name="systemd"></a>
## Background services for `mavryk-node` and daemons

### Systemd units on Ubuntu or Fedora

`mavryk-node`, `mavryk-accuser-<proto>`, `mavryk-baker-<proto>`,
`mavryk-endorser-<proto>`, and `mavryk-signer` packages have systemd files included to the
Ubuntu and Fedora packages.

Once you've installed the packages with systemd unit, you can run the service
with the binary from the package using the following command:
```
systemctl start <package-name>.service
```
To stop the service run:
```
systemctl stop <package-name>.service
```

Each service has configuration file located in `/etc/default`. Default
configurations can be found [here](docker/package/defaults/).

Files created by the services will be located in `/var/lib/tezos/` by default.
`mavryk-{accuser, baker, endorser}-<protocol>` services can have configurable
data directory.

`mavryk-{accuser, endorser}` have configurable node address, so that they can be used with both
remote and local node.

### Launchd services on macOS

`mavryk-accuser-<proto>`, `mavryk-baker-<proto>`, `mavryk-endorser-<proto>` formulas
provide backround services for running the corresponding daemons.

Since `mavryk-node` and `mavryk-signer` need multiple services they are provided
in dedicated meta-formulas. These formulas don't install any binaries and only add
background services.

Formulas with `mavryk-node` background services:
* `mavryk-node-mainnet`
* `mavryk-node-edo2net`

Formulas with `mavryk-signer` background services:
* `mavryk-signer-http`
* `mavryk-signer-https`
* `tesos-signer-tcp`
* `mavryk-signer-unix`

To start the service: `brew services start <formula>`.

To stop the service: `brew services stop <formula>`.

All of the brew services have various configurable env variables. These variables
can be changed in the corresponding `/usr/local/Cellar/mavryk-signer-tcp/<version>/homebrew.mxcl.<formula>.plist`.
Once the configuration is updated, you should restart the service:
`brew services restart <formula>`.

Note, that all services are run as a user agents, thus they're stopped after the logout.

### Systemd units on other Linux systems

If you're not using Ubuntu or Fedora you can still construct systemd units for binaries
from scratch.

For this you'll need `.service` file to define systemd service. The easiest way
to get one is to run [`gen_systemd_service_file.py`](gen_systemd_service_file.py).
You should specify service name as an argument. Note that there are three
predefined services for `mavryk-node`: `mavryk-node-{mainnet, delphinet}`.

E.g.:
```
./gen_systemd_service_file.py mavryk-node-mainnet
# or
./gen_systemd_service_file.py mavryk-baker-007-PsDELPH1
```
After that you'll have `.service` file in the current directory.

Apart from `.service` file you'll need service startup script and default configuration
file, they can be found in [`scripts`](./docker/package/scripts) and
[`defaults`](./docker/package/defaults) folders respectively.


### Multiple similar systemd services

It's possible to run multiple same services, e.g. two `mavryk-node`s that run different
networks.

`mavryk-node` packages provide three services out of the box:
`mavryk-node-delphinet` and `mavryk-node-mainnet` that run
`delphinet` and `mainnet` networks respectively.

In order to start it run:
```
systemctl start mavryk-node-<network>
```

In addition to node services where the config is predefined to a specific network
(e.g. `mavryk-node-mainnet` or `mavryk-node-delphinet`), it's possible to run `mavryk-node-custom`
service and provide a path to the custom node config file via the
`CUSTOM_NODE_CONFIG` variable in the `mavryk-node-custom.service` file.

Another case for running multiple similar systemd services is when one wants to have
multiple daemons that target different protocols.
Since daemons for different protocols are provided in the different packages, they will
have different service files. The only thing that needs to be changed is config file.
One should provide desired node address, data directory for daemon files and node directory
(however, this is the case only for baker daemon).

`mavryk-signer` package provides four services one for each mode in which signing daemon can run:
* Over TCP socket (`mavryk-signer-tcp.service`).
* Over UNIX socker (`mavryk-signer-unix.service`).
* Over HTTP (`mavryk-signer-http.service`).
* Over HTTPS (`mavryk-signer-https.service`)
Each signer service has dedicated config file in e.g. `/etc/default/mavryk-signer-{mode}`.

<a name="building"></a>
## Build Instructions

This repository provides two distinct ways for building and packaging tezos binaries:
* [Docker-based](./docker/README.md)
* [Nix-based](./nix/README.md)

<a name="baking-on-ubuntu"></a>
## Setting up baking instance on Ubuntu

Read [the article](./docs/baking.md) to find out an easy way to set up
baking instance on Ubuntu using packages provided by our launchpad PPA.

## For Contributors

Please see [CONTRIBUTING.md](.github/CONTRIBUTING.md) for more information.

## About Serokell

This repository is maintained with ❤️ by [Serokell](https://serokell.io/).
The names and logo for Serokell are trademark of Serokell OÜ.

We love open source software! See [our other projects](https://serokell.io/community?utm_source=github) or [hire us](https://serokell.io/hire-us?utm_source=github) to design, develop and grow your idea!
