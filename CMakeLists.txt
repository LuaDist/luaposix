# Copyright (C) 2007-2011 LuaDist.
# Created by Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

PROJECT(luaposix C)
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
INCLUDE(dist.cmake)

set ( FULL_VERSION 5.1.9 )

FIND_LIBRARY(CRYPT_LIB crypt)
FIND_LIBRARY(RT_LIB rt)

add_definitions ( -DVERSION="${FULL_VERSION}" )

if ( APPLE )
  # FIXME:  LDFLAGS_SHARED=-bundle -undefined dynamic_lookup
  # omit rt and crypt?
else ()
  # FIXME: Make rt conditional on _XOPEN_REALTIME
  add_definitions ( -D_XOPEN_SOURCE=700 )
endif ()


ADD_LUA_MODULE(posix lposix.c)
TARGET_LINK_LIBRARIES(posix ${CRYPT_LIB} ${RT_LIB})

ADD_LUA_TEST(test.lua)

INSTALL (TARGETS posix DESTINATION ${INSTALL_CMOD})
INSTALL (FILES README DESTINATION ${INSTALL_DATA})
INSTALL (FILES test.lua DESTINATION ${INSTALL_TEST})
INSTALL (FILES tree.lua DESTINATION ${INSTALL_FOO})
# not installed: ChangeLog.old

