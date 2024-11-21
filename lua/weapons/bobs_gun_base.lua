-- --Variables that are used on both client and server
SWEP.Category               = ""
SWEP.Gun                    = ""
SWEP.Author                 = "Generic Default, Worshipper, Clavus, and Bob"
SWEP.Contact                = ""
SWEP.Purpose                = ""
SWEP.Instructions           = ""
SWEP.MuzzleAttachment       = "1" -- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.DrawCrosshair          = true -- Hell no, crosshairs r 4 nubz!
SWEP.ViewModelFOV           = 65 -- How big the gun will look
SWEP.ViewModelFlip          = true -- True for CSS models, False for HL2 models

SWEP.Spawnable              = false
SWEP.AdminSpawnable         = false

SWEP.Primary.Sound          = "" -- Sound of the gun
SWEP.Primary.Round          = "" -- What kind of bullet?
SWEP.Primary.Cone           = 0.2 -- Accuracy of NPCs
SWEP.Primary.Damage         = 10
SWEP.Primary.SpreadHip         = .01 --define from-the-hip accuracy (1 is terrible, .0001 is exact)
SWEP.Primary.NumShots       = 1
SWEP.Primary.RPM            = 0 -- This is in Rounds Per Minute
SWEP.Primary.ClipSize       = 0 -- Size of a clip
SWEP.Primary.DefaultClip    = 0 -- Default number of bullets in a clip
SWEP.Primary.KickUp         = 0 -- Maximum up recoil (rise)
SWEP.KickUpMultiplier       = 2

SWEP.Primary.KickDown       = 0 -- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal = 0 -- Maximum side recoil (koolaid)
SWEP.Primary.Automatic      = true -- Automatic/Semi Auto
SWEP.Primary.Ammo           = "none" -- What kind of ammo

-- SWEP.Secondary.ClipSize                 = 0                                     -- Size of a clip
-- SWEP.Secondary.DefaultClip                      = 0                                     -- Default number of bullets in a clip
-- SWEP.Secondary.Automatic                        = false                                 -- Automatic/Semi Auto
SWEP.Secondary.Ammo         = ""
----HAHA! GOTCHA, YA BASTARD!

-- SWEP.Secondary.IronFOV                  = 0                                     -- How much you 'zoom' in. Less is more!

SWEP.IronsightsBlowback = true -- Disabled the default activity and use the blowback system instead?
SWEP.RecoilBack = 3 -- How much the gun kicks back in iron sights
SWEP.RecoilRecoverySpeed = 2 -- How fast does the gun return to the center
SWEP.RecoilAmount = 0 -- Internal, do not touch
SWEP.IronSightTime = 0.15

SWEP.Penetration            = true
SWEP.Ricochet               = true
SWEP.RicochetCoin           = 1
SWEP.BoltAction             = false
SWEP.Scoped                 = false
SWEP.ShellTime              = .35
SWEP.CanBeSilenced          = false
SWEP.Silenced               = false
SWEP.NextSilence            = 0
SWEP.SelectiveFire          = false
SWEP.NextFireSelect         = 0
SWEP.OrigCrossHair          = true

local CLIENT                = CLIENT
local SERVER                = SERVER
local MASK_SHOT             = MASK_SHOT
local IN_USE                = IN_USE

local dmgMultCvar = GetConVar( "M9KDamageMultiplier" )
local damageMultiplier = dmgMultCvar:GetFloat()

local function dmgMultCallback( _, _, new )
    damageMultiplier = tonumber( new )
end
cvars.AddChangeCallback( "M9KDamageMultiplier", dmgMultCallback, "gunbase" )

SWEP.IronSightsPos = Vector( 0, 0, 0 )
SWEP.IronSightsAng = Vector( 0, 0, 0 )

SWEP.VElements = {}
SWEP.WElements = {}

local defaultClipMult = GetConVar( "M9KDefaultClip" )

local entMeta = FindMetaTable( "Entity" )
local entity_GetTable = entMeta.GetTable

function SWEP:Initialize()
    self.Reloadaftershoot = 0 -- Can't reload when firing
    self:SetHoldType( self.HoldType )
    self.OrigCrossHair = self.DrawCrosshair
    if SERVER and self:GetOwner():IsNPC() then
        self:SetNPCMinBurst( 3 )
        self:SetNPCMaxBurst( 10 ) -- None of this really matters but you need it here anyway
        self:SetNPCFireRate( 1 / (self.Primary.RPM / 60) )
        -- --self:SetCurrentWeaponProficiency( WEAPON_PROFICIENCY_VERY_GOOD )
    end

    local clipMult = defaultClipMult:GetInt()
    if clipMult ~= -1 then
        self.Primary.DefaultClip = self.Primary.ClipSize * clipMult
    end

    if CLIENT then
        -- -- Create a new table for every weapon instance
        self.VElements = table.FullCopy( self.VElements )
        self.WElements = table.FullCopy( self.WElements )
        self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

        self:CreateModels( self.VElements ) -- create viewmodels
        self:CreateModels( self.WElements ) -- create worldmodels

        -- -- init view model bone build function
        if IsValid( self:GetOwner() ) and self:GetOwner():IsPlayer() then
            if self:GetOwner():Alive() then
                local vm = self:GetOwner():GetViewModel()
                if IsValid( vm ) then
                    self:ResetBonePositions( vm )
                    -- -- Init viewmodel visibility
                    if (self.ShowViewModel == nil or self.ShowViewModel) then
                        vm:SetColor( Color( 255, 255, 255, 255 ) )
                    else
                        -- -- however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
                        vm:SetMaterial( "Debug/hsv" )
                    end
                end
            end
        end
    end

    if CLIENT then
        self:SetupWepSelectIcon()
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar( "Bool", "IronsightsActive" )
    self:NetworkVar( "Bool", "Reloading" )
    self:NetworkVar( "Float", "IronsightsTime" )
end

function SWEP:SetIronsights( b )
    self:SetIronsightsActive( b )
    self:SetIronsightsTime( CurTime() )
end

