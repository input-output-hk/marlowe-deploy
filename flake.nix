{
  inputs = {
    # When updating past 23.11, use runtimeEnv in writeShellApplication
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    devenv.url = "github:cachix/devenv";
  };

  outputs = inputs@{ flake-parts, devenv, nixpkgs, self }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      imports = [ devenv.flakeModule ];
      systems = [ "x86_64-linux" ];
      flake.nixosConfigurations.marlowe = nixpkgs.lib.nixosSystem {
        modules = lib.singleton ./configuration.nix;
      };

      perSystem = { pkgs, ... }:
        let
          utilities = {
            start-vm = pkgs.writeShellApplication {
              name = "start-vm";
              text = ''
                export QEMU_NET_OPTS="hostfwd=tcp::2221-:22"
                exec run-nixos-vm
              '';
              runtimeInputs =
                [ self.nixosConfigurations.marlowe.config.system.build.vm ];
            };
          };
        in {
          apps =
            lib.mapAttrs (name: prog: { program = "${prog}/bin/${name}"; });
          devenv.shells.default = {
            pre-commit.hooks = {
              nixfmt.enable = true;
              deadnix.enable = true;
              statix.enable = true;
            };
            packages = with pkgs;
              [ nixos-rebuild ] ++ lib.mapAttrsToList (_: prog: prog) utilities;
          };
        };
    });
}
