--authentication with zero knowledge proof by rnd
-- instructions: change target name and hold w+s to send identity challenge

if not init then
	target = "qtest" -- player you want to authenticate with
	targetidentity = "qtest" -- other player identity - you want to check he is real
	myidentity = "rnd" -- your identity - you want other to believe to be this
	
	shared_secrets = { -- SHARED SECRETS: {name1, name2, secret}
		{"qtest","rnd","lekT$#J?434ijaakk4fa??_lDFg"},  -- shared secret between qtest and rnd
	}
	
	auth = {};
	
	for i=1,#shared_secrets do 
		local name1 = shared_secrets[i][1];
		local name2 = shared_secrets[i][2];
		local tname = ""
		if name1<name2 then tname = name1..name2 else tname = name2..name1 end
		auth[tname] =  shared_secrets[i][3]
	end
	
	
	teamname = "";
	if myidentity<targetidentity then teamname = myidentity .. targetidentity else teamname = targetidentity..myidentity end

	chatchar = "@@";
	challenge = 0
	
	init = true
	self.msg_filter(chatchar)
	
	-- rnd experimental hash ( min 256 bit output )
	rndm = 2^31 − 1; --C++11's minstd_rand
	rnda = 48271; -- generator
	rndseed = 0;
	
	random = function(n)
		rndseed = (rnda*rndseed)% rndm;
		return rndseed % n
	end
	
	local hash_ = function(input,seed) 
		local n = 128-32+1; -- Z_97, 97 prime
		local m = 32;
		local ret = {};input = input or "";
		rndseed = seed;
		local key = {};
		local out = {};
		for i=1, string.len(input) do 
			key[i] = random(n) -- generate keys from password
			out[i] = string.byte(input,i)-m
			if out[i] == -6 then out[i] = 96 end -- conversion back
		end
		
		local c0 = 1; -- this serves as accumulator too
		for i=1, string.len(input) do
			local offset=key[i]
			local c = out[i];
			for j = 1,string.len(input) do c0 = c0 + (out[j])^3; c0 = c0 % n end 
			c = (c+c0+offset) % n;
			out[i] = c
		end
		rndseed = rndseed+c0
		
		for i = 1, string.len(input) do
			if out[i] == 96 then out[i]=-6 end -- 32 + 96 = 128 (bad char)
			ret[#ret+1] = string.char(m+out[i])
		end
		
		return table.concat(ret,""),rndseed
	end
		
	rndhash = function(text)
		local length = string.len(text);
		if length<32 then text = text .. string.rep(" ", 32-length) end
		local seed = 0; -- accumulator
		local ret = text; for i = 1, 10 do ret,seed = hash_(ret,seed) end
		return ret
	end

	
	say(minetest.colorize("red","#AUTHENTICATION: press w+s to send challenge to " .. target .. " or wait for one."))
	
	local msg = "";	while msg do msg = self.listen_msg() end
end


if minetest.localplayer:get_key_pressed() == 3 then 
	rndseed = os.time();challenge = rndhash(random(2^31));
	say("/msg " .. target .. " " .. chatchar .. " " .. challenge,true)
	say(minetest.colorize("orange","#CHALLENGE SENT."))
end

msg = self.listen_msg()
if msg and msg~= "" then
	msg = minetest.strip_colors(msg)
	local i = string.find(msg,chatchar)
	local cstring = string.sub(msg,i+2);
	if string.sub(cstring,1,1) == " " then -- send back response
		say(minetest.colorize("orange","#SENDING RESPONSE"))
		local response = rndhash(string.sub(cstring,2) .. auth[teamname] ) --os.date("%x")
		say("/msg " .. target .. " " .. chatchar .. response, true)
		
	else
		say(minetest.colorize("orange","#VERIFYING RESPONSE "))
		local cresponse = rndhash(challenge .. auth[teamname] )
		if cresponse == cstring then 
			say(minetest.colorize("lawngreen","#IDENTITY OF " .. target .. " CONFIRMED AS " .. targetidentity))
		else
			say(minetest.colorize("red","#FAKE IDENTITY OF " .. target .. " DETECTED - IS NOT " .. targetidentity))
		end
	end
	
end