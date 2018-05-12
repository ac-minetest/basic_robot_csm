-- cubic mod spread encryptor by rnd
--TODO: use arrays, string generation only at end. better key schedule.

if not crypto then crypto = {} end

local rndm = 2^31 − 1; --C++11's minstd_rand
local rnda = 48271; -- generator
local rndseed = 1;
local random = function(n)
	rndseed = (rnda*rndseed)% rndm;
	return rndseed % n
end


local encrypt_ = function(input,password,sgn)
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
	

crypto.encrypt = function(text,password)
	local input = text;
	local out = "";
	for i = 1, #password do
		input = encrypt_(input,password[i], (i%1)*2-1)
	end
	return input
end

crypto.decrypt = function(text, password)
	local input = text;
	local out = "";
	for i = #password,1,-1 do
		input = encrypt_(input,password[i], -(i%1)*2+1)
	end
	return input
end


local encrypt_decrypt_test = function()
	local text = "Hello encrypted world! 12345 ..."
	local password = { -- ~30 bits per row, 10x ~ 300 bit, 2 consecutive passwords should be different!
		1728096374, 
		1301007001,
		1000050002,
		1040053203,
		1000000004,
		1000600005,
		1080156086,
		1047302203,
		1800100228,
		1480500509,
	}
	
	local enc = encrypt(text,password)
	local dec = decrypt(enc,password)
	say(text .. " -> " .. enc .. " -> " .. dec)
	self.remove()
end
--encrypt_decrypt_test()