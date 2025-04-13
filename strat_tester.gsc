#include maps\mp\gametypes\zombies;
#include maps\mp\zombies\_zombies;
#include maps\mp\zombies\zombies_spawn_manager;
#include maps\mp\zombies\_doors;
#include maps\mp\zombies\_terminals;
#include maps\mp\zombies\_util;
#include maps\mp\zombies\_wall_buys;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

init()
{    
    level.mapName = maps\mp\_utility::getmapname();
    
    // Pre-calculate door bitmasks if they don't exist
    if (!isdefined(level.doorbitmaskarray))
    {
        level.doorbitmaskarray = [];
    }
    
    level thread onPlayerConnect();
    level thread opendoors();
}

onPlayerConnect()
{
    level endon("game_ended");
    
    for(;;)
    {
        level waittill("connected", player);
        if (!isDefined(player.persistentInit))
        {
            player.persistentInit = true;
            player thread persistentPlayerInit();
        }
        player thread onPlayerSpawned();
    }
}

persistentPlayerInit()
{
    self endon("disconnect");
    
    // Cache weapon preset since it's used multiple times
    self.weaponPreset = getDvar("weapon_preset");
    
    self thread settings();
    if (self.weaponPreset != "fr") // Skip if fr preset
    {
        self thread give_perk_onRevive();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
    level endon("game_ended");
    iprintln("^5S^7trat Tester");
    
    for(;;)
    {
        self waittill("spawned_player");
        self freezeControls(false);
        
        // Counter for completed threads
        level.completedThreads = 0;
        
        // Start all threads
        self thread wait_before_start();
        self thread set_starting_round();
        self thread give_player_assets();
        
        // Wait for all to complete
        while(level.completedThreads < 3)
        {
            wait(0.05);
        }
    }
}

settings()
{
    // Group related dvars together
    setdvar("sv_cheats", 1);
    setdvar("g_useholdtime", 0);

    // Array of dvar pairs [name, value]
    dvars = [];
    dvars[dvars.size] = ["open_doors", "1"];
    dvars[dvars.size] = ["weapon_preset", "hr"];
    dvars[dvars.size] = ["start_round", "30"];
    dvars[dvars.size] = ["wait_start", "30"];

    // Create all dvars using while loop
    i = 0;
    while(i < dvars.size)
    {
        create_dvar(dvars[i][0], dvars[i][1]);
        i++;
    }
    
    level.start_round = 30;
    level.waitbs = 30;
    
    resetmoney(500000);
}

opendoors()
{   
    if(getDvarInt("open_doors") == 0)
        return;
        
    common_scripts\utility::flag_init("door_opened");

    if (!isdefined(level.doorhintstrings))
    {
        level.doorhintstrings = [];
    }

    if (!isdefined(level.zombiedoors))
    {
        level.zombiedoors = common_scripts\utility::getstructarray("door", "targetname");
        common_scripts\utility::array_thread(level.zombiedoors, ::init_door);
    }

    // Wait for the map to load
    wait(1);
    
    // Map-specific door sets
    doorSets = [];
    doorSets["mp_zombie_lab"] = [ // outbreak doors
        "courtyard_to_roundabout", "roundabout_to_lab", "roundabout_to_military",
        "courtyard_to_administration", "administration_to_lab", "military_to_experimentation"
    ];
    
    doorSets["mp_zombie_brg"] = [ // infection doors
        "warehouse_to_gas_station", "warehouse_to_atlas", "gas_station_to_sewer",
        "atlas_to_sewer", "sewer_to_burgertown", "sewertrans_to_sewertunnel",
        "sewermain_to_sewercave", "burgertown_storage", "gas_station_interior", "atlas_command"
    ];
    
    doorSets["mp_zombie_ark"] = [ // carrier doors
        "sidebay_to_armory", "rearbay_to_armory", "cargo_elevator_to_cargo_bay",
        "biomed_to_cargo_bay", "armory_to_biomed", "armory_to_cargo_elevator",
        "medical_to_biomed", "moonpool_to_cargo_elevator", "sidebay_to_medical", "rearbay_to_moonpool"
    ];
    
    doorSets["mp_zombie_h2o"] = [ // descent doors
        "start_to_zone_01", "start_to_zone_02", "zone_01_to_atrium",
        "zone_01_to_zone_01a", "zone_02_to_zone_01", "zone_02_to_zone_02a",
        "zone_02a_to_venthall", "venthall_to_zone_03", "venthall_to_atrium", "atrium_to_zone_04"
    ];
    
    // Only process doors for current map
    if (isdefined(doorSets[level.mapName]))
    {
        foreach(door_flag in doorSets[level.mapName])
        {
            foreach(door in level.zombiedoors)
            {
                if(isdefined(door.script_flag) && door.script_flag == door_flag)
                {
                    door notify("open", undefined);
                    
                    if(isdefined(level.doorbitmaskarray[door_flag]))
                    {
                        level.doorsopenedbitmask |= level.doorbitmaskarray[door_flag];
                    }
                }
            }
        }
    }
    
    common_scripts\utility::flag_set("door_opened");
}

set_starting_round()
{
    self endon("disconnect");
    
    desired_round = getDvarInt("start_round");
    if (desired_round < 1)
        desired_round = 1;
    
    level.start_round = desired_round - 1;
    level.wavecounter = level.start_round;
    
    // Set zombie manager values if available
    if (isdefined(level.zombie_spawn_manager))
    {
        level.zombie_spawn_manager.current_round = level.start_round;
        level.zombie_spawn_manager.next_round = level.start_round + 1;
        
        // Reset spawn counts for the new round
        level.zombie_spawn_manager.zombies_spawned_this_round = 0;
        level.zombie_spawn_manager.zombies_killed_this_round = 0;
    }
    
    // Force update HUD if exists
    if (isdefined(level.hud_round))
    {
        level.hud_round setValue(level.start_round + 1);
    }
    
    // Notify completion
    level.completedThreads++;
    self notify("done");
}

wait_before_start()
{
    self endon("disconnect");
    level endon("game_ended");

    level.waitbs = getDvarInt("wait_start");
    
    // Safety check to ensure waitbs is a reasonable number
    if (!isDefined(level.waitbs) || level.waitbs < 0)
    {
        level.waitbs = 5; // default value
    }
    else if (level.waitbs > 30)
    {
        level.waitbs = 30; // cap at 30 seconds
    }

    maps\mp\zombies\_util::pausezombiespawning(1);
    
    //Hud positioning
    self.waithud = newHudElem(self);
    self.waithud.horzAlign = "center";  // Horizontal center
    self.waithud.vertAlign = "top";     // Vertical top
    self.waithud.alignX = "center";     // Text alignment center
    self.waithud.alignY = "middle";     // Text alignment middle (for multi-line)
    self.waithud.x = 0;                 // No horizontal offset
    self.waithud.y = 20;                // 20 pixels down from top
    self.waithud.fontscale = 1.5;       // Slightly larger font
    self.waithud.color = (1, 1, 1);     // White color
    self.waithud.glowColor = (0.2, 0.8, 1); // Light blue glow
    self.waithud.glowAlpha = 0.8;
    self.waithud.label = &"Starting in: ";
    self.waithud.hideWhenInMenu = true;

    while(level.waitbs >= 0) // changed to >= 0 to properly handle 0 case
    {
        self.waithud setText(level.waitbs);
        wait 1;
        level.waitbs--;
    }
    
    maps\mp\zombies\_util::pausezombiespawning(0);
    if(isdefined(self.waithud))
    {
        self.waithud destroy();
    }
    
    // Notify completion
    level.completedThreads++;
    self notify("done");
}

give_player_assets()
{
    self endon("disconnect");
    
    // Initialize counter
    self.assetsThreadsComplete = 0;
    
    // Start both threads
    self thread give_upgrades();
    self thread give_loadout();
    
    // Wait for both threads to complete
    while(self.assetsThreadsComplete < 2)
    {
        wait(0.05);
    }
}

give_loadout()
{
    switch(self.weaponPreset)
    {
        case "hr":
            self thread give_hr_loadout();
            break;
        case "lr":
            self thread give_lr_loadout();
            break;
        case "fr":
            self thread give_fr_loadout();
            break;
    }
}

// Optimized perk giving functions
give_upgrades()
{
    if (self.weaponPreset == "fr")
        return;

    perks = [];
    perks["mp_zombie_lab"] = [
        "exo_suit", "exo_stabilizer", "exo_revive", 
        "exo_slam", "specialty_fastreload", "exo_health"
    ];
    
    perks["mp_zombie_brg"] = perks["mp_zombie_lab"]; // Same perks as lab
    
    perks["mp_zombie_ark"] = [
        "exo_suit", "exo_stabilizer", "exo_revive", 
        "exo_slam", "specialty_fastreload", "exo_health", 
        "exo_tacticalArmor"
    ];
    
    perks["mp_zombie_h2o"] = perks["mp_zombie_ark"]; // Same perks as ark

    if (isdefined(perks[level.mapName]))
    {
        foreach(perk in perks[level.mapName])
        {
            perkterminalgive(self, perk);
        }
    }
}

give_perk_onRevive()
{
    self endon("disconnect");
    level endon("game_ended");

    while(1)
    {
        self waittill("revive_trigger");
        self thread give_upgrades(); // Reuse the same function
    }
}

give_fr_loadout()
{
    wait 5;
    
    // Initialize loadouts array
    loadouts = [];
    
    // Create loadout structure for mp_zombie_brg
    brg_loadout = [];
    brg_loadout["weapons"] = ["iw5_fusionzm_mp", "iw5_rhinozm_mp"];
    brg_loadout["levels"] = [1, 1];
    brg_loadout["tactical"] = "distraction_drone_zombie_mp";
    loadouts["mp_zombie_brg"] = brg_loadout;
    
    // Create loadout structure for mp_zombie_h2o
    h2o_loadout = [];
    h2o_loadout["weapons"] = ["iw5_dlcgun4zm_mp", "iw5_rhinozm_mp"];
    h2o_loadout["levels"] = [2, 15];
    h2o_loadout["tactical"] = "distraction_drone_zombie_mp";
    loadouts["mp_zombie_h2o"] = h2o_loadout;

    if (isdefined(loadouts[level.mapName]))
    {
        loadout = loadouts[level.mapName];
        self takeweapon("iw5_titan45zm_mp");
        
        // Give weapons
        for(i = 0; i < loadout["weapons"].size; i++)
        {
            self giveweapon(loadout["weapons"][i]);
            setweaponlevel(self, loadout["weapons"][i], loadout["levels"][i]);
        }
        
        // Give tactical
        self settacticalweapon(loadout["tactical"]);
        self giveweapon(loadout["tactical"]);
        self setweaponammoclip(loadout["tactical"], 2);
    }
}

give_lr_loadout()
{
    wait 5;
    
    // Initialize loadouts array
    loadouts = [];
    
    // Create mp_zombie_lab loadout
    lab_loadout = [];
    lab_loadout["weapons"] = ["iw5_mahemzm_mp", "iw5_rhinozm_mp"];
    lab_loadout["levels"] = [2, 2];
    lab_loadout["tactical"] = "dna_aoe_grenade_zombie_mp";
    loadouts["mp_zombie_lab"] = lab_loadout;
    
    // Create mp_zombie_brg loadout
    brg_loadout = [];
    brg_loadout["weapons"] = ["iw5_mahemzm_mp", "iw5_fusionzm_mp"];
    brg_loadout["levels"] = [2, 2];
    brg_loadout["tactical"] = "dna_aoe_grenade_zombie_mp";
    loadouts["mp_zombie_brg"] = brg_loadout;
    
    // Create mp_zombie_ark loadout
    ark_loadout = [];
    ark_loadout["weapons"] = ["iw5_linegunzm_mp", "iw5_fusionzm_mp"];
    ark_loadout["levels"] = [2, 2];
    ark_loadout["tactical"] = "dna_aoe_grenade_zombie_mp";
    loadouts["mp_zombie_ark"] = ark_loadout;
    
    // Create mp_zombie_h2o loadout
    h2o_loadout = [];
    h2o_loadout["weapons"] = ["iw5_tridentzm_mp", "iw5_rhinozm_mp"];
    h2o_loadout["levels"] = [2, 2];
    h2o_loadout["tactical"] = "dna_aoe_grenade_zombie_mp";
    loadouts["mp_zombie_h2o"] = h2o_loadout;

    if (isdefined(loadouts[level.mapName]))
    {
        loadout = loadouts[level.mapName];
        self takeweapon("iw5_titan45zm_mp");
        
        for(i = 0; i < loadout["weapons"].size; i++)
        {
            self giveweapon(loadout["weapons"][i]);
            setweaponlevel(self, loadout["weapons"][i], loadout["levels"][i]);
        }
        
        self settacticalweapon(loadout["tactical"]);
        self giveweapon(loadout["tactical"]);
        self setweaponammoclip(loadout["tactical"], 2);
    }
}

give_hr_loadout()
{
    wait 5;
    
    // Initialize loadouts array
    loadouts = [];
    
    // Create mp_zombie_lab loadout
    lab_loadout = [];
    lab_loadout["weapons"] = ["iw5_mahemzm_mp", "iw5_exocrossbowzm_mp"];
    lab_loadout["levels"] = [15, 15];
    lab_loadout["tactical"] = "distraction_drone_zombie_mp";
    loadouts["mp_zombie_lab"] = lab_loadout;
    
    // Create mp_zombie_brg loadout
    brg_loadout = [];
    brg_loadout["weapons"] = ["iw5_mahemzm_mp", "iw5_exocrossbowzm_mp"];
    brg_loadout["levels"] = [15, 15];
    brg_loadout["tactical"] = "distraction_drone_zombie_mp";
    loadouts["mp_zombie_brg"] = brg_loadout;
    
    // Create mp_zombie_ark loadout
    ark_loadout = [];
    ark_loadout["weapons"] = ["iw5_linegunzm_mp", "iw5_fusionzm_mp"];
    ark_loadout["levels"] = [15, 15];
    ark_loadout["tactical"] = "distraction_drone_zombie_mp";
    loadouts["mp_zombie_ark"] = ark_loadout;
    
    // Create mp_zombie_h2o loadout
    h2o_loadout = [];
    h2o_loadout["weapons"] = ["iw5_tridentzm_mp", "iw5_dlcgun4zm_mp"];
    h2o_loadout["levels"] = [15, 15];
    h2o_loadout["tactical"] = "distraction_drone_zombie_mp";
    loadouts["mp_zombie_h2o"] = h2o_loadout;

    if (isdefined(loadouts[level.mapName]))
    {
        loadout = loadouts[level.mapName];
        self takeweapon("iw5_titan45zm_mp");
        
        for(i = 0; i < loadout["weapons"].size; i++)
        {
            self giveweapon(loadout["weapons"][i]);
            setweaponlevel(self, loadout["weapons"][i], loadout["levels"][i]);
        }
        
        self settacticalweapon(loadout["tactical"]);
        self giveweapon(loadout["tactical"]);
        self setweaponammoclip(loadout["tactical"], 2);
    }
}
