--triangulation by rnd
if not init then
	get_inter = function(x1,y1,a1,b1,x2,y2,a2,b2) 
		local s = (b1*x1-a1*y1-b1*x2+a1*y2)/(a2*b1-b2*a1); return x2+a2*s,y2+b2*s
	end
	init = true; state = 1; pos = {{{0,0,0},{0,0,0}},{{0,0,0},{0,0,0}}};
	say(minetest.colorize("red", "LOOK AT TARGET FROM 2 DIFFERENT POSITIONS. press shift to advance to next step."))
end

if minetest.localplayer:get_key_pressed() == 64 then 
	if state <=2 then
		say(minetest.colorize("orange", "point " .. state .. " set."))
		local p = minetest.localplayer:get_pos(); local view = minetest.camera:get_look_dir()
		pos[state] = {p,view}; state = state +1
		if state == 3 then
			local x1,z1,x2,y2;init = false
			x1,z1 = get_inter(pos[1][1].x,pos[1][1].z,pos[1][2].x,pos[1][2].z,pos[2][1].x,pos[2][1].z,pos[2][2].x,pos[2][2].z)
			x2,y2 = get_inter(pos[1][1].x,pos[1][1].y,pos[1][2].x,pos[1][2].y,pos[2][1].x,pos[2][1].y,pos[2][2].x,pos[2][2].y)
			local dist = math.floor(math.sqrt((p.x-x1)^2+(p.y-y2)^2+(p.z-z1)^2))
			x1 = math.floor(10*x1)/10;y2 = math.floor(10*y2)/10;z1 = math.floor(10*z1)/10
			say(minetest.colorize("lawngreen","TARGET IS AT " .. x1.. " " .. y2 .. " "  .. z1 .. " (dist = " .. dist ..")"))
		end
	end
end