function SWEP:GetIronsights()
    return self:GetIronsightsActive()
end

function SWEP:Equip()
    self:SetHoldType( self.HoldType )
end

function SWEP:Deploy()
    self:SetIronsights( false )
    self.DrawCrosshair = self.OrigCrossHair
    self:SetHoldType( self.HoldType )

    if self.Silenced then
        self:SendWeaponAnim( ACT_VM_DRAW_SILENCED )
    else
        self:SendWeaponAnim( ACT_VM_DRAW )
    end

    if self.DeployDelay then
        self:SetNextPrimaryFire( CurTime() + self.DeployDelay )
    end
    self:SetReloading( false )

    if not self:GetOwner():IsNPC() and self:GetOwner() ~= nil and self.ResetSights and self:GetOwner():GetViewModel() ~= nil then
        self.ResetSights = CurTime() + self:GetOwner():GetViewModel():SequenceDuration()
    end
    return true
end

function SWEP:Holster()
    if CLIENT and IsValid( self:GetOwner() ) and not self:GetOwner():IsNPC() then
        local vm = self:GetOwner():GetViewModel()
        if IsValid( vm ) then
            self:ResetBonePositions( vm )
        end
    end

    return true
end

function SWEP:OnRemove()
    if CLIENT and IsValid( self:GetOwner() ) and not self:GetOwner():IsNPC() then
        local vm = self:GetOwner():GetViewModel()
        if IsValid( vm ) then
            self:ResetBonePositions( vm )
        end
    end
end

function SWEP:GetCapabilities()
    return CAP_WEAPON_RANGE_ATTACK1, CAP_INNATE_RANGE_ATTACK1
end

local shellEffects = {
    pistol = "ShellEject",
    smg = "RifleShellEject",
    ar2 = "RifleShellEject",
    shotgun = "ShotgunShellEject"
}

function SWEP:FireAnimation()
    -- Sounds
    local silenced = self.Silenced
    if silenced then
        self:EmitSound( self.Primary.SilencedSound )
    else
        self:EmitSound( self.Primary.Sound )
    end

    -- If we're not iron-sighting, just fire normally and return
    if self.Scoped or ( not self:GetIronsightsActive() or not self.IronsightsBlowback ) then
        if silenced then
            self:SendWeaponAnim( ACT_VM_PRIMARYATTACK_SILENCED )
        else
            self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
        end

        return
    end

    -- Ironsights logic
    self.RecoilAmount = self.RecoilBack
    if silenced then
        self:SendWeaponAnim( ACT_VM_IDLE_SILENCED )
    else
        self:SendWeaponAnim( ACT_VM_IDLE )
    end

    -- Effects only clientside, for the owner and if we're in first person
    if not CLIENT then return end
    if not IsFirstTimePredicted() then return end
    if self:GetOwner() ~= LocalPlayer() then return end
    if EyePos() ~= self:GetOwner():EyePos() then return end

    local vm = self:GetOwner():GetViewModel()
    if not self.NoMuzzleFlash then
        local muzzleAtt = vm:GetAttachment( 1 )
        if muzzleAtt then
            local flash = EffectData()
            flash:SetOrigin( muzzleAtt.Pos )
            flash:SetAngles( muzzleAtt.Ang )
            flash:SetScale( 1 )
            flash:SetEntity( vm )
            flash:SetMagnitude( 1 )
            flash:SetAttachment( 1 )
            util.Effect( "CS_MuzzleFlash", flash )
        end
    end

    local shell = shellEffects[self.Primary.Ammo]
    if shell then
        local att = vm:GetAttachment( 2 )
        if att then
            local shellEffect = EffectData()
            shellEffect:SetOrigin( att.Pos )
            shellEffect:SetAngles( att.Ang )
            shellEffect:SetEntity( vm )
            util.Effect( shell, shellEffect )
        end
    end
end

function SWEP:PrimaryAttack()
    if not IsValid( self ) or not IsValid( self:GetOwner() ) then return end

    if self:CanPrimaryAttack() and self:GetOwner():IsPlayer() then
        if not self:GetOwner():KeyDown( IN_SPEED ) and not self:GetOwner():KeyDown( IN_RELOAD ) then
            self:ShootBulletInformation()
            self:TakePrimaryAmmo( 1 )

            self:FireAnimation()

            self:GetOwner():SetAnimation( PLAYER_ATTACK1 )
            self:GetOwner():MuzzleFlash()
            self:SetNextPrimaryFire( CurTime() + 1 / (self.Primary.RPM / 60) )
            self:CheckWeaponsAndAmmo()
            self.RicochetCoin = (math.random( 1, 4 ))
            if self.BoltAction then self:BoltBack() end
        end
    elseif self:CanPrimaryAttack() and self:GetOwner():IsNPC() then
        self:ShootBulletInformation()
        self:TakePrimaryAmmo( 1 )
        self:EmitSound( self.Primary.Sound )
        self:GetOwner():SetAnimation( PLAYER_ATTACK1 )
        self:GetOwner():MuzzleFlash()
        self:SetNextPrimaryFire( CurTime() + 1 / (self.Primary.RPM / 60) )
        self.RicochetCoin = math.random( 1, 4 )
    end
end

local weaponStrip = GetConVar( "M9KWeaponStrip" )
function SWEP:CheckWeaponsAndAmmo()
    if self:Clip1() ~= 0 then return end

    local hasAmmo = self:GetOwner():GetAmmoCount( self:GetPrimaryAmmoType() ) > 0
    if hasAmmo then
        self:Reload()
        return
    end

    if SERVER and weaponStrip:GetBool() then
        timer.Simple( 0.1, function()
            if not IsValid( self ) or not IsValid( self:GetOwner() ) then return end
            if self:GetOwner() == nil then return end
            self:GetOwner():StripWeapon( self.Gun )
        end )
    end
end

