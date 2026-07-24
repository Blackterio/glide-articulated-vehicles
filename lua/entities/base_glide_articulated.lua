AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_glide_car"

ENT.PrintName = "Glide Articulated Base"
ENT.Author = "Blackterio"
ENT.AdminOnly = false
ENT.Spawnable = false

DEFINE_BASECLASS( "base_glide_car" )

-- Marks this vehicle as the front section of an articulated vehicle.
ENT.IsArticulatedVehicle = true

--[[
    Children classes should set these:
]]

-- Class name of the rear section entity. It must inherit
-- from `base_glide_articulated_rear`.
ENT.ArticulatedRearClass = ""

-- Articulation pivot point, local to this section's chassis.
-- Both sections pivot around this point, so it should be the
-- same spot on both models (the center of the accordion).
ENT.ArticulationOffset = Vector( -100, 0, 40 )

-- How far the vehicle can bend at the joint, in degrees.
-- yaw: turning left/right, pitch: crests and dips, roll: twisting.
ENT.ArticulationLimits = { yaw = 42, pitch = 8, roll = 4 }

-- Name of the accordion bone in THIS section's model, if it has one.
-- It bends towards the other section as the vehicle articulates, so the
-- accordion mesh follows the bend instead of clipping or tearing apart.
-- Leave empty to disable.
ENT.ArticulationBone = ""

-- How much of the bend is applied to the accordion bone, per chassis
-- axis (pitch/yaw/roll, same meaning as `ArticulationLimits`).
-- 0.5 on both sections makes each bone bend halfway, meeting in the
-- middle. Zero an axis to ignore it, or flip a sign to bend the other
-- way. Tuned in chassis space: the bone's own orientation in the model
-- doesn't matter.
ENT.ArticulationBoneScale = Angle( 1, 1, 1 )

--- Override this base class function.
function ENT:SetupDataTables()
    BaseClass.SetupDataTables( self )

    -- Lets the client know which entity is our rear section,
    -- required by the unified seat list on the HUD.
    self:NetworkVar( "Entity", "RearSection" )
end

