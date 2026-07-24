AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_glide_trailer"

ENT.PrintName = "Glide Articulated Rear Section"
ENT.Author = "Blackterio"
ENT.AdminOnly = false
ENT.Spawnable = false

DEFINE_BASECLASS( "base_glide_trailer" )

-- Marks this entity as the rear section of an articulated vehicle.
-- The front section spawns it automatically, it is never spawned alone.
ENT.IsArticulatedRearSection = true

--[[
    Children classes should set these:
]]

-- Articulation pivot point, local to this section's chassis.
-- Must line up with the front section's `ArticulationOffset`.
ENT.ArticulationOffset = Vector( 100, 0, 40 )

-- Name of the accordion bone in THIS section's model, if it has one.
-- Works like the front section's `ArticulationBone`, bending towards
-- the front section. Leave empty to disable.
ENT.ArticulationBone = ""

-- Same as the front section's `ArticulationBoneScale`.
ENT.ArticulationBoneScale = Angle( 0.5, 0.5, 0.5 )

--- Override this base class function.
function ENT:SetupDataTables()
    BaseClass.SetupDataTables( self )

    -- Lets the client find the front section, for the shared HUD
    -- and the accordion bone.
    self:NetworkVar( "Entity", "FrontSection" )
end

--- Override this base class function.
---
--- This section has no driver, so every seat (including the
--- first one) uses the passenger animation.
function ENT:GetPlayerSitSequence( _seatIndex )
    return "sit"
end

if CLIENT then
    -- Exhaust smoke positions, relative to this section's chassis.
    -- Same format as on cars. Emits while the engine is running.
    ENT.ExhaustOffsets = {}
    ENT.ExhaustAlpha = 50

    -- Engine damage smoke positions, relative to this section's chassis.
    -- Same format as on cars. Emits when the engine health is low.
    ENT.EngineSmokeStrips = {}
    ENT.EngineSmokeMaxZVel = 100

    -- `EngineFireOffsets` comes from `base_glide` and works here too:
    -- it emits fire when the engine is on fire.

    --- Override this base class function.
    ---
    --- Look up the accordion bone once the model is ready.
    function ENT:OnActivateMisc()
        BaseClass.OnActivateMisc( self )

        local name = self.ArticulationBone
        local boneId = ( name and name ~= "" ) and self:LookupBone( name )

        self.articulationBoneId = ( boneId and boneId >= 0 ) and boneId or nil

        -- Read the bone's rest rotation again, the model may have changed
        self.articulationBoneLocal = nil
        self.articulationBoneLocalInv = nil
    end

    --- Override this base class function.
    ---
    --- Every frame, bend the accordion bone towards the front section.
    function ENT:OnUpdateAnimations()
        BaseClass.OnUpdateAnimations( self )

        local boneId = self.articulationBoneId
        if not boneId then return end

        Glide.UpdateArticulationBone( self, boneId, self:GetFrontSection() )
    end

    --- Override this base class function.
    ---
    --- Show the whole vehicle's HUD (speed, health, full passenger
    --- list) while sitting back here, instead of this section's own.
    function ENT:DrawVehicleHUD( screenW, screenH )
        local front = self:GetFrontSection()

        if IsValid( front ) then
            return front:DrawVehicleHUD( screenW, screenH )
        end

        return BaseClass.DrawVehicleHUD( self, screenW, screenH )
    end

    local DEFAULT_EXHAUST_ANG = Angle()
    local Effect = util.Effect
    local EffectData = EffectData
    local Clamp = math.Clamp

    --- Implement this base class function.
    ---
    --- Emit exhaust, engine smoke and engine fire at this section's own
    --- offsets, following the engine state of the front section (which
    --- is where the engine lives). Same logic cars use for their particles.
    function ENT:OnUpdateParticles()
        local front = self:GetFrontSection()
        if not IsValid( front ) then return end

        local velocity = self:GetVelocity()
        local rpmFraction = front.rpmFraction or 0

        if rpmFraction < 0.5 and front:IsEngineOn() then
            rpmFraction = rpmFraction * 2

            local emit

            for _, v in ipairs( self.ExhaustOffsets ) do
                emit = true

                -- Check for optional bodygroup requirement
                if v.ifBodygroupId then
                    emit = self:GetBodygroup( v.ifBodygroupId ) == ( v.ifSubModelId or 0 )
                end

                if emit then
                    local eff = EffectData()
                    eff:SetOrigin( self:LocalToWorld( v.pos ) )
                    eff:SetAngles( self:LocalToWorldAngles( v.ang or v.angle or DEFAULT_EXHAUST_ANG ) )
                    eff:SetStart( velocity )
                    eff:SetScale( v.scale or 1 )
                    eff:SetColor( self.ExhaustAlpha )
                    eff:SetMagnitude( rpmFraction * 1000 )
                    Effect( "glide_exhaust", eff, true, true )
                end
            end
        end

        -- Engine fire. Handled here because the base class only checks
        -- this entity's own fire flag, which never turns on back here.
        if front:GetIsEngineOnFire() then
            local eff = EffectData()

            for _, v in ipairs( self.EngineFireOffsets ) do
                eff:SetStart( velocity )
                eff:SetOrigin( self:LocalToWorld( v.offset ) )
                eff:SetAngles( self:LocalToWorldAngles( v.angle or DEFAULT_EXHAUST_ANG ) )
                eff:SetScale( v.scale or 1 )
                Effect( "glide_fire", eff, true, true )
            end
        end

        -- Engine damage smoke, following the front section's engine health
        local health = front:GetEngineHealth()
        if health > 0.6 then return end

        local color = Clamp( health * 255, 0, 255 )
        local scale = 2 - health * 2

        for _, v in ipairs( self.EngineSmokeStrips ) do
            local eff = EffectData()
            eff:SetOrigin( self:LocalToWorld( v.offset ) )
            eff:SetAngles( self:LocalToWorldAngles( v.angle or DEFAULT_EXHAUST_ANG ) )
            eff:SetStart( velocity )
            eff:SetColor( color )
            eff:SetMagnitude( v.width * 1000 )
            eff:SetScale( scale )
            eff:SetRadius( self.EngineSmokeMaxZVel )
            Effect( "glide_damaged_engine", eff, true, true )
        end
    end
