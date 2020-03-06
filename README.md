# N-API Stub

This repository contains the stub for N-API used to avoid linker error on building
native addon for Node.js using programming languages different from C and C++.

To build the stub you need to execute the following command:

`$ ./build.sh`

If you are on Windows system try to replicate the commands that are on the build 
script reported below:

```bash
#!/bin/bash 

echo Start building process ...  && \

echo Cleanup previous build ... && \
rm -rf ./build && \
rm -rf *.o && \
rm -rf *.a && \
echo Cleanup process completed. && \

# BUILD N-API STUB
echo Start building N-API stub library ...  && \
if [[ "$OSTYPE" == "darwin"* ]]; then
export MACOSX_DEPLOYMENT_TARGET=10.10
fi 

gcc -c node_api.c -DNAPI_EXPERIMENTAL=1 && \
ar -rcs libnode_api.a node_api.o && \
ranlib libnode_api.a && \
mkdir build && \
mv node_api.o ./build/node_api.o && \
mv libnode_api.a ./build/libnode_api.a && \
echo N-API stub library successfully builded. && \

echo Building process successfully ended.
```

## The Team

### Nicola Del Gobbo

<https://github.com/NickNaso/>

<https://www.npmjs.com/~nicknaso>

<https://twitter.com/NickNaso>

## Acknowledgements

Thank you to all people that encourage me every day.

## License

Licensed under [Apache license V2](./LICENSE)