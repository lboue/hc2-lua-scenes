-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Eco-Devices - Switch on/off BBox Sensation
--
-- 2015 Ludovic BOUÉ 
--
-- Version 1.0
--
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

--[[ 
%% properties 
%% globals 
--]] 

-- Broadcast Address 
selfId = fibaro:getSelfId();    

-- BBoxTV Address 192.168.1.64
ip = fibaro:get(selfId, 'IPAddress');
fibaro:debug("BBox IP Address=" .. ip);

-- Default port used 
-- local _wakeOnLanPort = 161;
local Snmp_Port = 161;

local _snmpPacket = string.char(0x30, 0x30, 0x02, 0x01, 0x00, 
  0x04, 0x06, 0x70, 0x75, 0x62, 0x6c, 0x69, 0x63, 0xa3, 0x23, 
  0x02, 0x04, 0x30, 0xe1, 0x44, 0x21, 0x02, 0x01, 0x00, 0x02, 
  0x01, 0x00, 0x30, 0x15, 0x30, 0x13, 0x06, 0x0d, 0x2b, 0x06, 
  0x01, 0x04, 0x01, 0xc4, 0x07, 0x65, 0x0d, 0x01, 0x03, 0x1c, 
  0x00, 0x04, 0x02, 0x30, 0x30);

fibaro:sleep(750); 

-- fibaro:debug("Magic packet successfully created");
fibaro:debug("SNMP packet successfully created");  

fibaro:sleep(1000); 

socket = Net.FUdpSocket(); 
socket:setBroadcast(true); 

local bytes, errorCode = socket:write(_snmpPacket, ip, Snmp_Port); 
--check for error      
if errorCode == 0 then 
  fibaro:debug("Successfully sent"); 
else 
  fibaro:debug("Transfer failed"); 
end 

-- clean up memory 
socket = nil; 

fibaro:sleep(1000); 
fibaro:debug("Please wait for the BBox startup/standby.");

