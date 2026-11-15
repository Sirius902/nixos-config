{
  lib,
  pkgs,
  ...
}: {
  options.my.jdk = lib.mkOption {
    type = lib.types.package;
    default = pkgs.temurin-bin-27;
    defaultText = lib.literalExpression "pkgs.temurin-bin-27";
    description = "JDK that everything wanting one uses unless told otherwise.";
  };
}
