AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_glide_articulated"

ENT.PrintName = "Articulated Coach"
ENT.GlideCategory = "Default"
ENT.ChassisModel = "models/blackterios_glide_vehicles/gtasacoacharticulated/gtasacoacharticulated.mdl"

ENT.Author = "Blackterio"
ENT.IconOverride = "entities/gtasacoacharticulated_blackterio.png"

DEFINE_BASECLASS( "base_glide_articulated" )

-- Articulation setup
ENT.ArticulatedRearClass = "glide_articulated_example_rear" -- Name of the LUA file of the rear part. Both will connect and spawn at the same time.
ENT.ArticulationOffset = Vector( -250.736, 0, 83.507 ) -- Socket offset
ENT.ArticulationLimits = { yaw = 45, pitch = 80, roll = 10 } -- Rotation limits

ENT.ArticulationBone = "articulated_bone_front" -- Accordion/bellows bone on the front model (if it has one)
ENT.ArticulationBoneScale = Angle( 1, 1, 1 )-- How much of the angle between the two sections is applied to the accordion bone


-- =========================
-- Start of plate parameters
-- =========================

local plateCustomText = ""
local platestypes = {"gtasaplates"}

ENT.LicensePlateConfigs = {

    { 
		id = "front_main",
		position = Vector(257, 0, 10),
		angles = Angle(0, 0, 0),
		modelRotation = Angle(0, 0, 0),
		plateType = platestypes, 
		customText = plateCustomText
    }
}

ENT.LicensePlateAdvancedConfigs = {
 
    { 
		id = "front_main", -- Plate ID, it must exist on the vehicle
        bodygroup = {12,1},  
		platetoggle = true
    }
}

-- =======================
-- End of plate parameters
-- =======================

if CLIENT then
    ENT.StartSound = "Glide.Engine.TruckStart"
    ENT.StartedSound = "glide/engines/start_tail_truck.wav"
    ENT.HornSound = "glide/horns/large_truck_horn_2.wav"

    ENT.ReverseSound = "glide/alarms/reverse_warning.wav"
    ENT.BrakeLoopSound = "glide/wheels/rig_brake_disc_1.wav"
    ENT.BrakeReleaseSound = "glide/wheels/rig_brake_release.wav"
    ENT.BrakeSqueakSound = "Glide.Brakes.Squeak"

    ENT.CameraOffset = Vector( -500, 0, 100 )
    ENT.CameraAngleOffset = Angle( 7, 0, 0 )

    ENT.ExhaustAlpha = 80
    ENT.ExhaustPopSound = ""

    ENT.Headlights = {
        { offset = Vector( 249.678, 40.275, 26.344 ) },
        { offset = Vector( 249.678, -40.275, 26.344 ) },
    }

    ENT.LightSprites = {

        { type = "headlight", offset = Vector( 249.678, 45.275, 26.344 ), dir = Vector( 1, 0, 0 ), size = 60 },
        { type = "headlight", offset = Vector( 249.678, -45.275, 26.344 ), dir = Vector( 1, 0, 0 ), size = 60 },
		
        { type = "headlight", offset = Vector( 249.678, 35.848, 26.344 ), dir = Vector( 1, 0, 0 ), size = 80, beamType = "high" },
        { type = "headlight", offset = Vector( 249.678, -35.848, 26.344 ), dir = Vector( 1, 0, 0 ), size = 80, beamType = "high" },


        { type = "signal_left", offset = Vector( 221.726, 42.882, 45.541 ), dir = Vector( -1, 0, 0 ), color = Glide.DEFAULT_TURN_SIGNAL_COLOR, size = 20 },
        { type = "signal_right", offset = Vector( 221.726, -43.882, 45.541 ), dir = Vector( -1, 0, 0 ), color = Glide.DEFAULT_TURN_SIGNAL_COLOR, size = 20 },
    }

    function ENT:OnCreateEngineStream( stream )
        stream.offset = Vector( -210.766, 0, 25.417 )
        stream:LoadPreset( "airbus" )
    end
end

