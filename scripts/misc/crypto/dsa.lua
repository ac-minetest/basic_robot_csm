--dsa by rnd
--digital signature algorithm 

-- parameters: p,q,g
-- 1. p,q primes such that p-1 = a'*q, for example p safe prime, p-1=2q (N bits, L bits)
-- 2. select g in Z_p of order q ( for example 2^(p-1)/q or 3^... if first one is 1)

-- user keys: x in Z_q private key, y = g^x in Z_p = private key

-- MAIN IDEA: given message m and random k in Z_q and r = g^k %p %q find
-- w such that: g^(hash(m)*w + x*r*w) %p %q = g^k %p %q
-- this is easy if we know x -> solve w*(h+x*r) =k in Z_q -> w = (h+x*r)^-1*k in Z_q

-- now we hide k and x and show only  y = g^x and r = g^k, problem is rewritten as:
-- PROBLEM:
-- g^(h*w) * y^(r*w) %p %q  = r. So problem is determining such r and w.

-- NOTE: the idea of %p %q is to make brute force  even slower, since:
-- x=y %p %q if x=y+t1*q+t2*p for some p,q

-- note : 
--1 .the attacker doesnt have much freedom with h since he cant precisely control hash values
--2. suppose same k is reused for 2 different m. Write s = w^-1 mod q. Since
--s = k^-1*(h+r*x) mod q we get: s2 = k^-1*(h2+r*x) and s1 = k^-1*(h1+r*x),
-- or s2-s1 = k^-1( h2-h1) -> k = (s2-s1)^-1*(h2-h1).. and r^-1*(k*s-h)=x = BAD
-- must be careful that we pick very different k each time
-- 3. CAREFUL! k1 s1 = (h1+r1*x), k2 s2 =(h2+r2*x) -> k1 s1- k2 s2  - (h1-h2) = (r1-r2)*x.
-- so if we know there is little difference between k1,k2 we can try small sample different k2 and try to solve for x!

local bignum = _G.bignum

--512 bit
--c1d3a133c9b3720da868dda10b6a0bde0e1a47d797d3e02f2673157ad26c33970553352abd72114a48813b3f1a3d86120c2150d9c33780bf0ce31acf2e28b813

p = {base = 67108864, sgn = 1,digits = {36222995, 13022155, 782542, 57085150, 34349392, 42951044, 1291249, 4532514, 19578226, 29447373, 19317561, 30168555, 65023782, 32892404, 31515044, 2992175, 6872481, 14451562, 34815131, 198478}}
barrettp = {["k"] = 42, ["m"] = {["base"] = 67108864, ["sgn"] = 1,["digits"] = {28949715, 54423101, 2288892, 15960629, 25093079, 30961036, 9893219, 18572583, 6060506, 53345934, 62824245, 21175570, 51585074, 64634085, 50626132, 23908947, 34461644, 49242303, 44848557, 11882353, 4640537, 7818826, 338}}, ["n"] = {["base"] = 67108864, ["sgn"] = 1, ["digits"] = {36222995, 13022155, 782542, 57085150, 34349392, 42951044, 1291249, 4532514, 19578226, 29447373, 19317561, 30168555, 65023782, 32892404, 31515044, 2992175, 6872481, 14451562, 34815131, 198478}}}

q = {["base"] = 67108864, ["sgn"] = 1, ["digits"] = {51665929, 6511077, 391271, 28542575, 17174696, 55029954, 645624, 2266257, 43343545, 48278118, 43213212, 15084277, 32511891, 16446202, 49311954, 35050519, 3436240, 40780213, 17407565, 99239}}
barrettq = {["k"] = 42, ["m"] = {["base"] = 67108864, ["sgn"] = 1, ["digits"] = {50630993, 11411608, 4806431, 31921258, 50186158, 61922072, 19786438, 37145166, 12121012, 39583004, 58539627, 42351141, 36061284, 62159307, 34143401, 47817895, 1814424, 31375743, 22588251, 23764707, 9281074, 15637652, 676}}, ["n"] = {["base"] = 67108864, ["sgn"] = 1, ["digits"] = {51665929, 6511077, 391271, 28542575, 17174696, 55029954, 645624, 2266257, 43343545, 48278118, 43213212, 15084277, 32511891, 16446202, 49311954, 35050519, 3436240, 40780213, 17407565, 99239}}}

