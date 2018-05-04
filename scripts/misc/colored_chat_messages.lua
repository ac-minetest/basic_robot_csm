--colored chat messages by rnd
if not init then
  friends = {boxface=1,FGH=1}
  
  self.msg_filter("",true) -- record & hide all incoming messages
  cfilter = {
	["***"] = "pink",
	["Message sent."] = false,
   }

   defaultcolor = "green";
   
   password = { -- ~30 bits per row, 10x ~ 300 bit, 2 consecutive passwords should be different!
		1410523800, 
		1000000001,
		1000000002,
		1000000003,
		1002890004,
		1000000005,
		1000000006,
		1000000007,
		1000354008,
		1000000009,
	}
	
	-- each password can be up to 10^10, plus random session key 4*10^13 for total 64*10^43 ~ 148.8 bits
	chatversion = "04302018a";
	-----------------------------------------------------------
	
	init = true
	say(minetest.colorize("red","#COLORED CHAT ".. chatversion .. " STARTED. "))
	
	rndm = 2^31 − 1; --C++11's minstd_rand
	rnda = 48271;
	random = function(n)
		rndseed = (rnda*rndseed)% rndm;
		return rndseed % n
	end
		
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
   
   
end

local msg = ""
while msg do
	msg = self.listen_msg()
	if msg and msg~= "" then
		color = defaultcolor;
		for k,v in pairs(cfilter) do
			local l = string.len(k);
			if string.sub(msg,1,l) == k then
				color = v;
			end
		end
		
		if color then
			if string.sub(msg,1,1) == "<" then -- chat
				local i = string.find(msg,">");
				local name = string.sub(msg,2,i-1)
				if friends[name] then color = "orange" else	color = "gray" end
				msg = string.sub(msg,i+1)
				say("    " .. minetest.colorize(color,name .. " > " .. msg ))
			elseif string.sub(msg,1,2) == "PM" then -- private message
				local i = string.find(msg,"from")+5;
				local j = string.find(msg,":")+2;
				local name = string.sub(msg,i,j-3);
				if friends[name] then
					msg = string.sub(msg,j)
					say( minetest.colorize("orange", name .. " > " .. decrypt(msg,password)))
				else
					say( minetest.colorize("yellow",msg))
				end
			elseif string.sub(msg,1,11) == "The player " then
				local i = string.find(msg," ", 12)
				local name = string.sub(msg,12,i-1);
				say("#CHAT: friend " .. name .. " is not online.")
				friends[name]=nil
				--say("XXX" .. string.sub(msg,12,i-1).."XXX")
			else
				say(minetest.colorize(color,msg))
			end
		end
	end
end

msg = self.sent_msg()
if msg then
	say(minetest.colorize("orange", "FRIENDS CHAT: " .. msg))
	for name,_ in pairs(friends) do
		say("/msg " .. name .. " " .. encrypt(msg,password),true)
	end
end