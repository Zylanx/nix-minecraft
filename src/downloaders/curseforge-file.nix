{ pkgs }:
let
    downloadCurseFile = {name, projectId, fileId, hash ? "", hashAlgo ? ""}:
        let
            inherit (builtins) toString;

            _hash =
                if (hash != "" && hashAlgo != "") then { outputHashAlgo = hashAlgo; outputHash = hash; }
                else if (hash != "") then { outputHashAlgo = null; outputHash = hash; }
                else { outputHashAlgo = "sha256"; outputHash = ""; };
        in
            pkgs.runCommandLocal "curseforge-mod-${name}"
                {
                    inherit (_hash) outputHashAlgo outputHash;
                    
                    nativeBuildInputs = [ pkgs.curl pkgs.jq ];
            
                    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
                }
                ''
                    echo "Getting file information..."
                    local url=$(curl -Ls --globoff 'https://api.curse.tools/v1/cf/mods/${toString projectId}/files/${toString fileId}' | jq -r '.data.downloadUrl')
                    echo "Downloading from: $url"
                    echo 
                    curl -L --globoff -o "$out" "$url"
                '';

    downloadTo = args@{ path, name, ... }: pkgs.linkFarm name [ { name = path; path = downloadCurseFile (removeAttrs args [ "path" ]); } ];
in
    {
        downloadRaw = downloadCurseFile;

        download = downloadTo;
    }
