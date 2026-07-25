$modelname		"blackterios_glide_vehicles/gtasacoacharticulated/gtasacoacharticulatedwheel.mdl"
$scale			1

$bodygroup "body"
{
	studio "wheel.smd"
}

$maxverts 500000
$cdmaterials	"blackterios_glide_vehicles/gtasacoacharticulated"


$mostlyopaque
$surfaceprop "metalvehicle"

$collisionmodel	"wheel.smd" 

$sequence "idle" "wheel.smd"  activity ACT_IDLE -1 loop fps 30
