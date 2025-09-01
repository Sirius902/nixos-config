{lib, ...}: {
  options.my.jdk = with lib;
    mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "Primary JDK to use.";
    };
}
