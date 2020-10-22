set(BITS_EXTERN_PROJ_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
   CACHE FILEPATH "file path to the external_project directory")
set(BITS_EXTERN_PROJ_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}"
   CACHE FILEPATH "file path to the external_project directory")

macro(extern_project name)
   set(options OPTIONAL NO_FORWARD_ARGS SKIP_INSTALL)
   set(oneValueArgs REPO TAG DIR ADD_SUBDIR)
   set(multiValueArgs ARGS)
   cmake_parse_arguments(EXTERN_PROJ "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   set(EXTERN_PROJ_NAME ${name})

   if(EXTERN_PROJ_NO_FORWARD_ARGS)
      get_cmake_property(vars CACHE_VARIABLES)
      foreach(var ${vars})
         get_property(hstr CACHE "${var}" PROPERTY HELPSTRING)
         if("${hstr}" MATCHES "No help, variable specified on the command line." OR "${hrstr}" STREQUAL "")
            list(APPEND EXTERN_PROJ_CL_ARGS "-D${var}=${${var}}")
         endif()
      endforeach()
   endif()

   if(EXTERN_PROJ_SKIP_INSTALL)
      set(EXTERN_PROJ_INSTALL_CMD "cmake -E echo \"Skipping install step.\"")
   else()
      set(EXTERN_PROJ_INSTALL_CMD ${CMAKE_COMMAND} --build . --target install)
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
      add_subdirectory(${BITS_EXTERN_PROJ_BIN_DIR}/${EXTERN_PROJ_NAME}/${EXTERN_PROJ_NAME}-prefix/src/${EXTERN_PROJ_NAME})
   else()
      find_package(${EXTERN_PROJ_NAME})
   endif()
endmacro()
