# AW-Strat-Tester

A Patch to test Strategys on Call of Duty: Advanced Warfare.

Some basics features are available for now, look at the following roadmap for more infos.

## How to use Patch

1. Download S1x Files (https://mega.nz/folder/oLAViLiZ#3xUbLir3T9AdB51FqdhPlQ)
2. Put S1X Files inside your Game folder
3. Open the "S1x" Folder and inside create a Folder called "scripts"
4. Drag and Drop the patch inside "scripts" Folder.

## Roadmap

- [x] Give starting loadout depending on map
- [x] Give all Exo upgrades depending on map
- [x] Zone Hud
- [x] Velocity Meter
- [x] Set Starting round
- [x] Delay before activating the zombies spawns
- [x] Different Weapon Presets 

More to come... 

- [ ] Round timer
- [ ] SPH timer
- [ ] Open Doors on/off

## How to use
### Game starting round, can be edited using the following dvar
```
start_round 100
```

### Delay before activating the zombies spawns, can be edited using the following dvar (time in seconds)
```
wait_start 60
```

### How to change Weapon preset (hr = High Round, lr = Low Round, fr = First Room)
```
weapon_preset "hr/lr/fr"
```

### Zone Hud on/off can be edited using the following dvar
```
zone_hud 0/1
```

### Velocity Meter on/off can be edited using the following dvar
```
velocity_hud 0/1
```

## Known Bugs

- Weird behaviour in toxic zones, and during survivors round (like have 2 consecutive toxic rounds or survivors)
- On Infection Goliath Round doesn't happen every 10 rounds as it should be
- Round past 162 aren't playable (Just an issue from the Strat Tester)
- Zone & Velocity Hud not working on Infection

## Credits

- **Developer**: [rFancy](https://github.com/IITreborII)
- **Developer at origins of the project**: [FOEDI](https://github.com/FOEDI)
- **Developer at origins of the project**: [llGaryyll](https://www.twitch.tv/ligaryyil)

- **Small help from**: Bread&Butter

