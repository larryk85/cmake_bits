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

wget(
   FILENAME foo
   DIR      "${CMAKE_BINARY_DIR}"
   URL      "https://releases.hashicorp.com/terraform/0.12.2/terraform_0.12.2_linux_amd64.zip"
)
