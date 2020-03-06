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