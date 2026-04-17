{ config, lib, pkgs, ... }:
let

  cfg = config.services.keynav;

in {
  options.services.keynav = {
    enable = lib.mkEnableOption "keynav";

    package = lib.mkPackageOption pkgs "keynav" { };

    extraConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description =
        "Configuration for keynav written to {file}`~/.keynavrc`. Each attribute name is a key binding and the value is the action. See <https://github.com/jordansissel/keynav/blob/master/keynav.pod> for available bindings and actions.";
      example = {
        "2" = "doubleclick,end";
        "4" = "click 4";
        "5" = "click 5";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.keynav" pkgs
        lib.platforms.linux)
    ];

    home.file.".keynavrc" = lib.mkIf (cfg.extraConfig != { }) {
      text = lib.concatStringsSep "\n"
        (lib.mapAttrsToList (key: value: "${key} ${value}") cfg.extraConfig);
    };

    systemd.user.services.keynav = {
      Unit = {
        Description = "keynav";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers = [ "${config.home.file.".keynavrc".source}" ];
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        RestartSec = 3;
        Restart = "always";
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
