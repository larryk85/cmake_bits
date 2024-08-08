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

function(bits_source_directory output)
   if(ARGN AND NOT ${ARGN} STREQUAL "")
      set(${output} ${ARGN} PARENT_SCOPE)
   else()
      set(${output} ${PROJECT_SOURCE_DIR} PARENT_SCOPE)
   endif()
endfunction(bits_source_directory)

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

function(bits_exec_git)
   cmake_parse_arguments(ARGS "" "DIRECTORY;OUTPUT;VERBOSE" "" ${ARGN})

   if(NOT ARGS_OUTPUT)
      message(FATAL_ERROR "OUTPUT argument is required")
   endif()
   
   bits_source_directory(src_dir ${ARGS_DIRECTORY})
   execute_process(
      COMMAND ${GIT_EXECUTABLE} ${ARGS_UNPARSED_ARGUMENTS}
      WORKING_DIRECTORY "${src_dir}"
      OUTPUT_VARIABLE out
      ERROR_VARIABLE  err
      OUTPUT_STRIP_TRAILING_WHITESPACE
   )
   if(err)
      if(VERBOSE)
         message(WARNING "git command {${GIT_EXECUTABLE} ${ARGS_UNPARSED_ARGUMENTS}} failed: ${err}")
      endif()
      set(${ARGS_OUTPUT} "null" PARENT_SCOPE)
   else()
      if("${out}" STREQUAL "")
         set(${ARGS_OUTPUT} "null" PARENT_SCOPE)
      else()
         set(${ARGS_OUTPUT} ${out} PARENT_SCOPE)
      endif()
   endif()
endfunction(bits_exec_git)

function(bits_git_submodule_synced output)
   set(options VERBOSE)
   set(oneValueArgs DIRECTORY)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}" 
                              "${oneValueArgs}" 
                              "${multiValueArgs}" 
                              "${ARGN}")

   bits_source_directory(src_dir ${ARGS_DIRECTORY})
   bits_exec_git(submodule status --recursive OUTPUT out DIRECTORY ${src_dir})

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
   bits_exec_git(submodule update --init --recursive OUTPUT out DIRECTORY ${src_dir})
endfunction(bits_git_submodule_update)


function(bits_git_full_info output)
   set(options)
   set(oneValueArgs DIRECTORY)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   bits_source_directory(src_dir ${ARGS_DIRECTORY})
   bits_exec_git(rev-parse --abbrev-ref HEAD OUTPUT branch DIRECTORY ${src_dir})
   bits_exec_git(rev-parse --short HEAD OUTPUT short_hash DIRECTORY ${src_dir})
   bits_exec_git(rev-parse HEAD OUTPUT full_hash DIRECTORY ${src_dir})
   bits_exec_git(diff --quiet OUTPUT is_dirty DIRECTORY ${src_dir})
   bits_exec_git(log --summary OUTPUT log_info DIRECTORY ${src_dir})
   bits_exec_git(describe --tags --abbrev=0 OUTPUT tag DIRECTORY ${src_dir})
   set(${output} "${branch};${short_hash};${full_hash};${is_dirty};${log_info};${tag}" PARENT_SCOPE)
endfunction()

function(bits_git_info output)
   set(options BRANCH SHORT_HASH FULL_HASH DIRTY LOG TAG)
   set(oneValueArgs DIRECTORY)
   set(multiValueArgs)
   cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   set(option_count 0)
   foreach(option ${options})
       if(ARG_${option})
           math(EXPR option_count "${option_count} + 1")
       endif()
   endforeach()
   
   if(option_count GREATER 1)
       message(FATAL_ERROR "Only one of the options (${options}) can be set at a time.")
   endif()

   bits_git_full_info(info DIRECTORY ${ARGS_DIRECTORY})

   if(ARGS_BRANCH)
      list(GET info 0 branch)
      set(${output} ${branch} PARENT_SCOPE)
   elseif(ARGS_SHORT_HASH)
      list(GET info 1 hash)
      set(${output} ${hash} PARENT_SCOPE)
   elseif(ARGS_FULL_HASH)
      list(GET info 2 hash)
      set(${output} ${hash} PARENT_SCOPE)
   elseif(ARGS_DIRTY)
      list(GET info 3 is_dirty)
      set(${output} ${is_dirty} PARENT_SCOPE)
   elseif(ARGS_LOG)
      list(GET info 4 log_sum_info)
      set(${output} ${log_sum_info} PARENT_SCOPE)
   elseif(ARGS_TAG)
      list(GET info 5 tag)
      set(${output} ${tag} PARENT_SCOPE)
   else()
      set(${output} ${info} PARENT_SCOPE)
   endif()
endfunction()
