--
-- SwitchCharsAddon
--
-- @author  agp8x <ls@agp8x.org>
-- @date  30.03.16

local switchCharAddon_dir = g_currentModDirectory;

if BaseMission.switchCharsAddon == nil then
	BaseMission.switchCharsAddon = {}
end;
print("-- loading SwitchChars addon");
local xmlFile = loadXMLFile("characters", Utils.getFilename("charactersAddon.xml", switchCharAddon_dir))
local i = 0;
while true do
	local key = string.format("characters.char(%d)", i);
	if not hasXMLProperty(xmlFile, key) then
		break;
	end;
	local filename = getXMLString(xmlFile, key.."#filename");
	if filename ~= nil then
		local path = Utils.getFilename(filename, switchCharAddon_dir);
		if fileExists(path) then
			table.insert(BaseMission.switchCharsAddon, {filename=path, push=false});
		else
			print("ERROR: character not found: ", path);
		end;
	end;
	i = i + 1;
end;