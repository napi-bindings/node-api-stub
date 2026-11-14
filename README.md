# Node-API Stub

![Node-API Build Matrix](https://github.com/napi-bindings/node-api-stub/workflows/Node-API%20Build%20Matrix/badge.svg)

- [Introduction](#introduction)
- [How it works](#how-it-works)
- [Using it from CMake](#using-it-from-cmake)
- [Targets and options](#targets-and-options)
- [Stub libraries](#stub-libraries)
- [Building and testing](#building-and-testing)
- [Updating the Node-API headers](#updating-the-node-api-headers)
- [Migrating from 8.x](#migrating-from-8x)
- [Code of conduct](CODE_OF_CONDUCT.md)
- [Changelog](CHANGELOG.md)
- [Team](#the-team)
- [Acknowledgements](#acknowledgements)
- [License](#license)

## Introduction

A native addon for Node.js calls the Node-API functions (`napi_*`, `node_api_*`)
exported by the host process (`node`, `node.exe`, Electron, ...). When the addon
is built, those symbols do not exist yet, and some toolchains refuse to link:
Windows always needs an import library, macOS rejects undefined symbols by
default, and on Linux some build systems add `-z defs`.

This project gives CMake projects (and any other build system) everything they
need to link an addon on every platform, without Node.js installed:

- the official Node-API headers, vendored from
  [node-api-headers](https://github.com/nodejs/node-api-headers) (Node-API 10);
- a `NodeApi::NodeApi` target that applies the right link mechanism for the
  platform;
- optional static and shared stub libraries for the cases that need them.

## How it works

The addon must always end up calling the Node-API functions of the host
process. A library with function bodies linked into the addon can be called
instead of them, so the right mechanism depends on the platform:

| Platform | What `NodeApi::NodeApi` does |
|---|---|
| Windows, MSVC / clang-cl (x64, x86, arm64) | links `node_api.lib`, an import library for `NODE.EXE` generated from the official `.def` file, plus `/DELAYLOAD:node.exe` and a delay-load hook so that the addon also loads in hosts with another name (Electron, a renamed `node.exe`) |
| Windows, MinGW / llvm-mingw | links `libnode_api.dll.a`, generated with `dlltool` |
| macOS | `-Wl,-U,_<symbol>` for each Node-API symbol: only those may stay undefined (or `-undefined dynamic_lookup`, see options) |
| Linux, BSD, Android (ELF) | nothing is linked; adds `-z undefs` so that `-z defs` does not reject the Node-API symbols |

The import libraries are generated at configure time, so the project builds
from source anywhere a C compiler is available; prebuilt archives are also
attached to each release.

> **Why not a stub everywhere?** A stub linked into the addon is called instead
> of Node-API when the linker binds the calls inside the addon: always on
> Windows and macOS, and on Linux when the addon is linked with `-Bsymbolic`.
> `go build -buildmode=c-shared` always passes `-Bsymbolic`, so a Go addon
> linked with the static stub calls the empty functions. The tests in
> [`tests/`](tests/CMakeLists.txt) reproduce this case.

## Using it from CMake

```cmake
# A) from source (recommended)
include(FetchContent)
FetchContent_Declare(node_api_stub
  GIT_REPOSITORY https://github.com/napi-bindings/node-api-stub.git
  GIT_TAG        v10.0.0)
FetchContent_MakeAvailable(node_api_stub)

# B) from an installed package or a release archive
# find_package(NodeApi 10 REQUIRED CONFIG)

add_library(my_addon MODULE addon.c)
set_target_properties(my_addon PROPERTIES PREFIX "" SUFFIX ".node")
target_link_libraries(my_addon PRIVATE NodeApi::NodeApi)
```

`add_subdirectory(node-api-stub)` works the same way as `FetchContent`.

## Targets and options

| Target | Content |
|---|---|
| `NodeApi::NodeApi` | **use this one.** Headers, `NAPI_VERSION`, `BUILDING_NODE_EXTENSION` and the platform link mechanism |
| `NodeApi::headers` | headers and compile definitions only |
| `NodeApi::stub` | static stub, position-independent |
| `NodeApi::stub_shared` | shared stub |
| `NodeApi::legacy` | alias of `NodeApi::stub`, for projects that used the old `node_api` target |

| Option | Default | Effect |
|---|---|---|
| `NODE_API_VERSION` | `8` | `NAPI_VERSION` defined for consumers; `experimental` defines `NAPI_EXPERIMENTAL`; empty to leave it to the consumer |
| `NODE_API_BUILD_STUB_STATIC` | ON on ELF, OFF on Windows/macOS | build `NodeApi::stub` |
| `NODE_API_BUILD_STUB_SHARED` | ON on ELF, OFF on Windows/macOS | build `NodeApi::stub_shared` |
| `NODE_API_ELF_ALLOW_UNDEFINED` | ON | add `-z undefs` on ELF |
| `NODE_API_MACOS_UNDEFINED` | `symbols` | `symbols` (`-U` per Node-API symbol) or `dynamic_lookup` |
| `NODE_API_WIN_DELAY_LOAD` | ON | MSVC: delay-load `node.exe` and redirect it to the host executable |
| `NODE_API_INSTALL` | ON when top level | install and export rules |
| `NODE_API_BUILD_TESTS` | ON when top level | tests that load the addons in Node.js |

When the project is used as a dependency, the stub libraries are excluded from
`all` and are built only if a target links them.

## Stub libraries

The stubs are generated from `def/node_api.def`: each function prints its own
name and calls `abort()`. They must never run; if they do, the addon fails
loudly instead of carrying on with uninitialised values.

- **Static (`libnode_api_stub.a`)**: for toolchains that need an archive to
  link and do not accept linker options. On ELF it works only through symbol
  interposition: do not use it with `-Bsymbolic`, and therefore not with Go
  `-buildmode=c-shared`.
- **Shared (`libnode_api_stub.so`)**: correct even with `-Bsymbolic`, but the
  addon records a `DT_NEEDED` entry for it: remove it after linking
  (`patchelf --remove-needed libnode_api_stub.so addon.node`) or ship the
  library next to the addon.
- **Windows and macOS**: not recommended; built only on explicit request.

Other options that avoid the link problem entirely are resolving the Node-API
functions at run time (`dlsym(RTLD_DEFAULT, ...)` / `GetProcAddress`), as
[napi-rs](https://napi.rs) does, or declaring them as weak references on ELF
(`#pragma weak napi_create_object`).

## Building and testing

You need CMake 3.16 or later and a C compiler. Node.js is optional and is used
only by the tests, which load the test addons and check that their calls reach
the real Node-API.

```
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure
cmake --install build --config Release --prefix ./dist
```

On Windows use the Visual Studio generator (`-A x64`, `-A Win32`, `-A ARM64`)
or MinGW / llvm-mingw with `-G Ninja`.

## Updating the Node-API headers

`include/` and `def/` come unmodified from the
[node-api-headers](https://www.npmjs.com/package/node-api-headers) npm package.
To update them (Node.js and npm are not needed):

```
cmake -DVERSION=1.9.0 -P scripts/update-node-api-headers.cmake
```

## Migrating from 8.x

- The headers moved from the repository root to `include/`; `node_api.c` is
  now generated.
- Replace the `node_api` target with `NodeApi::NodeApi`. If you really need the
  old static archive, link `NodeApi::legacy` (on ELF only).
- The static library is now called `libnode_api_stub.a`, and its functions
  abort instead of returning `napi_ok`.

## The Team

### Nicola Del Gobbo

<https://github.com/NickNaso/>

<https://www.npmjs.com/~nicknaso>

<https://twitter.com/NickNaso>

## Acknowledgements

Thank you to all people that encourage me every day.

## License

Licensed under [Apache license V2](./LICENSE).

The files in `include/` and `def/` come from
[node-api-headers](https://github.com/nodejs/node-api-headers) and are
licensed under the MIT license (see `def/LICENSE-node-api-headers`).
