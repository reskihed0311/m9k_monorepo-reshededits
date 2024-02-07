CFCM9K = true
CreateConVar( "M9KWeaponStrip", "0", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Allow empty weapon stripping? 1 for true, 0 for false" )
CreateConVar( "M9KDisablePenetration", "0", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Disable Penetration and Ricochets? 1 for true, 0 for false" )
CreateConVar( "M9KDynamicRecoil", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Use Aim-modifying recoil? 1 for true, 0 for false" )
CreateConVar( "M9KAmmoDetonation", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Enable detonatable M9K Ammo crates? 1 for true, 0 for false." )
CreateConVar( "M9KDamageMultiplier", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Multiplier for M9K bullet damage." )
CreateConVar( "M9KDefaultClip", "-1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "How many clips will a weapon spawn with? Negative reverts to default values." )
CreateConVar( "M9KUniqueSlots", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Give M9K Weapons unique slots? 1 for true, 2 for false. A map change may be required." )
CreateConVar( "M9KExplosiveNerveGas", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Use silent explosions for nerve gas? Doesn't clip through walls, but does make other things explode." )
CreateConVar( "M9K_Davy_Crockett_Timer", "3", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Time to make Davy Crockett holder wait before firing the weapon." )
CreateConVar( "DavyCrockettAllowed", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Allow people to shoot the Davy Crockett?" )
CreateConVar( "DavyCrocketAdminOnly", "0", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Make the Davy Crockett an Admin Only weapon?" )
CreateConVar( "OrbitalStrikeAdminOnly", "0", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Make the Orbital Cannon an Admin Only weapon?" )

CreateConVar( "nuke_yield", 200, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "nuke variables" )
CreateConVar( "nuke_.mp3eresolution", 0.2, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "nuke variables" )
CreateConVar( "nuke_ignoreragdoll", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "nuke variables" )
CreateConVar( "nuke_breakconstraints", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "nuke variables" )
CreateConVar( "nuke_disintegration", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "nuke variables" )
CreateConVar( "nuke_damage", 100, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "nuke variables" )
CreateConVar( "nuke_epic_blast.mp3e", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "nuke variables" )
CreateConVar( "nuke_radiation_duration", 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "nuke variables" )
CreateConVar( "nuke_radiation_damage", 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "nuke variables" )
