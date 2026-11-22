{
  lib,
  pkgs,
  ...
}: {
  options.my.jdk = lib.mkOption {
    type = lib.types.package;
    # TODO(Sirius902) Switch back to graalvm-oracle once its build is on JDK 25.0.5.1 or later.
    default = pkgs.temurin-bin-25;
    defaultText = lib.literalExpression "pkgs.temurin-bin-25";
    description = "JDK that everything wanting one uses unless told otherwise.";
  };
}
