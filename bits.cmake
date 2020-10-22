include(ProcessorCount)

add_subdirectory(external_project)

macro(add_project_dependency name)
   set(options)
   set(oneValueArgs VERSION)
   set(multiValueArgs)
   cmake_parse_arguments(ADD_DEP "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   find_package(${name} ${ADD_DEP_VERSION} QUIET)

   if(NOT ${name}_FOUND)
      extern_project(${name}
         VERSION ${ADD_DEP_VERSION}
         ${ARGN})
   else()
      list(APPEND CMAKE_MODULE_PATH "${${name}_DIR}")
   endif()
endmacro()
