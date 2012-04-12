# LuaDist CMake utility library for Lua.
# 
# Copyright (C) 2007-2012 LuaDist.
# by David Manura, Peter Drahos
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

set ( INSTALL_LMOD ${INSTALL_LIB}/lua CACHE PATH "Directory to install Lua modules." )
set ( INSTALL_CMOD ${INSTALL_LIB}/lua CACHE PATH "Directory to install Lua binary modules." )

option ( SKIP_LUA_WRAPPER "Do not build and install Lua executable wrappers." OFF)

# install_lua_executable ( target source )
# Automatically generate a binary wrapper for lua application and install it
# The wrapper and the source of the application will be placed into /bin
# If the application source did not have .lua suffix then it will be added
# USE: lua_executable ( sputnik src/sputnik.lua )
macro ( install_lua_executable _name _source )
  get_filename_component ( _source_name ${_source} NAME_WE )
  if ( NOT SKIP_LUA_WRAPPER )
    enable_language ( C )
  
    find_package ( Lua51 REQUIRED )
    include_directories ( ${LUA_INCLUDE_DIR} )

    set ( _wrapper ${CMAKE_CURRENT_BINARY_DIR}/${_name}.c )
    set ( _code 
"// Not so simple executable wrapper for Lua apps
#include <stdio.h>
#include <signal.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

lua_State *L\;

static int getargs (lua_State *L, char **argv, int n) {
int narg\;
int i\;
int argc = 0\;
while (argv[argc]) argc++\;
narg = argc - (n + 1)\;
luaL_checkstack(L, narg + 3, \"too many arguments to script\")\;
for (i=n+1\; i < argc\; i++)
  lua_pushstring(L, argv[i])\;
lua_createtable(L, narg, n + 1)\;
for (i=0\; i < argc\; i++) {
  lua_pushstring(L, argv[i])\;
  lua_rawseti(L, -2, i - n)\;
}
return narg\;
}

static void lstop (lua_State *L, lua_Debug *ar) {
(void)ar\;
lua_sethook(L, NULL, 0, 0)\;
luaL_error(L, \"interrupted!\")\;
}

static void laction (int i) {
signal(i, SIG_DFL)\;
lua_sethook(L, lstop, LUA_MASKCALL | LUA_MASKRET | LUA_MASKCOUNT, 1)\;
}

static void l_message (const char *pname, const char *msg) {
if (pname) fprintf(stderr, \"%s: \", pname)\;
fprintf(stderr, \"%s\\n\", msg)\;
fflush(stderr)\;
}

static int report (lua_State *L, int status) {
if (status && !lua_isnil(L, -1)) {
  const char *msg = lua_tostring(L, -1)\;
  if (msg == NULL) msg = \"(error object is not a string)\"\;
  l_message(\"${_source_name}\", msg)\;
  lua_pop(L, 1)\;
}
return status\;
}

static int traceback (lua_State *L) {
if (!lua_isstring(L, 1))
  return 1\;
lua_getfield(L, LUA_GLOBALSINDEX, \"debug\")\;
if (!lua_istable(L, -1)) {
  lua_pop(L, 1)\;
  return 1\;
}
lua_getfield(L, -1, \"traceback\")\;
if (!lua_isfunction(L, -1)) {
  lua_pop(L, 2)\;
  return 1\;
}
lua_pushvalue(L, 1)\; 
lua_pushinteger(L, 2)\;
lua_call(L, 2, 1)\;
return 1\;
}

static int docall (lua_State *L, int narg, int clear) {
int status\;
int base = lua_gettop(L) - narg\;
lua_pushcfunction(L, traceback)\;
lua_insert(L, base)\;
signal(SIGINT, laction)\;
status = lua_pcall(L, narg, (clear ? 0 : LUA_MULTRET), base)\;
signal(SIGINT, SIG_DFL)\;
lua_remove(L, base)\;
if (status != 0) lua_gc(L, LUA_GCCOLLECT, 0)\;
return status\;
}

int main (int argc, char **argv) {
L=lua_open()\;
lua_gc(L, LUA_GCSTOP, 0)\;
luaL_openlibs(L)\;
lua_gc(L, LUA_GCRESTART, 0)\;
int narg = getargs(L, argv, 0)\;
lua_setglobal(L, \"arg\")\;

// Script
char script[500] = \"./${_source_name}.lua\"\;
lua_getglobal(L, \"_PROGDIR\")\;
if (lua_isstring(L, -1)) {
  sprintf( script, \"%s/${_source_name}.lua\", lua_tostring(L, -1))\;
} 
lua_pop(L, 1)\;

// Run
int status = luaL_loadfile(L, script)\;
lua_insert(L, -(narg+1))\;
if (status == 0)
  status = docall(L, narg, 0)\;
else
  lua_pop(L, narg)\;

report(L, status)\;
lua_close(L)\;
return status\;
};
")
    file ( WRITE ${_wrapper} ${_code} )
    add_executable ( ${_name} ${_wrapper} )
    target_link_libraries ( ${_name} ${LUA_LIBRARY} )
    install ( TARGETS ${_name} DESTINATION ${INSTALL_BIN} )
  endif()
  install ( PROGRAMS ${_source} DESTINATION ${INSTALL_BIN} RENAME ${_source_name}.lua )
endmacro ()

# install_lua_module
# This macro installs a lua source module into destination given by lua require syntax.
# Binary modules are also supported where this funcion takes sources and libraries to compile separated by LINK keyword
# USE: install_lua_module ( socket.http src/http.lua )
# USE2: install_lua_module ( mime.core src/mime.c )
# USE3: install_lua_module ( socket.core ${SRC_SOCKET} LINK ${LIB_SOCKET} )
macro (install_lua_module _name )
  string ( REPLACE "." "/" _module "${_name}" )
  string ( REPLACE "." "_" _target "${_name}" )
  
  set ( _lua_module "${_module}.lua" )
  set ( _bin_module "${_module}${CMAKE_SHARED_MODULE_SUFFIX}" )
  
  parse_arguments ( _MODULE "LINK" "" ${ARGN} )
  get_filename_component ( _ext ${ARGV1} EXT )
  if ( _ext STREQUAL ".lua" )
      get_filename_component ( _path ${_lua_module} PATH )
      get_filename_component ( _filename ${_lua_module} NAME )
      install ( FILES ${ARGV1} DESTINATION ${INSTALL_LMOD}/${_path} RENAME ${_filename} )
  else ()
     enable_language ( C )
     get_filename_component ( _module_name ${_bin_module} NAME_WE )
     get_filename_component ( _module_path ${_bin_module} PATH )
     
     find_package ( Lua51 REQUIRED )
     include_directories ( ${LUA_INCLUDE_DIR} )
   
     add_library( ${_target} MODULE ${_MODULE_DEFAULT_ARGS})
     target_link_libraries ( ${_target} ${LUA_LIBRARY} ${_MODULE_LINK} )
     set_target_properties ( ${_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${_module_path}" PREFIX "" OUTPUT_NAME "${_module_name}" )
     
     install ( TARGETS ${_target} DESTINATION ${INSTALL_CMOD}/${_module_path})
  endif ()
endmacro ()


# add_lua_test
# Runs Lua script `_testfile` under CTest tester.
# Optional named argument `WORKING_DIRECTORY` is current working directory to run test under
# (defaults to ${CMAKE_CURRENT_BINARY_DIR}).
# Both paths, if relative, are relative to ${CMAKE_CURRENT_SOURCE_DIR}.
# Under LuaDist, set test=true in config.lua to enable testing.
# USE: add_lua_test ( test/test1.lua [args...] [WORKING_DIRECTORY dir])
macro ( add_lua_test _testfile )
	if ( NOT SKIP_TESTING )
		parse_arguments ( _ARG "WORKING_DIRECTORY" "" ${ARGN} )
		include ( CTest )
		find_program ( LUA NAMES lua lua.bat )
		get_filename_component ( TESTFILEABS ${_testfile} ABSOLUTE )
		get_filename_component ( TESTFILENAME ${_testfile} NAME )
		get_filename_component ( TESTFILEBASE ${_testfile} NAME_WE )

		# Write wrapper script.
		set ( TESTWRAPPER ${CMAKE_CURRENT_BINARY_DIR}/${TESTFILENAME} )
		set ( TESTWRAPPERSOURCE
"local configuration = ...
local sodir = '${CMAKE_CURRENT_BINARY_DIR}' .. (configuration == '' and '' or '/' .. configuration)
package.path  = sodir .. '/?.lua\;' .. sodir .. '/?.lua\;' .. package.path
package.cpath = sodir .. '/?.so\;'  .. sodir .. '/?.dll\;' .. package.cpath
arg[0] = '${TESTFILEABS}'
table.remove(arg, 1)
return assert(loadfile '${TESTFILEABS}')(unpack(arg))
"		)
		if ( _ARG_WORKING_DIRECTORY )
			get_filename_component ( TESTCURRENTDIRABS ${_ARG_WORKING_DIRECTORY} ABSOLUTE )
			# note: CMake 2.6 (unlike 2.8) lacks WORKING_DIRECTORY parameter.
#old:		set ( TESTWRAPPERSOURCE "require 'lfs'; lfs.chdir('${TESTCURRENTDIRABS}' ) ${TESTWRAPPERSOURCE}" )
			set ( _pre ${CMAKE_COMMAND} -E chdir "${TESTCURRENTDIRABS}" )
		endif ()
		file ( WRITE ${TESTWRAPPER} ${TESTWRAPPERSOURCE})
		add_test ( NAME ${TESTFILEBASE} COMMAND ${_pre} ${LUA} ${TESTWRAPPER} $<CONFIGURATION> ${_ARG_DEFAULT_ARGS} )
	endif ()
	# see also http://gdcm.svn.sourceforge.net/viewvc/gdcm/Sandbox/CMakeModules/UsePythonTest.cmake
endmacro ()


# Converts Lua source file `_source` to binary string embedded in C source
# file `_target`.  Optionally compiles Lua source to byte code (not available
# under LuaJIT2, which doesn't have a bytecode loader).  Additionally, Lua
# versions of bin2c [1] and luac [2] may be passed respectively as additional
# arguments.
#
# [1] http://lua-users.org/wiki/BinToCee
# [2] http://lua-users.org/wiki/LuaCompilerInLua
function ( add_lua_bin2c _target _source )
	find_program ( LUA NAMES lua lua.bat )
	execute_process ( COMMAND ${LUA} -e "string.dump(function()end)" RESULT_VARIABLE _LUA_DUMP_RESULT ERROR_QUIET )
	if ( NOT ${_LUA_DUMP_RESULT} )
		SET ( HAVE_LUA_DUMP true )
	endif ()
	message ( "-- string.dump=${HAVE_LUA_DUMP}" )

	if ( ARGV2 )
		get_filename_component ( BIN2C ${ARGV2} ABSOLUTE )
		set ( BIN2C ${LUA} ${BIN2C} )
	else ()
		find_program ( BIN2C NAMES bin2c bin2c.bat )
	endif ()
	if ( HAVE_LUA_DUMP )
		if ( ARGV3 )
			get_filename_component ( LUAC ${ARGV3} ABSOLUTE )
			set ( LUAC ${LUA} ${LUAC} )
		else ()
			find_program ( LUAC NAMES luac luac.bat )
		endif ()
	endif ( HAVE_LUA_DUMP )
	message ( "-- bin2c=${BIN2C}" )
	message ( "-- luac=${LUAC}" )

	get_filename_component ( SOURCEABS ${_source} ABSOLUTE )
	if ( HAVE_LUA_DUMP )
		get_filename_component ( SOURCEBASE ${_source} NAME_WE )
		add_custom_command (
			OUTPUT  ${_target} DEPENDS ${_source}
			COMMAND ${LUAC} -o ${CMAKE_CURRENT_BINARY_DIR}/${SOURCEBASE}.lo ${SOURCEABS}
			COMMAND ${BIN2C} ${CMAKE_CURRENT_BINARY_DIR}/${SOURCEBASE}.lo ">${_target}" )
	else ()
		add_custom_command (
			OUTPUT  ${_target} DEPENDS ${SOURCEABS}
			COMMAND ${BIN2C} ${_source} ">${_target}" )
	endif ()
endfunction()