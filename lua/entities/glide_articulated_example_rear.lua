AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_glide_articulated_rear"

ENT.PrintName = "Articulated Coach - Back"
ENT.ChassisModel = "models/blackterios_glide_vehicles/gtasacoacharticulated/gtasacoacharticulatedback.mdl"

ENT.Author = "Blackterio"

DEFINE_BASECLASS( "base_glide_articulated_rear" )

-- Articulation setup
ENT.ArticulationOffset = Vector( 245, 0, 83.507 )

-- Accordion/bellows bone on the rear model.
ENT.ArticulationBone = "articulated_bone_rear"

-- =========================
-- Start of plate parameters
-- =========================

local plateCustomText = ""
local platestypes = {"gtasaplates"}

ENT.LicensePlateConfigs = {

    { 
		id = "rear_main",
		position = Vector(-218, -21.3, 29.5),
		angles = Angle(0, 180, 0),
		modelRotation = Angle(0, 0, 0),
		plateType = platestypes, 
		customText = plateCustomText
    }
}


-- =======================
-- End of plate parameters
-- =======================

if CLIENT then
    ENT.CameraOffset = Vector( -380, 0, 100 )
    ENT.CameraAngleOffset = Angle( 7, 0, 0 )
	
    ENT.ExhaustAlpha = 150
    ENT.ExhaustPopSound = ""
	
    ENT.ExhaustOffsets = {
        { pos = Vector( -219.964, -39, -1 ), angle = Angle( -25, 0, 0 ), scale = 1 },
    }	
    ENT.EngineSmokeStrips = {
        { offset = Vector( -215.573, 0, 18 ), angle = Angle( 0, 180, 0 ), width = 80 },
    }

    ENT.EngineFireOffsets = {
        { offset = Vector( -216.156, 0, 33.126 ), angle = Angle( 0, 90, 0 ) },
    }
    ENT.LightSprites = {
	
        { type = "brake", offset = Vector( -218.384, 50.876, 56.169 ), dir = Vector( -1, 0, 0 ), size = 50 },
        { type = "brake", offset = Vector( -218.384, -50.876, 56.169 ), dir = Vector( -1, 0, 0 ), size = 50 },

        { type = "taillight", offset = Vector( -218.384, 50.876, 56.169 ), dir = Vector( -1, 0, 0 ), size = 50 },
        { type = "taillight", offset = Vector( -218.384, 50.876, 56.169 ), dir = Vector( -1, 0, 0 ), size = 50 },

        { type = "signal_left", offset = Vector( -214.727, 54.961, 93.857 ), dir = Vector( -1, 0, 0 ),  size = 50 },
        { type = "signal_right", offset = Vector( -214.727, -54.961, 93.857 ), dir = Vector( -1, 0, 0 ), size = 50 },
    }
end

if SERVER then
    function ENT:InitializePhysics()
        self:SetSolid( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:PhysicsInit( SOLID_VPHYSICS, Vector( 0, 0, 20 ) )
    end

    ENT.ChassisMass = 1000
    ENT.IsHeavyVehicle = true
    ENT.UnflipForce = 0
    ENT.AirControlForce = Vector( 0, 0, 0 )
    ENT.AirMaxAngularVelocity = Vector( 0, 0, 0 )	
	
			    ENT.LightBodygroups = {
			
        { type = "brake_or_taillight", bodyGroupId = 1, subModelId = 1 },  -- Tail/Brake lights		
        { type = "headlight", bodyGroupId = 2, subModelId = 1 },  -- Upper lights		
 		
        { type = "signal_left", bodyGroupId = 3, subModelId = 1 },
        { type = "signal_right", bodyGroupId = 4, subModelId = 1 },
    }
	
    function ENT:CreateFeatures()
        local params = {
            model = "models/blackterios_glide_vehicles/gtasacoacharticulated/gtasacoacharticulatedwheel.mdl",
            modelAngle = Angle( 0, 180, 0 ),
            useModelSize = true,
            springStrength = 1000,
            springDamper = 2000,
        }

        self:SetColor( Color( 255, 255, 255, 255 ) )
        self:SetSkin( 1 )

	-- These seats ADDS to the seats on the front part. Remember that Glide has a limit of 10 seats per vehicle.
        self:CreateSeat( Vector( 100, -40, 45 ), Angle( 0, 0, 0 ), Vector( -100, -95, 50 ), true )
        self:CreateSeat( Vector( 150, 40, 45 ), Angle( 0, 180, 0 ), Vector( -100, -95, 50 ), true )
		
        self:CreateSeat( Vector( -180, 30, 45 ), Angle( 0, -90, 0 ), Vector( -100, -95, 50 ), true )
        self:CreateSeat( Vector( -180, 0, 45 ), Angle( 0, -90, 0 ), Vector( -100, -95, 50 ), true )



        -- Left
        self:CreateWheel( Vector( -106, 55, 15 ), params )

        -- Right
        params.modelAngle = Angle( 0, 0, 0 )
        self:CreateWheel( Vector( -106, -55, 15 ), params )
    end
end
