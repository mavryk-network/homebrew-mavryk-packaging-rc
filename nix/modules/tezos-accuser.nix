# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

{config, lib, pkgs, ...}:

with lib;

let
  tezos-accuser-pkgs = {
    "012-Psithaca" =
      "${pkgs.ocamlPackages.tezos-accuser-012-Psithaca}/bin/tezos-accuser-012-Psithaca";
  };
  cfg = config.services.tezos-accuser;
  common = import ./common.nix { inherit lib; inherit pkgs; };
  instanceOptions = types.submodule ( {...} : {
    options = common.daemonOptions // {

      enable = mkEnableOption "Tezos accuser service";

    };
  });

in {
  options.services.tezos-accuser = {
    instances = mkOption {
      type = types.attrsOf instanceOptions;
      description = "Configuration options";
      default = {};
    };
  };
  config =
    let accuser-script = node-cfg: ''
        ${tezos-accuser-pkgs.${node-cfg.baseProtocol}} -d "$STATE_DIRECTORY/client/data" \
        -E "http://localhost:${toString node-cfg.rpcPort}" \
        run "$@"
      '';
    in common.genDaemonConfig cfg.instances "accuser" tezos-accuser-pkgs accuser-script;
}
