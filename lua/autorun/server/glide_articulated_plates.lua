--[[
    Glide Articulated Base — license plate synchronization.

    Optional integration with "Blackterio's Glide License Plates".
    Does nothing when that addon is not installed.

    The plate addon generates a random text/type per VEHICLE, and the two
    sections of an articulated bus are two separate vehicles — so each one
    ends up with a different plate. This makes both sections share a single
    plate identity, as long as they are configured the same way:

    - All plate configs (on both sections) must have a matching `plateType`
    - All plate configs (on both sections) must have a matching `customText`

    If either differs between sections, nothing is synchronized: the creator
    asked for different plates, so they get different plates.
]]

if not Glide then return end

local IsValid = IsValid

--- Compare two `plateType` values, which can be a string or a list of types.
local function PlateTypesMatch( a, b )
    if type( a ) ~= type( b ) then return false end

    if type( a ) == "table" then
        if #a ~= #b then return false end

        for i = 1, #a do
            if a[i] ~= b[i] then return false end
        end

        return true
    end

    return a == b
end

--- Get the plate id the addon would use for a config.
local function GetPlateId( config, index )
    return config.id or ( "plate_" .. index )
end

--- Get the model the addon would use for a plate type.
local function GetPlateModel( plateType, config )
    if config.customModel and config.customModel ~= "" and util.IsValidModel( config.customModel ) then
        return config.customModel
    end

    local typeData = GlideLicensePlates.PlateTypes[plateType]

    if typeData and typeData.model then
        return typeData.model
    end

    return GlideLicensePlates.Config.DefaultModel
end

--- Store the shared text/type on a vehicle, so that when the plate addon
--- creates its plates it reuses them instead of randomizing new ones.
---
--- Set `force` to also overwrite values that are already stored, and to
--- update plate entities that were created already.
local function ApplyPlateData( vehicle, text, plateType, force )
    vehicle.LicensePlateTexts = vehicle.LicensePlateTexts or {}
    vehicle.SelectedPlateTypes = vehicle.SelectedPlateTypes or {}
    vehicle.SelectedPlateSkins = vehicle.SelectedPlateSkins or {}

    for i, config in ipairs( vehicle.LicensePlateConfigs ) do
        local plateId = GetPlateId( config, i )
        local hasCustomText = config.customText and config.customText ~= ""

        -- Custom text is set by the creator, only the type is ours to sync
        if not hasCustomText and ( force or not vehicle.LicensePlateTexts[plateId] ) then
            vehicle.LicensePlateTexts[plateId] = text
        end

        if force or not vehicle.SelectedPlateTypes[plateId] then
            vehicle.SelectedPlateTypes[plateId] = plateType
        end

        local skin = GlideLicensePlates.GetPlateSkin( plateType, config.customSkin )
        vehicle.SelectedPlateSkins[plateId] = skin

        -- If this plate exists already (ex. re-linking after a game load),
        -- update it in place instead of waiting for it to be recreated.
        local plate = vehicle.LicensePlateEntities and vehicle.LicensePlateEntities[plateId]

        if force and IsValid( plate ) then
            local model = GetPlateModel( plateType, config )

            if plate:GetModel() ~= model then
                plate:UpdatePlateModel( model )
            end

            plate.PlateType = plateType
            plate:UpdatePlateSkin( skin )

            if not hasCustomText then
                plate:UpdatePlateText( text )
            end
        end
    end
end

--- Make both sections of an articulated vehicle share the same license plate.
--- Safe to call at any point: it no-ops when the plate addon is missing, when
--- either section has no plates, or when their configs don't match.
function Glide.SyncArticulatedPlates( front, rear )
    if not GlideLicensePlates then return end
    if not IsValid( front ) or not IsValid( rear ) then return end

    local frontConfigs = front.LicensePlateConfigs
    local rearConfigs = rear.LicensePlateConfigs

    if not frontConfigs or #frontConfigs == 0 then return end
    if not rearConfigs or #rearConfigs == 0 then return end

    -- Expand plate groups into plain type lists on both sections, so the
    -- comparison below works on equivalent values. This is idempotent.
    GlideLicensePlates.ValidateVehicleConfig( front )
    GlideLicensePlates.ValidateVehicleConfig( rear )

    -- Gather every plate config from the whole vehicle
    local configs = {}

    for _, config in ipairs( frontConfigs ) do
        configs[#configs + 1] = config
    end

    for _, config in ipairs( rearConfigs ) do
        configs[#configs + 1] = config
    end

    -- All of them must share the same type and custom text,
    -- otherwise the creator wants different plates: leave them alone.
    local firstType = configs[1].plateType
    local firstText = configs[1].customText or ""

    for i = 2, #configs do
        if not PlateTypesMatch( firstType, configs[i].plateType ) then return end
        if firstText ~= ( configs[i].customText or "" ) then return end
    end

    -- Reuse whatever the front section already has, so pasted copies keep
    -- their plates. Otherwise, roll a single plate for the whole vehicle.
    local frontId = GetPlateId( frontConfigs[1], 1 )
    local text = front.LicensePlateTexts and front.LicensePlateTexts[frontId]
    local plateType = front.SelectedPlateTypes and front.SelectedPlateTypes[frontId]

    -- When pasted with the duplicator, the front section's plate data is only
    -- restored a moment later, so read it straight from the pending duplicator
    -- data instead of rolling a new plate we'd have to correct afterwards.
    if not text or not plateType then
        local mods = front.EntityMods and front.EntityMods["glide_license_plate_data"]

        if mods then
            text = mods.plateTexts and mods.plateTexts[frontId]
            plateType = mods.selectedPlateTypes and mods.selectedPlateTypes[frontId]
        end
    end

    if not text or not plateType then
        text, plateType = GlideLicensePlates.GeneratePlate( firstType )
    end

    -- The front section keeps whatever it has; the rear always follows it.
    ApplyPlateData( front, text, plateType, false )
    ApplyPlateData( rear, text, plateType, true )

    if GlideLicensePlates.SavePlateData then
        GlideLicensePlates.SavePlateData( rear )
    end
end

--- Sync now, then again shortly after.
---
--- The second pass is a safety net for the duplicator: it restores the front
--- section's plate data on a delay of its own, after we have already linked
--- the sections. Running again once that settled makes the rear follow the
--- front's final plate. It is a no-op when both already match.
function Glide.SyncArticulatedPlatesDeferred( front, rear )
    Glide.SyncArticulatedPlates( front, rear )

    timer.Simple( 0.6, function()
        if not IsValid( front ) or not IsValid( rear ) then return end

        Glide.SyncArticulatedPlates( front, rear )
    end )
end