--[[---------------------------------------------------------
   Name: SWEP:ShootBulletInformation()
   Desc: This func add the damage, the recoil, the number of shots and the cone on the bullet.
-------------------------------------------------------]]
function SWEP:ShootBulletInformation()
    local currentCone
    if self:GetIronsightsActive() == true and self:GetOwner():KeyDown( IN_ATTACK2 ) then
        currentCone = self.Primary.SpreadIronSights
    else
        currentCone = self.Primary.SpreadHip
    end

    local damagedice = math.Rand( 0.95, 1.05 )

    local basedamage = damageMultiplier * self.Primary.Damage
    local currentDamage = basedamage * damagedice

    self:ShootBullet( currentDamage, self.Primary.NumShots, currentCone )
end

--[[---------------------------------------------------------
   Name: SWEP:BulletCallback()
   Desc: A convenience func to handle bullet callbacks.
-------------------------------------------------------]]
local iterationCount = {
    ["SniperPenetratedRound"] = 10,
    ["pistol"] = 2,
    ["357"] = 5,
    ["smg1"] = 4,
    ["ar2"] = 5,
    ["buckshot"] = 1,
    ["slam"] = 1,
    ["AirboatGun"] = 8
}

local penetrationDepthTbl = {
    ["SniperPenetratedRound"] = 20,
    ["pistol"] = 9,
    ["357"] = 12,
    ["smg1"] = 14,
    ["ar2"] = 16,
    ["buckshot"] = 5,
    ["slam"] = 5,
    ["AirboatGun"] = 17
}

local penetrationDamageMult = {
    [MAT_CONCRETE] = 0.3,
    [MAT_METAL] = 0.3,
    [MAT_WOOD] = 0.8,
    [MAT_PLASTIC] = 0.8,
    [MAT_GLASS] = 0.8,
    [MAT_FLESH] = 0.9,
    [MAT_ALIENFLESH] = 0.9
}

local easyPenMaterials = {
    [MAT_GLASS] = true,
    [MAT_PLASTIC] = true,
    [MAT_WOOD] = true,
    [MAT_FLESH] = true,
    [MAT_ALIENFLESH] = true
}

local spreadVec = Vector( 0, 0, 0 )

local disablepen = GetConVar( "M9KDisablePenetration" ):GetBool()
cvars.AddChangeCallback( "M9KDisablePenetration", function( _, _, new )
    disablepen = tobool( new )
end )

function SWEP:BulletCallback( iteration, attacker, bulletTrace, dmginfo, direction )
    if CLIENT then return end
    if bulletTrace.HitSky then return end

    iteration = iteration and iteration + 1 or 0
    local maxIterations = iterationCount[self.Primary.Ammo] or 14
    if iteration > maxIterations then return end

    direction = direction or bulletTrace.Normal

    if not disablepen then
        local penetrated = self:BulletPenetrate( iteration, attacker, bulletTrace, dmginfo, direction )
        if penetrated then return end
    end

    local ricochet = self:BulletRicochet( iteration, attacker, bulletTrace, dmginfo, direction )
    if ricochet then return end
end

function SWEP:BulletPenetrate( iteration, attacker, bulletTrace, dmginfo, direction )
    local penDepth = penetrationDepthTbl[self.Primary.Ammo] or 5
    local penDirection = direction * penDepth
    if easyPenMaterials[bulletTrace.MatType] then
        penDirection = direction * penDepth * 2
    end

    local hitEnt = bulletTrace.Entity
    local penTrace = util.TraceLine( {
        endpos = bulletTrace.HitPos,
        start = bulletTrace.HitPos + penDirection,
        mask = MASK_SHOT,
        filter = function( ent )
            return ent == hitEnt
        end
    } )

    --debugoverlay.Line( bulletTrace.HitPos + penDirection, penTrace.HitPos, 10, Color( 255, 0, 0 ), true )

    if penTrace.AllSolid and penTrace.HitWorld then return false end
    if not penTrace.Hit then return false end
    if penTrace.Fraction >= 0.99 or penTrace.Fraction <= 0.01 then return false end

    --debugoverlay.Text( penTrace.HitPos, "Pen:" .. tostring( iteration ), 10 )
    local damageMult = penetrationDamageMult[penTrace.MatType] or 0.5
    local bullet = {
        Num = 1,
        Src = penTrace.HitPos,
        Dir = direction,
        Spread = spreadVec,
        Tracer = 1,
        TracerName = "m9k_effect_mad_penetration_trace",
        Force = 5,
        Damage = dmginfo:GetDamage() * damageMult,
        Callback = function( a, b, c )
            if not IsValid( self ) then return end
            self:BulletCallback( iteration, a, b, c, direction )
        end
    }

    timer.Simple( 0, function()
        if not IsValid( attacker ) then return end
        attacker:FireBullets( bullet )
    end )

    return true
end

local bulletMissSounds = {
    "weapons/fx/nearmiss/bulletLtoR03.wav",
    "weapons/fx/nearmiss/bulletLtoR04.wav",
    "weapons/fx/nearmiss/bulletLtoR06.wav",
    "weapons/fx/nearmiss/bulletLtoR07.wav",
    "weapons/fx/nearmiss/bulletLtoR09.wav",
    "weapons/fx/nearmiss/bulletLtoR10.wav",
    "weapons/fx/nearmiss/bulletLtoR13.wav",
    "weapons/fx/nearmiss/bulletLtoR14.wav"
}

local ricochetAmmoTable = {
    ["pistol"] = true,
    ["buckshot"] = true,
    ["slam"] = true,
    ["SniperPenetratedRound"] = true
}

