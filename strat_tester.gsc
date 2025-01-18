#include maps\mp\gametypes\zombies;
#include maps\mp\zombies\_terminals;
#include maps\mp\zombies\_util;
#include maps\mp\zombies\_wall_buys;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\zombies\zombies_spawn_manager;
#include maps\mp\zombies\_zombies;

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
        self thread wait_before_start();
        self thread set_starting_round();
        self thread give_upgrades();
        self thread give_perk_onRevive();
        self thread velocity_hud();
        self thread zoneHud();
        self thread give_loadout();

        self iprintln("^5S^7trat Tester");
    }
}

settings()
{
    setdvar( "sv_cheats", 1);
    setdvar( "g_useholdtime", 0);

    create_dvar("velocity_hud", 0);
    create_dvar("zone_hud", 0);

    create_dvar( "start_round", 30 );
    level.start_round = getDvarInt( "start_round" );
    level.start_round = 30;

    create_dvar("wait_start", 30);
    level.waitbs = getDvarInt("wait_start");
    level.waitbs = 30;

    resetmoney( 500000 );
}

set_starting_round()
{
    level.start_round -= 1;    

    level.wavecounter = level.start_round;
    startinground = level.wavecounter + 1;
}

wait_before_start()
{
    self endon("disconnect");
    level endon("game_ended");

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

give_upgrades()
{
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

