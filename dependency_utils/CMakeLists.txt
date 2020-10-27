macro(create_dependency)
   set(options)
   set(oneValueArgs
      NAME # name of the dependency to be used elsewhere

   )
   set(multiValueArgs
      PACKMAN_INFO
   )
   cmake_parse_arguments(DEP "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")


endmacro()
