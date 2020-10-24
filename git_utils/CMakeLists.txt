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
      message(STATUS "RE_MATCH ${RE_MATCH}")
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
