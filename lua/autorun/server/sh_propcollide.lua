PropMingeConfig = {} -- DO NOT EDIT

------- BEGIN CONFIG -------

PropMingeConfig.IgnoreGroups = { -- Groups listed here will be exempt from the anti propminge
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
	"gmod_button"
}

PropMingeConfig.EnableAutoNocollide = true			-- Enable the automatic nocollide when physgunning a prop?
PropMingeConfig.EnableAutoNocollideConstraints = true 		-- Enable the automatic nocollide for all constrained props while physgunning a prop?
PropMingeConfig.EnableTransparency = true			-- Slightly fade props when they're being nocollided?
PropMingeConfig.StopPropDamage = true				-- Stop props from hurting people?
PropMingeConfig.StopVehicleDamage = false			-- Stop vehicles from hurting people?
PropMingeConfig.NocollidedTime = 2				-- Time that the entity stays nocollided after dropping with physgun
PropMingeConfig.AlphaFade = 200					-- The alpha the prop is set to while being physgunned (max 255)

------- END OF CONFIG -------

function IsPlayerInside(ent)
	local check = false
	local center = ent:LocalToWorld(ent:OBBCenter())
	for _,v in next, ents.FindInSphere(center, ent:BoundingRadius()) do
		if v:IsPlayer() then
			local pos = v:GetPos()
			local trace = { start = pos, endpos = pos, filter = v }
			local tr = util.TraceEntity( trace, v )
			if tr.Entity == ent then
				check = v
			end
			if check then break end
		end
	end
	return check or false
end

function AutoNoCollide( ply, ent )
	if (PropMingeConfig.EnableAutoNocollide) then
		if (ent:CPPIGetOwner() == ply) or (table.HasValue(ent:CPPIGetOwner():CPPIGetFriends(), ply)) or (ent:CPPICanPhysgun(ply)) then
			if (PropMingeConfig.IgnoreSteamIDs) and (!table.HasValue(PropMingeConfig.IgnoreSteamIDs, ply:SteamID())) and (PropMingeConfig.IgnoreGroups) and (!table.HasValue(PropMingeConfig.IgnoreGroups, ply:GetUserGroup())) then
				if (table.HasValue(PropMingeConfig.NoCollideEntities, ent:GetClass())) then
					if (timer.Exists("Unghost")) then 
						timer.Remove("Unghost")
					end
					ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
					local col = ent:GetColor()
					if (PropMingeConfig.EnableTransparency) then
						ent:SetColor( Color( col.r, col.g, col.b, (PropMingeConfig.AlphaFade) ) )
						ent:SetRenderMode(RENDERMODE_TRANSALPHA)
					end
					if (PropMingeConfig.EnableAutoNocollideConstraints) then
						for _, ent in pairs( constraint.GetAllConstrainedEntities( ent ) ) do
							ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
							local col = ent:GetColor()
							if (PropMingeConfig.EnableTransparency) then
								ent:SetColor( Color( col.r, col.g, col.b, (PropMingeConfig.AlphaFade) ) )
								ent:SetRenderMode(RENDERMODE_TRANSALPHA)
							end
						end
					end
				end
			end
		end
	end
end
hook.Add( "PhysgunPickup", "Auto Nocollide", AutoNoCollide )

function AutoUnNoCollide( ply, ent )
	local phys = ent:GetPhysicsObject()
	if (PropMingeConfig.EnableAutoNocollide) then
		if (table.HasValue(PropMingeConfig.NoCollideEntities, ent:GetClass())) then
			if (ent:CPPIGetOwner() == ply) or (table.HasValue(ent:CPPIGetOwner():CPPIGetFriends(), ply)) then
				if (table.HasValue(PropMingeConfig.NoCollideEntities, ent:GetClass())) then
					if not (IsPlayerInside(ent)) then
						timer.Create("Unghost", 0.5, 0, function()
							phys:SetVelocity( Vector (0, 0, 0) )
							ent:SetCollisionGroup(COLLISION_GROUP_NONE)
							ent:SetRenderMode(RENDERMODE_NORMAL)
							local col = ent:GetColor()
							ent:SetColor( Color( col.r, col.g, col.b, 255) )
							for _, ent in pairs( constraint.GetAllConstrainedEntities( ent ) ) do
								ent:SetCollisionGroup(COLLISION_GROUP_NONE)
								ent:SetRenderMode(RENDERMODE_NORMAL)
								local col = ent:GetColor()
								ent:SetColor( Color( col.r, col.g, col.b, 255) )
							end
						end)
						phys:SetVelocity( Vector( 0, 0, 0 ) )
					end
				end
			end
		end
	end
end
hook.Add( "PhysgunDrop", "Auto UnNocollide", AutoUnNoCollide )

function OnCollide( data, phys )
	phys:SetCollisionGroup(COLLISION_GROUP_WORLD)
	phys:SetVelocity(Vector(0,0,0))
	local col = phys:GetColor()
	if (PropMingeConfig.EnableTransparency) then
		phys:SetColor( Color( col.r, col.g, col.b, (PropMingeConfig.AlphaFade) ) )
		phys:SetRenderMode(RENDERMODE_TRANSALPHA)
	end
end
hook.Add( "PhysicsCollide", "On Collide", OnCollide )

function AntiPropDmg( ent, dmginfo )
	if (PropMingeConfig.StopPropDamage) then
		if ent:IsPlayer() and dmginfo:GetDamageType() == DMG_CRUSH then
			dmginfo:SetDamage(0)
			dmginfo:ScaleDamage(0)
			dmginfo:SetDamageForce(Vector(0,0,0))
			return dmginfo,true
		end
	end
end
hook.Add( "EntityTakeDamage", "AntiPropDmg", AntiPropDmg )

function AntiVehicleDmg( victim, attacker )
	if (PropMingeConfig.StopVehicleDamage) then
    	if (attacker:IsVehicle() or attacker:GetClass() == "prop_vehicle_jeep") then
        	return false
    	end
    end
end
hook.Add("PlayerShouldTakeDamage", "AntiVehicleDmg", AntiVehicleDmg)
