--MESSENGER with rnd auth and key exchange v2
-- v05162018b
-- 'public' key is exchanged securely (2048 bit diffie-hellman in safe-prime group). After that chat will be secure in future. 
-- Every session key is randomized and securely exchanged with srp (secure remote password) like protocol.

if not init then
	msgerver = "05172018a"
	
	targetid = {id = "qtest", name = "qtest"} -- WRITE IN WHO you want to talk to - id = real identity & name = current playername
	myid = {id = "rnd", name = minetest.localplayer:get_name()}  -- your identity
	
	-- targetid = {id = "rnd", name = "rnd"} -- real identity & playername
	-- myid = {id = "qtest", name = minetest.localplayer:get_name()}
	
	
	------------------------------------------------------
	DEBUG = false;
	
	-- SECRET KEYS: for yourself write in: private key, public key. for other player write {} in place of private key.
	-- keys are also loaded from mod_storage.
	keys = minetest.deserialize(self.mod_storage:get_string("messenger_keys"));	if not keys then keys = {} end
	-- keys = { 
		-- ["qtest"] ={ -- example key
			-- {48956649,6888054,39208061,49336825,13139894,28782086,33649864,52015757,41052181,6366916,19073280,28595777,9004077,49422303,3197447,56119809,34730143,60487773,51346526,36586011},
			-- {10668758,19566477,29269435,16175584,54357471,16537273,10758806,19610241,2888871,9931787,22143488,49139611,41680003,63337704,54062559,9659600,2850950,62931196,37706701,11112986}
		-- },
	-- }
	
	keygen = 0; -- both players set this to 1 to generate keys, 0 normal operation
	timeout = 5; -- unused (yet)
	chatchar1 = "''";
	chatchar0 = ": ";
	self.msg_filter(targetid.name .. chatchar0 .. chatchar1)  -- PM from name to name: @@xxxx
	init = true
	mode = 0;  
	state = 0;
	step = 0;
	
	welcomemsg = function()
		if keygen == 1 then
			say(minetest.colorize("red", "#MESSENGER v" .. msgerver .. ". hold w+s to generate and exchange private/public key or wait to receive one. say ,1 to view existing keys and ,2 to delete all keys."))
		else
			say(minetest.colorize("red", "#MESSENGER v" .. msgerver .. ". hold w+s to establish authenticated secure connection with " .. targetid.id .. " or wait to receive one.say ,1 to enter key management."))
		end
	end
	welcomemsg()
	
	crypto = _G.crypto; bignum = _G.bignum;
	crypto.randomseed(os.time()) -- weak, TODO: use better random generator with better randomness source
	
	-- generate safe prime in openssl: openssl prime -generate -safe -bits 512 -hex
	-- then import it here

	local importsshprime = function(GH, base)
		local G1 = bignum.importhex(GH); local G2 = bignum.base2binary(G1);
		local G3 = bignum.binary2base(G2,base);return minetest.serialize(G3.digits)
	end

	--GH = "";local code = importsshprime(GH,2^26)
	--local form = "size[5,5] textarea[0,0;6,6;MSG;MESSAGE;" .. minetest.formspec_escape(code) .. "]"
	--local t = os.clock();local barrett = bignum.get_barrett(p512);say(os.clock()-t) -- precompute barrett form
	--local code = minetest.serialize(barrett)
	--minetest.show_formspec("robot", form)

	--512 bit
	--c1d3a133c9b3720da868dda10b6a0bde0e1a47d797d3e02f2673157ad26c33970553352abd72114a48813b3f1a3d86120c2150d9c33780bf0ce31acf2e28b813
	p512 = {
		base = 2^26, sgn = 1,
		digits = {198478,34815131,14451562,6872481,2992175,31515044,32892404,65023782,30168555,19317561,29447373,19578226,4532514,1291249,42951044,34349392,57085150,782542,13022155,36222995}
		}
		
	barrett512 = {
		["k"] = 42, ["m"] = {["base"] = 67108864, ["sgn"] = 1, 
		["digits"] = {35898149, 41794076, 18684097, 46016930, 38889135, 63030343, 34383953, 50385002, 5837211, 26975470, 58748693, 26637596, 30851364, 25453708, 59604851, 52048498, 48309457, 2932823, 30408552, 42076151, 59509517, 57220987, 1}}, ["n"] = {["base"] = 67108864, ["sgn"] = 1, ["digits"] = {198478, 34815131, 14451562, 6872481, 2992175, 31515044, 32892404, 65023782, 30168555, 19317561, 29447373, 19578226, 4532514, 1291249, 42951044, 34349392, 57085150, 782542, 13022155, 36222995}}
		}

	--2048 bit
	--db726369acb4a51666ee14e0dc4305afc11692cc0dfa9d06b399ebc7b541b095ca3f48633ed936e0d4633af1c8b72886829c5fdd98861c44acdadc54075dc3beeb3d4a4bf9fb13b2c943e8bcb8c8df4440a84753c87d1512ff3db5083941ac88764c674da50771fdd7f4db99d7281e653253191df1f0137004b81488ecf9d15c49462c5438d4c060fa5a36e3e8e73ca1969d312b1b11df3e6fa3ce0a87641f4007884470d4911da45df914143c2c446a51443d6595c84cf83467825cf08007546e04c5137acac3ec0f413c522f5904d3b5230b4f5f2a26a0a8ad318ab541d1cd69079b0cb040827e2eb48f4fb7bc76623b96c7d38c603a186e24ae70a3bd66b3
	p2048 = {
		base = 2^26, sgn = 1,
		digits = {62744243, 19635240, 60917474, 55456128, 37459655, 32447896, 55112955, 34207930, 51163200, 56246758, 55844124, 45401642, 36085928, 47437770, 20664880, 12411923, 54606930, 45153027, 5322668, 22132755, 15761415, 18473111, 8703875, 16094807, 6967620, 17763089, 31428929, 38041233, 4485332, 63963618, 11040321, 29265720, 51502910, 55331526, 63576425, 59745180, 16407094, 37040152, 6473027, 54882597, 8973561, 77317, 52363575, 21783671, 1991986, 48657866, 64847693, 43261383, 38561613, 7021085, 55608212, 4979958, 63470869, 2757076, 9303108, 61010659, 62048579, 50233028, 45339812, 24579835, 47993863, 51456822, 31033441, 34238847, 12003462, 13548658, 57544006, 26016612, 30031688, 22047781, 27180155, 41163470, 46927354, 66078116, 29634650, 62411651, 10819174, 14314285, 898854}
		}
		
	barrett2048 = {
		["k"] = 160, ["m"] = {["base"] = 2^26, ["sgn"] = 1, 
		["digits"] = {52173231, 58926316, 7134135, 58005281, 29642925, 1996, 43704342, 19181367, 51834951, 40753938, 5670116, 25083444, 53681109, 39194353, 21018693, 16186348, 52641345, 34474171, 45582158, 65632598, 6663244, 17715531, 46582518, 715815, 35941432, 62741031, 14063905, 37500214, 33724930, 25815530, 29521098, 42349641, 30021354, 56331771, 20197595, 44642351, 39774, 15935544, 18538053, 54085894, 20262092, 170794, 877950, 7075184, 15922733, 42275553, 19627281, 61124663, 6351068, 20488035, 52369744, 26751026, 17905178, 25990200, 47243983, 42954366, 65859731, 23375626, 40610711, 9951837, 9139091, 55630155, 4911180, 17490059, 43409254, 37055369, 1417704, 12145177, 9055946, 41623298, 33230333, 1111792, 21966597, 20877280, 44498082, 6831928, 22418430, 4437100, 27282748, 12568457, 44322344, 74}}, ["n"] = {["base"] = 67108864, ["sgn"] = 1, ["digits"] = {62744243, 19635240, 60917474, 55456128, 37459655, 32447896, 55112955, 34207930, 51163200, 56246758, 55844124, 45401642, 36085928, 47437770, 20664880, 12411923, 54606930, 45153027, 5322668, 22132755, 15761415, 18473111, 8703875, 16094807, 6967620, 17763089, 31428929, 38041233, 4485332, 63963618, 11040321, 29265720, 51502910, 55331526, 63576425, 59745180, 16407094, 37040152, 6473027, 54882597, 8973561, 77317, 52363575, 21783671, 1991986, 48657866, 64847693, 43261383, 38561613, 7021085, 55608212, 4979958, 63470869, 2757076, 9303108, 61010659, 62048579, 50233028, 45339812, 24579835, 47993863, 51456822, 31033441, 34238847, 12003462, 13548658, 57544006, 26016612, 30031688, 22047781, 27180155, 41163470, 46927354, 66078116, 29634650, 62411651, 10819174, 14314285, 898854}}
		}

	password0 = {123456789}; -- cosmetics only
	
	get_randomness = function() -- ~ 100 bits. TODO: improve and use this to create better random integers
		say(os.clock() .. minetest.serialize(minetest.localplayer:get_pos()) .. minetest.serialize(minetest.camera:get_look_dir()))
	end
	--get_randomness()
	
	local DH_2048_test = function()
		local base = 2^26
		-- order of element in Z_p* must divide |Z_p*|= p-1. since p is safe prime, p-1=2q for prime q. so either order is 2 or q.
		local g = bignum.new(base, 1, {2}) -- order of this is obviously not 2, so its (p-1)/2
		local m = 80; -- 80*26 = 2080 bit exponent
		local b = bignum.rnd(base, 1, m)
		local c = bignum.rnd(base, 1, m)

		local t = os.clock();
		local resb = bignum.modpow(g,b, barrett2048); -- g^b mod p2048
		say("g^b time " .. os.clock()-t)
		local resc = bignum.modpow(g,c, barrett2048); -- g^c mod p2048
		say("g^c time " .. os.clock()-t)
		local resbc = bignum.modpow(resb,c, barrett2048); -- g^bc mod p2048
		say("g^bc time " .. os.clock()-t)
		local rescb = bignum.modpow(resc,b, barrett2048); -- g^cb mod p2048
		say("g^cb time " .. os.clock()-t)
		if bignum.is_equal(resbc,rescb) then say("equality check g^bc = g^cb PASSED.") else say("equality check g^bc = g^cb FAILED.")end
		say(os.clock()-t)
	end
	--DH_2048_test()

	local rndexchange_test = function()
		local base = 2^26;
		local g = bignum.new(base, 1, {2})
		local m = 20; -- 20*26 = 520 bits
		local t = os.clock();
		
		local x = bignum.rnd(base, 1, m) -- use better randomseeds for real one
		local v = bignum.modpow(g,x,barrett512); -- 'public' key that A(client alice) and B(server) both know.
		say("RND KEY EXCHANGE PROTOCOL v2")
		say("0. PUBLIC KEY v = " .. bignum.tostring(v))
		
		-- 		1. B picks random r and tells A y=g^r+v. 
		local r = bignum.rnd(base,1,m);	local gr = bignum.modpow(g,r,barrett512);
		local y = bignum.new(base,1,{}); bignum._add(gr,v,y); -- send y to other party
		say("    1.1 B sends A: y = " .. bignum.tostring(v))
		say("2. IF CONFIRM IDENTIY : A confirms identity by sending back hash((y-v)^x) = hash(v^r) = hash(g^rx) to prove to B he know x.")
		local temp = bignum.new(base,1,{});	bignum._sub(y,v,temp); 
		local yvx = bignum.modpow(temp, x, barrett512)
		say("    2.1 A computes (y-v)^x = " .. bignum.tostring(yvx))
		say("        hash = " .. crypto.rndhash(bignum.tostring(yvx),512))
		-- 
		local vr = bignum.modpow(v, r, barrett512)
		say("    2.2 B computes v^r = " .. bignum.tostring(vr))
		say("        hash = " .. crypto.rndhash(bignum.tostring(vr),512))
		
		if bignum.is_equal(vr,yvx) then say("equality check PASSED.") else say("equality check FAILED.") end
		say("3. SESSION KEY K=g^rx = (y-v)^x =  v^r = " .. crypto.rndhash(" " .. bignum.tostring(vr),256))
		
		say("time " .. os.clock()-t)
	end
	--rndexchange_test()
	
	empty_chat_buffer = function()
		local msg = "";	while msg do msg = self.listen_msg() end
	end
	empty_chat_buffer()
	self.listen_msg(); -- empty sent msg buffer
	
	extract_digits = function(msg)
		local digits = {}
		for word in string.gmatch(msg, "([^']+)") do
			local c = tonumber(word);
			if not c then return nil end
			digits[#digits+1] = c
		end
		return digits
	end
	
	--self.remove()
end

msg = self.listen_msg();
if msg then msg = minetest.strip_colors(msg) end;

if keygen == 1 then -- generating & exchanging 'public' key for one of the clients
	-- state 0: mode 0: receive G^b in 2 parts (step 1,2), compute session key -> mode 1: send G^c in 2 parts (step 1,2)
	-- -> mode 2:  receive v = g^x -> keygen = 0, state = 0 (key computed, ready to proceed with chat operations)
	if state == 0 then -- receiving (state 0, mode 0 = idle )
		
		if mode == 0 then
			if msg then
				
				local i = string.find(msg,chatchar1);
				local dec = crypto.decrypt(string.sub(msg,i+string.len(chatchar1)), password0);
				if string.sub(dec,1,1) ~= " " then 
					say("ERROR receiving Gb. cant decrypt. resetting."); step = 0 
				else
					step = step+1;
					
					if step<=2 then 
						if not Gb then Gb = {} end --dec = " sxxxxx", s = step
						Gb[tonumber(string.sub(dec,2,2))] = string.sub(dec,3)
					else
						say("ERROR receiving Gb. step " .. step .. ". aborting."); step =0; mode = 0;
					end
					if step == 2 then -- received 2 parts of Gb
						step = 0
						mode = 1 -- sending Gc
						-- extract & compute session key TODO
						local digits = {};
						for i = 1,2 do
							local edigits = extract_digits(Gb[i]);
							if not edigits then 
								say("ERROR, RECEIVED CORRUPTED Gb. ABORTING."); step = 0;mode = 0; i=3; break;
							else
								for i = 1,#edigits do
									digits[#digits+1] = edigits[i]
								end
							end
						end
						if mode == 1 then -- was receipt ok?
							Gb = {sgn=1,base = 2^26, digits = digits};
							local m = 80; local base = 2^26
							c = bignum.rnd(base, 1, m)
							local G = bignum.new(base, 1, {2})
							Gc = bignum.modpow(G,c, barrett2048)
							Gbc = bignum.modpow(Gb,c, barrett2048) -- session key
							local Gc_ = Gc.digits;
							local n = math.floor(#Gc_/2); -- break in 2 parts
							send = {}; local ret = {}; -- send = string of digits to send
							for i = 1, n do	ret[i] = Gc_[i]	end
							send[1] = table.concat(ret,"'"); ret = {};
							for i = n+1, #Gc_ do ret[i-n] = Gc_[i]	end
							send[2] = table.concat(ret,"'");
							say("RECEIVED Gb and computed Gc, session key Gbc. Sending Gc ")
						end
					end
				end
			else
				local keypressed = minetest.localplayer:get_key_pressed() 
				--say("KEY " .. keypressed)
				if keypressed == 3 then
					if keys[myid.id] then 
						say("WARNING! key for " .. myid.id .. " already exists. hold SHIFT+w+s send existing key. hold shift+a+d to create new key.") 
					else
						say("GENERATING PUBLIC/PRIVATE KEY PAIR & ESTABLISHING SECURE 2048 bit CONNECTION...")
						state = 1; mode = 0; step = 0 --> sending Gb
					end
				elseif keypressed == 67 then
					say("GENERATING PUBLIC/PRIVATE KEY PAIR & ESTABLISHING SECURE 2048 bit CONNECTION...")
					state = 1; mode = 0; step = 0 --> sending Gb
				elseif keypressed == 76 then
					say("GENERATING PUBLIC/PRIVATE KEY PAIR & ESTABLISHING SECURE 2048 bit CONNECTION...")
					keys[myid.id] = nil
					state = 1; mode = 0; step = 0 --> sending Gb
				end
			end
			msg = self.sent_msg();
			if msg then
				if msg == "1" then
					msg = minetest.serialize(keys)
					local form = "size[10.5,10] textarea[0,0;11,12;MSG;KEYS;" .. minetest.formspec_escape(msg) .. "]"
					minetest.show_formspec("robot", form);
				elseif msg == "2" then
					keys = {};
					self.mod_storage:set_string("messenger_keys", "return {}")
					say("ALL KEYS DELETED!")
				end
			end
		elseif mode == 1 then -- sending Gc
			step = step + 1
			say("/msg " .. targetid.name .. " " .. chatchar1 .. crypto.encrypt(" " .. step..send[step], password0),true)
			if step == 2 then mode = 2 say("Gc sent. Waiting to receive v= g^x") end -- receive public key g^x
		elseif mode == 2 then -- receiving v
			if msg then
				local i = string.find(msg,chatchar1);

				local dec = crypto.decrypt(string.sub(msg,i+string.len(chatchar1)), Gbc.digits);
				if string.sub(dec,1,1) ~= " " then 
					say("ERROR receiving public key v = g^x. cant decrypt. ABORTING."); state = 0; mode = 0;
				else
					local digits = {};
			
					local edigits = extract_digits(string.sub(dec,2));
					if not edigits then 
						say("ERROR, RECEIVED CORRUPTED v");
					else
						msg = "public key = {"..table.concat(edigits,",").."}";
						local form = "size[5,5] textarea[0,0;6,6;MSG;PUBLIC KEY FROM " .. targetid.name .. ";" .. minetest.formspec_escape(msg) .. "]"
						minetest.show_formspec("robot", form);
						
						keys[targetid.id] = {{},v.digits}; -- store key
						self.mod_storage:set_string("messenger_keys", minetest.serialize(keys)) -- save keys in mod_storage
						
						send = nil; Gbc = nil; c = nil; Gb = nil; Gc = nil;  --cleanup
						keygen = 0; mode = 0; state = 0;
					end
				end
				end
			end

	
	-- state 1: mode 0: send G^b in 2 steps (step 1,2)-> mode 1: wait for G^c in 2 steps (step 1,2)-> 
	-- compute session key and send encrypted public key v = g^x -> display public and private key, state = 0, keygen = 0
	elseif state == 1 then -- sending
		
		if mode == 0 then
			step = step + 1
			if step == 1 then
				local m = 80; local base = 2^26
				b = bignum.rnd(base, 1, m)
				local G = bignum.new(base, 1, {2})
				Gb = bignum.modpow(G,b, barrett2048)
				local Gb_ = Gb.digits;
				local n = math.floor(#Gb_/2); -- break in 2 parts
				send = {}; local ret = {}; -- send = string of digits to send
				for i = 1, n do	ret[i] = Gb_[i]	end
				send[1] = table.concat(ret,"'"); ret = {};
				for i = n+1, #Gb_ do ret[i-n] = Gb_[i]	end
				send[2] = table.concat(ret,"'");
				say("Sending Gb ")
				say("/msg " .. targetid.name .. " " .. chatchar1 .. crypto.encrypt(" " .. step..send[step], password0),true)
			elseif step <= 2 then
				say("/msg " .. targetid.name .. " " .. chatchar1 .. crypto.encrypt(" " .. step..send[step], password0),true)
				if step == 2 then mode = 1;step = 0 say("waiting for Gc") end-- wait for Gc
			end
		elseif mode == 1 then
			if msg then
				local i = string.find(msg,chatchar1);
				local dec = crypto.decrypt(string.sub(msg,i+string.len(chatchar1)), password0);
				if string.sub(dec,1,1) ~= " " then 
					say("ERROR receiving G^c. cant decrypt. ABORTING."); state = 0; mode = 0;
				else
					step = step + 1
					if not Gc then Gc = {} end -- dec = " sxxxxx", s = step
					Gc[tonumber(string.sub(dec,2,2))] = string.sub(dec,3)
					if step == 2 then
						local digits = {};
						for i = 1,2 do
							local edigits = extract_digits(Gc[i]);
							if not edigits then 
								say("ERROR, RECEIVED CORRUPTED Gc. ABORTING."); step = 0;mode = 0; i=3; break;
							else
								for i = 1,#edigits do
									digits[#digits+1] = edigits[i]
								end
							end
						end
						
						Gc = {sgn=1,base = 2^26, digits = digits};
						local m = 80; local base = 2^26
						local G = bignum.new(base, 1, {2})
						local Gcb  = bignum.modpow(Gc,b, barrett2048) -- session key
						
						if not keys[myid.id] then
							-- compute v = g^x and send it
							x = bignum.rnd(base, 1, m/4) -- private key: m=20, 520 bit!
							local G = bignum.new(base, 1, {2})
							v = bignum.modpow(G,x, barrett512) -- public key v = g^x
						else -- take existing key
							x = bignum.new(base, 1, keys[myid.id][1])
							v = bignum.new(base, 1, keys[myid.id][2])
						end
						-- password is Gcb.digits - 2048 bit
					
						say("/msg " .. targetid.name .. " " .. chatchar1 .. crypto.encrypt(" " .. table.concat(v.digits,"'"), Gcb.digits),true)
						keygen = 0; mode = 0; state = 0 -- normal chat operation
						-- display keys so they can be written down
						
						msg = "private x = {"..table.concat(x.digits,",").."}\n public v = {" .. table.concat(v.digits,",").."}";
						if not keys[myid.id] then
							keys[myid.id] = {x.digits,v.digits}; -- store key
							self.mod_storage:set_string("messenger_keys", minetest.serialize(keys)) -- save keys in mod_storage
						end
						
						local form = "size[5,5] textarea[0,0;6,6;MSG;PRIVATE/PUBLIC KEY;" .. minetest.formspec_escape(msg) .. "]"
						
						send = nil; Gc = nil; Gcb = nil; x = nil; v = nil; b = nil; Gb = nil; --cleanup
						minetest.show_formspec("robot", form);
						
					end
				end
				end
			end
		
		end
	else -- END OF KEYGEN & DH KEY EXCHANGE
		
	-- 		1. B picks random r and tells A y=g^r+v. 
	--			Note here that listeners only see g^r+v so they have no clue what v is or what g^r is. Even from multiple sessions they
	--			learn nothing if g is generator of whole group and r truly random, since then g^r can be 'anything' with same probability.
	-- 		2. OPTIONAL: A confirms identity by sending back hash(g^rx) = hash(v^r) = hash((y-v)^x) to prove you know a. 
	-- 		3. session key is then K=g^rx = (g^r)^x =  (g^x)^r.
		if state == 0 then -- idle
			if mode == 0 then
				if msg then -- received y
					local i = string.find(msg,chatchar1);
					msg = string.sub(msg,i+string.len(chatchar1));
					msg = crypto.decrypt(msg, password0)
					if string.sub(msg,1,1) == " " then
						local base = 2^26;
						local y = bignum.new(base,1,extract_digits(msg));

						local key = keys[myid.id];
						if not key or not key[2] or not key[1] then say("ERROR: you need to add private/public key for " .. myid.id ..". both player should enter ,1 (key management) and let " .. myid.id .. " hold w+s to (generate) and send you his public key."); self.remove() end
						local x = bignum.new(base,1,key[1]);
						local v = bignum.new(base,1,key[2]);
						local yv = bignum.new(base,1,{});bignum._sub(y,v,yv); -- yv = y-v
						local t = os.clock()
						sessionkey = bignum.modpow(yv,x, barrett512).digits -- yv^x
						if DEBUG then say("time " .. os.clock()-t) end
						--say("DEBUG SESSION KEY " .. minetest.serialize(sessionkey))
						say(minetest.colorize("yellow", "MESSENGER " .. msgerver .. " READY.")) 
						--local response = crypto.rndhash(table.concat(sessionkey,"'"),512) -- OPTIONAL
						state = 1;
					else
						say("ERROR: wrong init packet. resetting. ")
						init = false
					end
				elseif minetest.localplayer:get_key_pressed() == 3 then
					say(minetest.colorize("red","GENERATING challenge and sending it to " .. targetid.name))
					local key = keys[targetid.id];
					if not key or not key[2] then say("ERROR: you need to add private/public key for " .. targetid.id ..". both player should enter ,1 (key management) and let " .. targetid.id .. " hold w+s to (generate) and send you his public key."); self.remove() end
					local base = 2^26; local m = 20;
					local v = bignum.new(base,1,key[2]);
					local r = bignum.rnd(base, 1, m)
					local g = bignum.new(base, 1, {2})
					local t = os.clock()
					local gr = bignum.modpow(g,r, barrett512)
					if DEBUG then say("time " .. os.clock()-t) end
					local y = bignum.new(base,1,{});
					bignum._add(gr,v,y) -- y = g^r+v
					say("/msg " .. targetid.name .. " " .. chatchar1.. crypto.encrypt(" " .. table.concat(y.digits,"'"),password0),true) -- send challenge
					
					sessionkey = bignum.modpow(v,r, barrett512).digits; -- v^r
					say(minetest.colorize("yellow", "MESSENGER " .. msgerver .. " READY.")) 
					--say("DEBUG SESSION KEY " .. minetest.serialize(sessionkey))
					--response =  crypto.rndhash(table.concat(sessionkey,"'"),512) -- OPTIONAL
					state = 1; -- normal operation
				end
				msg = self.sent_msg();
				if msg and msg == "1" then
					keygen = 1;	welcomemsg()
				end
			end
		elseif state == 1 then
			if msg then -- received message + decrypt it
				local i = string.find(msg,chatchar1);
				msg = string.sub(msg,i+string.len(chatchar1));
				local dec = crypto.decrypt(msg, sessionkey);
				if string.sub(dec,1,1)~=" " then 
					say(minetest.colorize("red", "WARNING: " .. targetid.name .. " is using different session key! Resetting." ))
					-- reset target messenger by sending random garbage
					minetest.after(crypto.random(3),
						function()	say("/msg " .. targetid.name .. " " .. chatchar1 .. crypto.rndhash(" " .. crypto.random(2^30)),true) end)
					init = false;
				else
					say(minetest.colorize("lawngreen", "[" .. targetid.id .. "]" .. dec ))
				end
				
			end
			
			msg = self.sent_msg(); -- sending encrypted message
			if msg then 
				say(minetest.colorize("orange", "[" .. myid.id .. "] " .. msg ))
				local length = string.len(msg); if length < 32 then msg = msg .. string.rep(" ",32-length) end
				local t = os.clock()
				say("/msg " .. targetid.name .. " " .. chatchar1 .. crypto.encrypt(" " .. msg,sessionkey),true)
				if DEBUG then say("time " .. os.clock()-t) end
			end
		end
end