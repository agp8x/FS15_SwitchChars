--
-- IngolfValidator
-- Class for validating necessary mods 
--
-- @author  agp8x <ls@agp8x.org>
-- @date  10.03.16
--

IngolfValidator = {};

function IngolfValidator.prerequisitesPresent(specializations)
	local modname="AFS15_ClassicsPackV2";
	local targetConfigFilename = Utils.getFilename(modname.."/moddesc.xml", g_modsDirectory);
	if fileExists(targetConfigFilename) or fileExists(Utils.getFilename("-"..modname.."/moddesc.xml", g_modsDirectory)) then
		return true;
	end;
	print("ERROR: missing "..modname);
	return false;
end;
function IngolfValidator:load(xmlFile)
end;
function IngolfValidator:delete()
end;
function IngolfValidator:readStream(streamId, connection)
end;
function IngolfValidator:writeStream(streamId, connection)
end;
function IngolfValidator:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
end;
function IngolfValidator:getSaveAttributesAndNodes(nodeIdent)
end;
function IngolfValidator:mouseEvent(posX, posY, isDown, isUp, button)
end;
function IngolfValidator:keyEvent(unicode, sym, modifier, isDown)
end;
function IngolfValidator:update(dt)
end;
function IngolfValidator:updateTick(dt)
end;
function IngolfValidator:draw()
end;