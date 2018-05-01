-- colored text: string.char(27) .."(c@red)"..text
if not colors then
	colors = {"red","blue","violet", "lawngreen","brown","yellow","orange","pink"}
end

msg = self.sent_msg()
if msg then
	ret = {};
	for word in string.gmatch(msg,"%S+") do
		ret[#ret+1] = minetest.colorize(colors[math.random(#colors)],word)
	end
	say(table.concat(ret," "))
end