function(extern_project)
   set(options OPTIONAL)
   set(oneValueArgs NAME REPO TAG DIR)
   set(multiValueArgs ARGS)
   cmake_parse_arguments(EXTERN_PROJ "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   configure_file(template.in ${CMAKE_BINARY_DIR}/${EXTERN_PROJ_NAME}-CMakeLists.txt)

   execute_process(COMMAND "${CMAKE_COMMAND}" -G "${CMAKE_GENERATOR}" . WORKING_DIRECTORY "${EXTERN_PROJ_DIR}")
   execute_process(COMMAND "${CMAKE_COMMAND}" --build . WORKING_DIRECTORY "${EXTERN_PROJ_DIR}")

   add_subdirectory(${EXTERN_PROJ_DIR})
