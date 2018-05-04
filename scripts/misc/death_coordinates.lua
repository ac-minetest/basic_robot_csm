--DEATH COORDINATES by rnd
if not rom.death then
say("DEATH COORDINATES REGISTERED!")
minetest.register_on_death(function() 
  local pos = minetest.localplayer:get_pos(); say("DEAD AT " .. pos.x .. " " .. pos.y .. " " .. pos.z )
end
)
rom.death = true;self.remove()
end