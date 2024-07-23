# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ

let
  protocols = import ../protocols.nix;
  protocolsFormatted =
    builtins.concatStringsSep ", " (protocols.allowed ++ protocols.active);
in [
  {
    name = "mavryk-client";
    description = "CLI client for interacting with tezos blockchain";
    supports = protocolsFormatted;
  }
  {
    name = "mavryk-admin-client";
    description = "Administration tool for the node";
    supports = protocolsFormatted;
  }
  {
    name = "mavryk-node";
    description =
      "Entry point for initializing, configuring and running a Tezos node";
    supports = protocolsFormatted;
  }
  {
    name = "mavryk-signer";
    description = "A client to remotely sign operations or blocks";
    supports = protocolsFormatted;
  }
  {
    name = "mavryk-codec";
    description = "A client to decode and encode JSON";
    supports = protocolsFormatted;
  }
  {
    name = "mavryk-sandbox";
    description = "A tool for setting up and running testing scenarios with the local blockchain";
    supports = protocolsFormatted;
  }
] ++ builtins.concatMap (protocol: [
  {
    name = "mavryk-baker-${protocol}";
    description = "Daemon for baking";
    supports = protocol;
  }
  {
    name = "mavryk-accuser-${protocol}";
    description = "Daemon for accusing";
    supports = protocol;
  }
  {
    name = "mavryk-endorser-${protocol}";
    description = "Daemon for endorsing";
    supports = protocol;
  }
]) protocols.active
