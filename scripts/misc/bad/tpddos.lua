--ddos
if not init then 
target = "boxface"
init = true
t = 50
say("/msg " .. target .. " TPDDOS started.", true)
say("/tpr "..target,true); t = 50 
self.msg_filter("quest ",false)
end

local msg = self.listen_msg()
if msg and (string.find(msg,"denied") or string.find(msg,"Accepted")) then say("/tpr " .. target,true);t = 50 end
t=t-1
if t<=0 then 
	say("/tpr " .. target,true); t = 50 
end
