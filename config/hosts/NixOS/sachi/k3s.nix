{ pkgs, ... }:
# k3s node config for sachi (k8s node name: sacchan, cluster: gaia)
#
# Phase 0 DRAFT — do NOT import this from configuration.nix until Phase 1.
# See k8s/docs/migration-k0s-to-k3s.md for the full runbook.
{
  # ── k3s ────────────────────────────────────────────────────────────────────

  services.k3s = {
    enable = true;
    # Explicit minor-version pin so nixpkgs bumps don't silently upgrade k3s.
    package = pkgs.k3s_1_35;
    role = "server";
    extraFlags = toString [
      "--node-name=sacchan"
      "--disable=traefik"
      "--disable=servicelb"
      "--disable=local-storage"
    ];
  };

  # Write a k3s config snippet with the tailscale IP before k3s starts.
  # k3s merges /etc/rancher/k3s/config.yaml with CLI flags automatically.
  systemd.services.k3s-node-ip = {
    description = "Write k3s node-ip from tailscale";
    before = [ "k3s.service" ];
    requiredBy = [ "k3s.service" ];
    after = [ "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "k3s-node-ip" ''
        mkdir -p /etc/rancher/k3s
        echo "node-ip: $(${pkgs.tailscale}/bin/tailscale ip -4)" \
          > /etc/rancher/k3s/config.yaml
      '';
    };
  };

  # ── iSCSI initiator ────────────────────────────────────────────────────────
  # Longhorn exposes volumes as iSCSI targets; iscsid must be running on the
  # node before volumes can attach.

  services.openiscsi = {
    enable = true;
    name = "iqn.2026-04.lgbt.kiva:sacchan";
  };

  # ── Kernel modules ─────────────────────────────────────────────────────────

  boot.kernelModules = [
    "iscsi_tcp"   # iSCSI transport — required by Longhorn
    "dm_crypt"    # device-mapper crypto (Longhorn encrypted volumes)
    "br_netfilter" # bridge netfilter — required by k3s/flannel
    "overlay"     # overlayfs — required by container runtime
  ];

  # ── FHS path workaround for Longhorn ───────────────────────────────────────
  # longhorn-manager shells out to iscsiadm via `nsenter` into the host mount
  # namespace.  nsenter resolves binaries against the default FHS PATH
  # (/usr/local/sbin:/usr/local/bin:…); on NixOS, iscsiadm lives in the Nix
  # store, not on that PATH.  Additional helpers (dmsetup, nsenter itself) may
  # also need symlinking — verify with `longhornctl check preflight` after
  # first boot and add entries here as needed.

  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin/iscsiadm - - - - /run/current-system/sw/bin/iscsiadm"
  ];

  # ── Host packages ──────────────────────────────────────────────────────────

  environment.systemPackages = with pkgs; [
    nfs-utils   # NFS client helpers (NFS-backed PVs)
    cryptsetup  # dm-crypt / LUKS (Longhorn encrypted volumes)
    util-linux  # lsblk, losetup, etc. (Longhorn block device management)
  ];

  # ── Firewall ───────────────────────────────────────────────────────────────
  # All user-facing ingress flows through the Tailscale operator; only the k8s
  # API port needs to be reachable from the tailnet, and only for kubectl
  # access from the laptop.

  # k8s API server — intranet-accessible on all interfaces
  networking.firewall.allowedTCPPorts = [ 6443 ];

  # flannel VXLAN — single-node cluster; all inter-pod traffic stays local
  networking.firewall.interfaces."lo".allowedUDPPorts = [ 8472 ];
}
