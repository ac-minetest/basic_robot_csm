-- BIGNUM by rnd
-- contents: new, tostring, rnd, importdec, _add, _sub, is_larger, add, sub, mul

if not bignum then
	self.spam(1);

	bignum = {};
	bignum.new = function(base,sgn, digits)
		local ret = {};
		ret.base = base -- base of digit system
		ret.digits = {};
		ret.sgn = sgn -- sign of number,+1 or -1
		local data = ret.digits;
		local m = #digits;
		ret.digits = digits; -- digits by reference!
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
	
	importdec_test = function()
		local ndec = math.random(10^9);
		local n = bignum.importdec(ndec)
		say("importdec_test : " .. ndec .. " -> " .. bignum.tostring(n))
	end
	--importdec_test()
	
	bignum.exportdec = function(n) -- warning: can cause overflow
		local ndec = 0;
		for i = #n.digits,1,-1 do ndec = 10*ndec + n.digits[i] end
		return ndec*n.sgn
	end
	
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
	
	_add_test = function()
		local n1 = bignum.rnd(10,1,5)
		local n2 = bignum.rnd(10,1,5)
		local res = bignum.new(10,1,{})
		bignum._add(n1,n2,res)
		say("_add_test: " .. bignum.tostring(n1) .. " + " .. bignum.tostring(n2) .. " = " .. bignum.tostring(res))
	end
	--_add_test()
	
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
		
		for i = maxi+1,M do	data[i] = nil end -- remove trailing zero digits
		res.base = n1.base
	end
	
	_sub_test = function()
		local n1 = bignum.rnd(10,1,5)
		local n2 = bignum.rnd(10,1,5)
		local res = bignum.new(10,1,{})
		bignum._sub(n1,n2,res)
		say("_sub_test: " .. bignum.tostring(n1) .. " - " .. bignum.tostring(n2) .. " = " .. bignum.tostring(res))
	end
	--_sub_test()
	
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
	
	is_larger_test = function()
		local n1 = bignum.rnd(10,1,5)
		local n2 = bignum.rnd(10,1,5)
		local res = bignum.is_larger(n1,n2);
		if res then res = "larger" else res = "smaller" end
		say("is_larger_test : " .. bignum.tostring(n1) .. " is ".. res .. " than "  .. bignum.tostring(n2))
	end
	--is_larger_test()
	
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
	
	add_test = function()
		local ndec1 = math.random(10^5) * (2*math.random(2)-3);
		local ndec2 = math.random(10^5) * (2*math.random(2)-3);
		
		local n1 = bignum.importdec(ndec1)
		local n2 = bignum.importdec(ndec2)
		local res = bignum.new(10,1,{})
		bignum.add(n1,n2,res)
		
		local resdec = bignum.exportdec(res);
		say("add_test: " .. bignum.tostring(n1) .. " + " .. bignum.tostring(n2) .. " = " .. bignum.tostring(res) .. " CHECK : " .. resdec-(ndec1+ndec2))
	end
	--add_test()
	
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

	sub_test = function()
		local ndec1 = math.random(10^5) * (2*math.random(2)-3);
		local ndec2 = math.random(10^5) * (2*math.random(2)-3);
		
		local n1 = bignum.importdec(ndec1)
		local n2 = bignum.importdec(ndec2)
		local res = bignum.new(10,1,{})
		bignum.sub(n1,n2,res)
		local resdec = bignum.exportdec(res);
		say("sub_test: " .. bignum.tostring(n1) .. " - " .. bignum.tostring(n2) .. " = " .. bignum.tostring(res) .. " CHECK : " .. resdec-(ndec1-ndec2))
	end
	--sub_test()
	
	bignum.mul = function(n1,n2,res)
		
		local base = n1.base
		local sgn = n1.sgn*n2.sgn;
		
		local data1 = n1.digits; local m1 = #data1;
		local data2 = n2.digits; local m2 = #data2;
		
		res.digits = {}
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
	
	mul_test = function()
		local ndec1 = math.random(10^8) 
		local ndec2 = math.random(10^8)
		
		local n1 = bignum.importdec(ndec1)
		local n2 = bignum.importdec(ndec2)
		local res = bignum.new(10,1,{})
		bignum.mul(n1,n2,res)
		local resdec = bignum.exportdec(res);
		say("mul_test: " .. bignum.tostring(n1) .. "*" .. bignum.tostring(n2) .. " = " .. bignum.tostring(res) .. " CHECK : " .. resdec-(ndec1*ndec2))
	end
	--mul_test()
	
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
	mul_bench()
	
	exp_test = function()
		local n1 = bignum.importdec(2);
		local res1 = bignum.importdec(2);
		local res2 = bignum.importdec(1);
		
		local m=128
		for i = 1, m do
			bignum.mul(n1,res1, res2) -- n1*res1 = res2
			bignum.mul(n1,res2, res1) -- n1*res1 = res2
		end
		
		say("2^" .. (2*m) .. " = " .. bignum.tostring(res2) .. " CHECK " ..2^(2*m))

	end
	--exp_test()
	
	--[[
	rnd division: 
		at each step observe only the highest digits and decide what the correct quotient digit is:
		5325 : 62 -> 0, 2325 :22 -> here it could be either 0,or 1. have to test 1 and subtract. if <0 then it was 0.
		350:12 = 30? rem = 350-30*12 < 0 so 20!  rem = rem + 10*12 = 110
		110:12 = 10? rem = 110-10*12 < 0 so 0x!  decrease index for quotient digit and put 9!, rem = rem + 1*12 = 2, 
		THE END
	--]]
	
	bignum.div = function(N,D,res) -- res = quotient
		
		local base = N.base;
		local rem = bignum.new(base,1, {})
		
		local tmp = bignum.new(base,1, {})
		
		local data = rem.data;
		local dataD = D.digits; local mD = #dataD;
		local dataN = N.digits;
		
		if mN<mD then return true end

		for i = 1,#dataN do	data[i] = dataN[i] end -- rem = N, copy
		res.digits = {};
		
		local cD = dataD[mD];

		
		--32245 : 12 = 3 or 2
		local i = #dataN;
		local j = i - #dataD;
		while i > 0 do -- TODO!
			local cN = dataN[i];
			local q = math.floor(cN/cD);
			if q == 0 then
				j=j-1
			else
				local qdigits = {}; for k = 1,j-1 do qdigits[k] = 0 end; qdigits[j] = q;
				local qj = bignum.new(base,1,qdigits); -- q*base^j
				bignum.mul(qj, D,tmp); -- tmp = q*base^j*D
				bignum.sub(rem,tmp, rem) -- rem = rem - tmp
				res[j] == q
				if rem.sgn<0 then bignum.add(rem,qj);res[j] = res[j]-1 end
			end
		end
		
	end
	
	
end