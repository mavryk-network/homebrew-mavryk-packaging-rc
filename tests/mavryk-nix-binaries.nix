# SPDX-FileCopyrightText: 2020 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ
let
  nixpkgs = (import ../nix/nix/sources.nix).nixpkgs;
  pkgs = import ../nix/build/pkgs.nix {};
  inherit (pkgs.ocamlPackages) mavryk-client mavryk-admin-client mavryk-node mavryk-signer mavryk-codec
    mavryk-accuser-007-PsDELPH1 mavryk-baker-007-PsDELPH1 mavryk-endorser-007-PsDELPH1;
in import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ ... }:
{
  nodes.machine = { ... }: {
    virtualisation.memorySize = 1024;
    virtualisation.diskSize = 1024;
    environment.systemPackages = with pkgs; [
      libev
    ];
    environment.sessionVariables.LD_LIBRARY_PATH =
      [ "${pkgs.ocamlPackages.hacl-star-raw}/lib/ocaml/4.09.1/site-lib/hacl-star-raw" ];
  };

  testScript = ''
    mavryk_accuser = "${mavryk-accuser-007-PsDELPH1}/bin/mavryk-accuser-007-PsDELPH1"
    mavryk_admin_client = "${mavryk-admin-client}/bin/mavryk-admin-client"
    mavryk_baker = "${mavryk-baker-007-PsDELPH1}/bin/mavryk-baker-007-PsDELPH1"
    mavryk_client = (
        "${mavryk-client}/bin/mavryk-client"
    )
    mavryk_endorser = "${mavryk-endorser-007-PsDELPH1}/bin/mavryk-endorser-007-PsDELPH1"
    mavryk_node = "${mavryk-node}/bin/mavryk-node"
    mavryk_signer = (
        "${mavryk-signer}/bin/mavryk-signer"
    )
    mavryk_codec = "${mavryk-codec}/bin/mavryk-codec"
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
})
