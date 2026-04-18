{
  pkgs,
  config,
  inputs,
  ...
}:
{
  environment.systemPackages = [ pkgs.navidrome ];

  networking.firewall.allowedTCPPorts = [ 4533 ];

  sops.secrets."navidrome/lastfm/apiKey" = {
    sopsFile = "${inputs.repoRoot}/secrets/navidrome.yaml";
  };
  sops.secrets."navidrome/lastfm/apiSecret" = {
    sopsFile = "${inputs.repoRoot}/secrets/navidrome.yaml";
  };
  sops.templates."navidrome.env".content = ''
    ND_LASTFM_APIKEY=${config.sops.placeholder."navidrome/lastfm/apiKey"}
    ND_LASTFM_SECRET=${config.sops.placeholder."navidrome/lastfm/apiSecret"}
  '';

  containers.navidrome = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.67.1";
    localAddress = "192.168.67.4";
    bindMounts."/music" = {
      hostPath = "/mnt/prodigy/mojo/audio/music/Abarat";
      isReadOnly = true;
    };
    bindMounts."/run/secrets/navidrome.env" = {
      hostPath = config.sops.templates."navidrome.env".path;
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

        systemd.services.navidrome.serviceConfig.EnvironmentFile = "/run/secrets/navidrome.env";

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