--2048 bit
--db726369acb4a51666ee14e0dc4305afc11692cc0dfa9d06b399ebc7b541b095ca3f48633ed936e0d4633af1c8b72886829c5fdd98861c44acdadc54075dc3beeb3d4a4bf9fb13b2c943e8bcb8c8df4440a84753c87d1512ff3db5083941ac88764c674da50771fdd7f4db99d7281e653253191df1f0137004b81488ecf9d15c49462c5438d4c060fa5a36e3e8e73ca1969d312b1b11df3e6fa3ce0a87641f4007884470d4911da45df914143c2c446a51443d6595c84cf83467825cf08007546e04c5137acac3ec0f413c522f5904d3b5230b4f5f2a26a0a8ad318ab541d1cd69079b0cb040827e2eb48f4fb7bc76623b96c7d38c603a186e24ae70a3bd66b3

-- p = {
	-- base = 2^26, sgn = 1,
	-- digits = {62744243, 19635240, 60917474, 55456128, 37459655, 32447896, 55112955, 34207930, 51163200, 56246758, 55844124, 45401642, 36085928, 47437770, 20664880, 12411923, 54606930, 45153027, 5322668, 22132755, 15761415, 18473111, 8703875, 16094807, 6967620, 17763089, 31428929, 38041233, 4485332, 63963618, 11040321, 29265720, 51502910, 55331526, 63576425, 59745180, 16407094, 37040152, 6473027, 54882597, 8973561, 77317, 52363575, 21783671, 1991986, 48657866, 64847693, 43261383, 38561613, 7021085, 55608212, 4979958, 63470869, 2757076, 9303108, 61010659, 62048579, 50233028, 45339812, 24579835, 47993863, 51456822, 31033441, 34238847, 12003462, 13548658, 57544006, 26016612, 30031688, 22047781, 27180155, 41163470, 46927354, 66078116, 29634650, 62411651, 10819174, 14314285, 898854}
-- }
-- barrettp = {
	-- ["k"] = 160, ["m"] = {["base"] = 67108864, ["sgn"] = 1, 
	-- ["digits"] = {52173231, 58926316, 7134135, 58005281, 29642925, 1996, 43704342, 19181367, 51834951, 40753938, 5670116, 25083444, 53681109, 39194353, 21018693, 16186348, 52641345, 34474171, 45582158, 65632598, 6663244, 17715531, 46582518, 715815, 35941432, 62741031, 14063905, 37500214, 33724930, 25815530, 29521098, 42349641, 30021354, 56331771, 20197595, 44642351, 39774, 15935544, 18538053, 54085894, 20262092, 170794, 877950, 7075184, 15922733, 42275553, 19627281, 61124663, 6351068, 20488035, 52369744, 26751026, 17905178, 25990200, 47243983, 42954366, 65859731, 23375626, 40610711, 9951837, 9139091, 55630155, 4911180, 17490059, 43409254, 37055369, 1417704, 12145177, 9055946, 41623298, 33230333, 1111792, 21966597, 20877280, 44498082, 6831928, 22418430, 4437100, 27282748, 12568457, 44322344, 74}}, ["n"] = {["base"] = 67108864, ["sgn"] = 1, ["digits"] = {62744243, 19635240, 60917474, 55456128, 37459655, 32447896, 55112955, 34207930, 51163200, 56246758, 55844124, 45401642, 36085928, 47437770, 20664880, 12411923, 54606930, 45153027, 5322668, 22132755, 15761415, 18473111, 8703875, 16094807, 6967620, 17763089, 31428929, 38041233, 4485332, 63963618, 11040321, 29265720, 51502910, 55331526, 63576425, 59745180, 16407094, 37040152, 6473027, 54882597, 8973561, 77317, 52363575, 21783671, 1991986, 48657866, 64847693, 43261383, 38561613, 7021085, 55608212, 4979958, 63470869, 2757076, 9303108, 61010659, 62048579, 50233028, 45339812, 24579835, 47993863, 51456822, 31033441, 34238847, 12003462, 13548658, 57544006, 26016612, 30031688, 22047781, 27180155, 41163470, 46927354, 66078116, 29634650, 62411651, 10819174, 14314285, 898854}}

local importsshprime = function(GH) -- use this to precompute all the needed prime stuff for extra speed
	local base = 2^26;
	local G1 = bignum.importhex(GH); local G2 = bignum.base2binary(G1);

	local p = bignum.binary2base(G2,base);
	code1 = minetest.serialize(p.digits) -- prime GH digits
	local t = os.clock();

	local barrettp = bignum.get_barrett(p);say(os.clock()-t) -- precompute barrett form
	local code2 = minetest.serialize(barrettp)
	
	local q = bignum.new(base,1,p.digits); 	q.digits[1] = q.digits[1]-1; bignum.div2(q,q); -- q = (p-1)/2
	local code3 = minetest.serialize(q)

	local barrettq = bignum.get_barrett(q); -- precompute q and this!
	local code4 = minetest.serialize(barrettq)
	
	local msg = "p " ..code1.."\nbarrettp " .. code2 .. "\nq " .. code3 .. "\nbarrettq " .. code4;
	local form = "size[5,5] textarea[0,0;6,6;MSG;MESSAGE;" .. minetest.formspec_escape(msg) .. "]"
	minetest.show_formspec("robot", form)
end

--importsshprime("c1d3a133c9b3720da868dda10b6a0bde0e1a47d797d3e02f2673157ad26c33970553352abd72114a48813b3f1a3d86120c2150d9c33780bf0ce31acf2e28b813")



DSA = {};
--msg = 520 bit number base 2^26
DSA.sign = function(msg,x) -- msg = (hash) message as number, x = private key 
	local m = 20; local base = 2^26;
	local k = bignum.rnd(base,1,m); -- random value!
	
	--warning: possible problem if q1.digits[1]-2 = 1-2<0 cause we didnt do carry! extremely unlikely, since digits in base 2^26.
	local q1 = bignum.new(base,1,q.digits); q1.digits[1] = q1.digits[1]-2; -- q-2, needed to compute c^-1 = c^(q-2) mod q.
	local g = bignum.new(base,1,{2^2}); -- g^q = 1 mod q ( g = 2^(p-1)/q mod p = 2^2)
	local temp = bignum.modpow(g,k, barrettp); -- g^k mod p
	local r = bignum.new(base,1,{});bignum.mod(temp,barrettq,r); --r = g^k mod p mod q
	bignum.mul(x,r,temp); bignum._add(msg,temp,temp); -- temp = m+x*r
	local temp1 = bignum.new(base,1,{});bignum.mod(temp,barrettq,temp1) -- range is very important, temp1 < q or modpow can freeze
	temp = bignum.modpow(temp1, q1, barrettq); --(m+x*r)^-1 -- FREEZE PROBLEM if temp1>q. cause then temp1^2>q^2 and barret modpow fail..

	local w = bignum.new(base,1,{});
	bignum.mul(temp,k,w);bignum.mod(w,barrettq,temp1) 
	return {r,temp1} -- w = temp1 = (m+x*r)^-1*k in Z_q
end



DSA.verify = function(msg,sig,y) -- m = message, sig = {r,w} =  signature, y = public key (= g^x)
	-- CHECK: g^(m*w) * y^(r*w) %p %q  == r
	local m = 20; local base = 2^26;
	local g = bignum.new(base,1,{2^2});
	local temp1 = bignum.new(base,1,{});
	bignum.mul(msg,sig[2],temp1); temp1 = bignum.modpow(g,temp1,barrettp); -- temp1 = g^(m*w) mod p
	local temp2 = bignum.new(base,1,{});
	bignum.mul(sig[1],sig[2],temp2); temp2 = bignum.modpow(y,temp2,barrettp); -- temp2 = y^(r*w) mod p
	local temp = bignum.new(base,1,{});
	bignum.mul(temp1,temp2,temp); bignum.mod(temp,barrettq,temp1); -- temp1 = g^(m*w) * y^(r*w) %p %q
	return bignum.is_equal(temp1,sig[1])
end


dsa_sign_test = function()
	local x = bignum.rnd(2^26,1,20) -- private key
	local g = bignum.new(2^26,1,{2^2});
	local y = bignum.modpow(g,x,barrettp) -- public key
	
	local msg = bignum.importascii("hello world",2^26) -- will cut off at 520 bytes, use hash here for real thing
	
	local sig = DSA.sign(msg,x)
	--say(minetest.serialize(sig))

	local ok = DSA.verify(msg,sig,y)
	say(ok and "true" or "false")
end
dsa_sign_test()




self.remove()