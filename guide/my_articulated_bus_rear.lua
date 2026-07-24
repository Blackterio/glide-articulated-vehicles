--[[
    GLIDE ARTICULATED BASE — REAR SECTION (example / guide)

    Second half of the vehicle. It is spawned automatically by the front
    section (`my_articulated_bus.lua`), so it has NO spawnmenu entry, no
    engine and no driver.

    The front section is the one in charge: this one follows its paint,
    skin, lights, brakes, damage and engine state on its own. What you
    define here is only what belongs to this half of the vehicle: its
    model, its pivot point, its seats, its wheels and its particles.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_glide_articulated_rear" -- Rear section base

ENT.PrintName = "My Articulated Bus - Rear"
ENT.ChassisModel = "models/mybus/mybus_rear.mdl" -- Rear model

ENT.Author = "Your name"

DEFINE_BASECLASS( "base_glide_articulated_rear" )

-- =========================
-- Articulation parameters
-- =========================

-- Same joint as the front section's `ArticulationOffset`, but relative
-- to THIS model's origin. Both values must point at the same real-world
-- spot (the center of the accordion) or the sections will spawn
-- overlapped or too far apart.
ENT.ArticulationOffset = Vector( 245, 0, 83 )

-- Accordion bone in THIS model. Bends towards the front section.
-- Leave it out if your model has no bone.
ENT.ArticulationBone = "articulated_bone_rear"

-- How much of the bend goes into this bone. Tune it the same way as
-- on the front section: raise/lower to bend more or less, flip a sign
-- to bend the other way.
ENT.ArticulationBoneScale = Angle( 1, 1, 1 )

if CLIENT then
    ENT.CameraOffset = Vector( -380, 0, 100 )
    ENT.CameraAngleOffset = Angle( 7, 0, 0 )

    -- Particles use this model's coordinates, but follow the engine of
    -- the front section: exhaust while it runs, smoke when it is damaged,
    -- fire when it burns. Use these if the exhaust pipe or the engine
    -- bay are on this half of the bus.
    ENT.ExhaustAlpha = 80
    ENT.ExhaustOffsets = {
        { pos = Vector( -200, -44, 4 ), angle = Angle( -35, 50, 0 ), scale = 1 },
    }

    ENT.EngineSmokeStrips = {
        { offset = Vector( -180, 0, 15 ), angle = Angle( 0, 180, 0 ), width = 45 },
    }

    ENT.EngineFireOffsets = {
        { offset = Vector( -170, 0, 25 ), angle = Angle( 0, 90, 0 ) },
    }

    -- Rear lights. Brake, reverse and turn signals light up together
    -- with the front section, no extra code needed.
    ENT.LightSprites = {
        { type = "brake", offset = Vector( -221, 42, 33 ), dir = Vector( -1, 0, 0 ), size = 50 },
        { type = "brake", offset = Vector( -221, -43, 33 ), dir = Vector( -1, 0, 0 ), size = 50 },

        { type = "reverse", offset = Vector( -221, 42, 27 ), dir = Vector( -1, 0, 0 ), size = 30 },
        { type = "reverse", offset = Vector( -221, -43, 27 ), dir = Vector( -1, 0, 0 ), size = 30 },

        { type = "taillight", offset = Vector( -221, 42, 39 ), dir = Vector( -1, 0, 0 ), size = 30 },
        { type = "taillight", offset = Vector( -221, -43, 39 ), dir = Vector( -1, 0, 0 ), size = 30 },

        { type = "signal_left", offset = Vector( -221, 42, 45 ), dir = Vector( -1, 0, 0 ), color = Glide.DEFAULT_TURN_SIGNAL_COLOR, size = 20 },
        { type = "signal_right", offset = Vector( -221, -43, 45 ), dir = Vector( -1, 0, 0 ), color = Glide.DEFAULT_TURN_SIGNAL_COLOR, size = 20 },
    }
end

if SERVER then
    function ENT:InitializePhysics()
        self:SetSolid( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:PhysicsInit( SOLID_VPHYSICS, Vector( 20, 0, 20 ) ) -- Center of mass (X Y Z)
    end

    -- Lighter than the front section, so it follows instead of pushing.
    -- Too heavy makes the bus fold in corners, too light makes it skip
    -- around at speed.
    ENT.ChassisMass = 1000
    ENT.IsHeavyVehicle = true

    function ENT:CreateFeatures()
        -- ===== SEATS =====
        -- These continue the front section's seat numbering, so with 3
        -- seats up front, the first one here answers to key 4.
        -- Remember the 10 seat limit counts both sections together.
        self:CreateSeat( Vector( 50, 28, 23 ), Angle( 0, -90, 0 ), Vector( 80, -90, 50 ), true )
        self:CreateSeat( Vector( 50, -28, 23 ), Angle( 0, -90, 0 ), Vector( 80, -90, 50 ), true )
        self:CreateSeat( Vector( 0, -28, 23 ), Angle( 0, -90, 0 ), Vector( 80, -90, 50 ), true )

        -- ===== WHEELS =====
        -- These never steer and have no engine power: this half is
        -- dragged along by the front section.
        local params = {
            model = "models/mybus/mybus_wheel.mdl",
            modelAngle = Angle( 0, 180, 0 ),
            useModelSize = true,
            springStrength = 2000,
            springDamper = 3000,
        }

        -- Left
        self:CreateWheel( Vector( -106, 55, 15 ), params )

        -- Right
        params.modelAngle = Angle( 0, 0, 0 )
        self:CreateWheel( Vector( -106, -55, 15 ), params )
    end
end
