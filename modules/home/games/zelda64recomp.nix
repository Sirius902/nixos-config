{pkgs, ...}: {
  home.packages = [pkgs.zelda64recomp];

  xdg.configFile = {
    "Zelda64Recompiled/mods/mm_recomp_rando.nrm".source = "${pkgs.mm-recomp-rando}/share/mm-recomp-rando/mm_recomp_rando.nrm";
    "Zelda64Recompiled/mods/APCpp-Glue.so".source = "${pkgs.apcpp-glue}/lib/apcpp-glue/APCpp-Glue.so";
  };
}
