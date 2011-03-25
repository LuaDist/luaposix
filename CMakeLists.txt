# Copyright (C) 2007-2009 LuaDist.
# Created by Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

PROJECT(luaposix C)
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
INCLUDE(dist.cmake)

FIND_LIBRARY(CRYPT_LIB crypt)
ADD_LUA_MODULE(posix lposix.c)
TARGET_LINK_LIBRARIES(posix ${CRYPT_LIB})

ADD_LUA_TEST(test.lua) #~2DO - doesn't run in source dir

INSTALL (TARGETS posix DESTINATION ${INSTALL_CMOD})
INSTALL (FILES ChangeLog README DESTINATION ${INSTALL_DATA})
INSTALL (FILES test.lua DESTINATION ${INSTALL_TEST})
INSTALL (FILES tree.lua DESTINATION ${INSTALL_FOO})
