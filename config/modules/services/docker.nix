{
  lib,
  config,
  ...
}:
let
  cfg = config.services.docker;
in
{
  options.services.docker = {
    enable = lib.mkEnableOption "Docker container runtime";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.docker.enableOnBoot = true;
    virtualisation.docker.daemon.settings = { 
      fixed-cidr-v6 = "fd00::/80"; 
      ipv6 = true; 
      live-restore = true; 
      log-driver = "json-file";
      log-opts = {
        max-size = "50m";
        max-file = "3";
      };
    };
  };
  
}
