-- CLIENTSIDE basic_robot by rnd, 2017


basic_robot = {};
basic_robot.version = "04/15/2018b";
basic_robot.data = {}; -- stores all robot data
basic_robot.data.rom = {}


basic_robot.commands = {};
timestep  = 1; -- how often to run robot
running = 1; -- is robot running?

local cbuffer = {}; --chat buffer
local mod_storage = minetest.get_mod_storage()

--dofile(minetest.get_modpath("basic_robot").."/commands.lua")


-- SANDBOX for running lua code isolated and safely

function getSandboxEnv ()
	
	local commands = basic_robot.commands;
	local directions = {left = 1, right = 2, forward = 3, backward = 4, up = 5, down = 6, 
		left_down = 7, right_down = 8, forward_down = 9, backward_down = 10,
		left_up = 11, right_up = 12, forward_up = 13,  backward_up = 14
		}
	
	local env = 
	{
		pcall=pcall,
		robot_version = function() return basic_robot.version end,
		
		self = {
			pos = function() return minetest.localplayer:get_pos() end,
			name = function() return minetest.localplayer:get_name() end,
			viewdir = function() 
				local player = minetest.localplayer;
				local yaw = player:get_last_look_horizontal()
				local pitch = player:get_last_look_vertical(); 
				return {x=math.cos(yaw)*math.cos(pitch), y=math.sin(pitch), z=math.sin(yaw)*math.cos(pitch)} 
			end,
			
			listen_msg = function() 
				return cbuffer.read()
			end,
			
			msg_filter = function(filter, hide_msg) -- only records messages that match filter!, hide_msg = true -> dont display message
				basic_robot.data.msg_filter = filter; 
				basic_robot.data.hide_msg = hide_msg 
			end, 
		
			sent_msg = function() 
				local msg = basic_robot.data.sent_msg
				basic_robot.data.sent_msg = nil
				return msg
			end,

			read_form = function()
				local formname = basic_robot.data.formname;
				if not formname then return end
				local fields = basic_robot.data.fields;
				basic_robot.data.formname = nil; 
				return formname,fields
			end,
			
			remove = function()
				error("abort")
			end,
			
			-- display_text = function(text,linesize,size)
				-- local obj = basic_robot.data[name].obj;
				-- return commands.display_text(obj,text,linesize,size)
			-- end,
			
			sound = function(sample,volume)
				return minetest.sound_play( sample,
				{
					gain = volume or 1, 
				})
			end,
			
			sound_stop = function(handle)
				minetest.sound_stop(handle)
			end,
			
		},

		-- crypto = {-- basic cryptography - encryption, scramble, mod hash
			-- encrypt = commands.crypto.encrypt, 
			-- decrypt = commands.crypto.decrypt, 
			-- scramble = commands.crypto.scramble, 
			-- basic_hash = commands.crypto.basic_hash,
			-- };
		
		-- keyboard = {
			-- get = function() return commands.keyboard.get(name) end,
			-- set = function(pos,type) return commands.keyboard.set(basic_robot.data[name],pos,type) end,
			-- read = function(pos) return minetest.get_node(pos).name end,
		-- },
		
		say = function(text, toserver)
			if toserver then 
				minetest.send_chat_message(text)
			else
				minetest.display_chat_message(text)
			end
		end,
		
		
		code = { -- TODO
			set = function(text) -- replace bytecode in sandbox with this
				local err = commands.setCode( name, text ); -- compile code
				if err then
					minetest.chat_send_player(name,"#ROBOT CODE COMPILATION ERROR : " .. err) 
					local obj = basic_robot.data[name].obj;
					obj:remove();
					basic_robot.data[name].obj = nil;
					return
				end
			end,
			
			run = function(script)
				if basic_robot.data[name].isadmin ~= 1 then
					local err = check_code(script);
					script = preprocess_code(script);
					if err then 
						minetest.chat_send_player(name,"#ROBOT CODE CHECK ERROR : " .. err) 
						return 
					end
				end
				
				local ScriptFunc, CompileError = loadstring( script )
				if CompileError then
					minetest.chat_send_player(name, "#code.run: compile error " .. CompileError )
					return false
				end
			
				setfenv( ScriptFunc, basic_robot.data[name].sandbox )
			
				local Result, RuntimeError = pcall( ScriptFunc );
				if RuntimeError then
					minetest.chat_send_player(name, "#code.run: run error " .. RuntimeError )
					return false
				end
				return true
			end
		},
		
		rom = basic_robot.data.rom,
		
		string = {
			byte = string.byte,	char = string.char,
			find = string.find,
			format = string.format,	gsub = string.gsub,
			gmatch = string.gmatch,
			len = string.len, lower = string.lower,
			upper = string.upper, rep = string.rep,
			reverse = string.reverse, sub = string.sub,
		},
		math = {
			abs = math.abs,	acos = math.acos,
			asin = math.asin, atan = math.atan,
			atan2 = math.atan2,	ceil = math.ceil,
			cos = math.cos,	cosh = math.cosh,
			deg = math.deg,	exp = math.exp,
			floor = math.floor,	fmod = math.fmod,
			frexp = math.frexp,	huge = math.huge,
			ldexp = math.ldexp,	log = math.log,
			log10 = math.log10,	max = math.max,
			min = math.min,	modf = math.modf,
			pi = math.pi, pow = math.pow,
			rad = math.rad,	random = math.random,
			sin = math.sin,	sinh = math.sinh,
			sqrt = math.sqrt, tan = math.tan,
			tanh = math.tanh,
			},
		table = {
			concat = table.concat,
			insert = table.insert,
			maxn = table.maxn,
			remove = table.remove,
			sort = table.sort,
		},
		os = {
			clock = os.clock,
			difftime = os.difftime,
			time = os.time,
			date = os.date,			
		},
		
		colorize = core.colorize,
		tonumber = tonumber, pairs = pairs,
		ipairs = ipairs, error = error, type=type,
		minetest = minetest,
		_G = _G,
		
	};
	return env	
