# Node-API Stub

![Node-API Build Matrix](https://github.com/napi-bindings/node-api-stub/workflows/Node-API%20Build%20Matrix/badge.svg)

- [Introduction](#introduction)
- [Building](#building)
- [Code of conduct](CODE_OF_CONDUCT.md)
- [Changelog](CHANGELOG.md)
- [Team](#team)
- [Acknowledgments](#acknowledgements)
- [License](#license)

## Introduction

This repository contains the stub for Node-API used to avoid linker error on 
building native addon for Node.js using programming languages different from 
C and C++.

## Building

The main purpose of this reposistory is to build Node-API static library that 
you could include on your project. On release you can find the build for the 
following operating systems:

- **Windows**
- **Ubuntu 20.04**
- **Ubuntu 18.04**
- **Ubuntu 16.04**
- **macOS**

If you want to build the Node-API library on your own the first step is to 
clone this repository:

`> git clone https://github.com/napi-bindings/node-api-stub.git`

### Building on Windows

You will need to install **GCC** for Windows and **CMake**.

#### Install GCC compiler

- Download the right version for your system from this **[link](https://jmeubank.github.io/tdm-gcc/download/)**.
- Be sure that **gcc** in in your path of execution.

#### Install CMake

- Download the right version for your system from this **[link](https://cmake.org/download/)**.
- Be sure that **cmake** is in your path of execution.

#### Configure and build

Open your shell and execute the commands reported below:

```
mkdir ./build
cmake \
-DCMAKE_MAKE_PROGRAM=mingw32-make.exe \
-DCMAKE_C_COMPILER=gcc.exe \
-DCMAKE_CXX_COMPILER=g++.exe \
-DCMAKE_BUILD_TYPE=Release \
-G "CodeBlocks - Unix Makefiles" \
-S ./ \
-B ./build
cmake --build ./build
```

`-DCMAKE_BUILD_TYPE` could be set with one of the following two values:

- Release
- Debug

### Building on Unix-like platform

You will need to install **C / C++** compiler and **CMake**.

#### Prerequisistes to build on Linux

These steps were tested on: 

- **Ubuntu 16.04** 
- **Ubuntu 18.04** 
- **Ubuntu 20.04**

First, you will need to install dependencies:

```
sudo apt-get update
sudo apt-get install build-essential -y
sudo apt-get install cmake -y
```
#### Prerequisites to build on macOS

These steps were tested on macOS Catalina (10.15).

First, you will need to install dependencies:

- Install [Xcode](https://developer.apple.com/xcode/download/)
   - You also need to install the `XCode Command Line Tools` by running 
   `xcode-select --install`. Alternatively, if you already have the full Xcode 
   installed, you can find them under the menu 
   `Xcode -> Open Developer Tool -> More Developer Tools...`. This step will 
   install `clang`, `clang++`, and `make`.
- Install [Homebrew](https://brew.sh/)
- Install and `cmake` running the following command:
```
brew install cmake
```

#### Configure and build

Open your shell and execute the commands reported below:

```
mkdir ./build
cmake \
-DCMAKE_BUILD_TYPE=Release \
-G "Unix Makefiles" \
-S ./ \
-B ./build
cmake --build ./build
```

`-DCMAKE_BUILD_TYPE` could be set with one of the following two values:

- Release
- Debug

## The Team

### Nicola Del Gobbo

<https://github.com/NickNaso/>

<https://www.npmjs.com/~nicknaso>

<https://twitter.com/NickNaso>

## Acknowledgements

Thank you to all people that encourage me every day.

## License

Licensed under [Apache license V2](./LICENSE)