#include maps\mp\gametypes\zombies;
#include maps\mp\zombies\_terminals;
#include maps\mp\zombies\_util;
#include maps\mp\zombies\_wall_buys;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\zombies\zombies_spawn_manager;
#include maps\mp\zombies\_zombies;
#include maps\mp\zombies\_doors;

init()
{    
    level thread onPlayerConnect();
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
    level endon("game_ended");
    for(;;)
    {
        self waittill("spawned_player");
        if(isDefined(self.playerSpawned))
            continue;
        self.playerSpawned = true;
        self freezeControls(false);

        self thread settings();
        // Initialize doors system & Open specific doors at map launch
        opendoors();
        // Delays Spawn when launching a map
        self thread wait_before_start();
        // Sets the starting Round 
        self thread set_starting_round();
        // Gives Exo Suit and all Perks depending on choice
        self thread give_upgrades();
        // when you down you get your Perks back
        self thread give_perk_onRevive();
        // adds a Velocity (movement speed) Hud to the game (doesnt work for infection) 
        self thread velocity_hud();
        // adds a Zone Hud to the game (doesnt work for infection) 
        self thread zoneHud();
        // gives multiple choices of loadouts 
        self thread give_loadout();

        level.wavecounter = level.start_round;
        startinground = level.wavecounter + 1;

        self iprintln("^5S^7trat Tester");
    }
}

settings()
{
    setdvar( "sv_cheats", 1);
    setdvar( "g_useholdtime", 0);

    create_dvar("velocity_hud", 0);
    create_dvar("zone_hud", 0);
    create_dvar("open_doors", 1);
    create_dvar("weapon_preset", "hr");

    create_dvar( "start_round", 30 );
    level.start_round = 30;

    create_dvar("wait_start", 30);
    level.waitbs = 30;

    resetmoney( 500000 );
}

opendoors()
{   
    open_doors = getDvarInt("open_doors");

    if(open_doors == 0)
        return;
        
    common_scripts\utility::flag_init("door_opened");

    if (!isdefined(level.doorhintstrings))
        level.doorhintstrings = [];

    level.zombiedoors = common_scripts\utility::getstructarray("door", "targetname");
    common_scripts\utility::array_thread(level.zombiedoors, ::init_door);

    // Wait for the map to load
    wait(1);
    // Get current map name
    current_map = maps\mp\_utility::getmapname();
    
    // Initialize doors_to_open array with ALL possible doors (cuz switch statement is buggy due to some #include stuff)
    doors_to_open = [
        // outbreak doors
        "courtyard_to_roundabout",
        "roundabout_to_lab",
        "roundabout_to_military",
        "courtyard_to_administration",
        "administration_to_lab",
        "military_to_experimentation",
        
        // infection doors
        "warehouse_to_gas_station",
        "warehouse_to_atlas",
        "gas_station_to_sewer",
        "atlas_to_sewer",
        "sewer_to_burgertown",
        "sewertrans_to_sewertunnel",
        "sewermain_to_sewercave",
        "burgertown_storage",
        "gas_station_interior",
        "atlas_command",
        
        // carrier doors
        "sidebay_to_armory",
        "rearbay_to_armory",
        "cargo_elevator_to_cargo_bay",
        "biomed_to_cargo_bay",
        "armory_to_biomed",
        "armory_to_cargo_elevator",
        "medical_to_biomed",
        "moonpool_to_cargo_elevator",
        "sidebay_to_medical",
        "rearbay_to_moonpool",

        // descent doors
        "start_to_zone_01",
        "start_to_zone_02",
        "zone_01_to_atrium",
        "zone_01_to_zone_01a",
        "zone_02_to_zone_01",
        "zone_02_to_zone_02a",
        "zone_02a_to_venthall",
        "venthall_to_zone_03",
        "venthall_to_atrium",
        "atrium_to_zone_04"
    ];
    
    // Open all doors that exist on this map
    foreach(door_flag in doors_to_open)
    {
        foreach(door in level.zombiedoors)
        {
            if(isdefined(door.script_flag) && door.script_flag == door_flag)
            {
                // Open the door by simulating a player purchase
                door notify("open", undefined);
                
                // Set the door's opened bitmask
                if(isdefined(level.doorbitmaskarray[door_flag]))
                {
                    level.doorsopenedbitmask |= level.doorbitmaskarray[door_flag];
                }
            }
        }
    }
    
    // Set the global door opened flag
    common_scripts\utility::flag_set("door_opened");
}