end


local function CompileCode ( script )
	
	local ScriptFunc, CompileError = loadstring( script )
	if CompileError then
        return nil, CompileError
    end
	return ScriptFunc, nil
end

local function initSandbox() 
	basic_robot.data.sandbox = getSandboxEnv();
end

local function setCode(script) -- to run script: 1. initSandbox 2. setCode 3. runSandbox
	local err;
	local bytecode, err = CompileCode ( script );
	if err then return err end
	basic_robot.data.bytecode = bytecode;
	return nil
end

basic_robot.commands.setCode=setCode; -- so we can use it

local function runSandbox( name)
    
	local data = basic_robot.data;
	local ScriptFunc = data.bytecode;
	if not ScriptFunc then 
		return "Bytecode missing."
	end	
	
	setfenv( ScriptFunc, data.sandbox )
	
	local Result, RuntimeError = pcall( ScriptFunc )
	if RuntimeError then
		return RuntimeError
	end
    
    return nil
end

local robot_update_form = function ()
	
	local seltab = robogui["robot"].guidata.seltab;
	--minetest.display_chat_message("DEBUG seltab " .. seltab)
	local code = minetest.formspec_escape(basic_robot.data["code"..seltab]) or "";
	local form;
	local id = 1;
	local tablist = {};
	for i = 1,8 do
		tablist[i] = string.sub(minetest.formspec_escape(basic_robot.data["code"..i]) or (i .. "EMPTY "),1,8)
	end
	
	form  = 
	"size[9.5,8.25]" ..  -- width, height
	"tabheader[0,0;tabs;".. table.concat(tablist,",") ..";".. seltab .. ";true;true]"..
	"textarea[1.25,-0.25;8.75,10.1;code;;".. code.."]"..
	"button_exit[-0.25,-0.25;1.25,1;OK;START]".. 
	"button[-0.25, 0.75;1.25,1;despawn;STOP]"..
	"button[-0.25, 1.75;1.25,1;help;help]"..
	"button[-0.25, 7.75;1.25,1;save;SAVE]"
		
	basic_robot.data.form = form;
end


local timer = 0;
minetest.register_globalstep(function(dtime)
	timer=timer+dtime
	if timer>timestep and running == 1 then 
		timer = 0;
		local err = runSandbox();
		if err and type(err) == "string" then 
			local i = string.find(err,":");
			if i then err = string.sub(err,i+1) end
			if string.sub(err,-5)~="abort" then
				minetest.display_chat_message("#ROBOT ERROR : " .. err) 
			end
			running = 0; -- stop execution
		end
		return 
	end
	
	return
end)
	

	
-- robogui GUI START ==================================================
robogui = {}; -- a simple table of entries: [guiName] =  {getForm = ... , show = ... , response = ... , guidata = ...}
robogui.register = function(def)
	robogui[def.guiName] = {getForm = def.getForm, show = def.show, response = def.response, guidata = def.guidata or {}}
end

