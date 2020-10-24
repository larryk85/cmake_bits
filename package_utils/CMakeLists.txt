function()
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
