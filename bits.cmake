include(ProcessorCount)

add_subdirectory(external_project)

macro(add_project_dependency name)
   set(oneValueArgs VERSION)
   cmake_parse_arguments(ADD_DEP "${oneValueArgs}" "${ARGN}")

   find_package(${name} ${ADD_DEP_VERSION} QUIET)

   if(NOT ${name}_FOUND)
      extern_project(${name}
         VERSION ${ADD_DEP_VERSION}
         ${ARGN})
   endif()
endmacro()
