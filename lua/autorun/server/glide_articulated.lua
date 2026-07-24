--[[
    Glide Articulated Base — unified seat switching.

    Makes the 0-9 seat switch keys treat the front and rear
    sections of an articulated vehicle as a single vehicle.

    The seat indexes come from `front:GetUnifiedSeats()`:
    front section seats first (driver = 1), then rear seats.
]]

local IsValid = IsValid

--- If this vehicle is part of an articulated vehicle,
--- return its front section. Returns nothing otherwise.
local function GetArticulatedFront( vehicle )
    if vehicle.IsArticulatedVehicle then
        return vehicle
    end

    if vehicle.IsArticulatedRearSection and IsValid( vehicle.frontSection ) then
        return vehicle.frontSection
    end
end

hook.Add( "Glide_CanSwitchSeat", "GlideArticulated.UnifiedSeatSwitch", function( ply, seatIndex )
    local vehicle = ply:GlideGetVehicle()
    if not IsValid( vehicle ) then return end

    local front = GetArticulatedFront( vehicle )
    if not front then return end

    -- Resolve the index against the unified seat list, then
    -- perform the switch ourselves, since the target seat may
    -- be on the other section. Mirrors `Glide.SwitchSeat`.
    local seat = front:GetUnifiedSeats()[seatIndex]

    if not IsValid( seat ) or IsValid( seat:GetDriver() ) then
        ply:EmitSound( "player/suit_denydevice.wav", 50, 100, 1.0, 6, 0, 0 )
        return false
    end

    hook.Run( "Glide_PreSwitchSeat", ply, seatIndex )

    ply:ExitVehicle()
    ply:SetAllowWeaponsInVehicle( false )
    ply:EnterVehicle( seat )

    hook.Run( "Glide_PostSwitchSeat", ply, seatIndex )

    -- Don't let Glide run its own (single-entity) switch logic
    return false
end )
