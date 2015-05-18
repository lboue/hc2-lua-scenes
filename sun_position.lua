-- Fonction pour réduire à 2 décimales
function round(num, dec)
  local mult = 10^(dec or 0)
  return math.floor(num * mult + 0.5) / mult
end

function setDevicePropertyValue(id, label, value)
  fibaro:call(id, "setProperty", "ui."..label..".value", value)
end

local MVid = fibaro:getSelfId() 
local AzimutFenetre = 200 --Mettre ici l'azimut/orientation de la fenetre en degre (°), pour moi plein sud = 180°
local LargeurFenetre = 180
local EpaisseurFenetre = 30
local HauteurFenetre = 210
local PosSoleilAzimut = math.floor( tonumber( fibaro:getGlobalValue( "PosSoleilAzimut" ) ) )
local PosSoleilElevation = math.floor( tonumber( fibaro:getGlobalValue( "PosSoleilElevation" ) ) )
 
fibaro:debug("-----------------------------------------");
fibaro:debug("AzimutFenetre : " .. AzimutFenetre .. "°");
fibaro:debug("LargeurFenetre : " .. LargeurFenetre .. " cm, "
  			.. "EpaisseurFenetre : " .. EpaisseurFenetre .. " cm, " 
  		 	.. "HauteurFenetre : " .. HauteurFenetre .. "cm");
fibaro:debug("-----------------------------------------");

-- Seuils gauche et droit d'incidence Azimutale dans la fenetre = Az + ou - cet angle
masqueAz = round(math.deg(math.atan(LargeurFenetre/EpaisseurFenetre)),2)
--fibaro:debug("Seuils gauche et droit d'incidence Azimutale dans la fenetre : " .. masqueAz .. "°")

masqueAzG = round(AzimutFenetre-math.deg(math.atan(LargeurFenetre/EpaisseurFenetre)),2)
masqueAzD = round(AzimutFenetre+math.deg(math.atan(LargeurFenetre/EpaisseurFenetre)),2)

fibaro:debug("Seuils gauche d'incidence Azimutale dans la fenetre : " .. masqueAzG .. "°")
fibaro:debug("Seuils droit d'incidence Azimutale dans la fenetre : " .. masqueAzD .. "°")

-- Seuil haut d'incidence zenitale dans la fenetre = Horizon + cet angle
masqueElev = round(math.deg(math.atan(HauteurFenetre/EpaisseurFenetre)),2)
fibaro:debug("Seuil haut d'incidence zenitale dans la fenetre : " .. masqueElev .. "°")

 
--fibaro:debug("-----------------------------------------");
--fibaro:debug("PosSoleilAzimut : " .. PosSoleilAzimut .. "°");
--fibaro:debug("PosSoleilElevation : " .. PosSoleilElevation .. "°");

fibaro:debug("-----------------------------------------");

if (PosSoleilAzimut > masqueAzG 
      and PosSoleilAzimut < masqueAzD) then

  setDevicePropertyValue(MVid, "SalonLbl", "Oui")
 fibaro:debug("[Azimut] Soleil dans la fenêtre (" .. PosSoleilAzimut .. "°)");
elseif (PosSoleilAzimut < masqueAzG) then
  setDevicePropertyValue(MVid, "SalonLbl", "Non")
  fibaro:debug("[Azimut] Soleil à droite de la fenêtre (" .. PosSoleilAzimut .. "°)");
elseif (PosSoleilAzimut > masqueAzD) then
  setDevicePropertyValue(MVid, "SalonLbl", "Non")
  fibaro:debug("[Azimut] Soleil à droite de la fenêtre (" .. PosSoleilAzimut .. "°)");
end


if (PosSoleilElevation < 0) then
  fibaro:debug("[Elevation] Soleil couché (" .. PosSoleilElevation .. "°)");
elseif (PosSoleilElevation < masqueElev) then
  fibaro:debug("[Elevation] Soleil dans la fenêtre (" .. PosSoleilElevation .. "°)");
elseif (PosSoleilElevation > masqueElev) then
  fibaro:debug("[Elevation] Soleil au dessus de la fenêtre (" .. PosSoleilElevation .. "°)");
end

