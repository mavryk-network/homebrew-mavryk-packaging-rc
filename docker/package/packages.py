# SPDX-FileCopyrightText: 2020 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ
import os, shutil, sys, subprocess, json

from .model import Service, ServiceFile, SystemdUnit, Unit, OpamBasedPackage, MavrykSaplingParamsPackage

networks = ["mainnet"]

signer_units = [
    SystemdUnit(
        ServiceFile(Unit(after=["network.target"],
                         description="Mavryk signer daemon running over TCP socket"),
                    Service(environment_file="/etc/default/mavryk-signer-tcp",
                            environment=["ADDRESS=127.0.0.1", "PORT=8000", "TIMEOUT=1"],
                            exec_start="/usr/bin/mavryk-signer-start launch socket signer " \
                            + " --address ${ADDRESS} --port ${PORT} --timeout ${TIMEOUT}",
                            state_directory="tezos", user="tezos")),
        suffix="tcp",
        startup_script="mavryk-signer-start",
        config_file="mavryk-signer.conf"),
    SystemdUnit(
        ServiceFile(Unit(after=["network.target"],
                         description="Mavryk signer daemon running over UNIX socket"),
                    Service(environment_file="/etc/default/mavryk-signer-unix",
                            environment=["SOCKET="],
                            exec_start="/usr/bin/mavryk-signer-start launch local signer " \
                            + "--socket ${SOCKET}",
                            state_directory="tezos", user="tezos")),
        suffix="unix",
        startup_script="mavryk-signer-start",
        config_file="mavryk-signer.conf"),
    SystemdUnit(
        ServiceFile(Unit(after=["network.target"],
                         description="Mavryk signer daemon running over HTTP"),
                    Service(environment_file="/etc/default/mavryk-signer-http",
                            environment=["CERT_PATH=", "KEY_PATH=", "ADDRESS=127.0.0.1", "PORT=8080"],
                            exec_start="/usr/bin/mavryk-signer-start launch http signer " \
                            + "--address ${ADDRESS} --port ${PORT}",
                            state_directory="tezos", user="tezos")),
        suffix="http",
        startup_script="mavryk-signer-start",
        config_file="mavryk-signer.conf"),
    SystemdUnit(
        ServiceFile(Unit(after=["network.target"],
                         description="Mavryk signer daemon running over HTTPs"),
                    Service(environment_file="/etc/default/mavryk-signer-https",
                            environment=["CERT_PATH=", "KEY_PATH=", "ADDRESS=127.0.0.1", "PORT=8080"],
                            exec_start="/usr/bin/mavryk-signer-start launch https signer " \
                            + "${CERT_PATH} ${KEY_PATH} --address ${ADDRESS} --port ${PORT}",
                            state_directory="tezos", user="tezos")),
        suffix="https",
        startup_script="mavryk-signer-start",
        config_file="mavryk-signer.conf")
]

packages = [
    OpamBasedPackage("mavryk-client",
                     "CLI client for interacting with tezos blockchain",
                     optional_opam_deps=["tls", "ledgerwallet-tezos"],
                     requires_sapling_params=True),
    OpamBasedPackage("mavryk-admin-client",
                     "Administration tool for the node",
                     optional_opam_deps=["tls"]),
    OpamBasedPackage("mavryk-signer",
                     "A client to remotely sign operations or blocks",
                     optional_opam_deps=["tls", "ledgerwallet-tezos"],
                     systemd_units=signer_units),
    OpamBasedPackage("mavryk-codec",
                     "A client to decode and encode JSON")
]

postinst_steps_common = '''
useradd --home-dir /var/lib/tezos tezos || true
'''


def mk_node_unit(suffix, env, desc):
    service_file = ServiceFile(Unit(after=["network.target"], requires=[],
                                    description=desc),
                               Service(environment=env,
                                       exec_start="/usr/bin/mavryk-node-start",
                                       state_directory="tezos", user="tezos"
                               ))
    return SystemdUnit(suffix=suffix, service_file=service_file, startup_script="mavryk-node-start")


# v8.2 mavryk-node doesn't have predefined config for edo2net, so we're providing
# this config to the service manually
edo2net_config = '''{
"p2p": {},
"network":
    { "genesis":
        { "timestamp": "2021-02-11T14:00:00Z",
          "block": "BLockGenesisGenesisGenesisGenesisGenesisdae8bZxCCxh",
          "protocol": "PtYuensgYBb3G3x1hLLbCmcav8ue8Kyd2khADcL5LsT5R1hcXex" },
      "genesis_parameters":
        { "values":
            { "genesis_pubkey":
                "edpkugeDwmwuwyyD3Q5enapgEYDxZLtEUFFSrvVwXASQMVEqsvTqWu" } },
      "chain_name": "MAVRYK_EDO2NET_2021-02-11T14:00:00Z",
      "sandboxed_chain_name": "SANDBOXED_MAVRYK",
      "default_bootstrap_peers":
        [ "edonet.tezos.co.il", "188.40.128.216:29732", "edo2net.kaml.fr",
          "edonet2.smartpy.io", "51.79.165.131", "edonetb.boot.tezostaquito.io" ] }
}
'''

