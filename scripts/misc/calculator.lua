--calculator by rnd

if not init then
	init = true
	self.msg_filter("",false)
	say(minetest.colorize("red","#Calculator started. say ,1+1 or x=2;return x^0.5 "))
end

msg = self.sent_msg()
if msg and msg~="" then 
	local result,err;
	local f;
	if not string.find(msg,"return") then msg = "return " .. msg end
	f,err = _G.loadstring(msg);
	if err then 
		say("#compile error: " .. err) 
	else 
		err,result = pcall(f);
		if not result then
			say("#run error: " ..err)
		else
			result = tonumber(result)
			if result then say(minetest.colorize("lawngreen",msg .. " -> " .. result)) else say("empty result") end
		end
	end
end