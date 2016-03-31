--
-- SwitchChars
-- Class for switching characters, based on Ingolf's works
--
-- @author	agp8x <ls@agp8x.org>
-- @date	10.03.16 (start)
-- 1.0:	31.03.16

local chars_dir = g_currentModDirectory;

SwitchChars = {};

function SwitchChars.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Steerable, specializations);
end;
function SwitchChars:load(xmlFile)
	self.updateChar = SwitchChars.updateChar;
	if (not hasXMLProperty(xmlFile, "vehicle.characterNode#filename")) or getXMLString(xmlFile, "vehicle.characterNode#filename") == nil then
		local filename = Utils.getFilename(getXMLString(xmlFile, "vehicle.filename"), g_currentModDirectory);
		print("NOTICE: unanimated character found, no switchable characters at ", filename);
		return;
	end;
	
	-- load characters once
	if SwitchChars.switchableCharacters == nil then
		local xmlFile2 = loadXMLFile("charChains", Utils.getFilename("characters.xml", chars_dir))
		local switchableCharacters = {}
		local i = 0;
		while true do
			local key = string.format("vehicle.characters.char(%d)", i);
			if not hasXMLProperty(xmlFile2, key) then
				break;
			end;
			local filename = getXMLString(xmlFile2, key.."#filename");
			local push = Utils.getNoNil(getXMLBool(xmlFile2, key.."#push"), true);
			if filename ~= nil then
				local path = Utils.getFilename(filename, chars_dir);
				if fileExists(path) then
					table.insert(switchableCharacters, {filename=path, push=push});
				else
					print("ERROR: character not found: ", path);
				end;
			end;
			i = i + 1;
		end;
		SwitchChars.switchableCharacters = switchableCharacters
		-- load addons
		if BaseMission.switchCharsAddon ~= nil then
			print("Load additional characters: ",table.getn(BaseMission.switchCharsAddon));
			for _,v in pairs(BaseMission.switchCharsAddon) do
				table.insert(SwitchChars.switchableCharacters, v);
			end;
		end;
	
		local pushDowns = {}
		-- load node graph modifications
		local i = 0;
		while true do
			local key = string.format("vehicle.pushDown.push(%d)", i);
			if not hasXMLProperty(xmlFile2, key) then
				break;
			end;
			local index = getXMLString(xmlFile2, key.."#index");
			local name = getXMLString(xmlFile2, key.."#name");
			if index ~= nil and name ~= nil then
				table.insert(pushDowns, {index=index, name=name});
			end;
			i = i + 1;
		end;
		SwitchChars.pushDowns = pushDowns;
	end;
	
	-- individual settings
	self.charCurrent=1;
	-- remember character settings per vehicle
	self.charConf = {
		skin = getXMLString(xmlFile, "vehicle.characterNode#characterSkin"), 
		mesh = getXMLString(xmlFile, "vehicle.characterNode#characterMesh"), 
		gloves = getXMLString(xmlFile, "vehicle.characterNode#characterGloves"), 
		spineNode = getXMLString(xmlFile, "vehicle.characterNode#spineNode"), 
		offsets = Utils.getNoNil(getXMLString(xmlFile, "vehicle.characterNode#skinOffset"), "0 0.14 0"), 
		spineRot = Utils.getRadiansFromString(getXMLString(xmlFile, "vehicle.characterNode#spineRotation"), 3)
	}
	self.chainTargets={}
	local i = 0;
	while true do
		local key = string.format("vehicle.characterNode.ikChains.ikChain(%d)#target", i);
		if not hasXMLProperty(xmlFile, key) then
			break;
		end;
		table.insert(self.chainTargets, {target=getXMLString(xmlFile, key)});
		i = i + 1;
	end;
end;
function SwitchChars:delete()
end;
function SwitchChars:readStream(streamId, connection)
	local newChar = streamReadInt8(streamId);
	self:updateChar(newChar);
end;
function SwitchChars:writeStream(streamId, connection)
	streamWriteInt8(streamId, self.charCurrent);
end;
function SwitchChars:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	local newChar = Utils.getNoNil(getXMLInt(xmlFile, key.."#character"), 1);
	self:updateChar(newChar);
	return BaseMission.VEHICLE_LOAD_OK;
end;
function SwitchChars:getSaveAttributesAndNodes(nodeIdent)
	local nodes = "";
	local attributes = "";
	if self.charConf ~= nil then
		attributes = 'character="'..self.charCurrent..'"';
	end;
	return attributes,nodes;
end;
function SwitchChars:mouseEvent(posX, posY, isDown, isUp, button)
end;
function SwitchChars:keyEvent(unicode, sym, modifier, isDown)
end;
function SwitchChars:update(dt)
	if self:getIsActiveForInput() then
		if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA4) and self.charConf ~= nil then
			local newChar = self.charCurrent + 1;
			if SwitchChars.switchableCharacters[newChar] == nil then
				newChar = 1;
			end;
			if newChar ~= self.charCurrent then
				SwitchCharEvent.sendEvent(self, newChar);
				self:updateChar(newChar);
			end;
		end;
	end;
end;
function SwitchChars:updateTick(dt)
end;
function SwitchChars:draw()
	if self:getIsActiveForInput() and self.charConf ~= nil then
		g_currentMission:addHelpButtonText(SwitchChars.localized_text, InputBinding.IMPLEMENT_EXTRA4);
	end;
