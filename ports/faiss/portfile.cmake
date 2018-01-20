include(vcpkg_common_functions)

if(NOT VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
  message(FATAL_ERROR "faiss can only be built for x64 currently")
endif()

if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
      message(WARNING "Warning: Dynamic building not supported. Building static.")
      set(VCPKG_LIBRARY_LINKAGE static)
endif()

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO facebookresearch/faiss
  REF f1e411068474e7c2fabfef0904dc56dcda26666b
  SHA512 61ce2a479521412e0c56c352106c4adfb61a6bedb883921aba3ebccc29311ddd192646ac2c51b41572728d4de6ab4cb60a1dbc71515d742a80a8b59d89ca74d6
HEAD_REF master)


vcpkg_configure_cmake(
  SOURCE_PATH ${SOURCE_PATH}
  PREFER_NINJA
  OPTIONS
  -DBUILD_TUTORIAL=OFF
  -DBUILD_TEST=OFF
  -DBUILD_WITH_GPU=OFF
  -DWITH_MKL=OFF
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/faiss RENAME copyright)
