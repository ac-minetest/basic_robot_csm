-- MESSENGER by rnd, v04212018a
--[[ 
INSTRUCTIONS:

1.	set target player name bellow and encryption = true ( otherwise not encrypted)
2.	to skip session key exchange put state = 1 in settings, otherwise 0
	if session key enabled EXACTLY ONE player should have send_session_key = true (SENDER), 
	another false (RECEIVER).RECEIVER player starts first ( otherwise unnecesary spam by SENDER)
3.	to send message just write: ,hello

--]]

if not init then
	--- S E T T I N G S ---------------------------------------
	target = "test" --write name of player you want to talk to
	privatemsg = true -- false to chat, true for private msg
	send_session_key = true; -- do we send the key (if false receive it)
	encryption = true; -- target player must use same settings

	mode = 0; -- 1 to show window when message receiverd
	send_timeout = 2; -- stop sending session key after so many tries
	state = 0; -- if sendkey:  0: sending key, 1: key receipt aknowledged, ready.  if receieve key: 0: waiting for key, 1: ready
	chatchar = "''" -- some servers end msg announce with :, some with %)
	
	password = { -- 45 bits per row, 6x45 = 260 bit, 2 consecutive passwords should be different!
		40000000000001, -- this will change to session key!
		40000000000002,
		40000000000003,
		40000000000004,
		40000000000005,
		40000000000006,
	}
	
	-- each password can be up to 4*10^15, plus random session key 4*10^13 for total 64*10^43 ~ 148.8 bits
	msgversion = "04212018a";
	-----------------------------------------------------------
	
	init = true
	say(minetest.colorize("red","#MESSENGER ".. msgversion .. " STARTED. "))
	if encryption and not send_session_key then say("#MESSENGER: WAITING FOR SESSION KEY RECEIPT") end
	
	self.msg_filter(chatchar) -- only records messages that contain chatchar to prevent skipping if too many messages from server!
	
	
	maxn = 40000000000000;
	_G.math.randomseed(os.time()); session_key = math.random(maxn) -- derive session key


	if not encryption then state = 1 end
	scount = 0
	
	encrypt_ = function(input,password,sgn)
		local n = 128-32+1; -- Z_97, 97 prime
		local m = 32;
		local ret = {};input = input or "";
		_G.math.randomseed(password);
		local key = {};
		local out = {};
		for i=1, string.len(input) do 
			key[i] = math.random(n) -- generate keys from password
			out[i] = string.byte(input,i)-m
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

if state == 1 then
	msg = self.sent_msg()
	if msg then
		say(minetest.colorize("Pink", "MESSAGE SENT to " .. target .. "> " .. msg))
		if encryption then msg = encrypt(msg, password) end
		if privatemsg then
			say("/msg " .. target .. " " .. chatchar .. msg,true)
		else
			say(chatchar .. msg,true)
		end
	end
end

msg = self.listen_msg()
if state == 0 and send_session_key and not msg then msg = "" end -- trigger key sending at start

if msg then
	if state == 0 then
		
		if send_session_key then -- SENDING KEY
			
			if string.find(msg,target) and string.find(msg,chatchar) then -- did we receive confirmation?
				msg = minetest.strip_colors(msg)
				local i = string.find(msg, chatchar)
				if i then 
					msg = string.sub(msg,i+string.len(chatchar))
					msg = decrypt(msg,password) 
					if msg == "OK " .. session_key then  -- ready to chat
						state = 1 
						say("#MESSENGER: TARGET CONFIRMS RECEIPT OF SESSION KEY " .. session_key)
						password[1] = session_key;password[2] = password[2] - session_key;
						--say(password1 .. " " .. password2)
					end
				end
			else -- keep sending session key until 'timeout'
				scount = scount + 1
				if scount < send_timeout then
					msg = encrypt(session_key, password)
					say("/msg " .. target .. " " .. chatchar .. msg,true)
				elseif scount == send_timeout then say("#MESSENGER: waiting for " .. target .. " to respond ...")
				end
			end
		else -- RECEIVING KEY
			if string.find(msg,target) and string.find(msg,chatchar) then
				msg = minetest.strip_colors(msg)
				local i = string.find(msg, chatchar)
				if i then -- ready to chat
					msg = string.sub(msg,i+string.len(chatchar))
					session_key =  tonumber(decrypt(msg,password))
					if not session_key then say("#MESSENGER: restart .bot, wrong key") end
					msg = encrypt("OK " .. session_key, password)
					say("/msg " .. target .. " " .. chatchar .. msg,true) -- send confirmation of receipt
					state = 1 say("#MESSENGER: RECEIVED SESSION KEY " .. session_key)
					password[1] = session_key;password[2] = password[2] - session_key;
					--say(password1 .. " " .. password2)					
				end 
			end
		end
	
	elseif state == 1 then -- NORMAL OPERATION: DECRYPT
	
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