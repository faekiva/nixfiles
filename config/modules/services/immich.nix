{
  pkgs,
  ...
}:
{
  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = true;
  };

}
