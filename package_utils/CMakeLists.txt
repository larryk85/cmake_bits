if(NOT PACKAGE_MAP_URL)
   set(PACKAGE_MAP_URL "https://raw.githubusercontent.com/larryk85/package_map/main/package.map")
endif()

function(apt_install)
   set(options HARD_FAIL)
   set(oneValueArgs NAME VERSION)
   set(multiValueArgs)
   cmake_parse_arguments(PKG "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")
   find_program(APT_EXECUTABLE apt)
   execute_process(
         COMMAND ${APT_EXECUTABLE}
         WORKING_DIRECTORY         "${GIT_SRC_DIR}"
         OUTPUT_VARIABLE           STAT
         ERROR_QUIET
         OUTPUT_STRIP_TRAILING_WHITESPACE
   )
endfunction()

function(get_package_info NAME VERSION)
   file(READ ${CMAKE_BINARY_DIR}/package_install/packages PACKAGE_LIST)
   if(${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
      set(PKG_NM "brew")
   endif()
   message(STATUS "${CMAKE_SYSTEM}")
   #string(REGEX MATCH
endfunction()

function(install_package)
   set(options HARD_FAIL)
   set(oneValueArgs NAME VERSION)
   set(multiValueArgs)
   cmake_parse_arguments(PKG "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

endfunction()
#function(install_package)
#   set(options HARD_FAIL)
#   set(oneValueArgs NAME VERSION)
#   set(multiValueArgs)
#   cmake_parse_arguments(PKG "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")
#
#   if(NOT PACKAGE_MAP_URL)
#      set(PACKAGE_MAP_URL "https://raw.githubusercontent.com/larryk85/package_map/main/package.map")
#   endif()
#
#   set(PACKAGE_DIR ${CMAKE_BINARY_DIR}/package_install)
#   file(MAKE_DIRECTORY ${PACKAGE_DIR})
#
#   wget(
#      URL ${PACKAGE_MAP_URL}
#      FILENAME packages
#      DIR ${PACKAGE_DIR}
#      HARD_FAIL
#   )
#
#   get_package_info(foo 33)
##execute_process(
##         COMMAND ${GIT_EXECUTABLE} submodule status --recursive
##         WORKING_DIRECTORY         "${GIT_SRC_DIR}"
##         OUTPUT_VARIABLE           STAT
##         ERROR_QUIET
##         OUTPUT_STRIP_TRAILING_WHITESPACE
##   )
#endfunction()
