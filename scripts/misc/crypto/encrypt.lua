-- ENCRYPT, RNDHASH

if not crypto then crypto = {} end

local rndm = 2^31 − 1; --C++11's minstd_rand
local rnda = 48271; -- generator
local rndseed = 1;
local random = function(n)
	rndseed = (rnda*rndseed)% rndm;
	return rndseed % n
end

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
	
	local enc = crypto.encrypt(text,password)
	local dec = crypto.decrypt(enc,password)
	say(text .. " -> " .. enc .. " -> " .. dec)
end

encrypt_decrypt_test()

local rndhash_test = function()
	local t  = os.clock()
	for i = 1, 32 do say(i .. " -> " .. crypto.rndhash(i,1024))	end -- 512 bit output
	say("hash timing : " .. os.clock()-t )
end
rndhash_test()

self.remove()