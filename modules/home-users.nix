{lib, ...}: {
  options.my.homeUsers = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = ''
      Users that receive the per-user configuration wired up by feature
      modules (home-manager modules, desktop group memberships).
    '';
  };
}
