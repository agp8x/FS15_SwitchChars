--
-- SwitchChars
-- Class for switching characters
--
-- @author  agp8x <ls@agp8x.org>
-- @date  10.03.16
-- 0.1: 11.03.16
--		* swithcing works
--
local defaultChainFile = Utils.getFilename("characters.xml", g_currentModDirectory);

SwitchChars = {};

function SwitchChars.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Steerable, specializations);
end;
function SwitchChars:load(xmlFile)
	self.isSelectable=true;
	
	self.switchableCharacters = {}
	local i=0;
	while true do
		local key = string.format("vehicle.characters.char(%d)", i);
		if not hasXMLProperty(xmlFile, key) then
            break;
        end;
		local filename=getXMLString(xmlFile, key.."#filename");
		if filename ~=nil then
		    local path = Utils.getFilename(filename, self.baseDirectory);
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
	
	self.charCurrent=0;
	self.charCount=table.getn(self.switchableCharacters);
	self.updateChar=SwitchChars.updateChar;
end;
function SwitchChars:delete()
end;
function SwitchChars:readStream(streamId, connection)
end;
function SwitchChars:writeStream(streamId, connection)
end;
function SwitchChars:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
end;
function SwitchChars:getSaveAttributesAndNodes(nodeIdent)
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
				newChar=0;
			end;
			self:updateChar(newChar);
			self.charCurrent=newChar;
		end;
	end;
	--load: Steerable:loadSettingsFromXML(xmlFile) [l. 72]
end;
function SwitchChars:updateTick(dt)
end;
function SwitchChars:draw()
end;
function SwitchChars:updateChar(newChar)
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
		self:setCharacterVisibility(true);
	end;
	--ikChains
	self.ikChains={};
	self.ikChainsById={};
	local xmlFile=loadXMLFile("charChains", defaultChainFile)
	local i = 0;
	while true do
		local key = string.format("vehicle.characterNode.ikChains.ikChain(%d)", i);
		if not hasXMLProperty(xmlFile, key) then
			break;
		end;
		local chain = IKUtil.loadIKChain(xmlFile, key, self.components, skinBasenode, self.ikChains, self.ikChainsById, self.getParentComponent, self);
		if chain ~= nil then
			--print(tostring(chain))
			self.characterIsSkinned = true;
		end;
		i = i + 1;
	end;
	--post
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
function SwitchChars:loadSettingsFromXML_own(xmlFile)
--TODO: split: store indices & load i3d-file
--TODO: probably unlink some stuff
--TODO: maybe call from load()?
    if self.characterNode ~= nil then
        --[[self.characterCameraMinDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.characterNode#cameraMinDistance"), 1.5);
        self.characterDistanceRefNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.characterNode#distanceRefNode"));
        if self.characterDistanceRefNode == nil then
            self.characterDistanceRefNode = self.characterNode;
        end;
        setVisibility(self.characterNode, false);
]]
        local skinBasenode = self.components;
        local filename = getXMLString(xmlFile, "vehicle.characterNode#filename");
        if filename ~= nil then
            filename = Utils.getFilename(filename, self.baseDirectory);
            local i3dNode = Utils.loadSharedI3DFile(filename);
            if i3dNode ~= 0 then
                self.characterSkin = Utils.indexToObject(i3dNode, getXMLString(xmlFile, "vehicle.characterNode#characterSkin"));
                self.characterMesh = Utils.indexToObject(i3dNode, getXMLString(xmlFile, "vehicle.characterNode#characterMesh"));
                self.characterGloves = Utils.indexToObject(i3dNode, getXMLString(xmlFile, "vehicle.characterNode#characterGloves"));
                self.characterSpineNode = Utils.indexToObject(i3dNode, getXMLString(xmlFile, "vehicle.characterNode#spineNode"));
                local x,y,z  = Utils.getVectorFromString(Utils.getNoNil(getXMLString(xmlFile, "vehicle.characterNode#skinOffset"), "0 0.14 0"));
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
            end;
            self.characterFilename = filename;
        end;
    end;
end;