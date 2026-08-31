{
  description = "My NixOS and nix-darwin configurations";

  inputs = {
    # nixos-unstable with patches/nixpkgs applied.
    nixpkgs.url = "github:Sirius902/nixpkgs/nixos-config";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/Sirius902/nixos-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.sops-nix.follows = "sops-nix";
    };
    nvim-conf.url = "github:Sirius902/nvim-conf";
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      flake = {
        lib = import ./lib/default.nix {inherit inputs;};

        nixosConfigurations = {
          sirius-lee = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "sirius-lee";
          };

          nixtower = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "nixtower";
          };

          hee-ho = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "hee-ho";
          };

          iso = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "iso";
            setHostName = false;
          };

          netboot = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "netboot";
            setHostName = false;
          };

          raspberrypi = self.lib.nixosSystem {
            system = "aarch64-linux";
            host = "raspberrypi";
          };

          sd = self.lib.nixosSystem {
            system = "aarch64-linux";
            host = "sd";
            setHostName = false;
          };
        };

        darwinConfigurations = {
          Tralsebook-V2 = self.lib.darwinSystem {
            system = "aarch64-darwin";
            host = "Tralsebook-V2";
          };

          The-Rekening = self.lib.darwinSystem {
            system = "aarch64-darwin";
            host = "The-Rekening";
          };
        };
      };

      perSystem = {
        config,
        system,
        ...
      }: let
        pkgs = import inputs.nixpkgs (self.lib.nixpkgsConfig system);
        inherit (pkgs) lib;

        allPackages = import ./pkgs/all-packages.nix {inherit pkgs;};
        overlayNames = let
          overlays = import ./overlays/default.nix {inherit inputs;};
          tryGetNames = o: let
            result = builtins.tryEval (builtins.attrNames (o {} pkgs));
          in
            if result.success
            then result.value
            else [];
        in
          lib.unique (builtins.concatMap tryGetNames overlays);
        overlayPackages = let
          isDerivation = name: let
            result = builtins.tryEval (lib.isDerivation pkgs.${name});
          in
            result.success && result.value;
        in
          lib.genAttrs (builtins.filter isDerivation overlayNames) (name: pkgs.${name});

        packageSet =
          (lib.mapAttrs (name: _: pkgs.${name}) allPackages)
          // overlayPackages
          // {inherit (pkgs.graalvmPackages) graalvm-ce_8;};
      in {
        formatter = pkgs.alejandra;

        apps = {
          update = {
            type = "app";
            program = let
              mkUpdate = attr: drv:
                if isOurUpdate attr drv
                then let
                  injectArgs = cmd:
                    lib.replaceString "/bin/nix-update" ''/bin/nix-update "--flake" "--commit" "${attr}"''
                    (toString cmd);

                  cmd = injectArgs (lib.escapeShellArgs (lib.toList (drv.updateScript.command or drv.updateScript)));
                in ''
                  update_${attr}() {
                    ${cmd}
                  }
                ''
                else "";

              isOurUpdate = _: drv: let
                passthru = drv.passthru or {};
                updatePos = builtins.unsafeGetAttrPos "updateScript" passthru;
              in
                updatePos != null && lib.hasPrefix (toString ./.) updatePos.file;
              updatableAttrs = lib.attrNames (lib.filterAttrs isOurUpdate config.legacyPackages);
            in
              lib.getExe (pkgs.writeShellScriptBin "update" ''
                set -euo pipefail

                ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkUpdate config.legacyPackages)}

                updatable_attrs=(${lib.concatMapStringsSep " " lib.escapeShellArg updatableAttrs})

                git_bin=${lib.escapeShellArg (lib.getExe pkgs.gitMinimal)}
                repo_root="$("$git_bin" rev-parse --show-toplevel)"
                cd "$repo_root"

                worktree_status() {
                  "$git_bin" -C "$repo_root" status --porcelain=v1 --untracked-files=all
                }

                status="$(worktree_status)"
                if [[ -n "$status" ]]; then
                  echo "error: package updates require a clean worktree" >&2
                  exit 1
                fi

                run_update() {
                  local attr="$1"
                  local status
                  "update_$attr"

                  status="$(worktree_status)"
                  if [[ -n "$status" ]]; then
                    echo "error: updater '$attr' left the worktree dirty" >&2
                    exit 1
                  fi
                }

                if [ "$#" -eq 0 ]; then
                  for attr in "''${updatable_attrs[@]}"; do
                    run_update "$attr"
                  done
                else
                  for pattern in "$@"; do
                    if [[ "$pattern" == *[\*\?\[]* ]]; then
                      matched=0
                      for attr in "''${updatable_attrs[@]}"; do
                        if [[ "$attr" == $pattern ]]; then
                          run_update "$attr"
                          matched=1
                        fi
                      done
                      if [ "$matched" -eq 0 ]; then
                        echo "error: no packages matched '$pattern'" >&2
                        exit 1
                      fi
                    else
                      if declare -F "update_$pattern" >/dev/null; then
                        run_update "$pattern"
                      else
                        echo "error: unknown or non-updatable attr '$pattern'" >&2
                        exit 1
                      fi
                    fi
                  done
                fi
              '');
            meta.description = "Updates packages and overlays for this flake.";
          };
        };

        legacyPackages =
          packageSet
          // {
            deck-games = pkgs.linkFarm "deck-games" {
              inherit
                (pkgs)
                _2ship2harkinian
                dusklight
                dusklight-rando
                dusklight-ap
                shipwright
                shipwright-ap
                xash3d-fwgs
                zelda64recomp
                ;
            };
          };

        # Keep unavailable packages out of `nix flake check`.
        packages = lib.filterAttrs (_: p: p.meta.available or true) packageSet;

        checks.deadnix = pkgs.runCommandLocal "deadnix-check" {} ''
          ${lib.getExe pkgs.deadnix} --fail ${self}
          touch $out
        '';

        checks.mypy = let
          python = pkgs.python3.withPackages (ps: [ps.mypy ps.httpx ps.mpyq]);
        in
          pkgs.runCommandLocal "mypy-check" {} ''
            export MYPY_CACHE_DIR="$(mktemp -d)"
            ${python}/bin/mypy --config-file ${self}/mypy.ini ${self}
            touch $out
          '';

        # Enforce the fetched patch conventions in docs/patches.md.
        checks.patch-urls = pkgs.runCommandLocal "patch-urls-check" {} ''
          status=0

          check() {
            local reason="$1" pattern="$2"
            local hits
            if hits="$(grep -rnE --include='*.nix' -e "$pattern" -- ${self})"; then
              echo "error: $reason" >&2
              echo "$hits" | sed 's|^${self}/|  |' >&2
              status=1
            fi
          }

          check "use fetchpatch (v1), which strips the unstable index lines v2 keeps" \
            '\bfetchpatch2\b'
          check "GitHub patch URLs take no query parameters" \
            'https://github\.com/[^"]*\?'
          check "pin a commit SHA instead of a pull request URL, which follows the branch" \
            'https://github\.com/[^"]*/pull/[0-9]+\.(diff|patch)'
          check "fetch GitHub patches as .diff, not .patch" \
            'https://github\.com/[^"]*\.patch'

          if [ "$status" -ne 0 ]; then
            echo "see docs/patches.md" >&2
            exit 1
          fi

          touch $out
        '';

        checks.ruff = pkgs.runCommandLocal "ruff-check" {} ''
          ${lib.getExe pkgs.ruff} check --config ${self}/ruff.toml ${self}
          touch $out
        '';

        checks.shellcheck = pkgs.runCommandLocal "shellcheck-check" {} ''
          find ${self} -name '*.sh' -exec ${lib.getExe pkgs.shellcheck} {} +
          touch $out
        '';

        checks.statix = pkgs.runCommandLocal "statix-check" {} ''
          ${lib.getExe pkgs.statix} check ${self} --config ${self}/statix.toml
          touch $out
        '';

        devShells.default = pkgs.mkShell {
          packages = [pkgs.just pkgs.statix];
        };
      };
    };
}