function SWEP:BulletRicochet( iteration, attacker, bulletTrace, dmginfo, direction )
    local shouldRicochet = ricochetAmmoTable[self.Primary.Ammo] or false
    if not shouldRicochet and self.RicochetCoin ~= 1 then return false end

    if bulletTrace.MatType ~= MAT_METAL then
        local missSound = bulletMissSounds[math.random( #bulletMissSounds )]
        sound.Play( missSound, bulletTrace.HitPos, 75, math.random( 75, 150 ), 1 )

        if self.Tracer == 0 or self.Tracer == 1 or self.Tracer == 2 then
            local effectdata = EffectData()
            effectdata:SetOrigin( bulletTrace.HitPos )
            effectdata:SetNormal( bulletTrace.HitNormal )
            effectdata:SetScale( 20 )
            util.Effect( "AR2Impact", effectdata )
        elseif self.Tracer == 3 then
            local effectdata = EffectData()
            effectdata:SetOrigin( bulletTrace.HitPos )
            effectdata:SetNormal( bulletTrace.HitNormal )
            effectdata:SetScale( 20 )
            util.Effect( "StunstickImpact", effectdata )
        end

        return false
    end

    local dotProduct = bulletTrace.HitNormal:Dot( direction * -1 )
    local bullet = {
        Num = 1,
        Src = bulletTrace.HitPos + bulletTrace.HitNormal,
        Dir = ( ( 2 * bulletTrace.HitNormal * dotProduct ) + direction ) + ( VectorRand() * 0.05 ),
        Spread = spreadVec,
        Tracer = SERVER and 1 or 0,
        TracerName = "m9k_effect_mad_ricochet_trace",
        Force = dmginfo:GetDamage() * 0.15,
        Damage = dmginfo:GetDamage() * 0.5,
        Callback = function( a, b, c )
            if not IsValid( self ) then return end
            self:BulletCallback( iteration, a, b, c )
        end
    }

    --debugoverlay.Line( bulletTrace.HitPos, bulletTrace.HitPos + bullet.Dir * 100, 10, SERVER and Color( 255, 0, 0 ) or Color( 0, 255, 0 ), true )

    timer.Simple( 0, function()
        attacker:FireBullets( bullet )
    end )

    return true
end

--[[---------------------------------------------------------
   Name: SWEP:ShootBullet()
   Desc: A convenience func to shoot bullets.
-------------------------------------------------------]]
local shotBiasMin  = GetConVar( "ai_shot_bias_min" ):GetFloat()
local shotBiasMax  = GetConVar( "ai_shot_bias_max" ):GetFloat()

local function getSpread( dir, vec )
    local right = dir:Angle():Right()
    local up = dir:Angle():Up()

    local x, y, z
    local bias = 1

    local shotBias = ( ( shotBiasMax - shotBiasMin ) * bias ) + shotBiasMin
    local flatness = math.abs( bias ) * 0.5

    local s = 0
    local function getRnd()
        s = s + 1
        return util.SharedRandom( "m9k_spread_" .. CurTime(), -1, 1, s )
    end

    for _ = 1, 1000 do -- Not infinite, just in case
        x = getRnd() * flatness + getRnd() * ( 1 - flatness )
        y = getRnd() * flatness + getRnd() * ( 1 - flatness )

        if shotBias < 0 then
            x = x >= 0 and 1 - x or -1 - x
            y = y >= 0 and 1 - y or -1 - y
        end

        z = x * x + y * y
        if z <= 1 then break end
    end

    return ( dir + x * vec.x * right + y * vec.y * up ):GetNormalized()
end

function SWEP:ShootBullet( damage, bulletCount, aimcone )
    bulletCount = bulletCount or 1
    aimcone = aimcone or 0

    local owner = self:GetOwner()
    local bulletDir = ( owner:GetAimVector():Angle() + owner:GetViewPunchAngles() ):Forward()
    local tracer = self.Tracer or "Tracer"

    local bullet
    if bulletCount > 1 then -- Shotguns, otherwise we'd have to fire each bullet individually
        bullet = {
            Num = bulletCount,
            Src = owner:GetShootPos(),
            Dir = bulletDir,
            Spread = Vector( aimcone, aimcone, 0 ),
            Tracer = 3,
            TracerName = tracer,
            Force = damage * 0.25,
            Damage = damage,
            Callback = function( attacker, tracedata, dmginfo )
                if not IsValid( self ) then return end
                self:BulletCallback( 0, attacker, tracedata, dmginfo )
            end
        }
    else
        local spreadDir = getSpread( bulletDir, Vector( aimcone, aimcone, 0 ) )
        bullet = {
            Num = bulletCount,
            Src = owner:GetShootPos(),
            Dir = spreadDir,
            Spread = Vector( 0, 0, 0 ),
            Tracer = 3,
            TracerName = tracer,
            Force = damage * 0.25,
            Damage = damage,
            Callback = function( attacker, tracedata, dmginfo )
                if not IsValid( self ) then return end
                self:BulletCallback( 0, attacker, tracedata, dmginfo )
            end
        }
    end

    if IsValid( owner ) then
        owner:FireBullets( bullet )
    end

    local x = util.SharedRandom( "m9k_viewpunch", -self.Primary.KickDown, -self.Primary.KickUp * self.KickUpMultiplier, 100 )
    local y = util.SharedRandom( "m9k_viewpunch", -self.Primary.KickHorizontal, self.Primary.KickHorizontal, 200 )
    local anglo1 = Angle( x, y, 0 )

    if self:GetIronsightsActive() and not self.Scoped then
        anglo1 = anglo1 * 0.5
    end

    owner:ViewPunch( anglo1 )

    if SERVER and game.SinglePlayer() and not owner:IsNPC() then
        local offlineeyes = owner:EyeAngles()
        offlineeyes.pitch = offlineeyes.pitch + anglo1.pitch
        offlineeyes.yaw = offlineeyes.yaw + anglo1.yaw
        if GetConVar( "M9KDynamicRecoil" ):GetBool() then
            owner:SetEyeAngles( offlineeyes )
        end
    end

    if CLIENT and not game.SinglePlayer() and not owner:IsNPC() then
        -- case 1 old random
        local eyes = owner:EyeAngles()
        eyes.pitch = eyes.pitch + ( anglo1.pitch / 3 )
        eyes.yaw = eyes.yaw + ( anglo1.yaw / 3 )
        if IsFirstTimePredicted() and GetConVar( "M9KDynamicRecoil" ):GetBool() then
            owner:SetEyeAngles( eyes )
        end
    end
end

function SWEP:SecondaryAttack()
    return false
end

function SWEP:Reload()
    if self:GetReloading() then return end
    if self:Clip1() >= self.Primary.ClipSize then return end

    if self:GetIronsights() then
        self:SetIronsights( false )
        return
    end

    if self:GetOwner():IsNPC() then
        self:DefaultReload( ACT_VM_RELOAD )
        return
    end

    if self:GetOwner():KeyDown( IN_USE ) then return end -- Mode switch

    if self.Silenced then
        self:DefaultReload( ACT_VM_RELOAD_SILENCED )
    else
        self:DefaultReload( ACT_VM_RELOAD )
    end

    if CLIENT then
        self.DrawCrosshair = false
    end

    self:GetOwner():SetFOV( 0, self.IronSightTime )
    self:SetIronsights( false )
    self:SetReloading( true )

    local waitdammit = self:GetOwner():GetViewModel():SequenceDuration()
    timer.Simple( waitdammit, function()
        if not IsValid( self ) then return end
        if not IsValid( self:GetOwner() ) then return end

        self:SetReloading( false )

        if self:GetOwner():KeyDown( IN_ATTACK2 ) and self.Scoped == false then
            self:GetOwner():SetFOV( self.Secondary.IronFOV, self.IronSightTime )
            self.IronSightsPos = self.SightsPos -- Bring it up
            self.IronSightsAng = self.SightsAng -- Bring it up
            self:SetIronsights( true )
            if CLIENT then
                self.DrawCrosshair = false
            end

            return
        end

        if self:GetOwner():KeyDown( IN_SPEED ) then
            if self:GetNextPrimaryFire() <= CurTime() + .03 then
                self:SetNextPrimaryFire( CurTime() + self.IronSightTime ) -- Make it so you can't shoot for another quarter second
            end
            self.IronSightsPos = self.RunSightsPos -- Hold it down
            self.IronSightsAng = self.RunSightsAng -- Hold it down
            self:SetIronsights( true )
            self:GetOwner():SetFOV( 0, self.IronSightTime )
            return
        end

        if CLIENT then
            self.DrawCrosshair = self.OrigCrossHair
        end
    end )
end

function SWEP:Silencer()
    if self.NextSilence > CurTime() then return end

    self:GetOwner():SetFOV( 0, self.IronSightTime )
    self:SetIronsights( false )
    self:SetReloading( true ) -- i know we're not reloading but it works

    if self.Silenced then
        self:SendWeaponAnim( ACT_VM_DETACH_SILENCER )
        self.Silenced = false
    elseif not self.Silenced then
        self:SendWeaponAnim( ACT_VM_ATTACH_SILENCER )
        self.Silenced = true
    end

    local siltimer = CurTime() + self:GetOwner():GetViewModel():SequenceDuration() + 0.1
    if self:GetNextPrimaryFire() <= siltimer then
        self:SetNextPrimaryFire( siltimer )
    end
    self.NextSilence = siltimer

    timer.Simple( self:GetOwner():GetViewModel():SequenceDuration() + 0.1, function()
        if not IsValid( self ) then return end
        if not IsValid( self:GetOwner() ) then return end
        self:SetReloading( false )
        if self:GetOwner():KeyDown( IN_ATTACK2 ) then
            if CLIENT then return end
            if self.Scoped == false then
                self:GetOwner():SetFOV( self.Secondary.IronFOV, self.IronSightTime )
                self.IronSightsPos = self.SightsPos -- Bring it up
                self.IronSightsAng = self.SightsAng -- Bring it up
                self:SetIronsights( true )
                self.DrawCrosshair = false
            else
                return
            end
        elseif self:GetOwner():KeyDown( IN_SPEED ) then
            if self:GetNextPrimaryFire() <= CurTime() + self.IronSightTime then
                self:SetNextPrimaryFire( CurTime() + self.IronSightTime ) -- Make it so you can't shoot for another quarter second
            end

            self.IronSightsPos = self.RunSightsPos -- Hold it down
            self.IronSightsAng = self.RunSightsAng -- Hold it down
            self:SetIronsights( true )
            self:GetOwner():SetFOV( 0, self.IronSightTime )
        else
            return
        end
    end )
end

function SWEP:SelectFireMode()
    if self.Primary.Automatic then
        self.Primary.Automatic = false
        self.NextFireSelect = CurTime() + .5
        if CLIENT then
            self:GetOwner():PrintMessage( HUD_PRINTTALK, "Semi-automatic selected." )
        end
        self:EmitSound( "Weapon_AR2.Empty" )
    else
        self.Primary.Automatic = true
        self.NextFireSelect = CurTime() + .5
        if CLIENT then
            self:GetOwner():PrintMessage( HUD_PRINTTALK, "Automatic selected." )
        end
        self:EmitSound( "Weapon_AR2.Empty" )
    end
end

function SWEP:IronSight()
    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    local selfTbl = entity_GetTable( self )
    if not owner:IsNPC() and selfTbl.ResetSights and CurTime() >= selfTbl.ResetSights then
        selfTbl.ResetSights = nil

        if selfTbl.Silenced then
            self:SendWeaponAnim( ACT_VM_IDLE_SILENCED )
        else
            self:SendWeaponAnim( ACT_VM_IDLE )
        end
    end

    local pressingE = owner:KeyDown( IN_USE )
    local pressingM2 = owner:KeyDown( IN_ATTACK2 )

    if selfTbl.CanBeSilenced and selfTbl.NextSilence < CurTime() and pressingE and pressingM2 then
        self:Silencer()
        return
    end

    if selfTbl.SelectiveFire and selfTbl.NextFireSelect < CurTime() and not self:GetReloading() and pressingE and owner:KeyPressed( IN_RELOAD ) then
        self:SelectFireMode()
        return
    end

    -- Set run effect
    if owner:KeyPressed( IN_SPEED ) and not self:GetReloading() then
        if self:GetNextPrimaryFire() <= ( CurTime() + self.IronSightTime ) then
            self:SetNextPrimaryFire( CurTime() + self.IronSightTime )
        end
        selfTbl.IronSightsPos = selfTbl.RunSightsPos
        selfTbl.IronSightsAng = selfTbl.RunSightsAng
        self:SetIronsights( true )
        owner:SetFOV( 0, self.IronSightTime )
        selfTbl.DrawCrosshair = false
    end

    -- Unset run effect
    if owner:KeyReleased( IN_SPEED ) then
        self:SetIronsights( false )
        owner:SetFOV( 0, self.IronSightTime )
        selfTbl.DrawCrosshair = selfTbl.OrigCrossHair
    end

    -- Set iron sights
    if not owner:KeyDown( IN_SPEED ) and owner:KeyPressed( IN_ATTACK2 ) and not self:GetReloading() then
        owner:SetFOV( selfTbl.Secondary.IronFOV, self.IronSightTime )
        selfTbl.IronSightsPos = selfTbl.SightsPos
        selfTbl.IronSightsAng = selfTbl.SightsAng
        self:SetIronsights( true )
        selfTbl.DrawCrosshair = false
    end

    -- Unset iron sights
    if owner:KeyReleased( IN_ATTACK2 ) and not owner:KeyDown( IN_SPEED ) then
        owner:SetFOV( 0, self.IronSightTime )
        selfTbl.DrawCrosshair = selfTbl.OrigCrossHair
        self:SetIronsights( false )
    end

    if pressingM2 and not pressingE and not owner:KeyDown( IN_SPEED ) then
        selfTbl.SwayScale = 0.05
        selfTbl.BobScale  = 0.05
    else
        selfTbl.SwayScale = 1.0
        selfTbl.BobScale  = 1.0
    end

    if ( not CLIENT ) or ( not IsFirstTimePredicted() and not game.SinglePlayer() ) then return end
    self.bIron = self:GetIronsightsActive()
    self.fIronTime = self:GetIronsightsTime()
    self.CurrentTime = CurTime()
    self.CurrentSysTime = SysTime()
end

--[[---------------------------------------------------------
Think
-------------------------------------------------------]]
function SWEP:Think()
    self:IronSight()
end

--[[---------------------------------------------------------
GetViewModelPosition
-------------------------------------------------------]]
local host_timescale = GetConVar( "host_timescale" )
function SWEP:GetViewModelPosition( pos, ang )
    local selfTable = entity_GetTable( self )

    local bIron = selfTable.bIron
    if not selfTable.IronSightsPos or bIron == nil then return pos, ang end

    local time = selfTable.CurrentTime + ( SysTime() - selfTable.CurrentSysTime ) * game.GetTimeScale() * host_timescale:GetFloat()
    local fIronTime = selfTable.fIronTime
    local ironSightsTime = selfTable.IronSightTime

    if ( not bIron ) and fIronTime < time - ironSightsTime then
       return pos, ang
    end

    local mul = 1.0
    if fIronTime > time - ironSightsTime then
       mul = math.Clamp( ( time - fIronTime ) / ironSightsTime, 0, 1 )

       if not bIron then mul = 1 - mul end
    end

    local Offset = selfTable.IronSightsPos

    if selfTable.IronSightsAng then
        ang = ang * 1
        ang:RotateAroundAxis( ang:Right(), selfTable.IronSightsAng.x * mul )
        ang:RotateAroundAxis( ang:Up(), selfTable.IronSightsAng.y * mul )
        ang:RotateAroundAxis( ang:Forward(), selfTable.IronSightsAng.z * mul )
    end

    local Right = ang:Right()
    local Up = ang:Up()
    local Forward = ang:Forward()

    pos = pos + Offset.x * Right * mul
    pos = pos + Offset.y * Forward * mul
    pos = pos + Offset.z * Up * mul

    if self.RecoilAmount > 0 then
        local forward = ang:Forward()
        local recoilOffset = forward * -self.RecoilAmount
        pos = pos + recoilOffset
        self.RecoilAmount = Lerp( math.ease.OutCubic( FrameTime() * self.RecoilRecoverySpeed ), self.RecoilAmount, 0 )
    end

    return pos, ang
end

if CLIENT then
    local entity_ManipulateBoneScale = entMeta.ManipulateBoneScale
    local entity_ManipulateBoneAngles = entMeta.ManipulateBoneAngles
    local entity_ManipulateBonePosition = entMeta.ManipulateBonePosition

    local zeroVector = Vector( 0, 0, 0 )
    local zeroAngle = Angle( 0, 0, 0 )
    local oneVector = Vector( 1, 1, 1 )

    function SWEP:SetupWepSelectIcon()
        if self:GetOwner() ~= LocalPlayer() then return end

        local stored = weapons.GetStored( self:GetClass() )
        if not stored.WepSelectIconMaterial then
            local path = self.WeaponIconPath and self.WeaponIconPath or "vgui/hud/" .. self:GetClass()
            stored.WepSelectIconMaterial = Material( path )
        end

        self.WepSelectIconMaterial = stored.WepSelectIconMaterial
    end

    function SWEP:DrawWeaponSelection( x, y, wide, _tall, alpha )
        -- Set us up the texture
        surface.SetDrawColor( 255, 255, 255, alpha )
        if self.WepSelectIconMaterial then
            surface.SetMaterial( self.WepSelectIconMaterial )
        else
            self:SetupWepSelectIcon()
            surface.SetTexture( surface.GetTextureID( "weapons/swep" ) )
        end

        -- Borders
        y = y + 10
        x = x + 10
        wide = wide - 20

        -- Draw that mother
        surface.DrawTexturedRect( x, y,  wide, wide / 2 )
    end

    SWEP.vRenderOrder = nil
    function SWEP:ViewModelDrawn()
        local owner = self:GetOwner()
        if not IsValid( owner ) then return end
        local vm = owner:GetViewModel()
        if not IsValid( vm ) then return end

        local selfTable = entity_GetTable( self )
        if not selfTable.VElements then return end

        self:UpdateBonePositions( vm )

        if not selfTable.vRenderOrder then
            -- -- we build a render order because sprites need to be drawn after models
            selfTable.vRenderOrder = {}

            for k, v in pairs( selfTable.VElements ) do
                if v.type == "Model" then
                    table.insert( selfTable.vRenderOrder, 1, k )
                elseif v.type == "Sprite" or v.type == "Quad" then
                    table.insert( selfTable.vRenderOrder, k )
                end
            end
        end

        for _, name in ipairs( selfTable.vRenderOrder ) do
            local v = selfTable.VElements[name]
            if not v then
                selfTable.vRenderOrder = nil
                break
            end
            if v.hide then continue end

            local model = v.modelEnt
            local sprite = v.spriteMaterial

            if not v.bone then continue end

            local pos, ang = self:GetBoneOrientation( selfTable.VElements, v, vm )

            if not pos then continue end

            if v.type == "Model" and IsValid( model ) then
                model:SetPos( pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
                ang:RotateAroundAxis( ang:Up(), v.angle.y )
                ang:RotateAroundAxis( ang:Right(), v.angle.p )
                ang:RotateAroundAxis( ang:Forward(), v.angle.r )

                model:SetAngles( ang )
                -- --model:SetModelScale(v.size)
                local matrix = Matrix()
                matrix:Scale( v.size )
                model:EnableMatrix( "RenderMultiply", matrix )

                if v.material == "" then
                    model:SetMaterial( "" )
                elseif model:GetMaterial() ~= v.material then
                    model:SetMaterial( v.material )
                end

                if v.skin and v.skin ~= model:GetSkin() then
                    model:SetSkin( v.skin )
                end

                if v.bodygroup then
                    for k, v in pairs( v.bodygroup ) do
                        if model:GetBodygroup( k ) ~= v then
                            model:SetBodygroup( k, v )
                        end
                    end
                end

                if v.surpresslightning then
                    render.SuppressEngineLighting( true )
                end

                render.SetColorModulation( v.color.r / 255, v.color.g / 255, v.color.b / 255 )
                render.SetBlend( v.color.a / 255 )
                model:DrawModel()
                render.SetBlend( 1 )
                render.SetColorModulation( 1, 1, 1 )

                if v.surpresslightning then
                    render.SuppressEngineLighting( false )
                end
            elseif v.type == "Sprite" and sprite then
                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                render.SetMaterial( sprite )
                render.DrawSprite( drawpos, v.size.x, v.size.y, v.color )
            elseif v.type == "Quad" and v.draw_func then
                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                ang:RotateAroundAxis( ang:Up(), v.angle.y )
                ang:RotateAroundAxis( ang:Right(), v.angle.p )
                ang:RotateAroundAxis( ang:Forward(), v.angle.r )

                cam.Start3D2D( drawpos, ang, v.size )
                v.draw_func( self )
                cam.End3D2D()
            end
        end
    end

    SWEP.wRenderOrder = nil
    function SWEP:DrawWorldModel()
        local selfTbl = entity_GetTable( self )
        if selfTbl.ShowWorldModel == nil or selfTbl.ShowWorldModel then
            self:DrawModel()
        end

        if not selfTbl.WElements then return end

        if not selfTbl.wRenderOrder then
            selfTbl.wRenderOrder = {}

            for k, v in pairs( selfTbl.WElements ) do
                if v.type == "Model" then
                    table.insert( selfTbl.wRenderOrder, 1, k )
                elseif v.type == "Sprite" or v.type == "Quad" then
                    table.insert( selfTbl.wRenderOrder, k )
                end
            end
        end

        if IsValid( self:GetOwner() ) then
            bone_ent = self:GetOwner()
        else
            -- -- when the weapon is dropped
            bone_ent = self
        end

        for _, name in pairs( selfTbl.wRenderOrder ) do
            local v = selfTbl.WElements[name]
            if not v then
                selfTbl.wRenderOrder = nil
                break
            end
            if v.hide then continue end

            local pos, ang

            if v.bone then
                pos, ang = self:GetBoneOrientation( selfTbl.WElements, v, bone_ent )
            else
                pos, ang = self:GetBoneOrientation( selfTbl.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
            end

            if not pos then continue end

            local model = v.modelEnt
            local sprite = v.spriteMaterial

            if v.type == "Model" and IsValid( model ) then
                model:SetPos( pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
                ang:RotateAroundAxis( ang:Up(), v.angle.y )
                ang:RotateAroundAxis( ang:Right(), v.angle.p )
                ang:RotateAroundAxis( ang:Forward(), v.angle.r )

                model:SetAngles( ang )
                -- --model:SetModelScale(v.size)
                local matrix = Matrix()
                matrix:Scale( v.size )
                model:EnableMatrix( "RenderMultiply", matrix )

                if v.material == "" then
                    model:SetMaterial( "" )
                elseif model:GetMaterial() ~= v.material then
                    model:SetMaterial( v.material )
                end

                if v.skin and v.skin ~= model:GetSkin() then
                    model:SetSkin( v.skin )
                end

                if v.bodygroup then
                    for k, v in pairs( v.bodygroup ) do
                        if model:GetBodygroup( k ) ~= v then
                            model:SetBodygroup( k, v )
                        end
                    end
                end

                if v.surpresslightning then
                    render.SuppressEngineLighting( true )
                end

                render.SetColorModulation( v.color.r / 255, v.color.g / 255, v.color.b / 255 )
                render.SetBlend( v.color.a / 255 )
                model:DrawModel()
                render.SetBlend( 1 )
                render.SetColorModulation( 1, 1, 1 )

                if v.surpresslightning then
                    render.SuppressEngineLighting( false )
                end
            elseif v.type == "Sprite" and sprite then
                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                render.SetMaterial( sprite )
                render.DrawSprite( drawpos, v.size.x, v.size.y, v.color )
            elseif v.type == "Quad" and v.draw_func then
                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                ang:RotateAroundAxis( ang:Up(), v.angle.y )
                ang:RotateAroundAxis( ang:Right(), v.angle.p )
                ang:RotateAroundAxis( ang:Forward(), v.angle.r )

                cam.Start3D2D( drawpos, ang, v.size )
                v.draw_func( self )
                cam.End3D2D()
            end
        end
    end

    function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
        local bone, pos, ang
        if tab.rel and tab.rel ~= "" then
            local v = basetab[tab.rel]

            if not v then return end

            -- -- Technically, if there exists an element with the same name as a bone
            -- -- you can get in an infinite loop. Let's just hope nobody's that stupid.
            pos, ang = self:GetBoneOrientation( basetab, v, ent )
            if not pos then return end

            pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            ang:RotateAroundAxis( ang:Up(), v.angle.y )
            ang:RotateAroundAxis( ang:Right(), v.angle.p )
            ang:RotateAroundAxis( ang:Forward(), v.angle.r )
        else
            bone = ent:LookupBone( bone_override or tab.bone )

            if not bone then return end

            pos, ang = Vector( 0, 0, 0 ), Angle( 0, 0, 0 )
            local m = ent:GetBoneMatrix( bone )
            if m then
                pos, ang = m:GetTranslation(), m:GetAngles()
            end

            if IsValid( self:GetOwner() ) and self:GetOwner():IsPlayer() and ent == self:GetOwner():GetViewModel() and self.ViewModelFlip then
                ang.r = -ang.r ---- Fixes mirrored models
            end
        end

        return pos, ang
    end

    function SWEP:CreateModels( tab )
        if not tab then return end

        -- -- Create the clientside models here because Garry says we can't do it in the render hook
        for _, v in pairs( tab ) do
            if (v.type == "Model" and v.model and v.model ~= "" and (! IsValid( v.modelEnt ) or v.createdModel ~= v.model) and
                    string.find( v.model, ".mdl" ) and file.Exists( v.model, "GAME" )) then
                v.modelEnt = ClientsideModel( v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE )
                if (IsValid( v.modelEnt )) then
                    v.modelEnt:SetPos( self:GetPos() )
                    v.modelEnt:SetAngles( self:GetAngles() )
                    v.modelEnt:SetParent( self )
                    v.modelEnt:SetNoDraw( true )
                    v.createdModel = v.model
                else
                    v.modelEnt = nil
                end
            elseif (v.type == "Sprite" and v.sprite and v.sprite ~= "" and (! v.spriteMaterial or v.createdSprite ~= v.sprite)
                    and file.Exists( "materials/" .. v.sprite .. ".vmt", "GAME" )) then
                local name = v.sprite .. "-"
                local params = { ["$basetexture"] = v.sprite }
                -- -- make sure we create a unique name based on the selected options
                local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
                for i, j in pairs( tocheck ) do
                    if (v[j]) then
                        params["$" .. j] = 1
                        name = name .. "1"
                    else
                        name = name .. "0"
                    end
                end
                v.createdSprite = v.sprite
                v.spriteMaterial = CreateMaterial( name, "UnlitGeneric", params )
            end
        end
    end

    local allbones
    local hasGarryFixedBoneScalingYet = false

    function SWEP:UpdateBonePositions( vm )
        if self.ViewModelBoneMods then
            if (not vm:GetBoneCount()) then return end

            -- -- !! WORKAROUND !! ----
            -- -- We need to check all model names :/
            local loopthrough = self.ViewModelBoneMods
            if (not hasGarryFixedBoneScalingYet) then
                allbones = {}
                for i = 0, vm:GetBoneCount() do
                    local bonename = vm:GetBoneName( i )
                    if (self.ViewModelBoneMods[bonename]) then
                        allbones[bonename] = self.ViewModelBoneMods[bonename]
                    else
                        allbones[bonename] = {
                            scale = Vector( 1, 1, 1 ),
                            pos = Vector( 0, 0, 0 ),
                            angle = Angle( 0, 0, 0 )
                        }
                    end
                end

                loopthrough = allbones
            end
            --!! ----------- !! --

            for k, v in pairs( loopthrough ) do
                local bone = vm:LookupBone( k )
                if (not bone) then continue end

                -- -- !! WORKAROUND !! ----
                local s = Vector( v.scale.x, v.scale.y, v.scale.z )
                local p = Vector( v.pos.x, v.pos.y, v.pos.z )
                local ms = Vector( 1, 1, 1 )
                if (not hasGarryFixedBoneScalingYet) then
                    local cur = vm:GetBoneParent( bone )
                    while (cur >= 0) do
                        local pscale = loopthrough[vm:GetBoneName( cur )].scale
                        ms = ms * pscale
                        cur = vm:GetBoneParent( cur )
                    end
                end

                s = s * ms
                --!! ----------- !! --

                if vm:GetManipulateBoneScale( bone ) ~= s then
                    vm:ManipulateBoneScale( bone, s )
                end
                if vm:GetManipulateBoneAngles( bone ) ~= v.angle then
                    vm:ManipulateBoneAngles( bone, v.angle )
                end
                if vm:GetManipulateBonePosition( bone ) ~= p then
                    vm:ManipulateBonePosition( bone, p )
                end
            end
        else
            self:ResetBonePositions( vm )
        end
    end

    function SWEP:ResetBonePositions( vm )
        local vmBones = vm:GetBoneCount()
        if not vmBones then return end
        for i = 0, vmBones do
            entity_ManipulateBoneScale( vm, i, oneVector )
            entity_ManipulateBoneAngles( vm, i, zeroAngle )
            entity_ManipulateBonePosition( vm, i, zeroVector )
        end
    end

    --[[*************************
            Global utility code
    *************************--]]

    -- -- Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
    -- -- Does not copy entities of course, only copies their reference.
    -- -- WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
    function table.FullCopy( tab )
        if (not tab) then return nil end

        local res = {}
        for k, v in pairs( tab ) do
            if (type( v ) == "table") then
                res[k] = table.FullCopy( v ) ---- recursion ho!
            elseif (type( v ) == "Vector") then
                res[k] = Vector( v.x, v.y, v.z )
            elseif (type( v ) == "Angle") then
                res[k] = Angle( v.p, v.y, v.r )
            else
                res[k] = v
            end
        end

        return res
    end
end
