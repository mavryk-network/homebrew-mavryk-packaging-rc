# SPDX-FileCopyrightText: 2020 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ
{ path-to-binaries ? null } @ args:
let
  nixpkgs = (import ../nix/nix/sources.nix).nixpkgs;
  pkgs = import ../nix/build/pkgs.nix {};
  zcash = import ../nix/build/zcash.nix {};
in import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ ... }:
{
  nodes.machine = { ... }: {
    virtualisation.memorySize = 1024;
    virtualisation.diskSize = 1024;
    environment.sessionVariables.XDG_DATA_DIRS =
      [ "${zcash}" ];
  };

  testScript = ''
    path_to_binaries = "${path-to-binaries}"
    mavryk_accuser = f"{path_to_binaries}/mavryk-accuser-008-PtEdo2Zk"
    mavryk_admin_client = f"{path_to_binaries}/mavryk-admin-client"
    mavryk_baker = f"{path_to_binaries}/mavryk-baker-008-PtEdo2Zk"
    mavryk_client = f"{path_to_binaries}/mavryk-client"
    mavryk_endorser = f"{path_to_binaries}/mavryk-endorser-008-PtEdo2Zk"
    mavryk_node = f"{path_to_binaries}/mavryk-node"
    mavryk_signer = f"{path_to_binaries}/mavryk-signer"
    mavryk_codec = f"{path_to_binaries}/mavryk-codec"
    openssl = "${pkgs.openssl.bin}/bin/openssl"
    binaries = [
        mavryk_accuser,
        mavryk_admin_client,
        mavryk_baker,
        mavryk_client,
        mavryk_endorser,
        mavryk_node,
        mavryk_signer,
        mavryk_codec,
    ]
    ${builtins.readFile ./test_script.py}'';
}) args
