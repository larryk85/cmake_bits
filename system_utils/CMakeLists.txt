function(get_system_info)
   set(options)
   set(oneValueArgs OS VERSION ARCH BITS)
   set(multiValueArgs)
   cmake_parse_arguments(SYS_INFO "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   if(${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
      set(${SYS_INFO_OS} ${CMAKE_SYSTEM_NAME} PARENT_SCOPE)
      find_program(SW_VERS_EXE sw_vers)
      execute_process(
         COMMAND ${SW_VERS_EXE}
         OUTPUT_VARIABLE RES
         ERROR_QUIET
         OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      string(REGEX MATCH "ProductVersion:.*" RM ${RES})
      string(REGEX MATCH "([0-9]+(\.[0-9]+)(\.[0-9]+))" VERS ${RM})
      set(${SYS_INFO_VERSION} ${VERS} PARENT_SCOPE)
   elseif(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
      set(${SYS_INFO_OS} "osx" PARENT_SCOPE)
   else()
      message(WARNING "Currently this feature does not support ${CMAKE_SYSTEM_NAME}")
   endif()

   set(${SYS_INFO_ARCH} ${CMAKE_SYSTEM_PROCESSOR} PARENT_SCOPE)

   if (CMAKE_SIZEOF_VOID_P MATCHES 16)
      set(${SYS_INFO_BITS} 128 PARENT_SCOPE)
   elseif (CMAKE_SIZEOF_VOID_P MATCHES 8)
      set(${SYS_INFO_BITS} 64 PARENT_SCOPE)
   elseif(CMAKE_SIZEOF_VOID_P MATCHES 4)
      set(${SYS_INFO_BITS} 32 PARENT_SCOPE)
   elseif(CMAKE_SIZEOF_VOID_P MATCHES 2)
      set(${SYS_INFO_BITS} 16 PARENT_SCOPE)
   endif()
endfunction()

function(fail_on_system)
   set(options)
   set(oneValueArgs OS VERSION ARCH BITS)
   set(multiValueArgs)
   cmake_parse_arguments(ASYS "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

   get_system_info(
      OS _OS
      VERSION _VERSION
      ARCH _ARCH
      BITS _BITS
   )

   if(${ASYS_OS} EQUAL ${_OS})
      if(ASYS_VERSION)
         if(${ASYS_VERSION} EQUAL ${_VERSION})
            message(FATAL_ERROR "assert_system: ${ASYS_OS}@${ASYS_VERSION} not supported")
         endif()
      endif()
      message(FATAL_ERROR "assert_system: ${ASYS_OS} not supported")
   endif()
   if(ASYS_ARCH)
      if(${ASYS_ARCH} EQUAL ${_ARCH})
         if(${AYS_BITS} EQUAL ${_BITS})
            message(FATAL_ERROR "assert_system: ${ASYS_ARCH} architecture not supported with the bitwidth of ${ASYS_BITS}")
         endif()
         message(FATAL_ERROR "assert_system: ${ASYS_ARCH} architecture not supported")
      endif()
   endif()
endfunction()
