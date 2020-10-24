cmake_minimum_required(VERSION 3.8)
project(cmake_bits)

include(bits.cmake)

option(ENABLE_TESTS "enable unit tests" Off)

if(ENABLE_TESTS)
endif()

#git_submodule_update()

set(BR "FOO")

git_info(BRANCH BR
         COMMIT CM
         IS_DIRTY ID)

message(STATUS "Branch : ${BR}")
message(STATUS "Commit : ${CM}")
message(STATUS "Is Dirty : ${ID}")