end;
function SwitchChars:updateChar(newChar)
	if self.charConf ~= nil and SwitchChars.switchableCharacters[newChar] ~= nil and self.characterNode ~= nil then
		local visibility = getVisibility(self.characterNode);
		unlink(self.characterSkin);
		unlink(self.characterMesh);
		if self.characterGloves ~= nil then
			unlink(self.characterGloves);
		end;
		local i3dNode = Utils.loadSharedI3DFile(SwitchChars.switchableCharacters[newChar].filename);
		--Steerable.loadSettingsFromXML [90]
		if i3dNode ~= 0 then
			if SwitchChars.switchableCharacters[newChar].push then
				for _,index in pairs(SwitchChars.pushDowns) do
					-- extend node graph by rotNodes (basically automating Ingolf's idea)
					local newNode = createTransformGroup(index.name);
					local oldNode = Utils.indexToObject(i3dNode, index.index);
					setTranslation(newNode, getTranslation(oldNode));
					setRotation(newNode, getRotation(oldNode));
					setTranslation(oldNode, 0,0,0);
					setRotation(oldNode, 0,0,0);
					local parent = getParent(oldNode);
					local insertIndex = getChildIndex(oldNode);
					unlink(oldNode);
					link(newNode, oldNode);
					link(parent, newNode, insertIndex);
				end;
				-- create dummy
				self.characterGloves = createTransformGroup("gloves");
			else
				self.characterGloves = Utils.indexToObject(i3dNode, self.charConf.gloves);
			end;
			self.characterSkin = Utils.indexToObject(i3dNode, self.charConf.skin);
			self.characterMesh = Utils.indexToObject(i3dNode, self.charConf.mesh);
			self.characterSpineNode = Utils.indexToObject(i3dNode, self.charConf.spineNode);
			local x,y,z = Utils.getVectorFromString(self.charConf.offsets);
			setClipDistance(self.characterMesh, 150);
			link(self.characterNode, self.characterSkin);
			setTranslation(self.characterSkin, x,y,z);
			link(self.characterNode, self.characterMesh);
			if self.characterGloves ~= nil then
				setClipDistance(self.characterGloves, 50);
				link(self.characterNode, self.characterGloves);
				setVisibility(self.characterGloves, false);
			end;
			skinBasenode = self.characterNode;
			delete(i3dNode);
			if self.charConf.spineRot ~= nil and self.characterSpineNode ~= nil then
				setRotation(self.characterSpineNode, unpack(self.charConf.spineRot));
			end;
		end;
		self.characterFilename = SwitchChars.switchableCharacters[newChar].filename;
		-- reset ikChains
		self.ikChains = {};
		self.ikChainsById = {};
		local xmlFile = loadXMLFile("charChains", Utils.getFilename("characters.xml", chars_dir))
		-- overwrite ikChain#targets
		for k,v in pairs(self.chainTargets) do
			local key = string.format("vehicle.characterNode.ikChains.ikChain(%d)#target", k-1)
			setXMLString(xmlFile, key, self.chainTargets[k].target);
		end;
		-- continue
		local i = 0;
		while true do
			local key = string.format("vehicle.characterNode.ikChains.ikChain(%d)", i);
			if not hasXMLProperty(xmlFile, key) then
				break;
			end;
			local chain = IKUtil.loadIKChain(xmlFile, key, self.components, skinBasenode, self.ikChains, self.ikChainsById, self.getParentComponent, self);
			if chain ~= nil then
				self.characterIsSkinned = true;
			end;
			i = i + 1;
		end;
		--postLoad
		if self.characterMesh ~= nil then
			link(getRootNode(), self.characterMesh);
			if self.characterGloves ~= nil then
				link(getRootNode(), self.characterGloves);
			end;
		else
			if self.characterNode ~= nil and self.characterIsSkinned then
				link(getRootNode(), self.characterNode);
			end;
		end;
		self:setCharacterVisibility(visibility);
		self.charCurrent = newChar;
	end;
end;

--EVENT

SwitchCharEvent = {};
SwitchCharEvent_mt=Class(SwitchCharEvent, Event);

InitEventClass(SwitchCharEvent, "SwitchCharEvent");

function SwitchCharEvent:emptyNew()
	local self = Event:new(SwitchCharEvent_mt);
	return self;
end;

function SwitchCharEvent:new(object, newChar)
	local self = SwitchCharEvent:emptyNew()
	self.object = object;
	self.newChar = newChar;
	return self;
end;
function SwitchCharEvent:readStream(streamId, connection)
	self.object = networkGetObject(streamReadInt32(streamId));
	self.newChar = streamReadInt8(streamId);
	self:run(connection);
end;
function SwitchCharEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, networkGetObjectId(self.object));
	streamWriteInt8(streamId, self.newChar);
end;
function SwitchCharEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(SwitchCharEvent:new(self.object, self.newChar), nil, connection, self.object);
	end;
	self.object:updateChar(self.newChar);
	self.object:setCharacterVisibility(true);
end;
function SwitchCharEvent.sendEvent(vehicle, newChar, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SwitchCharEvent:new(vehicle, newChar), nil, nil, vehicle);
		else
			g_client:getServerConnection():sendEvent(SwitchCharEvent:new(vehicle, newChar));
		end;
	end;
end;
