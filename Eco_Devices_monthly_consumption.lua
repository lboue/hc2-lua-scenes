-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Eco-Devices - Calc consumption from JSON table
--
-- 2015 Ludovic BOUÉ 
--
-- Version 1.1.2
--
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

--[[ 
%% properties 
%% globals 

--]] 


--[[
  EXTRA FUNCTIONS
]]--

function isJson(value)
	local ok = pcall(function()
					local decodedData = json.decode(value)
				end)

		if (not ok) then
			return false , "is not a valid json"
		else
			return true, "is a valid json"
		end
end

-- counting elements in array (table)
function count(tab) local k,v,i; i=0; for k, v in pairs(tab) do i = i + 1; end return i; end

-- print any variable content
function printr(v,l,k) local d=function(t)fibaro:debug(t);end if(not l)then l=0;end local s=string.rep(string.char(0xC2,0xA0),(l*3)); local n="";if(k)then n=k.." = ";end if(v and type(v))then if(type(v)=="table")then d(s..n.."{");local i,j;for i,j in pairs(v)do printr(j,(l+1),tostring(i));end d(s.."}");elseif(type(v)=="function")then d(s..n..tostring(v).."() {");d(s.."}");elseif(type(v)=="userdata")then d(s..n..tostring(v).."() {");d(s.."}");elseif(type(v)=="string")then if(#v>50)then d(s..n.."String["..#v.."] = \""..string.sub(v,1,50).."\"...");else if(k)then v="\""..v.."\"";end d(s..n..tostring(v));end elseif(type(v)=="number")then d(s..n..tostring(v));else d(s..n..tostring(v).."["..type(v).."]");end else d(s..n.."{nil}");end end


--========================================================================
-- get date parts for a given ISO 8601 date format (http://richard.warburton.it )
function get_date_parts(date_str)
  _,_,y,m,d=string.find(date_str, "(%d+)-(%d+)-(%d+)")
  return tonumber(y),tonumber(m),tonumber(d)
end

--====================================================
function getmonth(month)
	local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
	return months[tonumber(month)]
end

local jsonString = fibaro:getGlobalValue("energylist")
local isJson, isJsonTxt = isJson(jsonString);
if (isJson == true) then
		fibaro:debug("Parsing jsonString from GlobalValue(energylist)".. ": " .. isJsonTxt);

		-- null will be decoded to json.null value
		jsonTable = json.decode(jsonString);
		local max = count(jsonTable);

		fibaro:debug("Calcul sur la periode du " .. jsonTable[1].date .. " au " .. jsonTable[max].date);

		local selfId=fibaro:getSelfId();
		local totalHP = 0;
		local totalHC = 0;
		local lastm = 1;
		local table = {};
		HP_cost = 0.1572;
		HC_cost = 0.1096;

		fibaro:debug("Cost: HP=" .. HP_cost .."€/kWh, HC=" ..HC_cost .. "€/kWh");

		local k,v,i; i=0; for k, v in pairs(jsonTable) do 
			_,m,_ = get_date_parts(v.date);
			if (lastm ~= m) then 
				totalHP = 0;
				totalHC = 0;
				lastm = lastm+1
			end
			totalHP = totalHP + v.hp_day;  
			totalHC = totalHC + v.hc_day; 
			table[m] = { mois = m, totalHP = totalHP, totalHC = totalHC}
		end

		fibaro:debug("---");
		for i=1,12 do
				button = "ui.Label" .. i .. ".value";  
				fibaro:call(selfId, "setProperty", button, "N.A");
		end

		for k, v in pairs(table) do
			local hp_next_bill = 0;
			local hc_next_bill = 0;
			local next_bill = 0;

	 	 	-- consumption cost
			hpc_next_bill = math.floor(v.totalHP*HP_cost);
			hcc_next_bill = math.floor(v.totalHC*HC_cost);
			next_bill = math.floor(hpc_next_bill + hcc_next_bill );

			fibaro:debug("* mois=" .. getmonth(v.mois) .. ", totalHP=" .. math.floor(v.totalHP) .. " kWh, totalHC=" .. math.floor(v.totalHC) .. " kWh, TOTAL==>" .. next_bill .. "€");

			button = "ui.Label" .. v.mois .. ".value";
			fibaro:call(selfId, "setProperty", button, "HP=" .. math.floor(v.totalHP) .. " HC=" .. math.floor(v.totalHC) .. " => " .. next_bill .. "€");
		end
	else 
		fibaro:debug("Fail to parse jsonString from GlobalValue(energylist)".. ": " .. isJsonTxt);
	end
	
	fibaro:debug("---");
