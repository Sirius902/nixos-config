find_package(SDL3 REQUIRED CONFIG GLOBAL)
add_library(SDL3::SDL3-static ALIAS SDL3::SDL3-shared)