set_starting_round()
{
    level.start_round = getDvarInt( "start_round" );
    level.start_round -= 1;    
}

wait_before_start()
{
    self endon("disconnect");
    level endon("game_ended");

    level.waitbs = getDvarInt("wait_start");

    maps\mp\zombies\_util::pausezombiespawning(1);
    self.waithud.label = &"Starting in: ^5";
    self.waithud maps\mp\gametypes\_hud_util::setpoint("CENTER", "CENTER", 0, 0);

    while(level.waitbs > -1)
    {
        self.waithud settext(level.waitbs);
        wait 1;
        level.waitbs --;
    }
    maps\mp\zombies\_util::pausezombiespawning(0);
    self.waithud destroy();
}

give_loadout()
{
    weapon_preset = getDvar("weapon_preset");

    if (weapon_preset == "hr")
    {
        self thread give_hr_loadout();
    }
    else if (weapon_preset == "lr")
    {
        self thread give_lr_loadout();
    }
    else if (weapon_preset == "fr")
    {
        self thread give_fr_loadout();
    }
}

give_upgrades()
{
    weapon_preset = getDvar("weapon_preset");
    if (weapon_preset == "fr")
        return;
    mapName = maps\mp\_utility::getmapname();
    switch ( mapName )
    {
        case "mp_zombie_lab": //Outbreak
            perkterminalgive(self, "exo_suit");
            perkterminalgive(self, "exo_stabilizer");
            perkterminalgive(self, "exo_revive");
            perkterminalgive(self, "exo_slam");
            perkterminalgive(self, "specialty_fastreload");
            perkterminalgive(self, "exo_health");
            break;

        case "mp_zombie_brg": //Infection
            perkterminalgive(self, "exo_suit");
            perkterminalgive(self, "exo_stabilizer");
            perkterminalgive(self, "exo_revive");
            perkterminalgive(self, "exo_slam");
            perkterminalgive(self, "specialty_fastreload");
            perkterminalgive(self, "exo_health");
            break;

        case "mp_zombie_ark": //Carrier
            perkterminalgive(self, "exo_suit");
            perkterminalgive(self, "exo_stabilizer");
            perkterminalgive(self, "exo_revive");
            perkterminalgive(self, "exo_slam");
            perkterminalgive(self, "specialty_fastreload");
            perkterminalgive(self, "exo_health");
            perkterminalgive(self, "exo_tacticalArmor");
            break;    

        case "mp_zombie_h2o": //Descent
            perkterminalgive(self, "exo_suit");
            perkterminalgive(self, "exo_stabilizer");
            perkterminalgive(self, "exo_revive");
            perkterminalgive(self, "exo_slam");
            perkterminalgive(self, "specialty_fastreload");
            perkterminalgive(self, "exo_health");
            perkterminalgive(self, "exo_tacticalArmor");
            break; 

        return;
    }
}

give_perk_onRevive()
{
    self endon("disconnect");
    level endon("game_ended");

    weapon_preset = getDvar("weapon_preset");
    if (weapon_preset == "fr")
        return;
        
    while(1)
    {
        self waittill("revive_trigger");                   
        mapName = maps\mp\_utility::getmapname();
        switch ( mapName )
        {
            case "mp_zombie_lab":
                perkterminalgive(self, "exo_suit");
                perkterminalgive(self, "exo_stabilizer");
                perkterminalgive(self, "exo_revive");
                perkterminalgive(self, "exo_slam");
                perkterminalgive(self, "specialty_fastreload");
                perkterminalgive(self, "exo_health");
                break;

            case "mp_zombie_brg":
                perkterminalgive(self, "exo_suit");
                perkterminalgive(self, "exo_stabilizer");
                perkterminalgive(self, "exo_revive");
                perkterminalgive(self, "exo_slam");
                perkterminalgive(self, "specialty_fastreload");
                perkterminalgive(self, "exo_health");
                break;

            case "mp_zombie_ark":
                perkterminalgive(self, "exo_suit");
                perkterminalgive(self, "exo_stabilizer");
                perkterminalgive(self, "exo_revive");
                perkterminalgive(self, "exo_slam");
                perkterminalgive(self, "specialty_fastreload");
                perkterminalgive(self, "exo_health");
                perkterminalgive(self, "exo_tacticalArmor");
                break;            

            case "mp_zombie_h2o":
                perkterminalgive(self, "exo_suit");
                perkterminalgive(self, "exo_stabilizer");
                perkterminalgive(self, "exo_revive");
                perkterminalgive(self, "exo_slam");
                perkterminalgive(self, "specialty_fastreload");
                perkterminalgive(self, "exo_health");
                perkterminalgive(self, "exo_tacticalArmor");
                break;    

            default:
                return;
        }
    }
}

