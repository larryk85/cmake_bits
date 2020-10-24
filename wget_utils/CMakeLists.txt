function(wget)
   set(options HARD_FAIL)
   set(oneValueArgs URL FILENAME DIR)
   set(multiValueArgs)
   cmake_parse_arguments(WGET "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   if(NOT WGET_URL)
      message(FATAL_ERROR "url is not supplied")
   endif()
   if(NOT WGET_FILENAME)
      message(FATAL_ERROR "filename is not supplied")
   endif()
   if(NOT WGET_DIR)
      message(FATAL_ERROR "directory is not supplied")
   endif()

   find_program(WGET_EXECUTABLE wget)

   if(NOT WGET_EXECUTABLE)
      message(FATAL_ERROR "wget not found")
   endif()

   execute_process(
      COMMAND ${WGET_EXECUTABLE} --connect-timeout=2 -t1 -O ${WGET_DIR}/${WGET_FILENAME} ${WGET_URL}
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
      RESULT_VARIABLE RES
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
   )

   if(NOT RES)
      if (HARD_FAIL)
         message(FATAL_ERROR "wget failed to download ${WGET_URL}")
      endif()
      set(WGET_SUCCESS 0 PARENT_SCOPE)
   else()
      set(WGET_SUCCESS 1 PARENT_SCOPE)
   endif()
endfunction()
