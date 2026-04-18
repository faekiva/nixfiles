{
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.navidrome ];

  networking.firewall.allowedTCPPorts = [ 4533 ];

  containers.navidrome = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.67.1";
    localAddress = "192.168.67.4";
    bindMounts."/music" = {
      hostPath = "/mnt/prodigy/mojo/audio/music/Abarat";
      isReadOnly = true;
    };
    config =
      { ... }:
      {
        services.navidrome = {
          enable = true;
          settings = {
            Address = "0.0.0.0";
            Port = 4533;
            MusicFolder = "/music";
          };
        };

        system.stateVersion = "25.11";
        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 4533 ];
        };
      };
    forwardPorts = [
      {
        containerPort = 4533;
        hostPort = 4533;
        protocol = "tcp";
      }
    ];
  };
}
