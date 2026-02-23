{
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.mattermost ];

  networking.firewall.allowedTCPPorts = [ 8065 ];

  services.mattermost = {
    enable = true;
    siteUrl = "https://mattermost.kiva.lgbt";
    host = "0.0.0.0";
    port = 8065;
  };
}
