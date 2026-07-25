$modelname		"blackterios_glide_vehicles/gtasacoacharticulated/gtasacoacharticulated.mdl"
$scale			1

$bodygroup "body"
{
	studio "front.smd"
}
$bodygroup "Front_Lights"
{
	studio "frontlights.smd"
	studio "frontlightson.smd"
}
$bodygroup "Headlights"
{
	studio "headlights.smd"
	studio "headlightson.smd"
}
$bodygroup "Turn_Left"
{
	studio "turnleftfront.smd"
	studio "turnleftfronton.smd"
}
$bodygroup "Turn_Right"
{
	studio "turnrightfront.smd"
	studio "turnrightfronton.smd"
}

$bodygroup "Destinations"
{
	studio "extra1.smd"
	studio "extra2.smd"
	studio "extra3.smd"
	studio "extra4.smd"
	studio "extra5.smd"
	studio "extra6.smd"
	blank
}
$bodygroup "Left_Door_[Toggle]"
{
	studio "door_l.smd"
	blank
}
$bodygroup "Right_Door_[Toggle]"
{
	studio "door_r.smd"
	blank
}
$bodygroup "Left_Passenger_Door_[Toggle]"
{
	studio "door_pass_l.smd"
	blank
}
$bodygroup "Right_Passenger_Door_[Toggle]"
{
	studio "door_pass_r.smd"
	blank
}
$bodygroup "Left_Compartment_[Toggle]"
{
	studio "compartment_l.smd"
	blank
}
$bodygroup "Right_Compartment_[Toggle]"
{
	studio "compartment_r.smd"
	blank
}
$bodygroup "Front_Bumper_[Toggle]"
{
	studio "bumper_front.smd"
	blank
}
$bodygroup "Decals_[Toggle]"
{
	studio "decals.smd"
	blank
}
$bodygroup "Glass_[Toggle]"
{
	studio "glass_front.smd"
	blank
}
$bodygroup "Steering_Wheel_[Toggle]"
{
	studio "steerw.smd"
	blank
}

$surfaceprop "metalvehicle"
$mostlyopaque


$maxverts 500000
$cdmaterials	"blackterios_glide_vehicles/gtasacoacharticulated"


$lod 100
{
	removemodel "steerw.smd" 
}
$lod 400
{
	replacemodel "front.smd" "frontlod.smd"
	removemodel "extra1.smd" 
	removemodel "extra2.smd" 
	removemodel "extra3.smd" 
	removemodel "extra4.smd" 
	removemodel "extra5.smd" 
	removemodel "extra6.smd" 
	removemodel "door_l.smd" 
	removemodel "door_r.smd" 
	removemodel "door_pass_l.smd" 
	removemodel "door_pass_r.smd" 
	removemodel "compartment_l.smd" 
	removemodel "compartment_r.smd" 
	removemodel "bumper_front.smd" 
	removemodel "decals.smd" 
	removemodel "glass_front.smd" 
}

$collisionmodel	"physicsfront.smd" 

{ 
	$mass 3000
	$concave
	$maxconvexpieces 5000000
}

$keyvalues
{
   "prop_data"
   {
       "base"  "Metal.Large"
   }
}
$poseparameter "vehicle_steer" -1 1


$sequence "idle" "anims/idlefront.smd"  activity ACT_IDLE -1 loop fps 30
$animation neutral "anims/idlefront.smd" frames 0 0
$sequence "steerw.smd" "anims/steering" fps 30

// steering
$weightlist steerwh { "steerw_bone" 1.0 }
$animation steer1 "anims/steering" frame 0 0 subtract neutral 0 weightlist steerwh
$animation steer2 "anims/steering" frame 1 1 subtract neutral 0 weightlist steerwh
$animation steer3 "anims/steering" frame 2 2 subtract neutral 0 weightlist steerwh
$animation steer4 "anims/steering" frame 3 3 subtract neutral 0 weightlist steerwh 
$animation steer5 "anims/steering" frame 4 4 subtract neutral 0 weightlist steerwh
$animation steer6 "anims/steering" frame 5 5 subtract neutral 0 weightlist steerwh //middle
$animation steer7 "anims/steering" frame 6 6 subtract neutral 0 weightlist steerwh
$animation steer8 "anims/steering" frame 7 7 subtract neutral 0 weightlist steerwh
$animation steer9 "anims/steering" frame 8 8 subtract neutral 0 weightlist steerwh
$animation steer10 "anims/steering" frame 9 9 subtract neutral 0 weightlist steerwh
$animation steer11 "anims/steering" frame 10 10 subtract neutral 0 weightlist steerwh
$sequence steering { steer1 steer2 steer3 steer4 steer5 steer6 steer7 steer8 steer9 steer10 steer11 blend vehicle_steer -1 1 } blendwidth 11 weightlist steerwh delta autoplay