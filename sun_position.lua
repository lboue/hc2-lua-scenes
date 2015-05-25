-- Fonction pour réduire à 2 décimales
function round(num, dec)
  local mult = 10^(dec or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Fonction pour déterminer 365 ou 366 selon l'année en question
function isLeapYear(year)
  return year%4==0 and (year%100~=0 or year%400==0)
end

function setDevicePropertyValue(id, label, value)
  fibaro:call(id, "setProperty", "ui."..label..".value", value)
end

function calcul_jour_julien(jour, mois, annee, heure, minute, seconde)
  local month
  local year
  local day
  local a
  local b
  local jour_julien
  day   = jour + heure /24 + minute/ 1440 + seconde / 86400
  year  = annee
  month = mois
  if month==1 or month==2 then
    year=year - 1
    month=month + 12
  end
  if isLeapYear(year) then
    days=365.25
	else
    days=365
  end
  a = math.floor(year / 100)
  b = 2 - a + math.floor( a / 4)
  jour_julien = math.floor( days * ( year + 4716)) + math.floor(30.6001*(month+1.0)) + day + b - 1524.5
  return jour_julien
end
 
  
-- ===========================================
-- Main
-- ===========================================
local days
local MVid = fibaro:getSelfId()

HC2 = Net.FHttp("127.0.0.1",11111);
local response, status, errorCode = HC2:GET("/api/settings/location");
 
if (tonumber(errorCode) == 0) then
  jsonTable = json.decode(response);
else
  fibaro:debug("error "..errorCode )
end
-- recuperation des données de la HC2 
local Ville = (jsonTable.city)
local latitude = (jsonTable.latitude);
local longitude = (jsonTable.longitude);
--fibaro:debug("Latitude : "..latitude.." - Longitude : " .. longitude)

fibaro:debug(os.date("%d/%m/%y %H:%M:%S"))
local dt = os.date("*t")
--local JourJulien = calcul_jour_julien(13,01,2015,12,00,00)
local correction_heure
-- Correction heure isdst = True => Eté => +2h sinon Hiver +1h (UT)
if (dt.isdst) then
  correction_heure = 2
else
  correction_heure = 1
end

local jour_nouveau = calcul_jour_julien(dt.day, dt.month, dt.year, dt.hour, dt.min, dt.sec)-correction_heure/24-2451545
setDevicePropertyValue(MVid, "JourJulienNouv", jour_nouveau)

------------------------------------------------------------------------------
-------------calculs et affichages ascension droite et délinaison-------------
------------------------------------------------------------------------------

local g = 357.529 + 0.98560028 * jour_nouveau
local q = 280.459 + 0.98564736 * jour_nouveau
local l = q + 1.915 * math.sin ( g * math.pi / 180 ) + 0.020 * math.sin( 2 * g * math.pi /180 )
local e = 23.439 - 0.00000036 * jour_nouveau
local ascension_droite = math.atan(math.cos( e * math.pi / 180) * math.sin( l * math.pi / 180 ) / math.cos( l * math.pi / 180)) * ( 180 / math.pi ) / 15
if (math.cos( l * math.pi / 180) < 0) then
  ascension_droite = 12 + ascension_droite
end
if (math.cos( l *math.pi / 180) > 0 and math.sin( l * math.pi / 180) < 0 ) then
  ascension_droite = ascension_droite + 24
end
setDevicePropertyValue(MVid, "AscensionDroite", ascension_droite)

local declinaison = math.asin(math.sin(e * math.pi / 180) * math.sin( l * math.pi / 180)) * 180 / math.pi
setDevicePropertyValue(MVid, "Declinaison", declinaison)
  
------------------------------------------------------------------------------
-----------------------------calculs heure sidérale et angle horaire----------
------------------------------------------------------------------------------
--local nb_siecle = jour_nouveau/36525
local nb_siecle = jour_nouveau/(days*100)
local heure_siderale1 = (24110.54841 + (8640184.812866 * nb_siecle) + (0.093104 * (nb_siecle * nb_siecle)) - (0.0000062 * (nb_siecle * nb_siecle * nb_siecle))) / 3600
local heure_siderale2 = ((heure_siderale1 / 24) - math.floor(heure_siderale1 / 24)) * 24

local angleH = 360 * heure_siderale2 / 23.9344
local angleT = ( dt.hour - correction_heure - 12 + dt.min / 60 + dt.sec / 3600) * 360 / 23.9344
local angle = angleT + angleH
local angle_horaire = angle - ascension_droite * 15.0 + longitude

-------------calculs et affichages altitude et azimut-------------------------
------------------------------------------------------------------------------
local altitude = math.asin(math.sin(declinaison * math.pi / 180) * math.sin(latitude * math.pi / 180) - math.cos(declinaison * math.pi / 180) * math.cos(latitude * math.pi / 180) * math.cos(angle_horaire * math.pi / 180)) * 180/math.pi

local azimut = math.acos((math.sin(declinaison * math.pi / 180) - math.sin( latitude * math.pi / 180) * math.sin(altitude * math.pi / 180)) / (math.cos(latitude * math.pi / 180) * math.cos(altitude * math.pi / 180))) * 180 / math.pi
local sinazimut = (math.cos(declinaison * math.pi / 180) * math.sin(angle_horaire * math.pi / 180)) / math.cos( altitude * math.pi / 180)
if(sinazimut<0) then
  azimut=360-azimut
end
local Result = string.format("Altitude %.2f °, azimut %.2f °.", altitude, azimut)

setDevicePropertyValue(MVid, "Resultat",  Result )
fibaro:debug(Result)
  
setDevicePropertyValue(MVid, "Maj",  os.date("%d/%m/%y %H:%M:%S") )

-- ------------------------------------------------------------------------------
-- Mis à jour des variables global (PosSoleilAzimut,PosSoleilElevation)
-- si plus 1° de différence.
-- ------------------------------------------------------------------------------
if math.floor(tonumber(fibaro:getGlobalValue("PosSoleilElevation") ) ) ~= math.floor(altitude) then
  fibaro:setGlobal("PosSoleilElevation", altitude)
end

if math.floor( tonumber( fibaro:getGlobalValue( "PosSoleilAzimut" ) ) ) ~= math.floor(azimut) then
  fibaro:setGlobal("PosSoleilAzimut", azimut)
end