minetest.register_on_formspec_input(
--minetest.register_on_player_receive_fields(
	function(formname, fields)
		local gui = robogui[formname];
		if gui then --run gui
			gui.response(formname,fields) 
		else -- collect data for robot
			basic_robot.data.formname = formname; 
			basic_robot.data.fields = fields; 
		end
	end
)
-- robogui GUI END ====================================================



--process forms from spawner
local on_receive_robot_form = function(formname, fields)
		
		--minetest.display_chat_message(dump(fields))
		
		if fields.tabs then
			local seltab = tonumber(fields.tabs) or 1;
			if seltab>8 then seltab = 8 end
			robogui["robot"].guidata.seltab = seltab;
			robot_update_form();
			minetest.show_formspec("robot", basic_robot.data.form)
			return
		end
		
		if fields.OK then
			local code = fields.code or "";
			local seltab = robogui["robot"].guidata.seltab;
			basic_robot.data["code"..seltab] = code;
			robot_update_form();
			
			initSandbox();

			local err = setCode(code);
			if err then minetest.display_chat_message("#ROBOT CODE COMPILATION ERROR : " .. err); running = 0 return end

			running = 1;
			-- minetest.after(0, -- why this doesnt show??
				-- function()
					-- minetest.show_formspec("robot", basic_robot.data.form); 
				-- end
			-- )
			return
		end
		
		if fields.save then
			local code = fields.code or "";
			local seltab = robogui["robot"].guidata.seltab;
			basic_robot.data["code"..seltab] = code;
			
			robot_update_form();
			
			mod_storage:set_string("code"..seltab, basic_robot.data["code"..seltab])
			minetest.display_chat_message("#ROBOT: code "..seltab .. " saved in mod storage.")
			return
		end
		
		if fields.help then 
			
			local text =  "BASIC LUA SYNTAX\n \nif x==1 then A else B end"..
			"\n  for i = 1, 5 do something end \nwhile i<6 do A; i=i+1; end\n"..
			"\n  arrays: myTable1 = {1,2,3},  myTable2 = {[\"entry1\"]=5, [\"entry2\"]=1}\n"..
			"  access table entries with myTable1[1] or myTable2.entry1 or myTable2[\"entry1\"]\n \n"
			
			text = minetest.formspec_escape(text);
			
			local list = "";
			for word in string.gmatch(text, "(.-)\r?\n+") do list = list .. word .. ", " end
			local form = "size [10,8] textlist[-0.25,-0.25;10.25,8.5;help;" .. list .. "]"
			minetest.show_formspec("robot_help", form);
			
			return
		end
		
		if fields.despawn then
			running = 0
			return
		end
		
end

--INIT GUI
robogui.register(
	{
		guiName = "robot",
		response = on_receive_robot_form,
		guidata = {seltab = 1},
	}
)

-- load code
for i =1,8 do
	basic_robot.data["code"..i] = mod_storage:get_string("code"..i) or ""
end



-- handle chats
	
	cbuffer.size = 10 -- store up to 10 chats
	cbuffer.idx = 0
	cbuffer.data = {};
	cbuffer.t = 0 -- how many unread insertions

	cbuffer.add = function(element) -- insert new element
		local i = cbuffer.idx+1;
		if i > cbuffer.size then i = 1 end
		cbuffer.data[i]=element
		cbuffer.idx = i
		local t = cbuffer.t +1
		if t>cbuffer.size then t = cbuffer.size end
		cbuffer.t =  t
	end

	cbuffer.read = function() -- pop 1 message, return nil if none
		local t = cbuffer.t; 
		if t>0 then
			cbuffer.t = t-1
			local idx = cbuffer.idx;
			if idx>1 then cbuffer.idx = idx - 1 else cbuffer.idx = cbuffer.size end
			return cbuffer.data[idx];
		end
	end

--minetest.register_on_receiving_chat_message( -- 0.4.16dev
core.register_on_receiving_chat_messages( -- 0.4.16 original!
function(message)
	local data = basic_robot.data;
	if data.msg_filter and not string.find(message,data.msg_filter) then return false end -- only listens if chat contains filter pattern!
	cbuffer.add(message);
	return (data.hide_msg == true); -- if hide_msg was set to true msg wont be visible to player
end
)


-- minetest.register_on_sending_chat_message( --0.4.16dev
core.register_on_sending_chat_messages( -- 0.4.16 original!
	function(message)
		if string.sub(message,1,1) == "," then 
			basic_robot.data.sent_msg = string.sub(message,2)
			return 	true
		end
	end
)


minetest.register_chatcommand("b", {
	description = "display robot gui, 0/1/2 to pause/start/resume bot",
	func = function(param)
		if param == "0" then 
			minetest.display_chat_message("#ROBOT: paused.")
			running = 0; return
		elseif param == "2" then
			minetest.display_chat_message("#ROBOT: resumed.")
			running = 1; return
		elseif param == "1" then
			initSandbox();
			local seltab = robogui["robot"].guidata.seltab;
			local err = setCode(basic_robot.data["code"..seltab]);
			if err then minetest.display_chat_message("#ROBOT CODE COMPILATION ERROR : " .. err); running = 0 return end
			running = 1;
			minetest.display_chat_message("#ROBOT: started.")
			return
		end
		robot_update_form(); local form  = basic_robot.data.form;
		minetest.show_formspec("robot", form)
	end
})
