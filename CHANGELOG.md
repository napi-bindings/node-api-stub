# node-api-stub Changelog

## Unreleased Version 10.0.0

### Notable changes

- Updated to Node-API version 10. Headers and the `.def` files are vendored
  unmodified from `node-api-headers` 1.9.0 (155 symbols); 9 symbols were missing
  in 8.0.0.
- New `NodeApi::NodeApi` CMake target that applies the right link mechanism for
  each platform: import library for `NODE.EXE` with a delay-load hook on
  Windows (MSVC and MinGW), `-U` for each Node-API symbol on macOS, nothing on
  ELF platforms.
- The project can be consumed with `FetchContent`, `add_subdirectory` and
  `find_package(NodeApi)` (exported targets and package config files).
- The stub source is generated from the `.def` file. Static and shared stub
  libraries are optional and abort with a message when called, instead of
  returning `napi_ok` with uninitialised results.
- New tests that load the addons in Node.js, including the `-Bsymbolic` case.
- New build matrix: Linux x64/arm64 (glibc and musl), macOS universal, Windows
  x64/x86/arm64 (MSVC) and x64 (MinGW).

### Breaking changes

- Headers moved from the repository root to `include/`; `node_api.c` removed.
- The `node_api` target and `libnode_api.a` are replaced by `NodeApi::NodeApi`
  and, for the static stub, `NodeApi::stub` / `libnode_api_stub.a`
  (`NodeApi::legacy` is an alias of it).

## 2021-03-27 Version 8.0.0, @NickNaso

### Notable changes

- Updated to Node-API version 8.

### Commits

* [[`09510f9b81`](https://github.com/nodejs/node/commit/09510f9b81)] - Update Node-API to version 8. (NickNaso)

## 2021-01-29 Version 7.0.0, @NickNaso

### Notable changes

- Updated to Node-API version 7.
- Added github action to build the library stub.
- Updated all documentation for the project.

### Commits

* [[`e27403db95`](https://github.com/nodejs/node/commit/e27403db95)] - Fixed doc. (NickNaso)
* [[`446216d350`](https://github.com/nodejs/node/commit/446216d350)] - Fixed typo. (NickNaso)
* [[`edaf24e20c`](https://github.com/nodejs/node/commit/edaf24e20c)] - Updated the doc. (NickNaso)
* [[`9df8a871bf`](https://github.com/nodejs/node/commit/9df8a871bf)] - Fixed build for macOS. (NickNaso)
* [[`2d710fa2e7`](https://github.com/nodejs/node/commit/2d710fa2e7)] - Fixed build for unix systems. (NickNaso)
* [[`31b172d9f7`](https://github.com/nodejs/node/commit/31b172d9f7)] - Added action to build the library. (NickNaso)
* [[`8121b5c812`](https://github.com/nodejs/node/commit/8121b5c812)] - Updated Node-API to version 7. (NickNaso)