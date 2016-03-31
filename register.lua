SpecializationUtil.registerSpecialization("SwitchChars", "SwitchChars", g_currentModDirectory.."SwitchChars.lua")
--accessing l18n with our text does work here, however not in the speci, so we save it
SwitchChars.localized_text = g_i18n:getText("agp8x_char_switch");

SwitchChars_Register = {};

function SwitchChars_Register:loadMap(name)
	if self.firstRun == nil then
		self.firstRun = false;
		print("-- registering SwitchChars specialization");
		for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
			if v ~= nil then
				local allowInsertion = true;
				for i = 1, table.maxn(v.specializations) do
					local vs = v.specializations[i];
					if vs ~= nil and vs == SpecializationUtil.getSpecialization("steerable") then
						local v_name_string = v.name 
						local point_location = string.find(v_name_string, ".", nil, true)
						if point_location ~= nil then
							local _name = string.sub(v_name_string, 1, point_location-1);
							if rawget(SpecializationUtil.specializations, string.format("%s.SwitchChars", _name)) ~= nil then
								allowInsertion = false;
							end;
						end;
						if allowInsertion then
							print("adding SwitchChars to "..tostring(v.name));
							table.insert(v.specializations, SpecializationUtil.getSpecialization("SwitchChars"));
						end;
					end;
				end;
			end;	
		end;
	end;
end;

function SwitchChars_Register:deleteMap()
end;
function SwitchChars_Register:keyEvent(unicode, sym, modifier, isDown)
end;
function SwitchChars_Register:mouseEvent(posX, posY, isDown, isUp, button)
end;
function SwitchChars_Register:update(dt)
end;
function SwitchChars_Register:draw()
end;

addModEventListener(SwitchChars_Register);