# glide-articulated-vehicles
Articulated Vehicles support for Glide

A base for making articulated vehicles (like articulated buses) for the [Glide](https://github.com/StyledStrike/gmod-glide) vehicle base in Garry's Mod.

## Features

- **Joined on spawn** - front and rear sections spawns at the same time and already connected.
- **No self-collision** - front and rear sections never collide with each other (to prevent glitches), while collisions with everything else still work normally.
- **Adjustable bending limits** - set how far the vehicle can bend at the joint (per axis), so it can't fold onto itself.
- **Deformable "accordion"** - optional bone-based deformation for the bellows/accordion between the two sections, so it bends naturally instead of clipping or stretching apart.
- **Unified seats** - passengers can move between both sections using the 0-9 seat keys, just like a single vehicle.
- **Shared damage and health** - damaging either section damages the whole vehicle, and both explode together if destroyed.
- **Synced colors and lights** - color, skin and lights automatically match between the two sections.
- **Duplicator & save support** - works correctly with the duplicator tool and game saves.
- **Optional license plate sync** - if using the [Glide License Plates addon](https://github.com/Blackterio/glide-license-plates), both sections can share the same plate.

## For developers

An example bus with commented code is included in the `guide/` folder. It also includes .blend and .qc files to make it easier to understand the process of creating your vehicle.
