#  ░▒▓██████▓▒░░▒▓█▓▒░▒▓████████▓▒░ 
# ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░  ░▒▓█▓▒░     
# ░▒▓█▓▒░      ░▒▓█▓▒░  ░▒▓█▓▒░     
# ░▒▓█▓▒▒▓███▓▒░▒▓█▓▒░  ░▒▓█▓▒░     
# ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░  ░▒▓█▓▒░     
# ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░  ░▒▓█▓▒░     
#  ░▒▓██████▓▒░░▒▓█▓▒░  ░▒▓█▓▒░     

find_package(Git)

if(NOT Git_FOUND)
   if(NOT BITS_GIT_EXEC)
      message(FATAL_ERROR "git program is not found, install to use this utility")
   else()
      set(GIT_EXECUTABLE ${BITS_GIT_EXEC})
   endif()
endif()

macro(bits_source_directory output)
   if(ARGN)
      set(${output} ${ARGN} PARENT_SCOPE)
   else()
      set(${output} ${PROJECT_SOURCE_DIR} PARENT_SCOPE)
   endif()
endmacro(bits_source_directory)

function(bits_is_git_project output)
   set(options)
   set(oneValueArgs DIRECTORY)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}" 
                              "${oneValueArgs}" 
                              "${multiValueArgs}" 
                              "${ARGN}")
   
   bits_source_directory(src_dir ${ARGS_DIRECTORY})

   set(${output} EXISTS "${src_dir}/.git" PARENT_SCOPE)
endfunction(bits_is_git_project)

function(bits_git_submodule_synced output)
   set(options VERBOSE)
   set(oneValueArgs DIRECTORY)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}" 
                              "${oneValueArgs}" 
                              "${multiValueArgs}" 
                              "${ARGN}")

   bits_source_directory(src_dir ${ARGS_DIRECTORY})

   execute_process(
      COMMAND ${GIT_EXECUTABLE} submodule status --recursive
      WORKING_DIRECTORY         "${src_dir}"
      OUTPUT_VARIABLE           out
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
   )
   string(REGEX MATCH "[-\+]" matches ${out})
   if(NOT matches AND ARGS_VERBOSE)
      message(WARNING "git submodules are out of sync with the project, please run `git submodule update --init --recursive`")
   endif()
   set(${output} ${matches} PARENT_SCOPE)
endfunction(bits_git_submodule_synced)

function(bits_git_submodule_update)
   set(options)
   set(oneValueArgs DIRECTORY)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}" 
                              "${oneValueArgs}" 
                              "${multiValueArgs}" 
                              "${ARGN}")
   
   bits_source_directory(src_dir ${ARGS_DIRECTORY})

   execute_process(
      COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
      WORKING_DIRECTORY "${src_dir}"
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
   )
endfunction(bits_git_submodule_update)

function(bits_exec_git cmd output)
   set(options)
   set(oneValueArgs DIRECTORY)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}" 
                              "${oneValueArgs}" 
                              "${multiValueArgs}" 
                              "${ARGN}")
   
   bits_source_directory(src_dir ${ARGS_DIRECTORY})

   execute_process(
      COMMAND ${GIT_EXECUTABLE} ${cmd}
      WORKING_DIRECTORY "${src_dir}"
      OUTPUT_VARIABLE out
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
   )
   set(${output} ${out} PARENT_SCOPE)
endfunction(bits_exec_git)

function(bits_git_info)
   set(options)
   set(oneValueArgs DIRECTORY BRANCH COMMIT IS_DIRTY IS_DIRTY_ALPHA LOG_INFO TAG)
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
