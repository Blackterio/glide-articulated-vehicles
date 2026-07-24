--[[
    GLIDE ARTICULATED BASE — FRONT SECTION (example / guide)

    An articulated vehicle is made of two entities:
      - The FRONT section (this file), which drives, steers and has the engine.
      - The REAR section, in `my_articulated_bus_rear.lua`.

    Only the front section goes in the spawnmenu. Spawning it also spawns
    the rear section, already connected.

    Copy both files into `lua/entities/` of your addon, rename them, and
    make sure the class names match (the file name IS the class name).

    Everything a normal Glide car supports works here as well (sounds,
    lights, wheels, gears, seats...), so only the articulation-specific
    parts are commented in detail below.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_glide_articulated" -- Front section base

ENT.PrintName = "My Articulated Bus" -- Name in the spawnlist
ENT.GlideCategory = "Default" -- Spawnlist category
ENT.ChassisModel = "models/mybus/mybus_front.mdl" -- Front model

ENT.Author = "Your name"
ENT.IconOverride = "entities/mybus.png" -- Spawnlist icon, always in materials/entities

DEFINE_BASECLASS( "base_glide_articulated" )

-- =========================
-- Articulation parameters
-- =========================

-- Class of the rear section (its file name, without ".lua").
-- Both parts spawn and connect at the same time.
ENT.ArticulatedRearClass = "my_articulated_bus_rear"

-- The point both sections pivot around, relative to THIS model's origin.
-- It is the center of the accordion. The rear section has its own
-- `ArticulationOffset` pointing at the same real-world spot, so if the
-- two sections spawn overlapped or too far apart, these two values are
-- what you fix.
ENT.ArticulationOffset = Vector( -250, 0, 83 )

-- How far the vehicle can bend at the joint, in degrees.
-- yaw: turning left/right — the important one for buses.
-- pitch: crests and dips. roll: twisting.
-- Too low feels stiff, too high lets the bus fold onto itself.
ENT.ArticulationLimits = { yaw = 45, pitch = 80, roll = 10 }

-- Name of the accordion bone in THIS model. It bends towards the rear
-- section, so the accordion mesh follows the bend instead of clipping
-- or tearing apart. Leave it out (or empty) if your model has no bone.
ENT.ArticulationBone = "articulated_bone_front"

-- How much of the bend goes into the accordion bone, per axis
-- (pitch, yaw, roll — same meaning as in `ArticulationLimits`).
-- Start at Angle( 1, 1, 1 ) and tune while driving in circles:
--   bends too little / too much  -> raise or lower that axis
--   bends the wrong way          -> flip the sign, ex. Angle( 1, -1, 1 )
-- Using 0.5 on both sections makes each half bend halfway instead.
ENT.ArticulationBoneScale = Angle( 1, 1, 1 )

if CLIENT then
    ENT.StartSound = "Glide.Engine.TruckStart"
    ENT.StartedSound = "glide/engines/start_tail_truck.wav"
    ENT.HornSound = "glide/horns/large_truck_horn_2.wav"

    ENT.ReverseSound = "glide/alarms/reverse_warning.wav"
    ENT.BrakeLoopSound = "glide/wheels/rig_brake_disc_1.wav"
    ENT.BrakeReleaseSound = "glide/wheels/rig_brake_release.wav"
    ENT.BrakeSqueakSound = "Glide.Brakes.Squeak"

    ENT.CameraOffset = Vector( -380, 0, 100 ) -- Camera position (x,y,z)
    ENT.CameraAngleOffset = Angle( 7, 0, 0 ) -- Camera angle

    -- Exhaust smoke. The rear section has its own list, if the
    -- exhaust pipe is back there instead.
    ENT.ExhaustAlpha = 80
    ENT.ExhaustOffsets = {
        { pos = Vector( -216, -44, 4 ), angle = Angle( -35, 50, 0 ), scale = 1 },
    }

    -- Engine damage smoke and fire
    ENT.EngineSmokeStrips = {
        { offset = Vector( -221, 0, 15 ), angle = Angle( 0, 180, 0 ), width = 45 },
    }

    ENT.EngineFireOffsets = {
        { offset = Vector( -210, 0, 25 ), angle = Angle( 0, 90, 0 ) },
    }

    ENT.Headlights = {
        { offset = Vector( 239, 37, 17 ) }, -- left
        { offset = Vector( 239, -38, 17 ) }, -- right
    }

    ENT.LightSprites = {
        { type = "headlight", offset = Vector( 239, 37, 17 ), dir = Vector( 1, 0, 0 ), size = 60 },
        { type = "headlight", offset = Vector( 239, -38, 17 ), dir = Vector( 1, 0, 0 ), size = 60 },

        { type = "signal_left", offset = Vector( 239, 43, 19 ), dir = Vector( 1, 0, 0 ), color = Glide.DEFAULT_TURN_SIGNAL_COLOR, size = 20 },
        { type = "signal_right", offset = Vector( 239, -44, 19 ), dir = Vector( 1, 0, 0 ), color = Glide.DEFAULT_TURN_SIGNAL_COLOR, size = 20 },
    }

    function ENT:OnCreateEngineStream( stream )
        stream.offset = Vector( -210, 0, 25 ) -- Where engine sounds come from
        stream:LoadPreset( "default_truck" ) -- Sound preset name
    end
end

if SERVER then
    function ENT:InitializePhysics()
        self:SetSolid( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:PhysicsInit( SOLID_VPHYSICS, Vector( 20, 0, 20 ) ) -- Center of mass (X Y Z)
    end

    ENT.SpawnPositionOffset = Vector( 0, 0, 20 ) -- Spawn offset
    ENT.ChassisMass = 3000 -- Weight of this section
    ENT.IsHeavyVehicle = true

    function ENT:GetGears()
        return {
            [-1] = 4.5, -- Reverse
            [0] = 0, -- Neutral
            [1] = 1.8,
            [2] = 1.5,
            [3] = 1.25,
            [4] = 1.05,
            [5] = 0.85,
            [6] = 0.7,
        }
    end

    function ENT:CreateFeatures()
        self:SetSpringStrength( 3000 )
        self:SetSpringDamper( 5000 )
        self:SetSuspensionLength( 10 )

        self:SetDifferentialRatio( 0.8 )
        self:SetTransmissionEfficiency( 0.9 )
        self:SetPowerDistribution( -1 ) -- 1 = front, 0 = all, -1 = back
        self:SetBrakePower( 5000 )

        self:SetMinRPMTorque( 3000 )
        self:SetMaxRPMTorque( 4000 )
        self:SetMinRPM( 1000 )
        self:SetMaxRPM( 4000 )

        self:SetMaxSteerAngle( 45 )

        -- ===== SEATS =====
        --
        -- The whole vehicle shares ONE seat list: the front section's
        -- seats come first, then the rear section's. Passengers move
        -- between both sections with the 0-9 keys as if it were a
        -- single vehicle.
        --
        -- The limit of 10 seats (Glide.MAX_SEATS) counts BOTH sections
        -- together. Extra seats are ignored, with a warning in console.
        --
        -- The first seat is always the driver.
        self:CreateSeat( Vector( 163, 28, 13 ), Angle( 0, -90, 0 ), Vector( 210, -90, 50 ), true )

        -- Passenger seats on this section
        self:CreateSeat( Vector( 118, 28, 23 ), Angle( 0, -90, 0 ), Vector( 210, -90, 50 ), true )
        self:CreateSeat( Vector( 108, -28, 23 ), Angle( 0, -90, 0 ), Vector( 210, -90, 50 ), true )

        -- Seats on the REAR section can also be declared from here, if you
        -- prefer having them all in one file. The offset is relative to the
        -- REAR model. (The other way is calling `CreateSeat` in the rear
        -- file's own `CreateFeatures`, like the rear example does.)
        --
        -- self:CreateRearSeat( Vector( 50, 28, 23 ), Angle( 0, -90, 0 ), Vector( 80, -90, 50 ), true )

        -- ===== WHEELS =====
        -- Only this section's wheels. The rear ones go in the rear file.

        -- Front left
        self:CreateWheel( Vector( 163, 55, 15 ), {
            model = "models/mybus/mybus_wheel.mdl",
            modelAngle = Angle( 0, 180, 0 ),
            useModelSize = true,
            steerMultiplier = 1, -- This wheel steers
        } )

        -- Front right
        self:CreateWheel( Vector( 163, -55, 15 ), {
            model = "models/mybus/mybus_wheel.mdl",
            modelAngle = Angle( 0, 0, 0 ),
            useModelSize = true,
            steerMultiplier = 1,
        } )

        -- Rear left
        self:CreateWheel( Vector( -152, 55, 15 ), {
            model = "models/mybus/mybus_wheel.mdl",
            modelAngle = Angle( 0, 180, 0 ),
            useModelSize = true,
        } )

        -- Rear right
        self:CreateWheel( Vector( -152, -55, 15 ), {
            model = "models/mybus/mybus_wheel.mdl",
            modelAngle = Angle( 0, 0, 0 ),
            useModelSize = true,
        } )
    end
end