if SERVER then
    function ENT:InitializePhysics()
        self:SetSolid( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:PhysicsInit( SOLID_VPHYSICS, Vector( 0, 0, 50 ) )
    end

    ENT.SpawnPositionOffset = Vector( 0, 0, 20 )
    ENT.ChassisMass = 3000
    ENT.IsHeavyVehicle = true

    ENT.BurnoutForce = 30
    ENT.UnflipForce = 20

    ENT.AirControlForce = Vector( 0.5, 0.3, 0.1 )
    ENT.AirMaxAngularVelocity = Vector( 100, 80, 100 )

    function ENT:GetGears()
        return {
            [-1] = 2,
            [0] = 0,
            [1] = 2,
            [2] = 1.3,
            [3] = 0.9,
            [4] = 0.75,
            [5] = 0.65,
        }
    end
		    ENT.LightBodygroups = {
			
        { type = "headlight", bodyGroupId = 1, subModelId = 1 },  -- Headlights		
        { type = "headlight", bodyGroupId = 2, subModelId = 1, beamType = "high" },  -- Headlights high		
 		
        { type = "signal_left", bodyGroupId = 3, subModelId = 1 },
        { type = "signal_right", bodyGroupId = 4, subModelId = 1 },
    }
	
    function ENT:CreateFeatures()
        self.engineBrakeTorque = 8000

        self:SetBodygroup( 25, 1 )

       -- self:SetColor( Color( 255, 255, 255, 255 ) )
       --self:SetSkin( 1 )

        self:SetSpringStrength( 2000 )
        self:SetSpringDamper( 5000 )
        self:SetSuspensionLength( 10 )

        self:SetDifferentialRatio( 1.2 )
        self:SetTransmissionEfficiency( 1 )
        self:SetPowerDistribution( -1 )
        self:SetBrakePower( 5000 )

        self:SetMinRPMTorque( 3000 )
        self:SetMaxRPMTorque( 5000 )
        self:SetMinRPM( 1000 )
        self:SetMaxRPM( 4000 )

        self:SetMaxSteerAngle( 55 )
        self:SetSteerConeChangeRate( 2 )
        self:SetSteerConeMaxSpeed( 1000 )
        self:SetSteerConeMaxAngle( 0.2 )
        self:SetCounterSteer( 0.2 )

        self:SetForwardTractionMax( 8000 )
        self:SetSideTractionMultiplier( 90 )
        self:SetSideTractionMaxAng( 50 )
        self:SetSideTractionMax( 5000 )
        self:SetSideTractionMin( 1500 )

        self:SetTurboCharged( false )
        self:SetFastTransmission( false )

        self:CreateSeat( Vector( 190, 35, 33 ), Angle( 0, -90, 0 ), Vector( 210, 95, 50 ), true )
		
        self:CreateSeat( Vector( 160, -40, 45 ), Angle( 0, 0, 0 ), Vector( 160, -95, 50 ), true )
        self:CreateSeat( Vector( 100, -40, 45 ), Angle( 0, 0, 0 ), Vector( 160, -95, 50 ), true )
		
        self:CreateSeat( Vector( 100, 40, 45 ), Angle( 0, 180, 0 ), Vector( 100, -95, 50 ), true )
		
        self:CreateSeat( Vector( -50, 40, 45 ), Angle( 0, 180, 0 ), Vector( -50, -95, 50 ), true )
		
        self:CreateSeat( Vector( -100, -40, 45 ), Angle( 0, 0, 0 ), Vector( -100, -95, 50 ), true )
 
		

        -- Front left
        self:CreateWheel( Vector( 163, 55, 15 ), {
            model = "models/blackterios_glide_vehicles/gtasacoacharticulated/gtasacoacharticulatedwheel.mdl",
            modelAngle = Angle( 0, 180, 0 ),
            useModelSize = true,
            steerMultiplier = 1,
        } )

        -- Front right
        self:CreateWheel( Vector( 163, -55, 15 ), {
            model = "models/blackterios_glide_vehicles/gtasacoacharticulated/gtasacoacharticulatedwheel.mdl",
            modelAngle = Angle( 0, 0, 0 ),
            useModelSize = true,
            steerMultiplier = 1,
        } )

        -- Rear left
        self:CreateWheel( Vector( -152, 55, 15 ), {
            model = "models/blackterios_glide_vehicles/gtasacoacharticulated/gtasacoacharticulatedwheel.mdl",
            modelAngle = Angle( 0, 180, 0 ),
            useModelSize = true,
        } )

        -- Rear right
        self:CreateWheel( Vector( -152, -55, 15 ), {
            model = "models/blackterios_glide_vehicles/gtasacoacharticulated/gtasacoacharticulatedwheel.mdl",
            modelAngle = Angle( 0, 0, 0 ),
            useModelSize = true,
        } )
    end
end
