cmake_minimum_required(VERSION 3.16...3.31)

# Major version = latest Node-API version covered (same scheme as 7.0.0 and 8.0.0).
project(node-api-stub VERSION 10.0.0 LANGUAGES C
        DESCRIPTION "Node-API headers, link-time stubs and import libraries")
file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/def/NODE_API_HEADERS_VERSION" NODE_API_HEADERS_VERSION LIMIT_COUNT 1)

if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
  set(NODE_API_IS_TOP_LEVEL ON)
else()
  set(NODE_API_IS_TOP_LEVEL OFF)
endif()

# --- Options -----------------------------------------------------------------
# Stub libraries are only useful on ELF platforms. On Windows and macOS a stub
# with function bodies ends up being called instead of Node-API (see README),
# so they are off by default there.
if(WIN32 OR APPLE)
  set(_stub_default OFF)
else()
  set(_stub_default ON)
endif()

set(NODE_API_VERSION "8" CACHE STRING
    "NAPI_VERSION defined for consumers (1-10 or 'experimental'); empty = do not define it")
option(NODE_API_BUILD_STUB_STATIC "Build the static stub (libnode_api_stub.a)" ${_stub_default})
option(NODE_API_BUILD_STUB_SHARED "Build the shared stub (libnode_api_stub.so/.dylib/.dll)" ${_stub_default})
option(NODE_API_ELF_ALLOW_UNDEFINED "ELF: add -z undefs to consumers (overrides -z defs / --no-undefined)" ON)
set(NODE_API_MACOS_UNDEFINED "symbols" CACHE STRING
    "macOS: 'symbols' (-U for each Node-API symbol) or 'dynamic_lookup'")
set_property(CACHE NODE_API_MACOS_UNDEFINED PROPERTY STRINGS symbols dynamic_lookup)
option(NODE_API_WIN_DELAY_LOAD "Windows/MSVC: delay-load node.exe and redirect it to the host executable (Electron, renamed node)" ON)
option(NODE_API_INSTALL "Generate install/export rules" ${NODE_API_IS_TOP_LEVEL})
option(NODE_API_BUILD_TESTS "Build tests (addon loaded by node)" ${NODE_API_IS_TOP_LEVEL})

include(GNUInstallDirs)
include(cmake/NodeApiStub.cmake)

node_api_read_symbols("${CMAKE_CURRENT_SOURCE_DIR}/def/node_api.def" NODE_API_SYMBOLS)
list(LENGTH NODE_API_SYMBOLS _n)
message(STATUS "node-api-stub ${PROJECT_VERSION} (node-api-headers ${NODE_API_HEADERS_VERSION}): ${_n} Node-API symbols")

set(_gen "${CMAKE_CURRENT_BINARY_DIR}/generated")

# --- NodeApi::headers --------------------------------------------------------
add_library(node_api_headers INTERFACE)
add_library(NodeApi::headers ALIAS node_api_headers)
set_target_properties(node_api_headers PROPERTIES EXPORT_NAME headers)
target_include_directories(node_api_headers INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/node-api>)
if(NODE_API_VERSION STREQUAL "experimental")
  target_compile_definitions(node_api_headers INTERFACE NAPI_EXPERIMENTAL)
elseif(NOT NODE_API_VERSION STREQUAL "")
  target_compile_definitions(node_api_headers INTERFACE NAPI_VERSION=${NODE_API_VERSION})
endif()
# On Windows this turns NAPI_EXTERN into __declspec(dllimport), which is what
# the import library expects.
target_compile_definitions(node_api_headers INTERFACE BUILDING_NODE_EXTENSION)

# --- NodeApi::NodeApi: the target consumers should use ---------------------
# Picks the right link mechanism for the platform; no stub is linked.
add_library(node_api INTERFACE)
add_library(NodeApi::NodeApi ALIAS node_api)
set_target_properties(node_api PROPERTIES EXPORT_NAME NodeApi)
target_link_libraries(node_api INTERFACE node_api_headers)

