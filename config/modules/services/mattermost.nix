{
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.mattermost ];

  networking.firewall.allowedTCPPorts = [ 8065 ];

  containers.mattermost = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.67.1";
    localAddress = "192.168.67.2";
    config =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        services.mattermost = {
          enable = true;
          siteUrl = "https://mattermost.kiva.lgbt";
          host = "0.0.0.0";
          port = 8065;
        };

        system.stateVersion = "25.11";
        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [ 8065 ];
          };
        };
      };
  };
}
