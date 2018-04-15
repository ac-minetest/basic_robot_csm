--TRANSFER FILE by rnd v04152018b
-- sends program 8 using pm chat (encoded, broken in pieces)
-- both players can talk during transfer with no problems

-- succesfully transfered 1mb random data between 2 clients on survival x (04/08/2018)

if not init then
	
	target = "rnd"; -- who to receive from
	mode = 0; -- 0: receive, 1: send
	
	chunksize = 450; -- maxlength that server supports
	chatchar = ": " -- used to trigger listener, change to what server uses, normally pm chat looks like: 'PM from NAME: TEXT'
	msgchar = "@" -- what to insert to message, so it will be like '... NAME: @TEXT'
	
	state = 0; -- dont edit
	
	--[[states:
		sending: 0: send initial header 1: wait for confirmation for next send, when confirmation send data, 2 finished
		receiving: 0 : wait for received data and reply with confirmation, 1 finished
	sent data: 
		initial: chunksize & maxidx = number of chunks (chunksize is of the form xxx )
		later: chunk & id_data (chunk is of the form xxxxx)
	reply from receiver: idx ( current idx )
		
	--]]
	
	idx = 0; -- current index
	maxids = 0; -- total number of chunks
	t = {os.time(),0}; -- timings
	data = {};
	if mode == 0 then say(minetest.colorize("red","LISTENING FOR DATA STREAM FROM " .. target)) else say(minetest.colorize("red","SENDING DATA STREAM TO " .. target)) end
	
	init = true
	
	read_data = function(data,inputfile)
		--local file = assert(_G.io.open(inputfile, "rb")) -- file read not available
		--local sdata = minetest.encode_base64(file:read("*all"));
		
		-- local ret = {}
		-- _G.math.randomseed(1)
		-- for i = 1, N do ret[i] = string.char(math.random(255)) end -- generate some random data
		-- sdata = minetest.encode_base64(table.concat(ret,""))
		
		sdata = minetest.encode_base64(_G.basic_robot.data["code"..8]) -- data to send, robot code 8
		
		local length = string.len(sdata);
		local chunks = math.ceil(length/chunksize);
		for i = 1, chunks do -- break data into smaller pieces with stamps
			data[i] = string.format("%05d",i) .. " " .. string.sub(sdata,1+(i-1)*chunksize,i*chunksize)
		end
		maxidx = chunks;
	end
	
	self.msg_filter(target.. chatchar .. msgchar, true); -- ignore all other receives
	read_data(data,inputfile)
end

t[2] = os.time();
if mode == 1 then -- SENDER/SERVER
	if state == 0 then
		say("/msg " .. target .. " ".. msgchar .. "00000" .. " " .. string.format("%03d",chunksize) .. " " .. maxidx, true) -- send init
		state = 1
		t[1] = t[2];
	elseif state == 1 then
		msg = self.listen_msg();
		if msg then
			msg = minetest.strip_colors(msg)
			local i = string.find(msg, msgchar);
			idx = tonumber(string.sub(msg,i+1,i+string.len(target)+2));
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
elseif mode == 0 then -- RECEIVER/CLIENT
	if state == 0 then
		msg = self.listen_msg();
		if msg then
			msg = minetest.strip_colors(msg)
			--say("RECEIVED : " .. msg)
			local i = string.find(msg, msgchar);
			if not i then say("restart. wrong message " .. msg ) self.remove() end
			
			local ridx = tonumber(string.sub(msg,i+1,i+5));
			say("/msg " .. target .. " " .. msgchar.. ridx, true)  -- confirmation
			if ridx == 0 then -- initial packet
				say("INIT PACKET RECEIVED")
				chunksize = tonumber(string.sub(msg,i+7,i+9))
				maxidx = tonumber(string.sub(msg,i+11))
				t[1] = t[2]
			else
				local rdata = string.sub(msg, i+7)
				data[ridx] = rdata;
				if ridx % 5 == 1 then -- less spam
					say(minetest.colorize("red","received " .. ridx .. "/" .. maxidx .. ", " .. chunksize/(t[2]-t[1]) .. " b/s"))
				end
				t[1] = t[2]
			end
			if ridx == maxidx then
				state = 1
				say(minetest.colorize("red","END."))
				local sdata = minetest.decode_base64(table.concat(data));
				say()
				
				_G.basic_robot.data["code"..8] = sdata
				say(minetest.colorize("red","RECEIVED DATA SAVED AS CODE 8!"))
			end
			
		end
	end

end
::abort::