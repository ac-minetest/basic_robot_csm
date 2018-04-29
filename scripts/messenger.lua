--MSGER by rnd, v04242018a
--[[ 
INSTRUCTIONS:

1.	set target player name bellow and encryption = true ( otherwise not encrypted)
2. start program and wait for session key or send one (hold W+S)
3.	to send message just write: ,hello

--]]

if not init then
	--- S E T T I N G S ---------------------------------------
	target = "test" --write name of player you want to talk to
	privatemsg = true -- false to chat, true for private msg
	encryption = true; -- target player must use same settings

	mode = 0; -- 1 to show window when message receiverd
	send_timeout = 2; -- stop sending session key after so many tries
	state = 0; -- if sendkey:  0: sending key, 1: key receipt aknowledged, ready.  if receieve key: 0: waiting for key, 1: ready
	chatchar = "''" -- some servers end msg announce with :, some with %)
	
	password = { -- ~30 bits per row, 10x ~ 300 bit, 2 consecutive passwords should be different!
		1000000000, -- this will change to session key!
		1000000001,
		1000000002,
		1000000003,
		1000000004,
		1000000005,
		1000000006,
		1000000007,
		1000000008,
		1000000009,
	}
	
	-- each password can be up to 10^10, plus random session key 4*10^13 for total 64*10^43 ~ 148.8 bits
	msgversion = "04242018a";
	-----------------------------------------------------------
	
	init = true
	say(minetest.colorize("red","#MESSENGER ".. msgversion .. " STARTED. "))
	
	if encryption then say(minetest.colorize("red","wait for receipt of session key or hold W+S to send session key!")) end
	
	
	self.msg_filter(chatchar) -- only records messages that contain chatchar to prevent skipping if too many messages from server!
	
	
	maxn = 1000000000;
	
	rndm = 2^31 − 1; --C++11's minstd_rand
	rnda = 48271;
	random = function(n)
		rndseed = (rnda*rndseed)% rndm;
		return rndseed % n
	end
	
	rndseed = os.time(); session_key = random(maxn) -- derive session key
	send_session_key = false
	state = -1
	
	if not encryption then state = 1 end
	scount = 0
	
	
	
	
	encrypt_ = function(input,password,sgn)
		local n = 128-32+1; -- Z_97, 97 prime
		local m = 32;
		local ret = {};input = input or "";
		rndseed = password;
		local key = {};
		local out = {};
		for i=1, string.len(input) do 
			key[i] = random(n) -- generate keys from password
			out[i] = string.byte(input,i)-m
			if out[i] == -6 then out[i] = 96 end -- conversion back
		end
		
		if sgn > 0 then -- encrypt
			
			for i=1, string.len(input) do
				local offset=key[i]
				local c = out[i];
				
				local c0 = 0;
				for j = 1,i-1 do c0 = c0 + (out[j])^3; c0 = c0 % n end
				for j = i+1,string.len(input) do c0 = c0 + (out[j])^3; c0 = c0 % n end
				
				c = (c+(c0+offset)*sgn) % n;
				out[i] = c
			end
		else -- decrypt
			local c0 = 0
			for i = string.len(input),1,-1 do
				local offset=key[i];
				local c = out[i];

				local c0 = 0;
				for j = 1,i-1 do c0 = c0 + (out[j])^3; c0 = c0 % n end
				for j = i+1,string.len(input) do c0 = c0 + (out[j])^3; c0 = c0 % n end
				
				c = (c+(c0+offset)*sgn) % n;
				out[i] = c
			end
		end
		
		
		for i = 1, string.len(input) do
			if out[i] == 96 then out[i]=-6 end -- 32 + 96 = 128 (bad char)
			ret[#ret+1] = string.char(m+out[i])
		end
		
		return table.concat(ret,"")
	end
		
	
	encrypt = function(text,password)
		local input = text;
		local out = "";
		for i = 1, #password do
			input = encrypt_(input,password[i], (i%1)*2-1)
		end
		return input
	end
	
	decrypt = function(text, password)
		local input = text;
		local out = "";
		for i = #password,1,-1 do
			input = encrypt_(input,password[i], -(i%1)*2+1)
		end
		return input
	end
	
	
	unit_test = function()
		local text = "Hello encrypted world! 12345 ..."
		--local password = {1,2,session_key}
		local enc = encrypt(text,password)
		local dec = decrypt(enc,password)
		say(text .. " -> " .. enc .. " -> " .. dec)
		self.remove()
	end
	--unit_test()
end


if state == -1 then -- idle
	msg = self.listen_msg()
	if msg then
		if string.find(msg,target) and string.find(msg,chatchar) then
			msg = minetest.strip_colors(msg)
			local i = string.find(msg, chatchar)
			if i then -- ready to chat
				msg = string.sub(msg,i+string.len(chatchar))
				session_key =  tonumber(decrypt(msg,password))
				if not session_key then say("#MESSENGER: restart .bot, wrong key") end
				
				msg = encrypt("OK " .. session_key, password)
				say("/msg " .. target .. " " .. chatchar .. msg,true) -- send confirmation of receipt
				msg = false
				state = 1 scount = 1
				say(minetest.colorize("lawngreen","#MESSENGER: RECEIVED SESSION KEY " .. session_key))
				password[1] = session_key;password[#password] = password[#password] - session_key;
				--say(password1 .. " " .. password2)					
			end 
		end
	end
	
	if not msg and minetest.localplayer:get_key_pressed() == 3 then 
		say(minetest.colorize("red","SENDING SESSION KEY TO " .. target))
		send_session_key = true; state = 0;
	end
else -- receive/send
	msg = self.listen_msg()
	
	if state == 0 then 
		if minetest.localplayer:get_key_pressed() == 3 then scount = 0 end
		if scount == 0 then msg = "" end -- trigger sending key at start
	end
	
	if msg then
		if state == 0 then
			-- SENDING KEY, listening for confirmation
			if string.find(msg,target) and string.find(msg,chatchar) then -- did we receive confirmation?
				msg = minetest.strip_colors(msg)
				local i = string.find(msg, chatchar)
				if i then 
					msg = string.sub(msg,i+string.len(chatchar))
					msg = decrypt(msg,password) 
					if msg == "OK " .. session_key then  -- ready to chat
						state = 1
						say(minetest.colorize("lawngreen","#MESSENGER: TARGET CONFIRMS RECEIPT OF SESSION KEY " .. session_key))
						password[1] = session_key;password[#password] = password[#password] - session_key;
						--say(password1 .. " " .. password2)
					end
				end
			elseif scount == 0 then -- send session key
				scount = 1
				msg = encrypt(session_key, password)
				say("/msg " .. target .. " " .. chatchar .. msg,true)
				say("#MESSENGER: waiting for " .. target .. " to respond ...")
			end
		elseif state == 1 then -- NORMAL OPERATION: DECRYPT INCOMMING MESSAGES, SEND ENCRYPTED MESSAGES
			if string.find(msg,target) and string.find(msg,chatchar) then
				--say("D1")
				msg = minetest.strip_colors(msg)
				local i = string.find(msg, chatchar)
				if i then 
					msg = string.sub(msg,i+string.len(chatchar))
					--say("ENCRYPTED :" .. msg)
					if encryption then msg = decrypt(msg,password); msg = minetest.colorize("LawnGreen","DECRYPTED from " .. target .. "> ") .. minetest.colorize("yellow", msg) end
					form = "size[5,5] textarea[0,0;6,6;MSG;MESSAGE FROM " .. target .. "> " .. minetest.formspec_escape(msg) .. "]"
					if mode == 1 then minetest.show_formspec("robot", form) else say(msg) end
				end
			end

		end
	end
end

msg = self.sent_msg() -- is there message to send?
if msg then
	say(minetest.colorize("Pink", "MESSAGE SENT to " .. target .. "> " .. msg))
	if encryption then msg = encrypt(msg, password) end
	if privatemsg then
		say("/msg " .. target .. " " .. chatchar .. msg,true)
	else
		say(chatchar .. msg,true)
	end
end