velocity_hud() /*Credit: Bread&Butter (small adjustments by rFancy)*/
{
	self endon("disconnect");
	level endon("game_ended");

    velocity_hud = getDvarInt("velocity_hud");

    if(velocity_hud == 0)
        return;

    mapName = maps\mp\_utility::getmapname();
	
	vel_hud = newClientHudElem(self);
	vel_hud.alignx = "right";
	vel_hud.aligny = "top";
	vel_hud.horzalign = "user_left";
	vel_hud.vertalign = "user_top";
	vel_hud.x -= 20;
	vel_hud.y += 60;
	vel_hud.fontscale = 1.0;
	vel_hud.hidewheninmenu = 1;
	vel_hud.label = &"Velocity: ";
	vel_hud.alpha = 1;
	while(true)
	{
        switch ( mapName )
        {
            case "mp_zombie_lab":
                self.newvel = self getvelocity();
                self.newvel = sqrt(float(self.newvel[0] * self.newvel[0]) + float(self.newvel[1] * self.newvel[1]));
                self.vel = self.newvel;
                vel_hud setvalue(floor(self.vel));
                break;

            /*
            case "mp_zombie_ark":
                self.newvel = self getvelocity();
                self.newvel = sqrt(float(self.newvel[0] * self.newvel[0]) + float(self.newvel[1] * self.newvel[1]));
                self.vel = self.newvel;
                vel_hud setvalue(floor(self.vel));
                break;
            */    

            case "mp_zombie_brg":
                self.newvel = self getvelocity();
                self.newvel = sqrt(float(self.newvel[0] * self.newvel[0]) + float(self.newvel[1] * self.newvel[1]));
                self.vel = self.newvel;
                vel_hud setvalue(floor(self.vel));
                break;

            case "mp_zombie_h2o":
                self.newvel = self getvelocity();
                self.newvel = sqrt(float(self.newvel[0] * self.newvel[0]) + float(self.newvel[1] * self.newvel[1]));
                self.vel = self.newvel;
                vel_hud setvalue(floor(self.vel));
                break;

            return;
        }
        wait 0.05; 
	}
}

zoneHud() /*Credit: Bread&Butter (small adjustments by rFancy)*/
{
	self endon("disconnect");
	level endon("game_ended");

    zone_hud = getDvarInt("zone_hud");

    if(zone_hud == 0)
        return;

    mapName = maps\mp\_utility::getmapname(); 

	zone_hud = newClientHudElem(self);
	zone_hud.alignx = "right";
	zone_hud.aligny = "top";
	zone_hud.horzalign = "user_left";
	zone_hud.vertalign = "user_top";
	zone_hud.x -= 20;
	zone_hud.y += 75;
	zone_hud.fontscale = 1.0;
	zone_hud.hidewheninmenu = 1;
	zone_hud.alpha = 1;

    mapName = maps\mp\_utility::getmapname(); 
    while(true)   
	{
		switch ( mapName )
        {
            case "mp_zombie_lab":
                zone_hud setText(self.currentzone);
                break;

            /*
            case "mp_zombie_brg":
                zone_hud setText(self.currentzone);
                break;  
            */          

            case "mp_zombie_ark":
                zone_hud setText(self.currentzone);
                break;

            case "mp_zombie_h2o":
                zone_hud setText(self.currentzone);
                break;
            return;                
        }
		wait 0.1;
	}
}

