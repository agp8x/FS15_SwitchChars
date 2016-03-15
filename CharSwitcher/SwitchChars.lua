--
-- SwitchChars
-- Class for switching characters
--
-- @author  agp8x <ls@agp8x.org>
-- @date  10.03.16
-- 0.1: 11.03.16
--		* switching works
-- 0.2: 11.03.16
--		* global installation to all steerables
-- 0.3: 15.03.16
--		* save and load
--		* multiplayer
--
local chars_dir = g_currentModDirectory;

SwitchChars = {};

function SwitchChars.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Steerable, specializations);
end;
function SwitchChars:load(xmlFile)
	--self.isSelectable=true; --TODO rly?
	self.switchableCharacters = {}
	local xmlFile2=loadXMLFile("charChains", Utils.getFilename("characters.xml", chars_dir))
	local i=0;
	while true do
		local key = string.format("vehicle.characters.char(%d)", i);
		if not hasXMLProperty(xmlFile2, key) then
            break;
        end;
		local filename=getXMLString(xmlFile2, key.."#filename");
		if filename ~=nil then
		    local path = Utils.getFilename(filename, chars_dir);
		    if fileExists(path) then
    			table.insert(self.switchableCharacters, {filename=path});
			else
			    print("ERROR: character not found: ", path);
		    end;
		end;
		i=i+1;
	end;
	self.charConf={
		skin=getXMLString(xmlFile, "vehicle.characterNode#characterSkin"), 
		mesh=getXMLString(xmlFile, "vehicle.characterNode#characterMesh"), 
		gloves=getXMLString(xmlFile, "vehicle.characterNode#characterGloves"), 
		spineNode=getXMLString(xmlFile, "vehicle.characterNode#spineNode"), 
		offsets=Utils.getNoNil(getXMLString(xmlFile, "vehicle.characterNode#skinOffset"), "0 0.14 0"), 
		spineRot = Utils.getRadiansFromString(getXMLString(xmlFile, "vehicle.characterNode#spineRotation"), 3)
	}
	
	self.charCurrent=1;
	self.charCount=table.getn(self.switchableCharacters);
	self.updateChar=SwitchChars.updateChar;
	self.chainTargets={}
	local i=0;
	while true do
		local key = string.format("vehicle.characterNode.ikChains.ikChain(%d)#target", i);
		if not hasXMLProperty(xmlFile, key) then
			break;
		end;
		table.insert(self.chainTargets, {target=getXMLString(xmlFile, key)});
		i=i+1;
	end;
end;
function SwitchChars:delete()
end;
function SwitchChars:readStream(streamId, connection)
end;
function SwitchChars:writeStream(streamId, connection)
end;
function SwitchChars:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
    local newChar = Utils.getNoNil(getXMLInt(xmlFile, key.."#character"), 1);
	self:updateChar(newChar);
    return BaseMission.VEHICLE_LOAD_OK;
end;
function SwitchChars:getSaveAttributesAndNodes(nodeIdent)
    local nodes = "";
	attributes = 'character="'..self.charCurrent..'"';
    return attributes,nodes;
end;
function SwitchChars:mouseEvent(posX, posY, isDown, isUp, button)
end;
function SwitchChars:keyEvent(unicode, sym, modifier, isDown)
end;
function SwitchChars:update(dt)
    if self:getIsActiveForInput() then
        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA3) then
			local newChar=self.charCurrent+1;
			if self.switchableCharacters[newChar] == nil then
				newChar=1;
			end;
			if newChar ~= self.charCurrent then
				SwitchCharEvent.sendEvent(self, newChar);
				self:updateChar(newChar);
				self.charCurrent=newChar;
			end;
		end;
	end;
end;
function SwitchChars:updateTick(dt)
end;
function SwitchChars:draw()
end;
function SwitchChars:updateChar(newChar)
	--print("local update to: ", newChar)
	if self.switchableCharacters[newChar] ~= nil and self.characterNode ~=nil then
		unlink(self.characterSkin);
		unlink(self.characterMesh);
		if self.characterGloves ~= nil then
			unlink(self.characterGloves);
		end;
		local i3dNode=Utils.loadSharedI3DFile(self.switchableCharacters[newChar].filename);
		if i3dNode ~= 0 then
			self.characterSkin = Utils.indexToObject(i3dNode, self.charConf.skin);
			self.characterMesh = Utils.indexToObject(i3dNode, self.charConf.mesh);
			self.characterGloves = Utils.indexToObject(i3dNode, self.charConf.gloves);
			self.characterSpineNode = Utils.indexToObject(i3dNode, self.charConf.spineNode);
			local x,y,z  = Utils.getVectorFromString(self.charConf.offsets);
			setClipDistance(self.characterMesh, 150);
			setClipDistance(self.characterGloves, 50);
			link(self.characterNode, self.characterSkin);
			setTranslation(self.characterSkin, x,y,z);
			link(self.characterNode, self.characterMesh);
			if self.characterGloves ~= nil then
				link(self.characterNode, self.characterGloves);
				setVisibility(self.characterGloves, false);
			end;
			skinBasenode = self.characterNode;
			delete(i3dNode);
			if self.charConf.spineRot ~= nil and self.characterSpineNode ~= nil then
				setRotation(self.characterSpineNode, unpack(self.charConf.spineRot));
			end;
		end;
		self.characterFilename = self.switchableCharacters[newChar].filename;
		self:setCharacterVisibility(false);
	end;
	--ikChains
	self.ikChains={};
	self.ikChainsById={};
	local xmlFile=loadXMLFile("charChains", Utils.getFilename("characters.xml", chars_dir))
	--overwrite ikChain#targets
	for k,v in pairs(self.chainTargets) do
		local key=string.format("vehicle.characterNode.ikChains.ikChain(%d)#target", k-1)
		setXMLString(xmlFile, key, self.chainTargets[k].target);
	end;
	--
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
	local self=SwitchCharEvent:emptyNew()
	self.object=object;
	self.newChar=newChar;
	return self;
end;
function SwitchCharEvent:readStream(streamId, connection)
	self.object=networkGetObject(streamReadInt32(streamId));
	self.newChar=streamReadInt8(streamId);
	self:run(connection);
end;
function SwitchCharEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, networkGetObjectId(self.object));
	streamWriteInt8(streamId, self.newChar);
end;
function SwitchCharEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(SwitchCharEvent:new(self.vehicle, self.newChar), nil, connection, self.object);
	end;
	--print("NETWORK update: ", self.newChar, "obj: ", type(self.object))
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