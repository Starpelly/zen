cmake_minimum_required(VERSION 3.15)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -U_DEBUG")

#====================================================================
# Shit nobody cares about award
#====================================================================
set(COPYRIGHT_YEAR ${YEAR})

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_SUPPRESS_REGENERATION true)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

#====================================================================
# Project setup
#====================================================================
project(Zen)

set(ZEN_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

file(GLOB_RECURSE ZEN_FILES
    ${ZEN_SOURCE_DIR}/*.c
    ${ZEN_SOURCE_DIR}/*.h
)

#set(ZEN_FILES
#    ${ZEN_SOURCE_DIR}/main.c
#)

add_executable(Zen ${ZEN_FILES})

set(RAYLIB_PATH "C:/Users/Braedon/Downloads/raylib-5.5_win64_msvc16/raylib-5.5_win64_msvc16")

target_include_directories(Zen PUBLIC ${ZEN_SOURCE_DIR})

# raylib
target_include_directories(Zen PUBLIC ${RAYLIB_PATH}/include)
target_link_libraries(Zen PUBLIC ${RAYLIB_PATH}/lib/raylib.lib)
target_link_libraries(Zen PUBLIC winmm.lib)

#====================================================================
# Folder structuring in Visual Studio
#====================================================================

if(MSVC_IDE)
	foreach(source IN LISTS ZEN_FILES)
		get_filename_component(source_path "${source}" PATH)
		string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}" "" relative_source_path ${source_path})
		string(REPLACE "/" "\\" source_path_msvc ${relative_source_path})
		source_group(${source_path_msvc} FILES ${source})
    endforeach()
endif()