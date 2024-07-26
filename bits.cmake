include(ProcessorCount)

set(BITS_EXTERN_PROJ_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
   CACHE FILEPATH "file path to the external_project directory")
set(BITS_EXTERN_PROJ_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}"
   CACHE FILEPATH "file path to the external_project directory")

macro(extern_project name)
   set(options OPTIONAL NO_FORWARD_ARGS SKIP_INSTALL SKIP_BUILD SKIP_CONFIG)
   set(oneValueArgs REPO TAG DIR ADD_SUBDIR VERSION PKG_NAME)
   set(multiValueArgs ARGS)
   cmake_parse_arguments(EXTERN_PROJ "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   set(EXTERN_PROJ_NAME ${name})

   if(NOT EXTERN_PROJ_PKG_NAME)
      set(EXTERN_PROJ_PKG_NAME ${name})
   endif()

   if(EXTERN_PROJ_SKIP_CONFIG)
      set(EXTERN_PROJ_CONFIGURE_CMD "CONFIGURE_COMMAND = \"\"")
   endif()

   set(EXTERN_PROJ_CL_ARGS "${EXTERN_PROJ_ARGS}")

   if(NOT EXTERN_PROJ_NO_FORWARD_ARGS)
      get_cmake_property(vars CACHE_VARIABLES)
      foreach(var ${vars})
         get_property(hstr CACHE "${var}" PROPERTY HELPSTRING)
         if("${hstr}" MATCHES "No help, variable specified on the command line." OR "${hstr}" STREQUAL "")
            set(EXTERN_PROJ_CL_ARGS "${EXTERN_PROJ_CL_ARGS} -D${var}=\"${${var}}\"")
         endif()
      endforeach()
   endif()


   if(EXTERN_PROJ_SKIP_BUILD)
      set(EXTERN_PROJ_BUILD_CMD "cmake -E echo \"Skipping build step.\"")
   else()
      set(EXTERN_PROJ_BUILD_CMD ${CMAKE_COMMAND} "--build . -j${PROC_COUNT}")
   endif()

   if(EXTERN_PROJ_SKIP_INSTALL)
      set(EXTERN_PROJ_INSTALL_CMD "cmake -E echo \"Skipping install step.\"")
   else()
      set(EXTERN_PROJ_INSTALL_CMD ${CMAKE_COMMAND} "--install . --config Debug")
   endif()

   configure_file(${BITS_EXTERN_PROJ_SOURCE_DIR}/template.in
      ${BITS_EXTERN_PROJ_BIN_DIR}/${EXTERN_PROJ_NAME}/CMakeLists.txt)

   execute_process(COMMAND "${CMAKE_COMMAND}" .
      WORKING_DIRECTORY "${BITS_EXTERN_PROJ_BIN_DIR}/${EXTERN_PROJ_NAME}")

   ProcessorCount(PROC_COUNT)

   execute_process(COMMAND "${CMAKE_COMMAND}" --build . --parallel ${PROC_COUNT}
      WORKING_DIRECTORY "${BITS_EXTERN_PROJ_BIN_DIR}/${EXTERN_PROJ_NAME}")

   list(APPEND CMAKE_PREFIX_PATH "${EXTERN_PROJ_DIR}/lib/cmake")

   if(EXTERN_PROJ_ADD_SUBDIR)
      set(_DIR ${BITS_EXTERN_PROJ_BIN_DIR}/${EXTERN_PROJ_NAME}/${EXTERN_PROJ_NAME}-prefix/src/${EXTERN_PROJ_NAME})
      add_subdirectory(${_DIR} ${_DIR}/build) # !KEEP THIS add_subdirectory!
   else()
      find_package(${EXTERN_PROJ_PKG_NAME} ${EXTERN_PROJ_VERSION} QUIET)
      list(APPEND CMAKE_MODULE_PATH "${EXTERN_PROJ_DIR}/lib/cmake/${EXTERN_PROJ_DIR}")
   endif()
endmacro()

macro(add_project_dependency name)
   set(options)
   set(oneValueArgs VERSION)
   set(multiValueArgs)
   cmake_parse_arguments(ADD_DEP "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   find_package(${name} ${ADD_DEP_VERSION} QUIET)

   if(NOT ${name}_FOUND)
      extern_project(${name}
         VERSION ${ADD_DEP_VERSION}
         ${ARGN})
   else()
      list(APPEND CMAKE_MODULE_PATH "${${name}_DIR}")
   endif()
endmacro()
macro(create_dependency)
   set(options)
   set(oneValueArgs
      NAME # name of the dependency to be used elsewhere

   )
   set(multiValueArgs
      PACKMAN_INFO
   )
   cmake_parse_arguments(DEP "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   set(DEP_NAME ${CREATE_DEPS_NAME})
   string(TOUPPER ${DEP_NAME} UDEP_NAME)

   find_package(${DEP_NAME} ${CREATE_DEPS_MAJOR_VERSION} QUIET)

   if (NOT ${DEP_NAME}_FOUND)
      FetchContent_Declare(
         ${CREATE_DEPS_NAME} 
         GIT_REPOSITORY https://github.com/${CREATE_DEPS_REPO}
         GIT_TAG ${TAG_NAME}
      )

      FetchContent_GetProperties(${DEP_NAME})
      if (NOT ${DEP_NAME}_POPULATED)
         set(${UDEP_NAME}_INSTALL ON)
         FetchContent_MakeAvailable(${DEP_NAME})
      endif()
   endif()

endmacro()

find_package(Git)

if(NOT GIT_SRC_DIR)
   set(GIT_SRC_DIR ${CMAKE_SOURCE_DIR})
endif()

if(NOT ${GIT_FOUND})
   message(FATAL_ERROR "git program is not found, install to use this utility")
endif()

if(NOT EXISTS ${GIT_SRC_DIR}/.git)
   message(FATAL_ERROR "(no .git found) this is not a git supported project")
endif()

function(git_submodule_update)
   set(options ONLY_WARN)
   set(oneValueArgs)
   set(multiValueArgs)
   cmake_parse_arguments(GIT_SUBMOD "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   if(GIT_SUBMOD_ONLY_WARN)
      execute_process(
         COMMAND ${GIT_EXECUTABLE} submodule status --recursive
         WORKING_DIRECTORY         "${GIT_SRC_DIR}"
         OUTPUT_VARIABLE           STAT
         ERROR_QUIET
         OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      string(REGEX MATCH "[-\+]" RE_MATCH ${STAT})
      if(NOT RE_MATCH)
         message(FATAL_ERROR "git submodules are out of sync with the project, please run `git submodule update --init --recursive`")
      endif()
   else()
      execute_process(
         COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
         WORKING_DIRECTORY         "${GIT_SRC_DIR}"
         ERROR_QUIET
         OUTPUT_STRIP_TRAILING_WHITESPACE
      )
   endif()
endfunction()

function(git_info)
   set(options)
   set(oneValueArgs BRANCH COMMIT IS_DIRTY IS_DIRTY_ALPHA LOG_INFO TAG)
   set(multiValueArgs)
   cmake_parse_arguments(GIT_INFO "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   if(GIT_INFO_BRANCH)
      execute_process(
         COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
         WORKING_DIRECTORY         "${GIT_SRC_DIR}"
         OUTPUT_VARIABLE           _BRANCH
         OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      set(${GIT_INFO_BRANCH} ${_BRANCH} PARENT_SCOPE)
   endif()

   if(GIT_INFO_COMMIT)
      execute_process(
         COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
         WORKING_DIRECTORY         "${GIT_SRC_DIR}"
         OUTPUT_VARIABLE           _COMMIT
         OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      set(${GIT_INFO_COMMIT} ${_COMMIT} PARENT_SCOPE)
   endif()

   if(GIT_INFO_IS_DIRTY OR GIT_INFO_IS_DIRTY_ALPHA)
      execute_process(
         COMMAND ${GIT_EXECUTABLE} diff --quiet
         WORKING_DIRECTORY         "${GIT_SRC_DIR}"
         RESULT_VARIABLE           DIFF_RES
         ERROR_QUIET
         OUTPUT_STRIP_TRAILING_WHITESPACE
      )

      if(${DIFF_RES} EQUAL 1 AND GIT_INFO_IS_DIRTY_ALPHA)
         set(${GIT_INFO_IS_DIRTY_ALPHA} "true" PARENT_SCOPE)
      elseif(GIT_INFO_IS_DIRTY_ALPHA)
         set(${GIT_INFO_IS_DIRTY_ALPHA} "false" PARENT_SCOPE)
      else()
         set(${GIT_INFO_IS_DIRTY} ${DIFF_RES} PARENT_SCOPE)
      endif()
   endif()

   if(GIT_INFO_LOG_INFO)
      execute_process(
         COMMAND ${GIT_EXECUTABLE} log origin..HEAD
         WORKING_DIRECTORY         "${GIT_SRC_DIR}"
         OUTPUT_VARIABLE           _LOG_INFO
         OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      set(${GIT_INFO_LOG_INFO} ${_LOG_INFO} PARENT_SCOPE)
   endif()

   if(GIT_INFO_TAG)
      execute_process(
         COMMAND ${GIT_EXECUTABLE} describe --tags --abbrev=0
         WORKING_DIRECTORY         "${GIT_SRC_DIR}"
         OUTPUT_VARIABLE           _TAG
         OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      set(${GIT_INFO_TAG} ${_TAG} PARENT_SCOPE)
   endif()
endfunction()

macro(create_version)
   set(options WITH_GIT)
   set(oneValueArgs MAJOR MINOR PATCH SUFF)
   set(multiValueArgs)
   cmake_parse_arguments(VER "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   set(PROJ ${CMAKE_PROJECT_NAME})

   if(VER_MAJOR)
      set(${PROJ}_VERSION_MAJOR ${VER_MAJOR})
   else()
      set(${PROJ}_VERSION_MAJOR "0")
   endif()
   if(VER_MINOR)
      set(${PROJ}_VERSION_MINOR ${VER_MINOR})
   else()
      set(${PROJ}_VERSION_MINOR "0")
   endif()
   if(VER_PATCH)
      set(${PROJ}_VERSION_PATCH ${VER_PATCH})
   else()
      set(${PROJ}_VERSION_PATCH "0")
   endif()

   if(VER_SUFF)
      if(VER_WITH_GIT)
         git_info(
            COMMIT         VCOMMIT
            IS_DIRTY       VID
         )
         if(VID)
            set(${PROJ}_VERSION_TWEAK "${VER_SUFF}-${VCOMMIT}-dirty")
         else()
            set(${PROJ}_VERSION_TWEAK "${VER_SUFF}-${VCOMMIT}")
         endif()
      else()
         set(${PROJ}_VERSION_TWEAK "${VER_SUFF}")
      endif()
   else()
      if(VER_WITH_GIT)
         git_info(
            COMMIT   VCOMMIT
            IS_DIRTY VID
         )
         if(VID)
            set(${PROJ}_VERSION_TWEAK "${VCOMMIT}-dirty")
         else()
            set(${PROJ}_VERSION_TWEAK "${VCOMMIT}")
         endif()
      endif()
   endif()

   if(${PROJ}_VERSION_TWEAK)
      set(${PROJ}_VERSION ${${PROJ}_VERSION_MAJOR}.${${PROJ}_VERSION_MINOR}.${${PROJ}_VERSION_PATCH}-${${PROJ}_VERSION_TWEAK})
   else()
      set(${PROJ}_VERSION ${${PROJ}_VERSION_MAJOR}.${${PROJ}_VERSION_MINOR}.${${PROJ}_VERSION_PATCH})
   endif()
   #set(${PROJ}_VERSION ${${PROJ}_VERSION_MAJOR}.${${PROJ}_VERSION_MINOR}.${${PROJ}_VERSION_PATCH})
endmacro()

macro(get_version)
   set(options)
   set(oneValueArgs VERSION)
   set(multiValueArgs)
   cmake_parse_arguments(VER "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   set(${VER_VERSION} ${${CMAKE_PROJECT_NAME}_VERSION})
endmacro()

macro(get_version_components)
   set(options)
   set(oneValueArgs MAJOR MINOR PATCH SUFF)
   set(multiValueArgs)
   cmake_parse_arguments(VER "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   if(VER_MAJOR)
      set(${VER_MAJOR} ${${PROJ}_VERSION_MAJOR})
   endif()
   if(VER_MINOR)
      set(${VER_MINOR} ${${PROJ}_VERSION_MINOR})
   endif()
   if(VER_PATCH)
      set(${VER_PATCH} ${${PROJ}_VERSION_PATCH})
   endif()
   if(VER_SUFF)
      set(${VER_SUFF} ${${PROJ}_VERSION_TWEAK})
   endif()
endmacro()
