{
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.immich ];

  networking.firewall.allowedTCPPorts = [ 2283 ];

  containers.immich = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.67.1";
    localAddress = "192.168.67.3";
    config =
      {
        # config,
        # pkgs,
        # lib,
        ...
      }:
      {
        services.immich = {
          enable = true;
          port = 2283;
          host = "0.0.0.0";
          openFirewall = true;
        };

        system.stateVersion = "25.11";
      };
    forwardPorts = [
      {
        containerPort = 2283;
        hostPort = 2283;
        protocol = "tcp";
      }
    ];
  };
}
