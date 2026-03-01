{ pkgs, lib, config, ... }:

{
  sops.secrets."jellyfin-backup-env" = {
    sopsFile = ../../secrets/backup.env;
    format = "dotenv";
  };

  sops.secrets."jellyfin-backup-password" = {
    sopsFile = ../../secrets/backup.env;
    format = "dotenv";
    key = "RESTIC_PASSWORD";
  };

  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };

  # Enable container name DNS for all Podman networks.
  networking.firewall.interfaces = let
    matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
  in {
    "${matchAll}".allowedUDPPorts = [ 53 ];
  };

  virtualisation.oci-containers.backend = "podman";

  systemd.tmpfiles.rules = [
    "d /var/lib/jellyfin/config 0755 root root -"
  ];

  # Containers
  virtualisation.oci-containers.containers."jellyfin" = {
    image = "jellyfin/jellyfin:10.11.6";
    volumes = [
      "/var/lib/jellyfin/config:/config:rw"
      "/mnt/prodigy:/prodigy:rw"
    ];
    ports = [
      "8097:8096/tcp"
      "8921:8920/tcp"
      "7359:7359/tcp"
      "1901:1900/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--device=/dev/dri/:/dev/dri/:rwm"
      "--dns=1.1.1.1"
      "--group-add=303"
      "--memory-reservation=268435456b"
      "--memory=8132755456b"
    ];
  };
  systemd.services."podman-jellyfin" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [ "jellyfin-restore.service" ];
    requires = [ "jellyfin-restore.service" ];
    wantedBy = [
      "multi-user.target"
    ];
  };

  # Auto-restore from backup if config dir is empty
  systemd.services."jellyfin-restore" = {
    description = "Restore Jellyfin config from restic backup if empty";
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.sops.secrets."jellyfin-backup-env".path;
    };
    script = ''
      if [ -z "$(ls -A /var/lib/jellyfin/config 2>/dev/null)" ]; then
        echo "Jellyfin config is empty, restoring latest backup..."
        ${pkgs.restic}/bin/restic \
          -r s3:s3.us-west-004.backblazeb2.com/restic-menagerie/jellyfin \
          -p ${config.sops.secrets."jellyfin-backup-password".path} \
          restore latest --target /
        echo "Restore complete."
      else
        echo "Jellyfin config exists, skipping restore."
      fi
    '';
  };

  # Restic backup for Jellyfin config
  services.restic.backups.jellyfin = {
    repository = "s3:s3.us-west-004.backblazeb2.com/restic-menagerie/jellyfin";
    passwordFile = config.sops.secrets."jellyfin-backup-password".path;
    environmentFile = config.sops.secrets."jellyfin-backup-env".path;
    paths = [ "/var/lib/jellyfin/config" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
      "--keep-yearly 2"
    ];
    backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop podman-jellyfin.service";
    backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start podman-jellyfin.service";
  };
}
