--[[
%% properties
	Replace with you IP and Authorization hash
%% globals
--]]
if not iLoObject then iLoObject = {
  _host = "192.168.1.1",
  _port = 443
};iLo=iLoObject;end;

local http = net. HTTPClient () 
http : request ( 'https://' .. iLo._host .. '/rest/v1/Systems/1',  {
    options =  {
        method =  "GET",
        headers =  {
            ['Authorization']  =  'Basic QWRtaW5p************VFJKR0dHVg=='
        }
    },
    success =  function (response) 
		result = json.decode(response.data)
      	fibaro: debug ( "## " .. result.Model .. " ## ")
      	fibaro: debug ( "PowerState: " .. result.PowerState .. "")
      	fibaro:setGlobal("HPiLO_Status", result.PowerState);
      
    end,
    error  =  function (err) fibaro: debug ("Error:"  .. err)  end
})



local http = net. HTTPClient () 
http : request ( 'https://' .. iLo._host .. '/rest/v1/Chassis/1/Thermal',  {
    options =  {
        method =  "GET",
        headers =  {
            ['Authorization']  =  'Basic QWRtaW5p************VFJKR0dHVg=='
        }
    },
    success =  function (response) 
      	--fibaro: debug(response. data)  
      	-- decoding json string to table
		result = json.decode(response.data)
      	fibaro: debug ( "## " .. result.Name .. " ## ")
      	fibaro: debug ( result.Temperatures[1].Context .. ": " ..
        				result.Temperatures[1].ReadingCelsius .. "°C"   					
      				   )
      	fibaro:setGlobal("HPiLO_AmbientTemp", result.Temperatures[1].ReadingCelsius)

        fibaro: debug ( result.Temperatures[2].Context .. ": " .. 
        				result.Temperatures[2].ReadingCelsius .. "°C"   					
          			   )
      	fibaro:setGlobal("HPiLO_CPUTemp", result.Temperatures[2].ReadingCelsius)      
      	fibaro: debug ( result.Temperatures[5].Context .. ": " .. 
        				result.Temperatures[5].ReadingCelsius .. "°C"   					
          			   ) 
      	fibaro:setGlobal("HPiLO_SysTemp", result.Temperatures[2].ReadingCelsius)      
      
    end,
    error  =  function (err) fibaro: debug ("Error:"  .. err)  end
})


fibaro:setGlobal("p_iLo_appToken", "");
fibaro:setGlobal("HPiLO_FwVersion", "");