--- Returns a list containing the seats of the whole vehicle:
--- front section seats first (driver = 1), then rear section seats.
---
--- The 0-9 seat switch keys and the `GlideSeatIndex` values
--- use the indexes of this list.
function ENT:GetUnifiedSeats()
    local list = {}

    for _, seat in ipairs( self.seats or {} ) do
        list[#list + 1] = seat
    end

    local rear = self:GetRearSection()

    if IsValid( rear ) and rear.seats then
        for _, seat in ipairs( rear.seats ) do
            list[#list + 1] = seat
        end
    end

    return list
end

if CLIENT then
    local ZERO_ANGLE = Angle()
    local halfAng = Angle()
    local mHalf = Matrix()

    --- Read and cache the bone's rest rotation within the chassis frame.
    --- It never changes (the bone isn't animated), and it must only be read
    --- once: calling `SetupBones` every frame would cache the bones with no
    --- manipulation applied, and the deformation would never render.
    local function GetBoneLocal( self, boneId )
        if self.articulationBoneLocalInv then return true end

        -- Temporarily clear the manipulation to read the natural pose
        self:ManipulateBoneAngles( boneId, ZERO_ANGLE )
        self:SetupBones()

        local natural = self:GetBoneMatrix( boneId )
        if not natural then return false end

        local mChassis = Matrix()
        mChassis:SetAngles( self:GetAngles() )

        local mBone = Matrix()
        mBone:SetAngles( natural:GetAngles() )

        -- L = chassis^-1 * bone  (pure rotation)
        local L = mChassis:GetInverse() * mBone

        self.articulationBoneLocal = L
        self.articulationBoneLocalInv = L:GetInverse()

        return true
    end

    --- Bend the accordion bone towards `other`, around THIS section's
    --- chassis axes. Used by both the front and rear bases.
    ---
    --- `ManipulateBoneAngles` rotates in the bone's own space, whose axes
    --- rarely line up with the model's — passing it a chassis-space angle
    --- would bend the bone on the wrong axis. The conjugation below
    --- (L^-1 * R * L, L being the bone's rest rotation) converts the
    --- rotation we want into the bone's space, so any bone orientation works.
    function Glide.UpdateArticulationBone( self, boneId, other )
        if not IsValid( other ) then
            self:ManipulateBoneAngles( boneId, ZERO_ANGLE )
            self:InvalidateBoneCache()
            return
        end

        if not GetBoneLocal( self, boneId ) then return end

        -- How much the other section is bent relative to us, scaled
        -- per axis by `ArticulationBoneScale`
        local rel = self:WorldToLocalAngles( other:GetAngles() )
        local scale = self.ArticulationBoneScale

        halfAng[1] = rel[1] * scale[1]
        halfAng[2] = rel[2] * scale[2]
        halfAng[3] = rel[3] * scale[3]

        mHalf:SetAngles( halfAng )

        local manip = self.articulationBoneLocalInv * mHalf * self.articulationBoneLocal

        self:ManipulateBoneAngles( boneId, manip:GetAngles() )

        -- Required: without this the bones stay cached and
        -- the deformation is never drawn.
        self:InvalidateBoneCache()
    end

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
    --- Every frame, bend the accordion bone towards the rear section.
    function ENT:OnUpdateAnimations()
        BaseClass.OnUpdateAnimations( self )

        local boneId = self.articulationBoneId
        if not boneId then return end

        Glide.UpdateArticulationBone( self, boneId, self:GetRearSection() )
    end

    --- Override this base class function.
    ---
    --- Draw the passenger list with the seats from both sections.
    function ENT:DrawPlayerListHUD( screenW, screenH )
        -- Not activated on this client yet
        if not self.seats then return 0 end

        local originalSeats = self.seats

        self.seats = self:GetUnifiedSeats()

        local w = BaseClass.DrawPlayerListHUD( self, screenW, screenH )

        self.seats = originalSeats

        return w
    end
end

if not SERVER then return end

--- Get the other section of an articulated vehicle, from either section.
function Glide.GetArticulatedPartner( vehicle )
    if vehicle.IsArticulatedVehicle then
        return vehicle:GetRearSection()
    end

    if vehicle.IsArticulatedRearSection then
        return vehicle:GetFrontSection()
    end
end

--- Blow up the other section too, so the whole vehicle explodes into gibs
--- instead of one half vanishing with the other.
--- Call this before running the base class `Explode`.
function Glide.PropagateArticulatedExplosion( self, attacker, inflictor )
    local other = Glide.GetArticulatedPartner( self )

    if not IsValid( other ) then return end
    if other.hasExploded or other.isExplodingArticulated then return end

    -- Flag both sections first, so the other one doesn't send
    -- the explosion right back at us.
    self.isExplodingArticulated = true
    other.isExplodingArticulated = true

    -- Stop each section from removing the other, or the second one
    -- would be gone before it can run its own explosion.
    self:DontDeleteOnRemove( other )
    other:DontDeleteOnRemove( self )

    other:Explode( attacker, inflictor )
end

--- Override this base class function.
function ENT:Explode( attacker, inflictor )
    if not self.hasExploded then
        Glide.PropagateArticulatedExplosion( self, attacker, inflictor )
    end

    BaseClass.Explode( self, attacker, inflictor )
end

--- Override this base class function.
function ENT:OnPostInitialize()
    BaseClass.OnPostInitialize( self )

    -- Wait a tick, so this section is fully set up (wheels, seats)
    -- before the rear one spawns. Also covers duplicator pastes,
    -- where the rear section has to be recreated.
    timer.Simple( 0, function()
        if IsValid( self ) and not IsValid( self.rearSection ) then
            self:SpawnRearSection()
        end
    end )
end

--- Spawn the rear section, align it with our articulation
--- pivot point, then constrain it to the front section.
function ENT:SpawnRearSection()
    local class = self.ArticulatedRearClass

    if not class or class == "" then
        Glide.Print( "'%s' has no ArticulatedRearClass set!", self:GetClass() )
        return
    end

    local rear = ents.Create( class )

    if not IsValid( rear ) then
        Glide.Print( "'%s' could not create the rear section '%s'!", self:GetClass(), class )
        return
    end

    local worldPivot = self:LocalToWorld( self.ArticulationOffset )

    -- The rear section must know who we are before it initializes,
    -- so the seats it creates get their unified index right away.
    rear.frontSection = self

    rear:SetPos( worldPivot )
    rear:SetAngles( self:GetAngles() )
    rear:Spawn()
    rear:Activate()

    -- Align the rear section's pivot point with ours
    rear:SetPos( worldPivot - ( rear:LocalToWorld( rear.ArticulationOffset ) - rear:GetPos() ) )

    Glide.CopyEntityCreator( self, rear )

    -- Create rear seats that were queued by `CreateRearSeat`
    if self.rearSeatSpecs then
        for _, spec in ipairs( self.rearSeatSpecs ) do
            rear:CreateSeat( spec[1], spec[2], spec[3], spec[4] )
        end
    end

    self:LinkRearSection( rear )
end

--- Tie a rear section to this vehicle: references on both sides, removal
--- and duplication behaviour, and the articulation constraints.
---
--- Runs right after spawning the rear section, and also when re-linking
--- one that already exists in the world (ex. after loading a save).
function ENT:LinkRearSection( rear )
    rear.frontSection = self

    -- The rear section is left out of duplications,
    -- this section recreates it when pasted.
    rear.DoNotDuplicate = true
    rear.DisableDuplicator = true

    -- Removing one section removes the other
    self:DeleteOnRemove( rear )
    rear:DeleteOnRemove( self )

    self.rearSection = rear
    self:SetRearSection( rear )
    rear:SetArticulatedFront( self )

    self:CreateArticulationConstraints()

    -- Optional: share one license plate between both sections.
    -- Only does something when the license plate addon is installed.
    if Glide.SyncArticulatedPlatesDeferred then
        Glide.SyncArticulatedPlatesDeferred( self, rear )
    end

    -- Copy our frozen/unfrozen state, so a vehicle pasted frozen
    -- by the duplicator doesn't have its rear section dangling.
    local frontPhys = self:GetPhysicsObject()
    local rearPhys = rear:GetPhysicsObject()

    if IsValid( frontPhys ) and IsValid( rearPhys ) then
        rearPhys:EnableMotion( frontPhys:IsMotionEnabled() )
    end
end

--- Like `CreateSeat`, but creates the seat on the rear section, so it
--- moves with the rear body when the vehicle bends. The offset is
--- relative to the REAR section's chassis.
---
--- Safe to call from `CreateFeatures`, before the rear section exists:
--- the seats are queued and created as soon as it spawns.
function ENT:CreateRearSeat( offset, angle, exitPos, isHidden )
    local specs = self.rearSeatSpecs or {}
    self.rearSeatSpecs = specs

    specs[#specs + 1] = { offset, angle, exitPos, isHidden }

    local rear = self.rearSection

    if IsValid( rear ) then
        return rear:CreateSeat( offset, angle, exitPos, isHidden )
    end
end

--- Create (or recreate) the constraints between the two sections.
function ENT:CreateArticulationConstraints()
    local rear = self.rearSection
    if not IsValid( rear ) then return end

    -- Remove leftover constraints first
    if self.articulationConstraints then
        for _, c in ipairs( self.articulationConstraints ) do
            if IsValid( c ) then
                c:Remove()
            end
        end
    end

    local limits = self.ArticulationLimits or {}
    local yaw = math.abs( limits.yaw or 42 )
    local pitch = math.abs( limits.pitch or 8 )
    local roll = math.abs( limits.roll or 4 )

    -- Stop the two sections from colliding with each other.
    -- Collisions against everything else still work normally.
    local noCollide = constraint.NoCollide( self, rear, 0, 0 )

    -- Hold both pivot points together. forcelimit = 0 makes it unbreakable.
    local ballSocket = constraint.Ballsocket( rear, self, 0, 0, self.ArticulationOffset, 0, 0, 0 )

    -- Limit how far the vehicle can bend.
    -- With the chassis pointing towards +X: X = roll, Y = pitch, Z = yaw.
    local advBallSocket = constraint.AdvBallsocket(
        rear, self, 0, 0,
        rear.ArticulationOffset, self.ArticulationOffset,
        0, 0,                   -- forcelimit, torquelimit (unbreakable)
        -roll, -pitch, -yaw,    -- xmin, ymin, zmin
        roll, pitch, yaw,       -- xmax, ymax, zmax
        0, 0, 0,                -- xfric, yfric, zfric
        1, 0                    -- onlyrotation, nocollide
    )

    local constraints = { noCollide, ballSocket, advBallSocket }

    for _, c in ipairs( constraints ) do
        if IsValid( c ) then
            c.DoNotDuplicate = true
            c.DisableDuplicator = true
        end
    end

    self.articulationConstraints = constraints
end

--- Override this base class function.
function ENT:OnPostThink( dt, selfTbl )
    BaseClass.OnPostThink( self, dt, selfTbl )

    local t = CurTime()
    if t < ( selfTbl.nextArticulationCheck or 0 ) then return end

    selfTbl.nextArticulationCheck = t + 1

    local rear = selfTbl.rearSection

    if IsValid( rear ) then
        -- If a constraint went missing (ex. someone used a tool to
        -- remove constraints), build them all again.
        local constraints = selfTbl.articulationConstraints
        if not constraints then return end

        for _, c in ipairs( constraints ) do
            if not IsValid( c ) then
                self:CreateArticulationConstraints()
                break
            end
        end

        return
    end

    -- No rear section: either we were just created, or we came from a
    -- game save, which restores the entity but not our Lua fields.
    -- Re-link the rear section if it's still around and really ours,
    -- otherwise spawn a new one.
    local networkedRear = self:GetRearSection()

    if
        IsValid( networkedRear ) and
        networkedRear:GetClass() == self.ArticulatedRearClass and
        networkedRear:GetFrontSection() == self
    then
        self:LinkRearSection( networkedRear )
    else
        self:SpawnRearSection()
    end
end
