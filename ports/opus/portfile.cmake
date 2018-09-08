if(VCPKG_CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
    message(FATAL_ERROR "UWP builds not supported")
endif()

include(vcpkg_common_functions)
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO xiph/opus
    REF v1.2.1
    SHA512 fdc64b43875dd07dc9eb1c37e9a61d1c10e3095de62ed9597d51b93445136958c9f5fee78c33ae7f90c72a20200083cdc727d8e79f2f9e580ad4e2f8c50cccb4
    HEAD_REF master
    PATCHES "${CMAKE_CURRENT_LIST_DIR}/no-main.patch"
)

if(NOT VCPKG_CMAKE_SYSTEM_NAME OR VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
# Ensure proper crt linkage
file(READ ${SOURCE_PATH}/win32/VS2015/common.props OPUS_PROPS)
if(VCPKG_CRT_LINKAGE STREQUAL dynamic)
    string(REPLACE ">MultiThreaded<" ">MultiThreadedDLL<" OPUS_PROPS "${OPUS_PROPS}")
    string(REPLACE ">MultiThreadedDebug<" ">MultiThreadedDebugDLL<" OPUS_PROPS "${OPUS_PROPS}")
else()
    string(REPLACE ">MultiThreadedDLL<" ">MultiThreaded<" OPUS_PROPS "${OPUS_PROPS}")
    string(REPLACE ">MultiThreadedDebugDLL<" ">MultiThreadedDebug<" OPUS_PROPS "${OPUS_PROPS}")
endif()
file(WRITE ${SOURCE_PATH}/win32/VS2015/common.props "${OPUS_PROPS}")

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    set(RELEASE_CONFIGURATION "Release")
    set(DEBUG_CONFIGURATION "Debug")
else()
    set(RELEASE_CONFIGURATION "ReleaseDll")
    set(DEBUG_CONFIGURATION "DebugDll")
endif()

if(TARGET_TRIPLET MATCHES "x86")
    set(ARCH_DIR "Win32")
elseif(TARGET_TRIPLET MATCHES "x64")
    set(ARCH_DIR "x64")
else()
    message(FATAL_ERROR "Architecture not supported")
endif()

vcpkg_build_msbuild(
    PROJECT_PATH ${SOURCE_PATH}/win32/VS2015/opus.vcxproj
    RELEASE_CONFIGURATION ${RELEASE_CONFIGURATION}
    DEBUG_CONFIGURATION ${DEBUG_CONFIGURATION}
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    # Install release build
    file(INSTALL ${SOURCE_PATH}/win32/VS2015/${ARCH_DIR}/${RELEASE_CONFIGURATION}/opus.lib DESTINATION ${CURRENT_PACKAGES_DIR}/lib/)

    # Install debug build
    file(INSTALL ${SOURCE_PATH}/win32/VS2015/${ARCH_DIR}/${DEBUG_CONFIGURATION}/opus.lib DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib/)
else()
    # Install release build
    file(INSTALL ${SOURCE_PATH}/win32/VS2015/${ARCH_DIR}/${RELEASE_CONFIGURATION}/opus.lib DESTINATION ${CURRENT_PACKAGES_DIR}/lib/)
    file(INSTALL ${SOURCE_PATH}/win32/VS2015/${ARCH_DIR}/${RELEASE_CONFIGURATION}/opus.dll DESTINATION ${CURRENT_PACKAGES_DIR}/bin/)

    # Install debug build
    file(INSTALL ${SOURCE_PATH}/win32/VS2015/${ARCH_DIR}/${DEBUG_CONFIGURATION}/opus.lib DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib/)
    file(INSTALL ${SOURCE_PATH}/win32/VS2015/${ARCH_DIR}/${DEBUG_CONFIGURATION}/opus.dll DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin/)
endif()

vcpkg_copy_pdbs()

# Install headers
file(INSTALL ${SOURCE_PATH}/include DESTINATION ${CURRENT_PACKAGES_DIR}/include RENAME opus)

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    file(READ ${CURRENT_PACKAGES_DIR}/include/opus/opus_defines.h OPUS_DEFINES)
    string(REPLACE "define OPUS_EXPORT" "define OPUS_EXPORT __declspec(dllimport)" OPUS_DEFINES "${OPUS_DEFINES}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/include/opus/opus_defines.h "${OPUS_DEFINES}")
endif()

elseif(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "Darwin" OR VCPKG_CMAKE_SYSTEM_NAME STREQUAL "Linux")
  file(REMOVE_RECURSE ${SOURCE_PATH}/build/debug)
    file(REMOVE_RECURSE ${SOURCE_PATH}/build/release)

    find_program(AUTORECONF autoreconf)
if(NOT AUTORECONF)
    message(FATAL_ERROR "\
    Please set up a development environment \
    On an Ubuntu or Debian family Linux distribution:\
    % sudo apt-get install git autoconf automake libtool gcc make\
    On a Fedora/Redhat based Linux:\
    % sudo dnf install git autoconf automake libtool gcc make\
    Or for older Redhat/Centos Linux releases:\
    % sudo yum install git autoconf automake libtool gcc make\
    On Apple macOS, install Xcode and brew.sh, then in the Terminal enter:\
    % brew install autoconf automake libtool\
    ")
endif()

##############
# Updating build configuration
#############
    message(STATUS "Updating build configuration files, please wait....")
    vcpkg_execute_required_process(
        COMMAND "${AUTORECONF}" -isf
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME updating-build-configuration-${TARGET_TRIPLET}
    )
message(STATUS "Updating build configuration files ${TARGET_TRIPLET} done.")

    ################
    # Debug build
    ################
    message(STATUS "Configuring ${TARGET_TRIPLET}-dbg")
    vcpkg_execute_required_process(
        COMMAND "${SOURCE_PATH}/configure" --prefix=${SOURCE_PATH}/build/debug 
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME config-${TARGET_TRIPLET}-dbg
    )
    message(STATUS "Configuring ${TARGET_TRIPLET}-dbg done.")

    message(STATUS "Installing ${TARGET_TRIPLET}-dbg")
    vcpkg_execute_required_process(
        COMMAND make -j install
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME build-${TARGET_TRIPLET}-dbg
    )
    message(STATUS "Installing ${TARGET_TRIPLET}-dbg done.")

    ################
    # Release build
    ################
    message(STATUS "Configuring ${TARGET_TRIPLET}-rel")
    vcpkg_execute_required_process(
        COMMAND make distclean
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME config-${TARGET_TRIPLET}-dbg
    )
    vcpkg_execute_required_process(
        COMMAND "${SOURCE_PATH}/configure" --prefix=${SOURCE_PATH}/build/release
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME config-${TARGET_TRIPLET}-rel
    )
    message(STATUS "Configuring ${TARGET_TRIPLET}-rel done.")

    message(STATUS "Installing ${TARGET_TRIPLET}-rel")
    vcpkg_execute_required_process(
        COMMAND make -j install
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME build-${TARGET_TRIPLET}-rel
    )
    message(STATUS "Installing ${TARGET_TRIPLET}-rel done.")

  file(INSTALL
            "${SOURCE_PATH}//build/debug/include/opusopus_defines.h"
            "${SOURCE_PATH}//build/debug/include/opusopus.h"
            "${SOURCE_PATH}//build/debug/include/opusopus_multistream.h"
	    "${SOURCE_PATH}//build/debug/include/opusopus_types.h"
      DESTINATION
            ${CURRENT_PACKAGES_DIR}/include
)

    file(
        INSTALL
            "${SOURCE_PATH}/build/debug/lib/libopus.a"
        DESTINATION
            ${CURRENT_INSTALLED_DIR}/debug/lib
)



    file(

        INSTALL
            "${SOURCE_PATH}/build/release/lib/libopus.a"
        DESTINATION
            ${CURRENT_PACKAGES_DIR}/lib

    )
endif()

# Handle copyright
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/opus RENAME copyright)