set(_install_files "")
if(WIN32)
  # Import library for NODE.EXE generated from the official .def file.
  node_api_generate_import_library("${CMAKE_CURRENT_SOURCE_DIR}/def/node_api.def" "${_gen}" _implib)
  get_filename_component(_implib_name "${_implib}" NAME)
  target_link_libraries(node_api INTERFACE
    $<BUILD_INTERFACE:${_implib}>
    $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${CMAKE_INSTALL_LIBDIR}/${_implib_name}>)
  list(APPEND _install_files "${_implib}")
  if(NODE_API_WIN_DELAY_LOAD AND MSVC)
    target_link_options(node_api INTERFACE "LINKER:/DELAYLOAD:node.exe")
    target_link_libraries(node_api INTERFACE delayimp)
    target_sources(node_api INTERFACE
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/win_delay_load_hook.c>
      $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${CMAKE_INSTALL_DATADIR}/node-api-stub/win_delay_load_hook.c>)
  endif()
elseif(APPLE)
  if(NODE_API_MACOS_UNDEFINED STREQUAL "dynamic_lookup")
    target_link_options(node_api INTERFACE "LINKER:-undefined,dynamic_lookup")
  else()
    # Only Node-API symbols may stay undefined: every other link error is still an error.
    foreach(_s IN LISTS NODE_API_SYMBOLS)
      target_link_options(node_api INTERFACE "LINKER:-U,_${_s}")
    endforeach()
  endif()
else()
  # ELF: undefined symbols are allowed in shared objects by default.
  # -z undefs is only needed when the toolchain enforces -z defs
  # (e.g. Android NDK, Meson b_lundef).
  if(NODE_API_ELF_ALLOW_UNDEFINED)
    target_link_options(node_api INTERFACE "LINKER:-z,undefs")
  endif()
endif()

# --- Stub libraries (optional) -----------------------------------------------
node_api_generate_stub_source("${_gen}/node_api_stub.c" "${NODE_API_SYMBOLS}")
set(_stub_targets "")
if(NODE_API_BUILD_STUB_STATIC)
  add_library(node_api_stub STATIC "${_gen}/node_api_stub.c")
  add_library(NodeApi::stub ALIAS node_api_stub)
  set_target_properties(node_api_stub PROPERTIES EXPORT_NAME stub POSITION_INDEPENDENT_CODE ON)
  target_compile_definitions(node_api_stub PRIVATE NODE_API_STUB_STATIC)
  target_link_libraries(node_api_stub INTERFACE node_api_headers)
  list(APPEND _stub_targets node_api_stub)
endif()
if(NODE_API_BUILD_STUB_SHARED)
  add_library(node_api_stub_shared SHARED "${_gen}/node_api_stub.c")
  add_library(NodeApi::stub_shared ALIAS node_api_stub_shared)
  set_target_properties(node_api_stub_shared PROPERTIES EXPORT_NAME stub_shared
    OUTPUT_NAME node_api_stub C_VISIBILITY_PRESET hidden)
  target_link_libraries(node_api_stub_shared INTERFACE node_api_headers)
  list(APPEND _stub_targets node_api_stub_shared)
endif()
# As a dependency (add_subdirectory/FetchContent) the stubs are built only if
# something links them.
if(NOT NODE_API_IS_TOP_LEVEL AND _stub_targets)
  set_target_properties(${_stub_targets} PROPERTIES EXCLUDE_FROM_ALL ON)
endif()
# Migration aid for projects that linked the old `node_api` target (libnode_api.a).
if(TARGET node_api_stub)
  add_library(NodeApi::legacy ALIAS node_api_stub)
endif()

# --- Install / export --------------------------------------------------------
if(NODE_API_INSTALL)
  include(CMakePackageConfigHelpers)
  install(TARGETS node_api_headers node_api ${_stub_targets} EXPORT NodeApiTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
  install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/node-api)
  install(FILES def/node_api.def def/js_native_api.def def/LICENSE-node-api-headers
          DESTINATION ${CMAKE_INSTALL_DATADIR}/node-api-stub)
  install(FILES src/win_delay_load_hook.c DESTINATION ${CMAKE_INSTALL_DATADIR}/node-api-stub)
  if(_install_files)
    install(FILES ${_install_files} DESTINATION ${CMAKE_INSTALL_LIBDIR})
  endif()
  install(EXPORT NodeApiTargets NAMESPACE NodeApi::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/NodeApi)
  configure_package_config_file(cmake/NodeApiConfig.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/NodeApiConfig.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/NodeApi)
  write_basic_package_version_file("${CMAKE_CURRENT_BINARY_DIR}/NodeApiConfigVersion.cmake"
    COMPATIBILITY SameMajorVersion)
  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/NodeApiConfig.cmake"
                "${CMAKE_CURRENT_BINARY_DIR}/NodeApiConfigVersion.cmake"
          DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/NodeApi)
endif()

if(NODE_API_BUILD_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()