give_fr_loadout()
{
    mapName = maps\mp\_utility::getmapname();
    wait 5;

    switch ( mapName )
    {
        case "mp_zombie_brg":
            self takeweapon( "iw5_titan45zm_mp" );
            loadout = [ "iw5_fusionzm_mp", "iw5_rhinozm_mp" ]; 
            setweaponlevel( self, loadout[1], 1);
            setweaponlevel( self, loadout[0], 1);

            self settacticalweapon( "distraction_drone_zombie_mp" );
            self giveweapon( "distraction_drone_zombie_mp" );
            self setweaponammoclip( "distraction_drone_zombie_mp", 2 );
        break;

        case "mp_zombie_h2o":
            self takeweapon( "iw5_titan45zm_mp" );
            loadout = [ "iw5_dlcgun4zm_mp", "iw5_rhinozm_mp" ]; 
            setweaponlevel( self, loadout[1], 15);
            setweaponlevel( self, loadout[0], 2);
            
            self settacticalweapon( "distraction_drone_zombie_mp" );
            self giveweapon( "distraction_drone_zombie_mp" );
            self setweaponammoclip( "distraction_drone_zombie_mp", 2 );
        break;
            return;
    }
}

give_lr_loadout()
{
    mapName = maps\mp\_utility::getmapname();
    wait 5;

    switch ( mapName )
    {
        case "mp_zombie_lab": //Outbreak
            self takeweapon( "iw5_titan45zm_mp" );
            loadout = [ "iw5_mahemzm_mp", "iw5_rhinozm_mp" ]; 
            setweaponlevel( self, loadout[1], 2);
            setweaponlevel( self, loadout[0], 2);
            break;

        case "mp_zombie_brg": //Infection
            self takeweapon( "iw5_titan45zm_mp" );
            loadout = [ "iw5_mahemzm_mp", "iw5_fusionzm_mp" ];                 
            setweaponlevel( self, loadout[1], 2);
            setweaponlevel( self, loadout[0], 2); 
            break;  

        case "mp_zombie_ark":  //Carrier
            self takeweapon( "iw5_titan45zm_mp" );
            loadout = ["iw5_linegunzm_mp", "iw5_fusionzm_mp"];                
            setweaponlevel( self, loadout[1], 2);
            setweaponlevel( self, loadout[0], 2);    
            break;      

        case "mp_zombie_h2o": //Descent
            self takeweapon( "iw5_titan45zm_mp" );
            loadout = ["iw5_tridentzm_mp", "iw5_rhinozm_mp"];               
            setweaponlevel( self, loadout[1], 2);			
            setweaponlevel( self, loadout[0], 2);             
            break;    

        return;                
    }
    self settacticalweapon( "dna_aoe_grenade_zombie_mp" );
    self giveweapon( "dna_aoe_grenade_zombie_mp" );
    self setweaponammoclip( "dna_aoe_grenade_zombie_mp", 2 );
}

give_hr_loadout()
{
    mapName = maps\mp\_utility::getmapname();
    wait 5;

    switch ( mapName )
    {
        case "mp_zombie_lab": //Outbreak
            self takeweapon( "iw5_titan45zm_mp" );
            loadout = ["iw5_mahemzm_mp", "iw5_exocrossbowzm_mp"]; 
            setweaponlevel( self, loadout[1], 15);
            setweaponlevel( self, loadout[0], 15);
            break;

        case "mp_zombie_brg": //Infection
            self takeweapon( "iw5_titan45zm_mp" );
            loadout = ["iw5_mahemzm_mp", "iw5_exocrossbowzm_mp"];                 
            setweaponlevel( self, loadout[1], 15);
            setweaponlevel( self, loadout[0], 15); 
            break;  

        case "mp_zombie_ark":  //Carrier
            self takeweapon( "iw5_titan45zm_mp" );
            loadout = ["iw5_linegunzm_mp", "iw5_fusionzm_mp"];                
            setweaponlevel( self, loadout[1], 15);
            setweaponlevel( self, loadout[0], 15);    
            break;      

        case "mp_zombie_h2o": //Descent
            self takeweapon( "iw5_titan45zm_mp" );
            loadout = ["iw5_tridentzm_mp", "iw5_dlcgun4zm_mp"];               
            setweaponlevel( self, loadout[1], 15);			
            setweaponlevel( self, loadout[0], 15);             
            break;    

        return;                
    }
    self settacticalweapon( "distraction_drone_zombie_mp" );
    self giveweapon( "distraction_drone_zombie_mp" );
    self setweaponammoclip( "distraction_drone_zombie_mp", 2 );
}