node_units = []
node_postinst_steps = postinst_steps_common
common_node_env = ["NODE_RPC_ADDR=127.0.0.1:8732", "CERT_PATH=", "KEY_PATH="]
for network in networks:
    env = [f"DATA_DIR=/var/lib/tezos/node-{network}", f"NETWORK={network}"] + common_node_env
    node_units.append(mk_node_unit(suffix=network, env=env, desc=f"Mavryk node {network}"))
    node_postinst_steps += f'''mkdir -p /var/lib/tezos/node-{network}
[ ! -f /var/lib/tezos/node-{network}/config.json ] && mavryk-node config init --data-dir /var/lib/tezos/node-{network} --network {network}
chown -R tezos:tezos /var/lib/tezos/node-{network}
'''

# Add custom config service
node_units.append(mk_node_unit(suffix="custom", env=["DATA_DIR=/var/lib/tezos/node-custom",
                                                     "CUSTOM_NODE_CONFIG="] + common_node_env,
                               desc="Mavryk node with custom config"))
node_postinst_steps += "mkdir -p /var/lib/tezos/node-custom\n"

# Add edo2net service
node_units.append(mk_node_unit(suffix="edo2net", env=common_node_env + ["DATA_DIR=/var/lib/tezos/node-edo2net"],
                               desc="Mavryk node edo2net"))

node_postinst_steps += f'''mkdir -p /var/lib/tezos/node-edo2net
rm -f /var/lib/tezos/node-edo2net/config.json
cat > /var/lib/tezos/node-edo2net/config.json <<- EOM
{edo2net_config}
EOM
chown -R tezos:tezos /var/lib/tezos/node-edo2net
'''

packages.append(OpamBasedPackage("mavryk-node",
                                 "Entry point for initializing, configuring and running a Mavryk node",
                                 node_units,
                                 optional_opam_deps=[
                                     "mavryk-embedded-protocol-001-PtCJ7pwo",
                                     "mavryk-embedded-protocol-002-PsYLVpVv",
                                     "mavryk-embedded-protocol-003-PsddFKi3",
                                     "mavryk-embedded-protocol-004-Pt24m4xi",
                                     "mavryk-embedded-protocol-005-PsBABY5H",
                                     "mavryk-embedded-protocol-005-PsBabyM1",
                                     "mavryk-embedded-protocol-006-PsCARTHA"],
                                 requires_sapling_params=True,
                                 postinst_steps=node_postinst_steps))

active_protocols = json.load(open(f"{os.path.dirname( __file__)}/../../protocols.json", "r"))["active"]

daemons = ["baker", "accuser", "endorser"]

daemon_decs = {
    "baker": "daemon for baking",
    "accuser": "daemon for accusing",
    "endorser": "daemon for endorsing"
}

daemon_postinst = postinst_steps_common + "\nmkdir -p /var/lib/tezos/.mavryk-client\nchown -R tezos:tezos /var/lib/tezos/.mavryk-client\n"

for proto in active_protocols:
    service_file_baker = ServiceFile(Unit(after=["network.target"],
                                          description="Mavryk baker"),
                                     Service(environment_file=f"/etc/default/mavryk-baker-{proto}",
                                             environment=[f"PROTOCOL={proto}"],
                                             exec_start="/usr/bin/mavryk-baker-start",
                                             state_directory="tezos", user="tezos"))
    service_file_accuser = ServiceFile(Unit(after=["network.target"],
                                            description="Mavryk accuser"),
                                       Service(environment_file=f"/etc/default/mavryk-accuser-{proto}",
                                               environment=[f"PROTOCOL={proto}"],
                                               exec_start="/usr/bin/mavryk-accuser-start",
                                               state_directory="tezos", user="tezos"))
    service_file_endorser = ServiceFile(Unit(after=["network.target"],
                                             description="Mavryk endorser"),
                                        Service(environment_file=f"/etc/default/mavryk-endorser-{proto}",
                                                environment=[f"PROTOCOL={proto}"],
                                                exec_start="/usr/bin/mavryk-endorser-start",
                                                state_directory="tezos", user="tezos"))
    packages.append(OpamBasedPackage(f"mavryk-baker-{proto}", "Daemon for baking",
                                     [SystemdUnit(service_file=service_file_baker,
                                                  startup_script="mavryk-baker-start",
                                                  config_file="mavryk-baker.conf")],
                                     proto,
                                     optional_opam_deps=["tls", "ledgerwallet-tezos"],
                                     requires_sapling_params=True,
                                     postinst_steps=daemon_postinst))
    packages.append(OpamBasedPackage(f"mavryk-accuser-{proto}", "Daemon for accusing",
                                     [SystemdUnit(service_file=service_file_accuser,
                                                  startup_script="mavryk-accuser-start",
                                                  config_file="mavryk-accuser.conf")],
                                     proto,
                                     optional_opam_deps=["tls", "ledgerwallet-tezos"],
                                     postinst_steps=daemon_postinst))
    packages.append(OpamBasedPackage(f"mavryk-endorser-{proto}", "Daemon for endorsing",
                                     [SystemdUnit(service_file=service_file_endorser,
                                                  startup_script="mavryk-endorser-start",
                                                  config_file="mavryk-endorser.conf")],
                                     proto,
                                     optional_opam_deps=["tls", "ledgerwallet-tezos"],
                                     postinst_steps=daemon_postinst))

packages.append(MavrykSaplingParamsPackage())
