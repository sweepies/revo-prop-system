PropMingeConfig = {} -- DO NOT EDIT

------- BEGIN CONFIG -------

PropMingeConfig.IgnoreGroups = { -- Groups listed here will be exempt from the effects
	"group1",
	"group2"
}

PropMingeConfig.IgnoreSteamIDs = { -- Same as IgnoreGroups, but for SteamIDs
	"STEAM_0:0:11",
	"STEAM_0:0:00"
}

PropMingeConfig.NoCollideEntities = { -- The entities you want the effect to be applied to
	"prop_physics",
	"gmod_cameraprop",
	"Keypad",
	"gmod_button",
}

PropMingeConfig.EnableAutoNocollide = true -- Enable the automatic nocollide when physgunning a prop?
PropMingeConfig.EnableAutoNocollideConstraints = true -- Enable the automatic nocollide for all constrained props while physgunning a prop?
PropMingeConfig.EnableTransparency = true -- Slightly fade props when they're being nocollided?
PropMingeConfig.AlphaFade = 200 -- The alpha the prop is set to while being physgunned (max 255)
PropMingeConfig.DisableThrowing = true -- Set velocity to 0 upon dropping a prop
PropMingeConfig.DisableDamage = true -- Disable damage caused by props

------- END OF CONFIG -------

function IsPlayerInside(ent) -- Check if there's a player or vehicle inside ent
	local check = false
	local center = ent:LocalToWorld(ent:OBBCenter())
	for _,v in next, ents.FindInSphere(center, ent:BoundingRadius() - 20) do
		if v:IsPlayer() or v:IsVehicle() then
			return true
		end
	end
end

function FadeProp(ply, ent) -- On physgun pickup, nocollide the prop and make it slightly transparent
	if (PropMingeConfig.EnableAutoNocollide) then
		if (ent:CPPICanPhysgun(ply)) then
			if (!table.HasValue(PropMingeConfig.IgnoreSteamIDs, ply:SteamID())) and (!table.HasValue(PropMingeConfig.IgnoreGroups, ply:GetUserGroup())) then
				if (table.HasValue(PropMingeConfig.NoCollideEntities, ent:GetClass())) then
					ent:SetCollisionGroup(COLLISION_GROUP_WORLD) -- Nocollide
					local col = ent:GetColor()
					if (PropMingeConfig.EnableTransparency) then
						ent:SetColor(Color(col.r, col.g, col.b, (PropMingeConfig.AlphaFade)))
						ent:SetRenderMode(RENDERMODE_TRANSALPHA) -- Set transparency
					end
					if (PropMingeConfig.EnableAutoNocollideConstraints) then -- Do the same for all connected props
						for _, ent in pairs(constraint.GetAllConstrainedEntities(ent)) do
							ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
							local col = ent:GetColor()
							if (PropMingeConfig.EnableTransparency) then
								ent:SetColor(Color(col.r, col.g, col.b, (PropMingeConfig.AlphaFade)))
								ent:SetRenderMode(RENDERMODE_TRANSALPHA)
							end
						end
					end
				end
			end
		end
	end
end
hook.Add("PhysgunPickup", "FadeProp", FadeProp)

function UnfadeProp(weapon, phys, ent, ply)
	if (PropMingeConfig.EnableAutoNocollide) then
		if (table.HasValue(PropMingeConfig.NoCollideEntities, ent:GetClass())) then
			if (ent:CPPICanPhysgun(ply)) then -- Make sure they're actually allowed to do it
				if not (IsPlayerInside(ent)) then -- Make sure it's not obstructed by a player
					if (IsValid(ent)) then
						ent:SetCollisionGroup(COLLISION_GROUP_NONE) -- Return prop to norma;
						ent:SetRenderMode(RENDERMODE_NORMAL)
						local col = ent:GetColor()
						ent:SetColor( Color(col.r, col.g, col.b, 255))
						if (PropMingeConfig.EnableAutoNocollideConstraints) then -- Do the same for all connected props, if enabled
							for _, ent in pairs( constraint.GetAllConstrainedEntities(ent)) do
								ent:SetCollisionGroup(COLLISION_GROUP_NONE)
								ent:SetRenderMode(RENDERMODE_NORMAL)
								local col = ent:GetColor()
								ent:SetColor(Color(col.r, col.g, col.b, 255))
							end
						end
					end
				end
			end
		end
	end
end
hook.Add("OnPhysgunFreeze", "UnfadeProp", UnfadeProp)

function DisablePropDamage(ent, dmg)
	if ent:IsPlayer() and dmg:GetDamageType() == DMG_CRUSH and PropMingeConfig.DisableDamage then
		return true
	end
end
hook.Add("EntityTakeDamage", "DisablePropDamage", DisablePropDamage)

function OnDrop(ply, ent) -- On physgun drop, set velocity to 0
	if (PropMingeConfig.DisableThrowing) then
		if not (ent:IsPlayer()) then
			ent:SetVelocity(Vector(0, 0, 0))
		end
	end
end
hook.Add("PhysgunDrop", "Reset Velocity", OnDrop)