end

if not SERVER then return end

-- This section is part of the vehicle, not a trailer someone can drop,
-- so collisions against it have to hurt. The damage is handed over to
-- the front section, which applies its own bullet and blast multipliers.
ENT.CollisionDamageMultiplier = 0.5

-- The front section is the only one that catches fire and takes fire
-- damage, so the vehicle can't burn twice as fast. The flames are still
-- drawn back here, see `OnUpdateParticles` above.
ENT.CanCatchOnFire = false

--- Override this base class function.
---
--- Follow the front section: it owns the vehicle's paint and damage.
--- (Lights and brakes are already copied by the trailer base class.)
function ENT:OnPostThink( dt, selfTbl )
    BaseClass.OnPostThink( self, dt, selfTbl )

    local front = selfTbl.frontSection
    if not IsValid( front ) then return end

    local color = front:GetColor()

    if color ~= self:GetColor() then
        self:SetColor( color )
    end

    local skin = front:GetSkin()

    if skin ~= self:GetSkin() then
        self:SetSkin( skin )
    end

    -- Match the front section's damage, as a fraction of each section's
    -- own max health, so both sections are always equally beaten up
    -- even if they have a different `MaxChassisHealth`.
    local fraction = front:GetChassisHealth() / front.MaxChassisHealth
    local health = fraction * self.MaxChassisHealth

    if math.abs( self:GetChassisHealth() - health ) > 0.01 then
        self:SetChassisHealth( health )
        self:UpdateHealthOutputs()
    end

    local engineHealth = front:GetEngineHealth()

    if self:GetEngineHealth() ~= engineHealth then
        self:SetEngineHealth( engineHealth )
    end
end

--- Override this base class function.
---
--- Damage done to this section belongs to the whole vehicle, so hand it
--- over to the front section, which owns the health and runs its own
--- damage multipliers, fire and explosion logic. `OnPostThink` then
--- copies the resulting health back here.
function ENT:OnTakeDamage( dmginfo )
    local front = self.frontSection

    if not IsValid( front ) or front.hasExploded then
        return BaseClass.OnTakeDamage( self, dmginfo )
    end

    front:TakeDamageInfo( dmginfo )
end

--- Override this base class function.
---
--- Repairing either section repairs the whole vehicle.
function ENT:Repair()
    BaseClass.Repair( self )

    local front = self.frontSection

    -- Skip while this entity is still initializing: the base class
    -- repairs itself as part of that, before we're linked to anything.
    if not self.articulationLinked then return end
    if not IsValid( front ) then return end

    if front:GetChassisHealth() < front.MaxChassisHealth or front:GetEngineHealth() < 1 then
        front:Repair()
    end
end

--- Override this base class function.
function ENT:Explode( attacker, inflictor )
    if not self.hasExploded then
        Glide.PropagateArticulatedExplosion( self, attacker, inflictor )
    end

    BaseClass.Explode( self, attacker, inflictor )
end

--- Set which vehicle acts as the front section.
---
--- Setting `attachedVehicle` is what makes the trailer base class
--- copy its lights, brakes and reverse state every tick.
function ENT:SetArticulatedFront( vehicle )
    self.frontSection = vehicle
    self:SetFrontSection( vehicle )
    self.attachedVehicle = vehicle
    self.articulationLinked = true
    self:SetIsAttached( true )
    self:UpdateWiremodOutputs()
end

--- Override this base class function.
---
--- Seats here are numbered after the front section's seats, so the whole
--- vehicle acts as one seat list: the 0-9 keys move between sections,
--- the HUD shows the real seat number, and the camera follows along.
function ENT:CreateSeat( offset, angle, exitPos, isHidden )
    local front = self.frontSection
    local frontSeatCount = IsValid( front ) and #front.seats or 0

    -- Glide's seat limit applies to the whole vehicle: seats past it
    -- could not be reached with the 0-9 keys.
    if frontSeatCount + #self.seats + 1 > Glide.MAX_SEATS then
        Glide.Print( "%s: seat limit reached (%d seats on the whole vehicle), ignoring extra seat!", self:GetClass(), Glide.MAX_SEATS )
        return
    end

    local seat = BaseClass.CreateSeat( self, offset, angle, exitPos, isHidden )
    if not IsValid( seat ) then return seat end

    -- Renumber the seat, continuing after the front section's seats
    local localIndex = seat.GlideSeatIndex
    local unifiedIndex = frontSeatCount + localIndex

    seat.GlideSeatIndex = unifiedIndex

    -- Player inputs are looked up by seat index, so this seat's
    -- input tables have to answer to the new number as well.
    self.inputBools[unifiedIndex] = self.inputBools[localIndex]
    self.inputFloats[unifiedIndex] = self.inputFloats[localIndex]

    self.seatIndexOffset = frontSeatCount

    return seat
end

--- Override this base class function.
---
--- Glide asks for the exit position using the renumbered seat index,
--- so turn it back into an index of our own seat list.
function ENT:GetSeatExitPos( index )
    return BaseClass.GetSeatExitPos( self, index - ( self.seatIndexOffset or 0 ) )
end
