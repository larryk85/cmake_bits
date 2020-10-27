cmake_minimum_required(VERSION 3.8)
project(cmake_bits)

include(bits.cmake)

option(ENABLE_TESTS "enable unit tests" Off)

if(ENABLE_TESTS)
endif()

create_version(
   MAJOR 2
   MINOR 0
   PATCH 2
)

get_version( VERSION VER )

message(STATUS "v${VER}")

#install_package(
#   NAME foo
#   VERSION 2.3
#)

#fail_on_system(
#   OS Darwin
#   ARCH x86_64
#)
