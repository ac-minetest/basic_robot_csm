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

--dofile(minetest.get_modpath("basic_robot_csm").."scripts/misc/crypto/encrypt.lua") -- doesnt work, blocked access in mod




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


--CANT USE DOFILE CAUSE CSM BLOCKING READ FILE ACCESS SO CODE INCLUDED HERE:


--OPTIONAL: (un)comment to use
--[[ -- ]]




-- BIGNUM by rnd v05122018b
-- functions: 
--	new, tostring, rnd, import/exportdec,import/exporthex _add, _sub, mul, div2, div, is_larger, is_equal, add, sub,
--	binary2base, base2binary
--	bignum.barrett, bignum.mod, bignum.modpow

bignum = {};
bignum.new = function(base,sgn, digits)
	local ret = {};
	ret.base = base -- base of digit system
	ret.digits = {};
	ret.sgn = sgn -- sign of number,+1 or -1
	local data = ret.digits;
	local m = #digits;
	ret.digits = digits; -- THIS SEEMS TO MAKE A NEW COPY! if you work on this original wont change
	--for i=1,m do data[i] = digits[m-i+1] end -- copy
	return ret
end

bignum.rnd = function(base,sgn, length) -- random number
	local ret = {};
	for i =1,length do ret[#ret+1] = math.random(base)-1 end
	return bignum.new(base,sgn,ret)
end

bignum.tostring = function(n)
	local ret =  {};
	for i = #n.digits,1,-1 do ret[#ret+1] = n.digits[i] end
	return (n.sgn>0 and "" or "-") .. table.concat(ret,"'") .. "_" ..n.base
end

--n1 = bignum.new(10,-1,{5,7,3,1})
--say(bignum.tostring(n1))

bignum.importdec = function(ndec)
	local ret = {};
	local sgn = ndec>0 and 1 or -1;
	local base = 10;
	local n = ndec*sgn;
	local data = {};
	while n>0 do
		local r = n%base
		data[#data+1] = r;
		n=(n-r)/base
	end
	ret.base = base; ret.sgn = sgn; ret.digits = data;
	return ret
end

bignum.exportdec = function(n) -- warning: can cause overflow if number larger than 2^52 ~ 4.5*10^15
	local ndec = 0;
	for i = #n.digits,1,-1 do ndec = 10*ndec + n.digits[i] end
	return ndec*n.sgn
end

bignum.importhex = function(hex) -- nhex is string with characters 0-9(48-57) and a-f(97-102)
	local ret = {sgn=1,base = 16, digits = {}};
	local data = ret.digits;
	local length = string.len(hex);
	for i = length,1,-1 do
		local c = string.byte(hex,i)
		if c>=48 and c<=57 then
			data[length-i+1] = c-48
		elseif c>=97 and c<=102 then
			data[length-i+1]=c-97+10
		end
	end
	return ret
end

bignum.exporthex = function(nhex) -- returns string with hex
	if nhex.base~=16 then return end
	local data = nhex.digits;
	local ret = {};
	for i = #data,1,-1 do
		local c = data[i];
		if c<10 then ret[#ret+1] =  string.char(48+c) else ret[#ret+1] =  string.char(97+c-10) end
	end
	return table.concat(ret,"")
end


-----------------------------------------------
--	ADDITION
-----------------------------------------------


bignum._add = function(n1,n2,res) -- assume both >0, same base: n1+n2 -> res
	local b = n1.base;
	local m1 = #n1.digits;
	local m2 = #n2.digits
	local m = m1; if m2<m then m = m2 end
	local M = m1;if m2>M then M = m2 end
	
	local data1 = n1.digits; local data2 = n2.digits;
	res.digits = {} -- expensive?
	local data = res.digits; local carry = 0;
	for i = 1,M do
		local j = (data1[i] or 0) +(data2[i] or 0) + carry;
		if j >=b then carry = 1; j = j-b else carry = 0 end
		data[i] = j
	end
	if carry== 1 then data[M+1] = 1 end
	res.base = n1.base
end


-----------------------------------------------
--	SUBTRACTION
-----------------------------------------------

bignum._sub = function(n1,n2,res) -- assume n1>n2>0, same base: n1-n2 -> res
	local b = n1.base;
	local m1 = #n1.digits;
	local m2 = #n2.digits
	local m = m1; if m2<m then m = m2 end
	local M = m1;if m2>M then M = m2 end
	
	local data1 = n1.digits; local data2 = n2.digits;
	res.digits = {};
	local data = res.digits; local carry = 0;
	local maxi = 0;
	for i = 1,M do
		local j = (data1[i] or 0) - (data2[i] or 0) + carry;
		if j < 0 then carry = -1; j = j+b else carry = 0 end
		if j~=0 then maxi = i end -- max nonzero digit
		data[i] = j
	end
	
	for i = maxi+1,M do	data[i] = nil end -- remove trailing zero digits if any
	res.base = n1.base
end


bignum.is_equal = function(n1,n2) -- assume both >0, same base. return true if n1==n2
	local b = n1.base;
	local data1 = n1.digits; local data2 = n2.digits;
	if #data1~=#data2 then return false end
	for i =#data1,1,-1 do -- from high bits
		local d1 = data1[i];
		local d2 = data2[i];
		if d1~=d2 then return false end
	end
	return true -- all digits were ==
end

bignum.is_larger = function(n1,n2) -- assume both >0, same base. return true if n1>=n2
	local b = n1.base;
	local data1 = n1.digits; local data2 = n2.digits;
	if #data1>#data2 then return true elseif #data1<#data2 then return false end
	--remains when both same lentgth
	for i =#data1,1,-1 do -- from high bits
		local d1 = data1[i];
		local d2 = data2[i];
		if d1>d2 then return true elseif d1<d2 then return false end
	end
	return true -- all digits were >=, still larger
end

bignum.add = function(n1,n2,res) -- handle all cases, >0 or <0
	local sgn1 = n1.sgn;
	local sgn2 = n2.sgn;
	if sgn1*sgn2>0 then bignum._add(n1,n2,res); res.sgn = sgn1; return end -- simple case
	
	local is_larger = bignum.is_larger(n1,n2) -- is abs(n1)>abs(n2) ?
	local sgn = 1;
	if is_larger then sgn = sgn1 else sgn = sgn2 end
	
	if is_larger then 
		bignum._sub(n1,n2,res);
	else
		bignum._sub(n2,n1,res);
	end
	res.sgn = sgn
end

bignum.sub = function(n1,n2,res) -- handle all cases, >0 or <0
	--just add(n1,-n2)
	local sgn1 = n1.sgn;
	local sgn2 = -n2.sgn;
	if sgn1*sgn2>0 then bignum._add(n1,n2,res); res.sgn = sgn1; return end -- simple case
	
	local is_larger = bignum.is_larger(n1,n2) -- is abs(n1)>abs(n2) ?
	local sgn = 1;
	if is_larger then sgn = sgn1 else sgn = sgn2 end
	
	if is_larger then 
		bignum._sub(n1,n2,res);
	else
		bignum._sub(n2,n1,res);
	end
	res.sgn = sgn
end


-----------------------------------------------
--	MULTIPLY 
-----------------------------------------------

bignum.mul = function(n1,n2,res)
	
	local base = n1.base
	local sgn = n1.sgn*n2.sgn;
	
	local data1 = n1.digits; local m1 = #data1;
	local data2 = n2.digits; local m2 = #data2;
	
	res.digits = {}; res.base = base
	local data = res.digits; local m = m1+m2;
	
	local carry = 0
	for i = 1, m1 do
		-- multiply i-th digit of data1 and add to res
		local d1 = data1[i];
		carry  = 0
		for j = 1,m2 do
			local d2 = data2[j];
			local d = carry + d1*d2;
			local r =  (data[i+j-1] or 0) + d
			if r>=base then 
				data[i+j-1] = r % base; carry = (r - (r%base))/base 
			else 
				data[i+j-1] = r; carry = 0
			end
		end
		if carry>0 then data[i+m2] = carry % base end
	end
end


-- m = 300, base 2^26, 100 repeats: amd ryzen 1200: 0.1s, amd-e350 apu 1.6ghz (2010) : 5.15s
mul_bench = function()
	local m = 300;
	local base = 2^26
	local r = 100
	
	local n1 = bignum.rnd(base, 1, m)
	local n2 = bignum.rnd(base, 1, m)
	local res = {digits = {}};
	local t = os.clock()
	for i = 1, r do	bignum.mul(n1,n2,res) end
	local elapsed = os.clock() - t;
	--say("n1 = " .. bignum.tostring(n1) .. ", n2 = " .. bignum.tostring(n2))
	say("mul benchmark. ".. m .. " digits, base " .. base .. ", repeats " .. r ..  " -> time " .. elapsed)
end
--mul_bench()


-----------------------------------------------
--	DIVIDE
-----------------------------------------------

bignum.div2 = function(n,res) -- res = n/2, return n % 2. note: its safe to do: bignum.div2(res,res);
	
	local base = n.base;
	local data = n.digits; local m = #data;
	
	res.digits = {};
	local rdata = res.digits;
	local carry = 0
	
	local q = data[m]/2; 
	local fq = math.floor(q);
	if q~=fq then carry = base end
	if fq>0 then rdata[m] = fq else rdata[m]=nil end -- maybe digits shrink by 1?
	
	for i = m-1,1,-1 do
		local q = (data[i]+carry)/2;
		local fq = math.floor(q)
		if q~= fq then carry = base else carry = 0 end
		rdata[i] = fq;
	end
	if carry ~= 0 then return 1 else return 0 end
end

bignum.div = function(N,D, res) -- res = [N/D]
	
	local base = N.base;
	res.base = base
	res.digits = {}; 
	local data = res.digits; 
	
	local n1 = #N.digits;local n2 = #D.digits;
	-- trivial cases, prevent wasting time here
	if n1<n2 then res.digits = {0}; return end -- clearly N<D
	if n2 == 1 and D.digits[1] == 1 then res.digits = N.digits return end -- division by 1!
	
	local low = bignum.new(base,1,{})
	local high = bignum.new(base,1,{})
	-- better initial range for less needed iterations
	local ldigits = low.digits;local hdigits = high.digits;
	for i = 1,n1-n2 do ldigits[i]=0;hdigits[i]=0 end
	ldigits[n1-n2]=N.digits[n1];hdigits[n1-n2+1] = ldigits[n1-n2];
	--say("low " .. bignum.tostring(low) .. " high " .. bignum.tostring(high))
	
	local mid = bignum.new(base,1,{});
	local temp = bignum.new(base,1,{});
	local step = 0;
	
	while step < 100000 do -- in practice this uses around log_2 (base^(n2-n1)) iterations, for example dividing 8192 bit number by 4096 takes ~4000 iterations..
		step = step + 1
		bignum._add(low,high,mid); bignum.div2(mid,mid); -- mid = (low+high)/2
		
		if bignum.is_equal(low,mid) then 
			if DEBUG then say("DONE. step  " .. step) end-- .. " low = " .. bignum.tostring(low) .. " high = " .. bignum.tostring(high) .. " mid = " .. bignum.tostring(mid))
			res.digits = mid.digits
			return
		end

		bignum.mul(D, mid, temp) -- temp = D*mid
		if bignum.is_larger(N,temp) then low.digits = mid.digits else high.digits = mid.digits end
	end
end

bignum.base2binary = function(_n)
	local base = _n.base;
	local n = {sgn = 1, base = base, digits = _n.digits }
	local data = n.digits;
	local i = 0;
	local out =  {};
	while (#data > 1 or (#data==1 and data[1] > 0)) do -- n>0
		i=i+1
		out[i]  = bignum.div2(n,n); data = n.digits;
	end
	return {sgn=1,base = 2, digits = out}
end

bignum.binary2base = function(n, newbase) -- newbase must be even
	local base = n.base;
	local ret = {sgn=1,base=newbase, digits = {0}}
	local out = ret.digits
	local data = n.digits
	for i = #data,1,-1 do
		bignum._add(ret,ret,ret) -- ret = 2*ret
		out = ret.digits
		out[1]=out[1]+ data[i]; -- if newbase is even no carry, else more complication here
	end
	return ret
end


-----------------------------------------------
--	MODULAR MULTIPLY
-----------------------------------------------

bignum.get_barrett = function(n) 
	local base = n.base;
	local k = 2*#n.digits+2; -- n<B^(n1+1) -> k = 2*(n1+1)
	local Bk = bignum.new(base,1,{})
	local res = bignum.new(base,1,{})
	local data = Bk.digits;
	for i =1,k do data[i]= 0 end; data[k+1]=1; -- this is B^k
	bignum.div(Bk, n,res);
	return {n=n, m=res, k=k};
end

-- mod using barrett. possible improvement: montgomery.
bignum.mod = function(a,barrett,res) -- a should be less or equal (n-1)^2, stores a%n into res
	
	local k = barrett.k;
	local n = barrett.n;
	local m = barrett.m;
	local base = a.base;
	
	bignum.mul(a,m,res); -- large multiply 1: res = a*m

	local data = res.digits;local n1 = #data;  --res = res / B^k
	for i = 1, n1-k do data[i]=data[i+k] end; for i = n1-k+1,n1 do data[i] = nil end -- bitshift
	
	local temp = bignum.new(base,1,{});
	bignum.mul(res,n, temp); -- multiply 2: res*n
	bignum._sub(a,temp,res); -- subtract: res = a - res*n
	if bignum.is_larger(res,n) then bignum._sub(res,n,res) end
end


bignum.modpow = function(a_,b_,barrett) -- efficiently calculate a^b mod n, need log_2 b steps
	local base = a_.base
	local a = bignum.new(base,1,a_.digits); -- base
	local b = bignum.new(base,1,b_.digits); -- exponent
	local bdata = b.digits;
	
	local ret = bignum.new(base,1,{1});
	local temp = bignum.new(base,1,{});
	
	while (#bdata > 1 or (#bdata==1 and bdata[1] > 0)) do -- b>0
		if bdata[1] % 2 == 1 then
			bignum.mul(ret, a, temp) 
			bignum.mod(temp,barrett, ret) -- ret = a*ret % n
		end
		bignum.div2(b,b); bdata = b.digits -- b = b/2
		
		bignum.mul(a,a,temp);bignum.mod(temp,barrett, a) -- a=a^2 % n
	end
	return ret
end


-- ENCRYPT & HASH

crypto = {}
--if not crypto then crypto = {} end

local rndm = 2^31-1; --C++11's minstd_rand
local rnda = 48271; -- generator
local rndseed = 1;
local random = function(n)
	rndseed = (rnda*rndseed)% rndm;
	return rndseed % n
end

crypto.random = random;
crypto.randomseed = function(seed) rndseed = seed end

local string2arr = function(input) -- convert string to array of numbers
	local m = 32; -- ascii 32-128
	local out = {}
	for i=1, string.len(input) do 
		out[i] = string.byte(input,i)-m
		if out[i] == -6 then out[i] = 96 end -- conversion back
	end
	return out
end

local arr2string = function(out) -- convert array back to string
	local m = 32
	local ret = {}
	for i = 1, #out do
		if out[i] == 96 then out[i]=-6 end -- 32 + 96 = 128 (bad char)
		ret[#ret+1] = string.char(m+out[i])
	end
	return table.concat(ret,"")
end

--TODO: possible improvements: use 256 bytes in out and instead of "i%3 mod 97" use permutation table
-- like s-box in aes

local pbox = {}; for i = 0, 96 do pbox[i] = i^3 % 97 end -- each value is assigned another (arbitrary) value.faster to just lookup than compute
-- note: f:x->x^3 is homomorphism of Z_97* with ker f = {1,35,61}, so |im f| ~ 96/3 = 32
-- im f = {1,8,12,18,19,20,22,27,28,30,33,34,42,45,46,47,50,51,22,55,63,64,67,69,70,75,77,78,79,85,89,96}
-- also gcd(y=f(x),97) = 1 for all x~=0 since 97 prime so when adding numbers its unlikely to get 0


local encrypt_ = function(out,password,sgn)
	local n = 128-32+1; -- Z_97, 97 prime
	local ret = {};input = input or "";
	rndseed = password;
	local key = {};
	for i=1, #out do 
		key[i] = random(n) -- generate key sequence from password
	end
	
	if sgn > 0 then -- encrypt
		
		for i=1, #out do
			local c = out[i];
			local c0 = 0;
			for j = 1,i-1 do c0 = c0 + pbox[out[j] % n]; c0 = c0 % n end
			for j = i+1,#out do c0 = c0 + pbox[out[j] % n]; c0 = c0 % n end
			
			c = (c+(c0+key[i])*sgn) % n;
			out[i] = c
		end
	else -- decrypt
		local c0 = 0
		for i = #out,1,-1 do
			local c = out[i];
			local c0 = 0;
			for j = 1,i-1 do c0 = c0 + pbox[out[j] % n]; c0 = c0 % n end
			for j = i+1,#out do c0 = c0 + pbox[out[j] % n]; c0 = c0 % n end
			c = (c+(c0+key[i])*sgn) % n;
			out[i] = c
		end
	end

end
	

crypto.encrypt = function(text,password)
	local out = string2arr(text);
	for i = 1, #password do
		encrypt_(out,password[i], (i%1)*2-1)
	end
	return arr2string(out)
end

crypto.decrypt = function(text, password)
	local out = string2arr(text);
	for i = #password,1,-1 do
		encrypt_(out,password[i], -(i%1)*2+1)
	end
	return arr2string(out)
end

-- hash
local hash_ = function(out,state,seed)
	local n = 128-32+1; -- Z_97, 97 prime
	local ret = {};input = input or "";
	rndseed = seed;
	for i=1, #out do 
		state[i] = (state[i] + random(n)) % n
	end

	local c0 = 1;
	for i=1, #out do
		local c = out[i];
		for j = 1,#out do c0 = c0 + pbox[out[j] % n]; c0 = c0 % n end
		c = (c+(c0+state[i])) % n;
		out[i] = c
		state[i] = (1 + state[i] + pbox[c0 % n])%n
	end
	return seed + c0
end
	

crypto.rndhash = function(text, bits)
	if not bits then bits = 256 end
	local bytes = math.floor(bits/8)
	
	local length = string.len(text)
	if length<bits then text = text .. string.rep(" ", bytes-length) end -- ensure output 256 bit
	local out = string2arr(text);
	local state = {}; for i = 1, #out do state[i] = 0 end
	local seed = 1;
	for i = 1, 10 do
		seed = hash_(out,state,seed)
	end
	return string.sub(arr2string(out),1,bytes) -- 256 bit output
end