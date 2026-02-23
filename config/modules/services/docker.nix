{
  #pkgs,
  ...
}:
{
  config = {
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
