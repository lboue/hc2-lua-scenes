-- Declenchement de la notification vers PushOver
 
local token=""
local user=""
local priority=0
local title="Scénario"
local message=fibaro:getGlobal("PushOver_message")

fibaro:debug("PushOver_message: " .. message)
 
HC2 = Net.FHttp("api.pushover.net")
url = "/1/messages.json?"
payload = ""
payload = payload .. "token=" .. token
payload = payload .. "&" .. "user=" .. user
payload = payload .. "&" .. "message=" .. message
payload = payload .. "&" .. "priority=" .. priority
payload = payload .. "&" .. "title=" .. title
 
fibaro:debug(payload)
 
response, status, errorCode = HC2:POST(url,payload)
 
fibaro:debug("response = " .. response)
fibaro:debug("status = " .. status)
 
