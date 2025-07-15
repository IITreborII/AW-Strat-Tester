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
#include maps\mp\zombies\_power;

init()
{    
    level.getMapName = maps\mp\_utility::getMapName();
    level thread onPlayerConnect();
    level thread doors();
}

onPlayerConnect()
{
    level endon("game_ended");
    
    for(;;)
    {
        level waittill("connected", player);
        player thread setup_settings();
        player thread onPlayerSpawned();
    }
}

setup_settings()
{
    self endon("disconnect");
    self thread settings();
    self thread hud_init();
}

hud_init()
{
    self endon("disconnect");
    self thread strat_tester_txt();
    
    if (getDvarInt("zombie_hud"))
    {
        self thread zombie_hud();
    }
    if (getDvarInt("velocity_hud"))
    {
        self thread velocity_hud();
    }
    if (getDvarInt("zone_hud"))
    {
        self thread zone_hud();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
    level endon("game_ended");
    
    for(;;)
    {
        self waittill("spawned_player");
        self freezeControls(false);
        
        self thread set_delay();
        self thread set_round();
        self thread give_player_assets();
    }
}

settings()
{
    setdvar("sv_cheats", 1);
    setdvar("g_useholdtime", 0);
    resetmoney(500000);

    dvars = [];
    dvars[dvars.size] = ["doors", "1"];
    //dvars[dvars.size] = ["power", "1"];

    dvars[dvars.size] = ["round", "60"];
    dvars[dvars.size] = ["delay", "30"];

    dvars[dvars.size] = ["zombie_hud", "0"];
    dvars[dvars.size] = ["velocity_hud", "0"];
    dvars[dvars.size] = ["zone_hud", "0"];

    i = 0;
    while(i < dvars.size)
    {
        create_dvar(dvars[i][0], dvars[i][1]);
        i++;
    }
}

doors()
{   
    if(getDvarInt("doors") == 0)
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
    wait(1);
    
    doorFlags = undefined;
    switch(level.getMapName)
    {
        case "mp_zombie_lab":
            doorFlags = [
                "courtyard_to_roundabout", "roundabout_to_lab", "roundabout_to_military",
                "courtyard_to_administration", "administration_to_lab", "military_to_experimentation"
            ];
            break;
        case "mp_zombie_brg":
            doorFlags = [
                "warehouse_to_gas_station", "warehouse_to_atlas", "gas_station_to_sewer",
                "atlas_to_sewer", "sewer_to_burgertown", "sewertrans_to_sewertunnel",
                "sewermain_to_sewercave", "burgertown_storage", "gas_station_interior", "atlas_command"
            ];
            break;
        case "mp_zombie_ark":
            doorFlags = [
                "sidebay_to_armory", "rearbay_to_armory", "cargo_elevator_to_cargo_bay",
                "biomed_to_cargo_bay", "armory_to_biomed", "armory_to_cargo_elevator",
                "medical_to_biomed", "moonpool_to_cargo_elevator", "sidebay_to_medical", "rearbay_to_moonpool"
            ];
            break;
        case "mp_zombie_h2o":
            doorFlags = [
                "start_to_zone_01", "start_to_zone_02", "zone_01_to_atrium",
                "zone_01_to_zone_01a", "zone_02_to_zone_01", "zone_02_to_zone_02a",
                "zone_02a_to_venthall", "venthall_to_zone_03", "venthall_to_atrium", "atrium_to_zone_04"
            ];
            break;
        return;
    }

    if (isdefined(doorFlags))
    {
        foreach(door_flag in doorFlags)
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

set_round()
{
    level.wavecounter = getDvarInt("round");
    level.wavecounter -=1;
}

set_delay()
{
    self endon("disconnect");
    level endon("game_ended");

    level.waitbs = getDvarInt("delay");

    maps\mp\zombies\_util::pausezombiespawning(1);

    while(level.waitbs > -1)
    {
        self.waithud settext(level.waitbs);
        wait 1;
        level.waitbs --;
    }

    maps\mp\zombies\_util::pausezombiespawning(0);
    self.waithud destroy();
}

//Loadout Section

//give_player_assets --- function that runs upgrades, loadout and upgrades_revive
//upgrade --- gives Exo suit and Exo upgrades depending on map
//upgrades_revive --- gives Exo health and Exo revive after player is revived
//loadout --- gives player weapons depending on map

give_player_assets()
{
    self thread upgrades();
    self thread loadout();
    self thread upgrades_revive();
}

upgrades()
{
    wait 5;
    switch(level.getMapName)
    {
        case "mp_zombie_lab":
            perkterminalgive(self, "exo_suit");
            perkterminalgive(self, "exo_revive");
            perkterminalgive(self, "exo_stabilizer");
            perkterminalgive(self, "exo_slam");
            perkterminalgive(self, "specialty_fastreload");
            perkterminalgive(self, "exo_health");
            break;
        case "mp_zombie_brg":
            perkterminalgive(self, "exo_suit");
            perkterminalgive(self, "exo_revive");
            perkterminalgive(self, "exo_stabilizer");
            perkterminalgive(self, "exo_slam");
            perkterminalgive(self, "specialty_fastreload");
            perkterminalgive(self, "exo_health");
            break;
        case "mp_zombie_ark":
            perkterminalgive(self, "exo_suit");
            perkterminalgive(self, "exo_revive");
            perkterminalgive(self, "exo_stabilizer");
            perkterminalgive(self, "exo_slam");
            perkterminalgive(self, "specialty_fastreload");
            perkterminalgive(self, "exo_tacticalArmor");
            perkterminalgive(self, "exo_health");
            break;
        case "mp_zombie_h2o":
            perkterminalgive(self, "exo_suit");
            perkterminalgive(self, "exo_revive");
            perkterminalgive(self, "exo_stabilizer");
            perkterminalgive(self, "exo_slam");
            perkterminalgive(self, "specialty_fastreload");
            perkterminalgive(self, "exo_tacticalArmor");
            perkterminalgive(self, "exo_health");
            break;
        return;
    }
}

upgrades_revive()
{
    wait 2;
    while(1)
    {
        self waittill("revive_trigger");
        switch(level.getMapName)
        {
        case "mp_zombie_lab":
            perkterminalgive(self, "exo_health");
            perkterminalgive(self, "exo_revive");
            break;
        case "mp_zombie_brg":
            perkterminalgive(self, "exo_health");
            perkterminalgive(self, "exo_revive");
            break;
        case "mp_zombie_ark":
            perkterminalgive(self, "exo_health");
            perkterminalgive(self, "exo_revive");
            break;
        case "mp_zombie_h2o":
            perkterminalgive(self, "exo_health");
            perkterminalgive(self, "exo_revive");
            break;  
        return; 
        }
    }
}

loadout()
{
    switch(level.getMapName)
    {
        case "mp_zombie_lab":
            loadout = ["iw5_mahemzm_mp", "iw5_exocrossbowzm_mp"]; 
            setweaponlevel( self, loadout[1], 15);
            setweaponlevel( self, loadout[0], 15);
                wait 5;
            self takeweapon( "iw5_titan45zm_mp" );  
            break;

        case "mp_zombie_brg":
            loadout = ["iw5_mahemzm_mp", "iw5_exocrossbowzm_mp"];                 
            setweaponlevel( self, loadout[1], 15);
            setweaponlevel( self, loadout[0], 15);
                wait 5;
            self takeweapon( "iw5_titan45zm_mp" );   
            break;  

        case "mp_zombie_ark":
            loadout = ["iw5_linegunzm_mp", "iw5_fusionzm_mp"];                
            setweaponlevel( self, loadout[1], 15);
            setweaponlevel( self, loadout[0], 15);    
                wait 5;
            self takeweapon( "iw5_titan45zm_mp" );  
            break;      

        case "mp_zombie_h2o":
            loadout = ["iw5_tridentzm_mp", "iw5_dlcgun4zm_mp"];               
            setweaponlevel( self, loadout[1], 15);			
            setweaponlevel( self, loadout[0], 15);  
                wait 5;
            self takeweapon( "iw5_titan45zm_mp" );           
            break;    
        return;                
    }
    self settacticalweapon( "distraction_drone_zombie_mp" );
    self giveweapon( "distraction_drone_zombie_mp" );
    self setweaponammoclip( "distraction_drone_zombie_mp", 2 );
}

//HUD Section

//zombie_hud --- zombie_remaining, has a bug where it breaks past round 75 and it doesnt include nuke kills & Explo Zombies 
//velocity_hud --- prints current player speed
//zone_hud --- prints current zone area

//return mp_zombie_brg due to overflow issues

zombie_hud()
{
    if (level.getMapName == "mp_zombie_brg")
        return;

    zT_hud = newClientHudElem(self);
    zT_hud.alignx = "right";
    zT_hud.aligny = "top";
    zT_hud.horzalign = "user_left";
    zT_hud.vertalign = "user_top";
    zT_hud.x += 20;
    zT_hud.y += 80;
    zT_hud.fontscale = 1;
    zT_hud.hidewheninmenu = 1;
    zT_hud.label = &"Zombies remaining: ";
    zT_hud.alpha = 1;
    
    while(true)
    {
        var_1 = maps\mp\zombies\zombies_spawn_manager::calculatetotalai();
        var_2 = int(self.kills);
        var_3 = int(self.killsatroundstart);
        var_4 = (var_2 - var_3);
        var_5 = (var_1 - var_4); 
        zT_hud setvalue(var_5);
            wait 0.1; 
    }
}

velocity_hud()
{
    if (level.getMapName == "mp_zombie_brg")
        return;

    vel_hud = newClientHudElem(self);
    vel_hud.alignx = "right";
    vel_hud.aligny = "top";
    vel_hud.horzalign = "user_left";
    vel_hud.vertalign = "user_top";
    vel_hud.x += 20;
    vel_hud.y += 70;
    vel_hud.fontscale = 1.0;
    vel_hud.hidewheninmenu = 1;
    vel_hud.label = &"Velocity: ";
    vel_hud.alpha = 1;

    while(true)
    {
        self.newvel = self getvelocity();
        self.newvel = sqrt(float(self.newvel[0] * self.newvel[0]) + float(self.newvel[1] * self.newvel[1]));
        vel_hud setvalue(floor(self.newvel));
        wait 0.05; 
    }
}

zone_hud()
{
    if (level.getMapName == "mp_zombie_brg")
        return;

    zone_hud = newClientHudElem(self);
    zone_hud.alignx = "right";
    zone_hud.aligny = "top";
    zone_hud.horzalign = "user_left";
    zone_hud.vertalign = "user_top";
    zone_hud.x += 20;
    zone_hud.y += 60;
    zone_hud.fontscale = 1.0;
    zone_hud.hidewheninmenu = 1;
    zone_hud.alpha = 1;

    while(true)
    {
        if (isdefined(self.currentzone))
        {
            zone_hud setText(self.currentzone);
        }
        wait 0.1;
    }
}

strat_tester_txt()
{
    if (level.getMapName == "mp_zombie_brg")
        return;

    hud_text = self createfontstring("default", 1.4);
    hud_text setpoint("TOPRIGHT", "TOPRIGHT", -20, 20);     
    hud_text.label = &"Strat Tester";
    hud_text.sort = 1000; 
}


