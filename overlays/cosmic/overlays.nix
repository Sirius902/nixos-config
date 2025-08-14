{
  cosmic-applets = final: prev:
    prev.cosmic-applets.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-13";

      src = prevAttrs.src.override {
        tag = null;
        rev = "467716c1678b7ec33e0b836e5bda1970de0c452a";
        hash = "sha256-kgzGMni8neCz6cFtBYd26xvotq6ezBKJtTAHMTF/mEU=";
      };

      cargoHash = "sha256-mpwBsBlA53OCoG1xT+YQzKrzpCDnec7ImJfZEfBrndw=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-applibrary = final: prev:
    prev.cosmic-applibrary.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-01";

      src = prevAttrs.src.override {
        tag = null;
        rev = "efb4cce330c61578fff10b57ed04e225d2dca91c";
        hash = "sha256-XiYrch2vhBWik8WDhJRBZi3FlUYDZSZKYni0r/Wri2s=";
      };

      cargoHash = "sha256-Jw8XvrMMIGzioMxNUWXV+hfu6fGu0vpvS7dAmJwo7SU=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-bg = final: prev:
    prev.cosmic-bg.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-05-01";

      src = prevAttrs.src.override {
        tag = null;
        rev = "1da843a63656cf58b373a4823c15326be448b24e";
        hash = "sha256-x/nCEiE+tGAlgAOJKT+zpi3fMJt9cTx0mFteibdC9FE=";
      };

      cargoHash = "sha256-GLXooTjcGq4MsBNnlpHBBUJGNs5UjKMQJGJuj9UO2wk=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  # TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
  cosmic-comp = final: prev:
    prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-13";

      src = prevAttrs.src.override {
        tag = null;
        rev = "0095b6d505fe45e7e09f980cbf48fff1800a9d79";
        hash = "sha256-LPHCFiabMHOokcQG6ZN5JFvlrBp5QTo1CC3PQu+FZRw=";
      };

      cargoHash = "sha256-XyiPpYVqk9y1V+0R0zIHXxLuao8qS8o8ZGTqp8+32PE=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-edit = final: prev:
    prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-13";

      src = prevAttrs.src.override {
        tag = null;
        rev = "3c9d2a077e1fdec663c535d0a9dc0939edfe13b3";
        hash = "sha256-+Eke1rt8sQITTrDb2jayAHNWHIe4bD+ZozSXo1HhwrM=";
      };

      cargoHash = "sha256-/cA9t2npFZqWcMD+0KmFfS7lV2Qu5fHkTH18csIUQ+E=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      buildInputs = (prevAttrs.buildInputs or []) ++ [final.glib];

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-ext-calculator = final: prev:
    prev.cosmic-ext-calculator.overrideAttrs (finalAttrs: prevAttrs: {
      version = "0.1.1-unstable-2025-05-17";

      src = prevAttrs.src.override {
        tag = null;
        rev = "277343ec73ae00d5d350a8993d1b5a5c46f3fbcd";
        hash = "sha256-IArtmgDhWfdHbIrHA2aOwamFjyqgFrYW9Tj8Sx/+WQo=";
      };

      cargoHash = "sha256-HVe/Ry6dvG1VSKQyND5yqhB6YAS3+eRvwyXCsaQQXww=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {};
        };
    });

  cosmic-ext-ctl = final: prev:
    prev.cosmic-ext-ctl.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.5.0-unstable-2025-05-02";

      src = prevAttrs.src.override {
        tag = null;
        rev = "08b4e26ceddcba8d3df8df29ae865055a5bc3a04";
        hash = "sha256-URqNhkC1XrXYxr14K6sT3TLso38eWLMA+WplBdj52Vg=";
      };

      cargoHash = "sha256-OL1LqOAyIFFCGIp3ySdvEXJ1ECp9DgC/8mfAPo/E7k4=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru.updateScript = final.nix-update-script {};
    });

  cosmic-ext-tweaks = final: prev:
    prev.cosmic-ext-tweaks.overrideAttrs (finalAttrs: prevAttrs: {
      version = "0.1.3-unstable-2025-06-18";

      src = prevAttrs.src.override {
        tag = null;
        rev = "3d212df083d5c3f0cfb9d56929edcc69962e008d";
        hash = "sha256-1ITB1PnTER2dGuH/L/NDuiJmBxTN9hpau2um5tPh1Rg=";
      };

      cargoHash = "sha256-FJg9AuOSNwDHfqO838Vg3OMWr2I6EMGQoUb5YeXOJ0A=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {};
        };
    });

  cosmic-files = final: prev:
    prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-13";

      src = prevAttrs.src.override {
        tag = null;
        rev = "b3a6d14bc63ebec6aae5ee5d20c12b967cecbbc5";
        hash = "sha256-CKsVnNgHhJBjAJU0kD/zBHd8WBMx2zbffxRYisnYY0k=";
      };

      cargoHash = "sha256-TDXo0PsDLIBewAasBK82VsG1O0lPqY6g3dBRFsGzF6A=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru.updateScript = final.nix-update-script {
        extraArgs = [
          "--version-regex"
          "epoch-(.*)"
        ];
      };
    });

  cosmic-greeter = final: prev:
    prev.cosmic-greeter.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-12";

      src = prevAttrs.src.override {
        tag = null;
        rev = "7317353a32f9ed831423819d620775d4bad1db2f";
        hash = "sha256-2MfbtEVTarhsHM3zjX1csHU/nPkxiZLT1F6bmNPrkBI=";
      };

      cargoHash = "sha256-X/tSofi4aNtA5MeWCy03Tnnz3AxIF8MCZ7ofeMSWNCc=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-icons = final: prev:
    prev.cosmic-icons.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-03-21";

      src = prevAttrs.src.override {
        tag = null;
        rev = "0b2aed444daa52c65effbb8e71a8a19b0f2e4cb9";
        hash = "sha256-KDmEYeuiDTYvqg2XJK8pMDfsmROKtN+if5Qxz57H5xs=";
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-idle = final: prev:
    prev.cosmic-idle.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-02-25";

      src = prevAttrs.src.override {
        tag = null;
        rev = "267bb837f127eb805a17250ebcad02db57eb72cb";
        hash = "sha256-dRvcow+rZ4sJV6pBxRIw6SCmU3aXP9uVKtFEJ9vozzI=";
      };

      cargoHash = "sha256-iFR0kFyzawlXrWItzFQbG/tKGd3Snwk/0LYkPzCkJUQ=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-launcher = final: prev:
    prev.cosmic-launcher.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-07-29";

      src = prevAttrs.src.override {
        tag = null;
        rev = "2831b8c5faf6297f64d2a90d8edd48a7efbcdf77";
        hash = "sha256-m8AAsbptnCd5gHNIBCoy4+5IjXW3eui24dnHY4qoS0E=";
      };

      cargoHash = "sha256-57rkCufJPWm844/iMIfULfaGR9770q8VgZgnqCM57Zg=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-notifications = final: prev:
    prev.cosmic-notifications.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-07-25";

      src = prevAttrs.src.override {
        tag = null;
        rev = "744439a6e79f7bcb74ba861d525318f9b774c7f5";
        hash = "sha256-Yymjsj+3aeaP8pv4jO2VKVOrADE2sBVar92ElVVUJgw=";
      };

      cargoHash = "sha256-3rBbjAVdpNKYBHOrI/Zsb4Q5J9Xx4ddeCpzsUK51mns=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-osd = final: prev:
    prev.cosmic-osd.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-07-24";

      src = prevAttrs.src.override {
        tag = null;
        rev = "78e4f7c7b2708b49460342932a22885b8cd7e0cc";
        hash = "sha256-VsZ+FjxClv5oEVmA1Zj28pgNj51vp/RyfylAx3yY01s=";
      };

      cargoHash = "sha256-C+R2XgWtErznv6TQZ9eke9/ZNiRUVparP5yHu9442wA=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  # TODO(Sirius902) Overlay new cosmic-panel to avoid crashes when disconnecting displays
  # until the nixos-unstable version is newer.
  cosmic-panel = final: prev:
    prev.cosmic-panel.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-12";

      src = prevAttrs.src.override {
        tag = null;
        rev = "9da7dc180f87613aa7edae5e9e692d695ffdde3f";
        hash = "sha256-LNkCqR6KKQt3tjaj5qXJ2my8nY4sS6yx3+MWhfQpaoA=";
      };

      cargoHash = "sha256-VlEbbQTAX05zJYURZym4bBhCtbQ85ujvqLMQNHSz23o=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-player = final: prev:
    prev.cosmic-player.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-13";

      src = prevAttrs.src.override {
        tag = null;
        rev = "21866486bd207e7654a19ede7829bf5eb35b5475";
        hash = "sha256-Misdcb/szhvdEp5ZR0EmGCWKShLGbXd/OkMB3rjmCu8=";
      };

      cargoHash = "sha256-0RrtErTR2J5mn/Lfppk+5X8UUOC2LN65krAq1uz/O4M=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-protocols = final: prev:
    prev.cosmic-protocols.overrideAttrs (finalAttrs: prevAttrs: {
      version = "0-unstable-2025-08-12";

      src = prevAttrs.src.override {
        tag = null;
        rev = "8e84152fedf350d2756a2c1c90e07313acb9cdf6";
        hash = "sha256-rFoSSc2wBNiW8wK3AIKxyv28FNTEiGk6UWjp5dQVxe8=";
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            # FUTURE(Sirius902) From nixos-cosmic: "add if upstream ever makes a tag"
            # extraArgs = [
            #   "--version-regex"
            #   "epoch-(.*)"
            # ];
          };
        };
    });

  cosmic-randr = final: prev:
    prev.cosmic-randr.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-12";

      src = prevAttrs.src.override {
        tag = null;
        rev = "f2cf6dfe9af22c005018b1aa952347dcc1d80b1c";
        hash = "sha256-fKGKp00otdGxz64xdhDQ1/IkAqV/69ikfr4a8SK/6T4=";
      };

      cargoHash = "sha256-lW44Y7RhA1l+cCDwqSq9sbhWi+kONJ0zy1fUu8WPYw0=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-screenshot = final: prev:
    prev.cosmic-screenshot.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-05-02";

      src = prevAttrs.src.override {
        tag = null;
        rev = "f7d066971061b530cdff56281351af0feee72a59";
        hash = "sha256-0gycikRbCykenfCZ+WNNvKNjhaowOUDHPXjTwvCq+as=";
      };

      cargoHash = "sha256-1r0Uwcf4kpHCgWqrUYZELsVXGDzbtbmu/WFeX53fBiQ=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-session = final: prev:
    prev.cosmic-session.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-06-13";

      src = prevAttrs.src.override {
        tag = null;
        rev = "b2f42771222b1d0acd267355a83776abd465eff7";
        hash = "sha256-gGpDKPxlEcT8PA+9Pbktm49sI+gPTyVtPnuimqYALEk=";
      };

      cargoHash = "sha256-4leO8F32O4E+fqpR0/Nj5wBcY0N00J/JdsYnPwPCWps=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-settings-daemon = final: prev:
    prev.cosmic-settings-daemon.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-11";

      src = prevAttrs.src.override {
        tag = null;
        rev = "19f10525ff00d76558147ea060bd856a87122353";
        hash = "sha256-Uxl0Ku9O1HZCB+rHjNuZqKED9dVEAJph3XKWN8Vy5wM=";
      };

      cargoHash = "sha256-9BeC0Y29NOMoEJHKLV3aRHZQbglbLnnTH4uS3h129iw=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      buildInputs = (prevAttrs.buildInputs or []) ++ [final.openssl];

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-settings = final: prev:
    prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-13";

      src = prevAttrs.src.override {
        tag = null;
        rev = "6e67ff11e05b905df9572a4c713ebfd6ed2f9f8d";
        hash = "sha256-QF2CDrdhDmBmnn/vwDhkNo78AJZja4erJUMFqIum/FI=";
      };

      cargoHash = "sha256-LTdI5H7QbDKTqIoPwYsddxU/4ujJv8k2oXa2INIzeJw=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-store = final: prev:
    prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-13";

      src = prevAttrs.src.override {
        tag = null;
        rev = "8bfaa4ffc073df49dcc6e6001635b729141a3b38";
        hash = "sha256-vSazAZ5OTe7qn4hU1gdLl3Y9snSoRolMPxZEjybtrwA=";
      };

      cargoHash = "sha256-sTS3i25DGbpsEyXfb6DHbLa7s7QnnF4H5Xn1gLroKtY=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-term = final: prev:
    prev.cosmic-term.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-13";

      src = prevAttrs.src.override {
        tag = null;
        rev = "555e1aeee5ce8f573270e208bd01d38c1e766f6c";
        hash = "sha256-hUGlENXRX7TGuLzN5BLQxE9ut4ygh3iQHTPs08QZpgk=";
      };

      cargoHash = "sha256-GQUIluFtQbJ/6p9HLV+HIuh36sUQw71bEGK3eR1klVo=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-wallpapers = final: prev:
    prev.cosmic-wallpapers.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-04-08";

      src = prevAttrs.src.override {
        tag = null;
        rev = "189c2c63d31da84ebb161acfd21a503f98a1b4c7";
        hash = "sha256-XtNmV6fxKFlirXQvxxgAYSQveQs8RCTfcFd8SVdEXtE=";
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  cosmic-workspaces-epoch = final: prev:
    prev.cosmic-workspaces-epoch.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-06-26";

      src = prevAttrs.src.override {
        tag = null;
        rev = "30ca652b1e8c0e50ed5638e9023ceb48b2a82720";
        hash = "sha256-TzRed3tDflsgsZQwS+wJHWBYa8HA/l01s6XHpMI6ZyE=";
      };

      cargoHash = "sha256-wFX5EReAnZ7ymXYfMfiZU1MeUUCcOKEkWdSeyGHEuKg=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });

  pop-launcher = final: prev:
    prev.pop-launcher.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.2.4-unstable-2025-05-01";

      src = prevAttrs.src.override {
        tag = null;
        rev = "8d9da92dbae520b37ab93fc2364a01d7adbd2f29";
        hash = "sha256-HaSAGLE+sn/1yUEFhHrgf+d4IGMMXdlB2/FzIlj73og=";
      };

      cargoHash = "sha256-00ZGcdzq8Q4lvA/87wjtNbFAx/41Dar2L8K4f/a5xjg=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {};
        };
    });

  # TODO(Sirius902) Overlay new xdg-desktop-portal-cosmic to maybe fix clipboard shenanigans
  # until the nixos-unstable version is newer.
  xdg-desktop-portal-cosmic = final: prev:
    prev.xdg-desktop-portal-cosmic.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.0-alpha.7-unstable-2025-08-13";

      src = prevAttrs.src.override {
        tag = null;
        rev = "7e803d13e3b4d28f2954a628675dcc2be4f3765c";
        hash = "sha256-rxUVVvNlb3IjVfCeIIKzDecN1TDZ2WdmxVwdTngXMAI=";
      };

      cargoHash = "sha256-NQoqbfNEMWowo2KxdgKqTbn/BDgv218NFCCGYR9OAO0=";

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version-regex"
              "epoch-(.*)"
            ];
          };
        };
    });
}
