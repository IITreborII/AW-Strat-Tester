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

        self thread change_dvar();
        self thread wait_before_start();
        self thread give_upgrades();
        self thread give_perk_onRevive();        

        set_starting_round();
        level.wavecounter = level.start_round;
        startinground = level.wavecounter + 1;
		
        wait 5;	
        self thread give_loadout();
        self iprintln("^5S^7trat Tester");
    }
}

change_dvar()
{
    setdvar( "sv_cheats", 1);
    setdvar( "g_useholdtime", 0);
    resetmoney( 500000 );

    level.start_round = 30;
    level.waitbs = 30;
}

set_starting_round()
{
    create_dvar( "start_round", 30 );
    level.start_round = getDvarInt( "start_round" );
    level.start_round -= 1;
}

wait_before_start()
{
    self endon("disconnect");
    level endon("game_ended");

    create_dvar("wait_start", 30);
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
    mapName = maps\mp\_utility::getmapname();
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
