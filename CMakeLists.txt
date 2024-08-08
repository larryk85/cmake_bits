# ▄▄▄▄· ▪  ▄▄▄▄▄.▄▄ · 
# ▐█ ▀█▪██ •██  ▐█ ▀. 
# ▐█▀▀█▄▐█· ▐█.▪▄▀▀▀█▄
# ██▄▪▐█▐█▌ ▐█▌·▐█▄▪▐█  _          _ _ _   
# ·▀▀▀▀ ▀▀▀ ▀▀▀  ▀▀▀▀  | |        | (_) |                         
#   ___ _ __ ___   __ _| | _____  | |_| |__  _ __ __ _ _ __ _   _ 
#  / __| '_ ` _ \ / _` | |/ / _ \ | | | '_ \| '__/ _` | '__| | | |
# | (__| | | | | | (_| |   <  __/ | | | |_) | | | (_| | |  | |_| |
#  \___|_| |_| |_|\__,_|_|\_\___| |_|_|_.__/|_|  \__,_|_|   \__, |
#                                                            __/ |
#                                                           |___/ 

project(foo)

include(ProcessorCount)

if(NOT BITS_NO_DEPENDENCY_UTILS)
   add_subdirectory(dependency_utils)
endif()

if(NOT BITS_NO_EXTERNAL_PROJECT_UTILS)
   add_subdirectory(external_project_utils)
endif()

if(NOT BITS_NO_GIT_UTILS)
   add_subdirectory(git_utils)
endif()

if(NOT BITS_NO_TUI_UTILS)
   add_subdirectory(tui_utils)
endif()

if(NOT BITS_NO_VERSION_UTILS)
   add_subdirectory(version_utils)
endif()

bits_git_info(output LOG)
message(STATUS "GIT INFO: ${output}")