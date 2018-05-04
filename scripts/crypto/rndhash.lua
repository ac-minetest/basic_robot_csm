-- rnd experimental hash ( min 256 bit output )
if not rndhash then
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

	for i = 1, 32 do
		say(i .. " -> " .. rndhash(i))
	end
	
end