-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Eco-Devices - Estimate next bill cost
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

function getFileFromServer(tcp, path)
  r, s, e = tcp:GET(path);
  if (tonumber(s)~=200) then
    return 0, nil;
  else
    return string.len(r), r;
  end
  return nil;
end


--[[
  EXTRA FUNCTIONS
]]--
-- counting elements in array (table)
function count(tab) local k,v,i; i=0; for k, v in pairs(tab) do i = i + 1; end return i; end
-- print any variable content
function printr(v,l,k) local d=function(t)fibaro:debug(t);end if(not l)then l=0;end local s=string.rep(string.char(0xC2,0xA0),(l*3)); local n="";if(k)then n=k.." = ";end if(v and type(v))then if(type(v)=="table")then d(s..n.."{");local i,j;for i,j in pairs(v)do printr(j,(l+1),tostring(i));end d(s.."}");elseif(type(v)=="function")then d(s..n..tostring(v).."() {");d(s.."}");elseif(type(v)=="userdata")then d(s..n..tostring(v).."() {");d(s.."}");elseif(type(v)=="string")then if(#v>50)then d(s..n.."String["..#v.."] = \""..string.sub(v,1,50).."\"...");else if(k)then v="\""..v.."\"";end d(s..n..tostring(v));end elseif(type(v)=="number")then d(s..n..tostring(v));else d(s..n..tostring(v).."["..type(v).."]");end else d(s..n.."{nil}");end end


function trace(value)
  if (_trace) then
    return fibaro:debug(tostring(value));
  end
end

function split(str, delim)
    local result,pat,lastPos = {},"(.-)" .. delim .. "()",1
    for part, pos in string.gfind(str, pat) do
        table.insert(result, part); lastPos = pos
    end
    table.insert(result, string.sub(str, lastPos))
    return result
end

---============================================================
function padzero(s, count)
	return string.rep("0", count-string.len(s)) .. s 
end

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

--====================================================
function getday_posfix(day)
local idd = math.mod(day,10)
       return	(idd==1 and day~=11 and "st")  or (idd==2 and day~=12 and "nd") or (idd==3 and day~=13 and "rd") or "th"
end



--========================================================================
-- Note : date_str has to be  ISO 8601 date format  ie. yyyy-mm-dd
--
function format_date(date_str, dateformat)
local iyy, imm, idd 

	if (date_str and date_str~="") then
		iyy, imm, idd =  get_date_parts(date_str)
		dateformat = string.gsub(dateformat, "DDD",  idd..string.upper(getday_posfix(idd)))
		dateformat = string.gsub(dateformat, "ddd",  idd..getday_posfix(idd) )
		dateformat = string.gsub(dateformat, "dd", padzero(idd,2))
		dateformat = string.gsub(dateformat, "MMM", string.upper(getmonth(imm)))
		dateformat = string.gsub(dateformat, "mmm", getmonth(imm))
		dateformat = string.gsub(dateformat, "mm", padzero(imm,2))
		dateformat = string.gsub(dateformat, "yyyy", padzero(iyy,4))
		dateformat = string.gsub(dateformat, "yy", string.sub(padzero(iyy,4),3,4))
	else
		dateformat = ""
	end

	return(dateformat)
end

function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

local energylist = {};

selfId=fibaro:getSelfId();
local ip = fibaro:get(selfId, 'IPAddress');

-- connect to server
fibaro:debug("Connecting to [" .. ip .. "]...");
local tcpSERVER = Net.FHttp(ip, 80);
HP_cost = 0.1572;
HC_cost = 0.1096;

local LastBill =os.time{year=2015, month=04, day=05};

if (not tcpSERVER) then
  fibaro:debug("SERVER ERROR! Skipping...");
else
  fibaro:debug("---");
  size, content  = getFileFromServer(tcpSERVER, "/protect/download/xdata.csv");

  if (size>0) then
		fibaro:debug("Received file [" .. size .. " bytes].");
		fibaro:debug("content [" .. content .. "].");
		local table = split(content, "\n");
		if(not l)then l=0; end
    
		for i,j in pairs(table)do
			-- test du pattern
				annee, mois, jour, hp, hc = j:match("(%d+),(%d+),(%d+),%d+,(%d+),(%d+),");
				
			if(annee) then 
        		local seconds = os.time{year=annee, month=mois, day=jour};
				local diff = tonumber(os.difftime(seconds, LastBill));
				-- insertion dans le tableau
      			day = annee .. "-" .. mois .. "-"  .. jour
				f_day = format_date(day, "dd/mm/yy");
				if(diff > 0) then
					energylist[#energylist + 1] = { date = f_day, hp = hp, hc = hc }
          		end
            end
      	end
		local max = count(energylist)
		
    	-- comparer les valeurs pour calculer la facture
    	fibaro:debug("Calcul sur la perdiode du " .. energylist[1].date .. " au " .. energylist[max].date);
    	-- caclul conso 
    	hp_next_bill = tonumber( (energylist[max].hp - energylist[1].hp) /1000);
    	hc_next_bill = tonumber( (energylist[max].hc - energylist[1].hc) /1000);
		-- calcul du cout
    	hpc_next_bill = math.floor(hp_next_bill*HP_cost);
    	hcc_next_bill = math.floor(hc_next_bill*HC_cost);
	    next_bill = math.floor(hpc_next_bill + hcc_next_bill +(123.95/6) );
    
        fibaro:debug("hp_next_bill: " .. hp_next_bill .. " kWH, " .. hpc_next_bill .. "€" );
        fibaro:debug("hc_next_bill: " .. hc_next_bill .. " kWH, " .. hcc_next_bill .. "€" );
    	fibaro:debug("next_bill: " .. next_bill .. "€");
		fibaro:debug("DONE!");
  else
    fibaro:debug("Connection problem!");
  end
end
