cmake_minimum_required(VERSION 3.16)

project(libnode_api LANGUAGES C)

add_library(node_api STATIC node_api.c)
install(TARGETS node_api RUNTIME)
