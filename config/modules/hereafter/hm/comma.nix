{
  config,
  lib,
  inputs,
  ...
}:

/*
  Comma (,) allows running software without installing it first:
  , hello # Runs hello from nixpkgs
  , vim file.txt # Opens file.txt in vim
  , node --version # Checks node version
  Uses nix-index database to find and run packages on-demand and wraps in nix shell -c
*/
let
  cfg = config;
in
{
  imports = [
     inputs.nix-index-database.homeModules.nix-index
    # handles both local build and template flake
    # (
    #   if inputs ? nix-index-database then
       
    #   else
    #     inputs.hydenix.inputs.nix-index-database.homeModules.nix-index
    # )
  ];

#   options.hydenix.hm.comma = {
#     enable = lib.mkOption {
#       type = lib.types.bool;
#       default = config.hydenix.hm.enable;
#       description = "Enable comma module";
#     };
#   };

#   config = lib.mkIf cfg.enable {
  config = {
    programs.nix-index-database.comma.enable = true;
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    #   enableBashIntegration = config.hydenix.hm.shell.bash.enable;
    #   enableFishIntegration = config.hydenix.hm.shell.fish.enable;
    };
  };
}
