{
  lib,
  pkgs,
  ...
}: {
  options.my.jdk = lib.mkOption {
    type = lib.types.package;
    default = pkgs.graalvmPackages.graalvm-oracle;
    defaultText = lib.literalExpression "pkgs.graalvmPackages.graalvm-oracle";
    description = "JDK that everything wanting one uses unless told otherwise.";
  };
}
