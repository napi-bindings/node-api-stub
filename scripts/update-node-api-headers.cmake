# Refreshes include/ and def/ from the official node-api-headers npm package.
#   cmake -DVERSION=1.9.0 -P scripts/update-node-api-headers.cmake
# Needs neither Node.js nor npm: the tarball is downloaded from the registry.
cmake_minimum_required(VERSION 3.18)

if(NOT VERSION)
  message(FATAL_ERROR "Pass -DVERSION=<x.y.z> of node-api-headers")
endif()
get_filename_component(_root "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(_tmp "${_root}/.tmp-node-api-headers")
file(REMOVE_RECURSE "${_tmp}")
file(MAKE_DIRECTORY "${_tmp}")

set(_url "https://registry.npmjs.org/node-api-headers/-/node-api-headers-${VERSION}.tgz")
file(DOWNLOAD "${_url}" "${_tmp}/pkg.tgz" STATUS _st TLS_VERIFY ON)
list(GET _st 0 _code)
if(NOT _code EQUAL 0)
  message(FATAL_ERROR "Download failed: ${_url}\n${_st}")
endif()
file(ARCHIVE_EXTRACT INPUT "${_tmp}/pkg.tgz" DESTINATION "${_tmp}")

file(REMOVE_RECURSE "${_root}/include" "${_root}/def")
file(COPY "${_tmp}/package/include/" DESTINATION "${_root}/include")
file(COPY "${_tmp}/package/def/" DESTINATION "${_root}/def")
file(COPY "${_tmp}/package/LICENSE" DESTINATION "${_root}/def")
file(RENAME "${_root}/def/LICENSE" "${_root}/def/LICENSE-node-api-headers")
file(WRITE "${_root}/def/NODE_API_HEADERS_VERSION" "${VERSION}\n")
file(REMOVE_RECURSE "${_tmp}")
message(STATUS "node-api-headers ${VERSION} vendored into include/ and def/")
