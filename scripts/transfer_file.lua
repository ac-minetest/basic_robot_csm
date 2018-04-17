--TRANSFER FILE by rnd v04162018a
-- write target name. hold w and s simultaneously to start send data in robot code 8.
-- DESCRIPTION: sends program 8 using pm chat (encoded, broken in pieces).
-- both players can talk during transfer with no problems

if not init then
	target = "test"; -- who to receive from

	chunksize = 450; -- maxlength that server supports
	chatchar = ": " -- used to trigger listener, change to what server uses, normally pm chat looks like: 'PM from NAME: TEXT'
	msgchar = "@" -- what to insert to message, so it will be like '... NAME: @TEXT'
	
	state = 0; -- dont edit
	mode = 0; -- 1 send, 0: idle(2 receive)
	idx = 0; -- current index
	maxids = 0; -- total number of chunks
	t = {os.time(),0}; -- timings
	data = {};
	if mode == 0 then say(minetest.colorize("red","#TRANSFER: wait to receive from '" .. target .. "' or hold w & s to start sending")) end
	
	init = true
	
	read_data = function(data,inputfile)
		sdata = minetest.encode_base64(_G.basic_robot.data["code"..8]) -- data to send, robot code 8
		
		local length = string.len(sdata);
		local chunks = math.ceil(length/chunksize);
		for i = 1, chunks do -- break data into smaller pieces with stamps
			data[i] = string.format("%05d",i) .. " " .. string.sub(sdata,1+(i-1)*chunksize,i*chunksize)
		end
		maxidx = chunks;
	end
	
	self.msg_filter(target.. chatchar .. msgchar, true); -- ignore all other receives
	self.listen_msg(); -- reset msg
	read_data(data,inputfile)
end

t[2] = os.time();
if mode == 0 then -- IDLE
	-- press w and s simultaneously to start 'send'
	if minetest.localplayer:get_key_pressed() == 3 then 
		say(minetest.colorize("red","SENDING DATA STREAM TO " .. target))
		mode = 1; goto abort 
	end
	msg = self.listen_msg();
	if msg then
		msg = minetest.strip_colors(msg)
		local i = string.find(msg, msgchar);
		local ridx = tonumber(string.sub(msg,i+1,i+5));
		if ridx == 0 then -- initial packet
			say("INIT PACKET RECEIVED")
			chunksize = tonumber(string.sub(msg,i+7,i+9))
			maxidx = tonumber(string.sub(msg,i+11))
			t[1] = t[2]
			mode = 2 -- receiver!
			say("/msg " .. target .. " " .. msgchar.. ridx, true)  -- confirmation
		end
	end
elseif mode == 1 then -- SENDER/SERVER
	if state == 0 then
		say("/msg " .. target .. " ".. msgchar .. "00000" .. " " .. string.format("%03d",chunksize) .. " " .. maxidx, true) -- send init
		state = 1
		t[1] = t[2];
	elseif state == 1 then
		msg = self.listen_msg();
		if msg then
			msg = minetest.strip_colors(msg)
			local i = string.find(msg, msgchar);
			idx = tonumber(string.sub(msg,i+1,i+5));
			if not idx then say("restart. wrong message: " .. msg); self.remove() end
			idx= idx+1
			
			if idx>maxidx then 
				state = 2 
				say(minetest.colorize("red","END."))
			else
				if idx % 5 == 1 then -- less spam
					say("SENDING " .. idx.."/" .. maxidx .. ", " .. chunksize/(t[2]-t[1]) .. " b/s")
				end
				say("/msg " .. target .. " ".. msgchar .. data[idx], true)
				t[1] = t[2]
			end
		end
	end
elseif mode == 2 then -- RECEIVER/CLIENT
	if state == 0 then
		msg = self.listen_msg();
		if msg then
			msg = minetest.strip_colors(msg)
			--say("RECEIVED : " .. msg)
			local i = string.find(msg, msgchar);
			if not i then say("restart. wrong message " .. msg ) self.remove() end
			
			local ridx = tonumber(string.sub(msg,i+1,i+5));
			say("/msg " .. target .. " " .. msgchar.. ridx, true)  -- confirmation

			local rdata = string.sub(msg, i+7)
			data[ridx] = rdata;
			if ridx % 5 == 1 then -- less spam
				say(minetest.colorize("red","received " .. ridx .. "/" .. maxidx .. ", " .. chunksize/(t[2]-t[1]) .. " b/s"))
			end
			t[1] = t[2]

			if ridx == maxidx then
				state = 1
				local sdata = minetest.decode_base64(table.concat(data));
				_G.basic_robot.data["code"..8] = sdata
				say(minetest.colorize("red","END. RECEIVED DATA SAVED AS CODE 8!"))
			end
			
		end
	end

end
::abort::