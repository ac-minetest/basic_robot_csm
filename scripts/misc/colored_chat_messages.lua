if not init then
  self.msg_filter("",true) -- record & hide all incoming messages
  cfilter = {
	["***"] = "pink",
	["<"] = "lawngreen",
	["PM"] = "red",
   }
   defaultcolor = "yellow";
  
end

msg = self.listen_msg()
if msg and msg~= "" then
	color = defaultcolor;
	for k,v in pairs(cfilter) do
		local l = string.len(k);
		if string.sub(msg,1,l) == k then
			color = v;
		end
	end
	say(minetest.colorize(color,msg))
end