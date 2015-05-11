--[[ 
%% properties 
%% globals 
--]] 

--[[
  EXTRA FUNCTIONS
]]--
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

local jsonString = fibaro:getGlobalValue("energylist");

-- null will be decoded to json.null value
jsonTable = json.decode(jsonString);
--fibaro:debug(jsonString);

local max = count(jsonTable);

-- comparer les valeurs pour calculer la facture
fibaro:debug("Calcul sur la periode du " .. jsonTable[1].date .. " au " .. jsonTable[max].date);

local hc_day
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
  totalHP = totalHP + v.hc_day;  
  totalHC = totalHC + v.hp_day; 
  --fibaro:debug(v.date);
  --fibaro:debug(json.encode(v));  
  table[m] = { mois = m, totalHP = totalHP, totalHC = totalHC}
  --fibaro:debug(v.date .. ", m=" .. m .. ", lastm=" .. lastm);
end

-- Affichage du rapport des mois
--printr(table);
fibaro:debug("---");
for i=1,12 do
  	button = "ui.Label" .. i .. ".value";  
    fibaro:call(selfId, "setProperty", button, "N.A");
end

for k, v in pairs(table) do
 	 -- calcul du cout
  	local hp_next_bill = 0;
  	local hc_next_bill = 0;
  	local next_bill = 0;

  	hpc_next_bill = math.floor(v.totalHP*HP_cost);
  	hcc_next_bill = math.floor(v.totalHC*HC_cost);
  	next_bill = math.floor(hpc_next_bill + hcc_next_bill );

		fibaro:debug("* mois=" .. getmonth(v.mois) .. ", totalHP=" .. math.floor(v.totalHP) .. " kWh, totalHC=" .. math.floor(v.totalHC) .. " kWh, TOTAL==>" .. next_bill .. "€");

		--update month labels
		button = "ui.Label" .. v.mois .. ".value";  
    fibaro:call(selfId, "setProperty", button, "HP=" .. math.floor(v.totalHP) .. " HC=" .. math.floor(v.totalHC) .. " => " .. next_bill .. "€");
end

fibaro:debug("---");
