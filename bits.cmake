include(ProcessorCount)

add_subdirectory(external_project_utils)
add_subdirectory(git_utils)
add_subdirectory(wget_utils) #required to be included before package_utils
add_subdirectory(system_utils)
add_subdirectory(package_utils)
add_subdirectory(version_utils)
