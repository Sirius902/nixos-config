find_package(SDL2 REQUIRED CONFIG GLOBAL)
add_library(SDL2-static ALIAS SDL2::SDL2)
