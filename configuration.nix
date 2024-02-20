{
  imports = [ ./access.nix ./bootloader.nix ./vm.nix ];

  nixpkgs.localSystem.system = "x86_64-linux";

  system.stateVersion = "23.11";
}
