# Checks that every symbol in DEF is defined in LIB (nm output) and vice versa.
#   cmake -DNM=<nm> -DLIB=<static lib> -DDEF=<node_api.def> -P check_symbols.cmake
include("${CMAKE_CURRENT_LIST_DIR}/../cmake/NodeApiStub.cmake")
node_api_read_symbols("${DEF}" _expected)

execute_process(COMMAND "${NM}" -g --defined-only "${LIB}"
  OUTPUT_VARIABLE _out RESULT_VARIABLE _rc)
if(NOT _rc EQUAL 0)
  message(FATAL_ERROR "nm failed on ${LIB}")
endif()
string(REGEX MATCHALL "[ \t][Tt][ \t]+_?((napi|node_api)_[A-Za-z0-9_]+)" _matches "${_out}")
set(_defined "")
foreach(_m IN LISTS _matches)
  string(REGEX REPLACE ".*[Tt][ \t]+_?" "" _s "${_m}")
  list(APPEND _defined "${_s}")
endforeach()
list(REMOVE_DUPLICATES _defined)

set(_missing ${_expected})
list(REMOVE_ITEM _missing ${_defined})
set(_extra ${_defined})
list(REMOVE_ITEM _extra ${_expected})
list(LENGTH _expected _ne)
list(LENGTH _defined _nd)
if(_missing OR _extra)
  message(FATAL_ERROR "stub symbols mismatch (expected ${_ne}, defined ${_nd})\nmissing: ${_missing}\nextra: ${_extra}")
endif()
message(STATUS "stub defines all ${_ne} Node-API symbols")
