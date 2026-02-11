{
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.mattermost ];

  services.mattermost = {
    enable = true;
    siteUrl = "https://mattermost.kiva.lgbt";
  };
}
