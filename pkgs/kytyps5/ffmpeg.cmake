find_package(PkgConfig REQUIRED)
pkg_check_modules(FFMPEG REQUIRED IMPORTED_TARGET GLOBAL
  libavformat libavcodec libswscale libavutil libavfilter libswresample)
add_library(ffmpeg INTERFACE)
target_link_libraries(ffmpeg INTERFACE PkgConfig::FFMPEG)
