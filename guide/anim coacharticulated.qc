$modelname		"blackterios_glide_vehicles/gtasacoacharticulated/gtasacoacharticulatedback.mdl"
$scale			1

$bodygroup "body"
{
	studio "back.smd"
}
$bodygroup "Brake_Tail_Lights"
{
	studio "braketaillights.smd"
	studio "braketaillightson.smd"
}
$bodygroup "Lights"
{
	studio "lightsrear.smd"
	studio "lightsrearon.smd"
}
$bodygroup "Turn_Left"
{
	studio "turnleftrear.smd"
	studio "turnleftrearon.smd"
}
$bodygroup "Turn_Right"
{
	studio "turnrightrear.smd"
	studio "turnrightrearon.smd"
}
$bodygroup "Left_Passenger_Door_[Toggle]"
{
	studio "door_pass_rl.smd"
	blank
}
$bodygroup "Right_Passenger_Door_[Toggle]"
{
	studio "door_pass_rr.smd"
	blank
}
$bodygroup "Back_Bumper_[Toggle]"
{
	studio "bumper_back.smd"
	blank
}
$bodygroup "Glass_[Toggle]"
{
	studio "glass_back.smd"
	blank
}
$surfaceprop "metalvehicle"
$mostlyopaque


$maxverts 500000
$cdmaterials	"blackterios_glide_vehicles/gtasacoacharticulated"

$lod 400
{
	replacemodel "back.smd" "backlod.smd"
	removemodel "door_pass_rl.smd" 
	removemodel "door_pass_rr.smd" 
	removemodel "bumper_back.smd" 
	removemodel "glass_back.smd" 
}
$collisionmodel	"physicsback.smd" 

{ 
	$mass 1000
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

$sequence "idle" "anims/idleback.smd"  activity ACT_IDLE -1 loop fps 30
$animation neutral "anims/idleback.smd" frames 0 0