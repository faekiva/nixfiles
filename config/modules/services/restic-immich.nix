{
  config,
  inputs,
  ...
}:
{
  sops.secrets."restic/password" = {
    sopsFile = "${inputs.repoRoot}/secrets/restic.yaml";
  };
  sops.secrets."restic/s3-env" = {
    sopsFile = "${inputs.repoRoot}/secrets/restic.yaml";
  };

  services.restic.backups.immich = {
    # B2 S3-compatible endpoint — replace region and bucket as needed
    # Find your region in the B2 bucket settings (e.g. us-west-004)
    repository = "s3:https://s3.us-west-004.backblazeb2.com/restic-menagerie/immich";
    passwordFile = config.sops.secrets."restic/password".path;
    environmentFile = config.sops.secrets."restic/s3-env".path;

    paths = [
      "/var/lib/nixos-containers/immich/var/lib/immich"
    ];

    # Dump the Immich PostgreSQL DB into the media directory before backup,
    # so it gets snapshotted together with the library.
    backupPrepareCommand = ''
      nixos-container run immich -- \
        runuser -u postgres -- pg_dumpall \
        -f /var/lib/immich/db-dump.sql
    '';

    backupCleanupCommand = ''
      rm -f /var/lib/nixos-containers/immich/var/lib/immich/db-dump.sql
    '';

    pruneOpts = [
      "--keep-last 5"
    ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Ensure the container is running before the backup starts
  systemd.services.restic-backups-immich = {
    requires = [ "container@immich.service" ];
    after = [ "container@immich.service" ];
  };
}
