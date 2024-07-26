function(bits_create_dependency)
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

endfunction(bits_create_dependency)
