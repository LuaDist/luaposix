# Copyright (C) 2007-2012 LuaDist.
# Created by Peter Kapec, David Manura
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

project ( luaposix C )
cmake_minimum_required ( VERSION 2.6 )
include ( cmake/dist.cmake )
include ( cmake/lua.cmake )

set ( VERSION 5.1.19 )

find_package ( Curses REQUIRED )
# config.h.cmake variables
foreach ( _name HAVE_CURSES_H HAVE_NCURSES_H HAVE_NCURSES_NCURSES_H HAVE_NCURSES_CURSES_H )
  if ( CURSES_${_name} )
    set ( ${_name} 1 )
  endif ()
endforeach ()

include ( CheckFunctionExists )
check_function_exists ( strlcpy HAVE_STRLCPY )  # for config.h.cmake

find_library ( CRYPT_LIB crypt )
find_library ( RT_LIB rt )
find_package ( Perl )  # for documentation only (optional)

add_definitions ( -DVERSION="${VERSION}" )

if ( APPLE )
  # FIXME:  LDFLAGS_SHARED=-bundle -undefined dynamic_lookup
  # omit rt and crypt?
  add_definitions ( -D_POSIX_C_SOURCE )
else ()
  # FIXME: Make rt conditional on _XOPEN_REALTIME
  add_definitions ( -D_XOPEN_SOURCE=700 )
endif ()

configure_file ( config.h.cmake config.h )
include_directories ( ${CMAKE_CURRENT_BINARY_DIR} )

install_lua_module ( posix_c lposix.c )
target_link_libraries ( posix_c ${CRYPT_LIB} ${RT_LIB} )
install_lua_module ( posix posix.lua )

install_lua_module ( curses_c lcurses.c )
install_lua_module ( curses curses.lua )
target_link_libraries ( curses_c ${CURSES_LIBRARIES} )

install_data ( README COPYING )
install_foo ( tree.lua )
# not installed: ChangeLog.old

# docs
if ( PERL_EXECUTABLE )
  add_custom_command ( OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/curses.html"
    COMMAND "${CMAKE_COMMAND}" -E copy
      "${CMAKE_CURRENT_SOURCE_DIR}/lcurses.c"
      "${CMAKE_CURRENT_BINARY_DIR}/lcurses.c"
    COMMAND "${PERL_EXECUTABLE}" ${CMAKE_CURRENT_SOURCE_DIR}/make_lcurses_doc.pl
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/make_lcurses_doc.pl lcurses.c
  )
  add_custom_target ( html ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/curses.html )
  install_doc ( ${CMAKE_CURRENT_BINARY_DIR}/curses.html )
endif ()

# tests
add_lua_test ( tests-posix.lua )
add_lua_test ( tests-curses.lua )
file ( WRITE ${CMAKE_CURRENT_BINARY_DIR}/tmp.la "" ) # for tests-posix.lua
