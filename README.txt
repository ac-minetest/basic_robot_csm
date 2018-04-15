BASIC_ROBOT CSM: lightweight robot mod for client
minetest 0.4.16dev+
(c) 2017 rnd

instructions:
1. unpack in "minetest DIR"/clientmods/
2. enable client mods in advanced settings menu or in minetest.conf
3. inside /clientmods/mods.conf there should be line: load_mod_basic_robot_csm = true
4. while playing say .bot
5. there are 2 example programs in /scripts,
	you can see commands in init.lua, function getSandboxEnv() or for more available commands
	https://github.com/minetest/minetest/blob/master/doc/client_lua_api.md 
	(you might need newer minetest client)


---------------------------------------------------------------------
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
----------------------------------------------------------------------