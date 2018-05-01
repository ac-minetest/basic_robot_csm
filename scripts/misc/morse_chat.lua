-- morse code by rnd, 10 minutes
if not mcode then
	self.msg_filter("",false)
	mdecode = {
		[","] = " ",[".-"] = "A",["-..."] = "B",["-.-."] = "C",["-.."] = "D",
		["-..."] = "B",["."] = "E",["..-."] = "F",["--."] = "G",["...."] = "H",
		[".."] = "I",[".---"] = "J",["-.-"] = "K",[".-.."] = "L",["--"] = "M",
		["-."] = "N",["---"] = "O",[".--."] = "P",["--.-"] = "Q",[".-."] = "R",
		["..."] = "S",["-"] = "T",["..-"] = "U",["...-"] = "V",[".--"] = "W",
		["-..-"] = "X",["-.--"] = "Y",["--.."] = "Z",

		[".----"] = "1",["..---"] = "2",["...--"] = "3",["....-"] = "4",
		["....."] = "5",["-...."] = "6",["--..."] = "7",["---.."] = "8",
		["----."] = "9",["-----"] = "0",
	}

	mcode = {}; for k,v in pairs(mdecode) do mcode[v] = k end

	encode = function(input)
		input = string.upper(input)
		local ret = {}
		for i=1,string.len(input) do
			ret[#ret+1] = mcode[string.sub(input,i,i)] or ","
		end
		return table.concat(ret," ")
	end
	
	decode = function(input)
		local ret = {};
		for word in string.gmatch(input,"%S+") do
			ret[#ret+1] = mdecode[word] or ""
		end
		return table.concat(ret,"")
	end
	
	--local enc = encode("attack at dawn 451322E 12874541N");
	--local dec = decode(enc);
	--say(enc .. " -> " .. dec)
end

msg = self.listen_msg()
if msg and msg~= "" then
	i = string.find(msg,">")
	if i then
		msg = decode(string.sub(msg,i+2))
		if msg~="" then
			say( minetest.colorize("red",msg))
		end
	end
end

msg = self.sent_msg()
if msg then
	say(encode(msg),true)
end