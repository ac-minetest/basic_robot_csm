--calculator by rnd
--say ,2+3 in chat

if not init then
	init = true
	self.msg_filter("",false)
end

msg = self.sent_msg()
if msg and msg~="" then 
	result = _G.loadstring("return "..msg)();
	result = tonumber(result)
	if result then say(minetest.colorize("lawngreen",msg .. " = " .. result)) else say("error in formula") end
end