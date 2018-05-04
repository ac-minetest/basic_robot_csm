--buffer by rnd

buffer = {};
buffer.idx = 0
buffer.data = {};
buffer.t = 0 -- how many unread insertions

buffer.add = function(element) -- insert new element
	local i = buffer.idx+1;
	if i > buffer.size then i = 1 end
	buffer.data[i]=element
	buffer.idx = i
	local t = buffer.t +1
	if t>buffer.size then t = buffer.size end
	buffer.t =  t
end

buffer.read = function() -- pop 1 message, return nil if none
	local t = buffer.t; 
	if t>0 then
		buffer.t = t-1
		local idx = buffer.idx;
		if idx>1 then buffer.idx = idx - 1 else buffer.idx = buffer.size end
		return buffer.data[idx];
	end
end

buffer.last = function(count) -- returns list of "count" recently inserted elements
	local ret = {};
	local idx = buffer.idx;
	local size = buffer.size;
	if count > size then count = size end
	local data = buffer.data
	for i = idx,1,-1 do
		ret[#ret+1] = data[i];
	end
	
	if count > idx then
		for i = 1,count - idx do
			ret[#ret+1]=data[buffer.size-i+1]
		end
	end
	return ret
end



buffer.size =  3;
buffer.add(1);buffer.add(2);
--say(minetest.serialize(buffer.read()))
say("1 " .. buffer.read())
say(buffer.t)
say("2 " .. buffer.read())
say("3 " .. buffer.read())

self.remove()