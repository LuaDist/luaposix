# Copyright (C) 2007-2011 LuaDist.
# Created by Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

project ( luaposix C )
cmake_minimum_required ( VERSION 2.6 )
include ( dist.cmake )

set ( FULL_VERSION 5.1.11 )

find_library ( CRYPT_LIB crypt )
find_library ( RT_LIB rt )

add_definitions ( -DVERSION="${FULL_VERSION}" )

if ( APPLE )
  # FIXME:  LDFLAGS_SHARED=-bundle -undefined dynamic_lookup
  # omit rt and crypt?
  add_definitions ( -D_POSIX_C_SOURCE )
else ()
  # FIXME: Make rt conditional on _XOPEN_REALTIME
  add_definitions ( -D_XOPEN_SOURCE=700 )
endif ()

install_lua_module ( posix lposix.c )
target_link_libraries ( posix ${CRYPT_LIB} ${RT_LIB} )

install_data ( README )
install_test ( test.lua )
install_foo ( tree.lua )
# not installed: ChangeLog.old

add_lua_test ( test.lua )
