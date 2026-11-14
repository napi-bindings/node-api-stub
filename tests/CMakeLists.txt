find_program(NODE_EXECUTABLE node)
if(NOT NODE_EXECUTABLE)
  message(WARNING "node-api-stub: node not found, the addons are built but not loaded")
endif()

function(node_api_test_addon name)
  add_library(${name} MODULE addon/addon.c)
  set_target_properties(${name} PROPERTIES PREFIX "" SUFFIX ".node" C_VISIBILITY_PRESET hidden)
  target_link_libraries(${name} PRIVATE ${ARGN})
endfunction()

set(_expect_real "const r=require(process.argv[1]); if(r!=='real-node-api'){console.error('got',r);process.exit(1)}")

# 1. Recommended target, with the most hostile link options on ELF:
#    -z defs (rejects undefined symbols) and -Bsymbolic (as go build -buildmode=c-shared).
node_api_test_addon(addon_nodeapi NodeApi::NodeApi)
if(NOT WIN32 AND NOT APPLE)
  target_link_options(addon_nodeapi PRIVATE "LINKER:-z,defs" "LINKER:-Bsymbolic")
endif()
if(NODE_EXECUTABLE)
  add_test(NAME load_nodeapi COMMAND ${NODE_EXECUTABLE} -e "${_expect_real}" $<TARGET_FILE:addon_nodeapi>)
endif()

# 2. Windows: the addon must also load from a host that is not called node.exe
#    (delay-load hook). The node executable is copied under another name.
if(WIN32 AND MSVC AND NODE_API_WIN_DELAY_LOAD AND NODE_EXECUTABLE)
  set(_renamed "${CMAKE_CURRENT_BINARY_DIR}/renamed-host.exe")
  configure_file("${NODE_EXECUTABLE}" "${_renamed}" COPYONLY)
  add_test(NAME load_nodeapi_renamed_host COMMAND "${_renamed}" -e "${_expect_real}" $<TARGET_FILE:addon_nodeapi>)
endif()

if(TARGET node_api_stub AND NOT WIN32 AND NOT APPLE)
  # 3. Static stub + -Bsymbolic: must fail loudly (abort with a message).
  node_api_test_addon(addon_stub_bsymbolic NodeApi::stub)
  target_link_options(addon_stub_bsymbolic PRIVATE "LINKER:-Bsymbolic")
  # 4. Static stub without -Bsymbolic: works through ELF symbol interposition.
  node_api_test_addon(addon_stub_interpose NodeApi::stub)
  if(NODE_EXECUTABLE)
    add_test(NAME stub_bsymbolic_traps
      COMMAND ${NODE_EXECUTABLE} -e "const c=require('child_process').spawnSync(process.execPath,['-e','require(process.argv[1])',process.argv[1]],{encoding:'utf8'});process.stderr.write(c.stderr);process.exit(c.signal==='SIGABRT'&&/node-api-stub: 'napi_create_string_utf8' was called/.test(c.stderr)?0:1)"
              $<TARGET_FILE:addon_stub_bsymbolic>)
    add_test(NAME load_stub_interpose COMMAND ${NODE_EXECUTABLE} -e "${_expect_real}" $<TARGET_FILE:addon_stub_interpose>)
  endif()
endif()

if(TARGET node_api_stub_shared AND NOT WIN32 AND NOT APPLE)
  # 5. Shared stub: correct even with -Bsymbolic, as long as the .so can be found at load time.
  node_api_test_addon(addon_stub_shared NodeApi::stub_shared)
  target_link_options(addon_stub_shared PRIVATE "LINKER:-Bsymbolic")
  set_target_properties(addon_stub_shared PROPERTIES BUILD_RPATH "$<TARGET_FILE_DIR:node_api_stub_shared>")
  if(NODE_EXECUTABLE)
    add_test(NAME load_stub_shared COMMAND ${NODE_EXECUTABLE} -e "${_expect_real}" $<TARGET_FILE:addon_stub_shared>)
  endif()
endif()

# The stub must export exactly the symbols listed in the .def file.
if(TARGET node_api_stub AND CMAKE_NM)
  add_test(NAME stub_exports_all_symbols
    COMMAND ${CMAKE_COMMAND} -DNM=${CMAKE_NM} -DLIB=$<TARGET_FILE:node_api_stub>
            -DDEF=${PROJECT_SOURCE_DIR}/def/node_api.def -P ${CMAKE_CURRENT_SOURCE_DIR}/check_symbols.cmake)
endif()
