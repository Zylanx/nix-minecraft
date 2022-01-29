# This file is part of nix-minecraft.

# nix-minecraft is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# nix-minecraft is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with nix-minecraft.  If not, see <https://www.gnu.org/licenses/>.

{ config, pkgs, lib, ... }:
let
  inherit (lib) mkOption types;
  cfg = config.minecraft;
in
{
  imports = [
    ./runners.nix
    ./downloaders.nix
  ];

  options.minecraft = {
    version = mkOption {
      example = "1.18";
      description = "The version of minecraft to use.";
      type = types.nonEmptyStr;
      default = config.internal.requiredMinecraftVersion;
    };
    hash = mkOption {
      description = ''
        The hash of the minecraft version.
        Leave it empty to have nix tell you what to use.
      '';
      type = types.str;
    };
  };

  config.internal =
    let
      package = pkgs.runCommandLocal "version.json"
        {
          outputHash = cfg.hash;
          outputHashAlgo = "sha256";
          nativeBuildInputs = [ pkgs.curl pkgs.jq ];
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        }
        ''
          url=$(
          curl -L 'http://launchermeta.mojang.com/mc/game/version_manifest_v2.json' \
          | jq -r '.versions[] | select(.id == "${cfg.version}") | .url'
          )
          curl -L -o $out $url
        '';
      normalized =
        pkgs.runCommand "package.json"
          {
            nativeBuildInputs = [ pkgs.jsonnet ];
          }
          ''
            jsonnet -J ${./jsonnet} --tla-str-file orig_str=${package} -o $out \
              ${./jsonnet/normalize.jsonnet}
          '';
      module = lib.importJSON normalized;
    in
    # tell nix what attrs to expect to avoid infinite recursion
    { inherit (module) minecraftArgs jvmArgs assets javaVersion libraries mainClass; };
}
