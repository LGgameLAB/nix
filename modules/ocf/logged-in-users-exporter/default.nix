{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.ocf.logged-in-users-exporter;
in
{
  options.ocf.logged-in-users-exporter = {
    enable = mkEnableOption "Enable logged in users exporter for Prometheus (used by OCF Labmap)";
    interval = mkOption {
      type = types.int;
      default = 5;
    };
  };

  config = mkIf cfg.enable {
    environment.etc = {
      "prometheus_scripts/logged_in_users_exporter.sh" = {
        mode = "0555";
        text = builtins.readFile ./logged_in_users_exporter.sh;
      };
    };

    # Create the textfile collector directory
    systemd.tmpfiles.rules = [
      "d /var/lib/node_exporter/textfile_collector 0755 root root -"
      "d /etc/prometheus_scripts 0755 root root -"
      "z /etc/prometheus_scripts/logged_in_users_exporter.sh 0755 root root -"
    ];

    systemd.timers."logged_in_users_exporter" = {
      description = "Run logged_in_users_exporter.sh every 5 seconds";
      wantedBy = [ "multi-user.target" ];
      timerConfig = {
        OnBootSec = "5s";
        OnUnitActiveSec = "5s";
        Unit = "logged_in_users_exporter.service";
      };
    };

    systemd.services."logged_in_users_exporter" = {
      description = "Logged in users exporter";
      script = "bash /etc/prometheus_scripts/logged_in_users_exporter.sh";
      serviceConfig = {
        Environment = "PATH=/run/current-system/sw/bin";
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
    };

    services.prometheus = {
      exporters = {
        node = {
          enable = true;
          port = 9100;
          enabledCollectors = [ "systemd" "textfile" ];
          extraFlags = [ "--collector.ethtool" "--collector.softirqs" "--collector.tcpstat" "--collector.wifi" "--collector.textfile.directory=/var/lib/node_exporter/textfile_collector" ];
        };
      };
    };
  };
}
