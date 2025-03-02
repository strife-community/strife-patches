# Entities
## Introduction
What is entity? Pretty much everything in the game: heroes, pets and other units, their abilities, states they set, projectiles they throw. Everything moving, everything changing values, everything storing information. Enitity is a foundational building block for Strife. All entities has similar structure and mostly they use same elements to describe their behavior.
Entities are described by files with .entity extension. Those are .xml files with extension changed. An entity file structure follows this general hierarchy:
- Entity Type: The root element defines the entity's category (e.g., `<hero>`, `<item>`).
- Events: Nested within the entity, events like `<ondeath>`, `<onframe>`, `<onspawn>`, or `<onupgrade>` represent triggers tied to in-game or system conditions.
- Actions: Inside each event, one or more action elements specify the operations to perform when the event occurs, such as spawning an object, dealing damage, modifying stats, or playing an visual or sound effect.

## Entity types
### Entities hierarchy (children inherit all attributes of their parents):
- [affector](#affector)
- [game](#game)
- [linearaffector](#linearaffector)
- order (can't be created from xml)
- [projectile](#projectile)
- [slave](#slave) (can't be created from xml)
    - [state](#state)
        - [statenetaccum](#statenetaccum)
    - [tool](#tool) (can't be created from xml)
        - [ability](#ability)
            - [proxyability](#proxyability)
            - [abilityattribute](#abilityattribute)
        - [item](#item)
            - [qualityitem](#qualityitem)
                - [crafteditem](#crafteditem)
- [spawner](#spawner)
- [unit](#unit)
    - bit (can't be created from xml)
    - [building](#building)
    - [creep](#creep)
    - [critter](#critter)
    - [familiar](#familiar)
    - [gadget](#gadget)
        - [attachablegadget](#attachablegadget)
    - [hero](#hero)
        - [heropet](#heropet)
    - [neutral](#neutral)
        - [neutralboss](#neutralboss)
    - [pet](#pet)
    - [powerup](#powerup)
- [waypoint](#waypoint)

### affector
| attribute name | valid value | default value | description |
|---|---|---|---|
| radius |  | - |  |
| arc |  | - |  |
| angle |  | - |  |
| speed |  | - |  |
| innerradiusoffset |  | - |  |
| hazardradius |  | - |  |
| hazardthreat |  | - |  |
| serverentity |  | - |  |
| lifetime |  | - |  |
| impactdelay |  | - |  |
| impactinterval |  | - |  |
| maxintervals |  | - |  |
| maxtotalimpacts |  | - |  |
| maximpactsperinterval |  | - |  |
| maximpactspertarget |  | - |  |
| maximpactspertargetperinterval |  | 1 |  |
| targetselection |  | - |  |
| targetscheme |  | - |  |
| effecttype |  | - |  |
| ignoreinvulnerable |  | - |  |
| persist |  | - |  |
| destroytrees |  | - |  |
| visibility |  | - |  |
| canturn, true |  | - |  |
| touchpropradius |  | -1.0 |  |
| touchpropanim |  | - |  |
| sightedradius |  | 0.f |  |
| effect |  | - |  |
| impacteffect |  | - |  |
| bridgeeffect |  | - |  |
| linkeffect |  | - |  |

### game
| attribute name | valid value | default value | description |
|---|---|---|---|
| startinggold |  | - |  |
| repickcost |  | - |  |
| randombonus |  | - |  |
| heropoolsize |  | - |  |
| extratime |  | - |  |
| goldpertick |  | - |  |
| incomeinterval |  | - |  |
| experiencemultiplier |  | - |  |
| towerdenygoldmultiplier |  | - |  |
| nolobby |  | - |  |
| noheroselect |  | - |  |
| nodev |  | - |  |
| allowpotentialpick |  | - |  |
| bots |  | - |  |
| roundwinsforvictory |  | - |  |
| respawnsperround |  | -1 |  |

### linearaffector
| attribute name | valid value | default value | description |
|---|---|---|---|
| radius |  | - |  |
| minlength |  | - |  |
| maxlength |  | - |  |
| serverentity |  | - |  |
| lifetime |  | - |  |
| impactdelay |  | - |  |
| impactinterval |  | - |  |
| maxintervals |  | - |  |
| maxtotalimpacts |  | - |  |
| maximpactsperinterval |  | - |  |
| maximpactspertarget |  | - |  |
| maximpactspertargetperinterval |  | 1 |  |
| subsegmentoffset |  | - |  |
| subsegmentlength |  | - |  |
| targetselection |  | - |  |
| targetscheme |  | - |  |
| effecttype |  | - |  |
| ignoreinvulnerable |  | - |  |
| persist |  | - |  |
| destroytrees |  | - |  |
| visibility |  | - |  |
| effect |  | - |  |
| impacteffect |  | - |  |
| bridgeeffect |  | - |  |
| linkeffect |  | - |  |

### projectile
| attribute name | valid value | default value | description |
|---|---|---|---|
| serverentity |  | - |  |
| inheritvisibilityfromowner |  | - |  |
| inheritvisibilityfromtarget |  | - |  |
| speed |  | - |  |
| acceleration |  | - |  |
| minspeed |  | - |  |
| maxspeed |  | - |  |
| gravity |  | - |  |
| arc |  | - |  |
| lifetime |  | - |  |
| model |  | - |  |
| traileffect |  | - |  |
| deatheffect |  | - |  |
| impacteffect |  | - |  |
| invalideffect |  | - |  |
| modelscale |  | 1.0 |  |
| effectscale |  | 1.0 |  |
| canturn |  | true |  |
| useexactlifetime |  | - |  |
| flying |  | - |  |
| pathing |  | - |  |
| range |  | - |  |
| flyheight |  | - |  |
| touchradius |  | - |  |
| touchpropradius |  | -1.0 |  |
| touchpropanim |  | - |  |
| touchradiusdiradjust |  | - |  |
| touchtargetscheme |  | - |  |
| touchtargetactivescheme |  | - |  |
| touchowneractivescheme |  | - |  |
| toucheffecttype |  | - |  |
| touchignoreinvulnerable |  | - |  |
| maxtouches |  | - |  |
| maxtouchespertarget |  | - |  |
| dieonmaxtouches |  | - |  |
| dieonmaxtouchespertarget |  | - |  |
| touchcliffs |  | - |  |
| touchprojectileblockers |  | - |  |
| initialcharges |  | - |  |
| maxcharges |  | - |  |
| impactdistance |  | - |  |
| noimpactstealth |  | - |  |
| curve |  | - |  |
| orbit |  | - |  |
| orbitclockwise |  | - |  |
| orbitradius |  | - |  |
| orbitspeed |  | - |  |
| orbitacceleration |  | - |  |
| orbitmainspeed |  | - |  |
| orbitmaxspeed |  | - |  |
| orbitmaxtouches |  | - |  |
| orbitmaxtouchespertarget |  | - |  |
| orbitdieonmaxtouches |  | - |  |
| orbitdieonmaxtouchespertarget |  | - |  |
| orbitmodelangles |  | - |  |
| orbitfollowz |  | - |  |
| bindcountsformovement |  | - |  |
| disjointable |  | true |  |
| homing |  | - |  |
| homingturnspeed |  | - |  |
| homingseekrange |  | - |  |
| homingspeedmul |  | - |  |
| homingunlockrange |  | - |  |
| hominglocktarget |  | - |  |
| homingseekstealth |  | - |  |
| homingtargetscheme |  | - |  |
| unitwalking |  | true |  |
| treewalking |  | - |  |
| cliffwalking |  | - |  |
| buildingwalking |  | - |  |
| noentercombat |  | - |  |
| bindpriority |  | - |  |
| hazardradius |  | - |  |
| hazardthreat |  | - |  |
| hazardoffset |  | - |  |
| sightedradius |  | 0.f |  |

### slave
| attribute name | valid value | default value | description |
|---|---|---|---|
| unittype |  | - |  |
| icon |  | - |  |
| mapicon |  | - |  |
| mapiconcolor |  | - |  |
| passiveeffect |  | - |  |
| forceanim |  | - |  |
| strength |  | - |  |
| agility |  | - |  |
| intelligence |  | - |  |
| maxhealth |  | - |  |
| maxhealthmultiplier |  | - |  |
| healthregen |  | - |  |
| basehealthregen |  | - |  |
| healthproportionregen |  | - |  |
| healthregenmultiplier |  | - |  |
| healthregenmultiplier2 |  | - |  |
| healthregenpercent |  | - |  |
| maxmana |  | - |  |
| maxmanamultiplier |  | - |  |
| manaregen |  | - |  |
| basemanaregen |  | - |  |
| manaproportionregen |  | - |  |
| manaregenmultiplier |  | - |  |
| manaregenmultiplier2 |  | - |  |
| manaregenpercent |  | - |  |
| armor |  | - |  |
| magicarmor |  | - |  |
| mitigation |  | - |  |
| resistance |  | - |  |
| attacklifesteal |  | - |  |
| magiclifesteal |  | - |  |
| abilitymulitplier |  | - |  |
| deflection |  | - |  |
| deflectionchance |  | - |  |
| incomingdamagemultiplier |  | - |  |
| debuffdurationmultiplier |  | - |  |
| stunneddurationmultiplier |  | - |  |
| healmultiplier |  | - |  |
| attackspeed |  | - |  |
| attackspeedmultiplier |  | - |  |
| attackspeedslow |  | - |  |
| baseattackspeed |  | - |  |
| baseattackspeedmultiplier |  | - |  |
| baseattackspeedslow |  | - |  |
| castspeed |  | - |  |
| cooldownspeed |  | - |  |
| reducedcooldowns |  | - |  |
| increasedcooldowns |  | - |  |
| movespeed |  | - |  |
| minmovespeed |  | - |  |
| maxmovespeed |  | - |  |
| movespeedmultiplier |  | - |  |
| slowresistance |  | - |  |
| movespeedslow |  | - |  |
| damage |  | - |  |
| basedamage |  | - |  |
| basedamagemultiplier |  | - |  |
| totaldamagemultiplier |  | - |  |
| attackrange |  | - |  |
| attackrangemultiplier |  | - |  |
| lifesteal |  | - |  |
| criticalchance |  | - |  |
| criticalmultiplier |  | - |  |
| evasion, ranged, melee |  | - | TheChiprel: need to solve how it works |
| misschance |  | - |  |
| healthregenreduction |  | - |  |
| manaregenreduction |  | - |  |
| stunned |  | - |  |
| stunnedimmunity |  | - |  |
| silenced |  | - |  |
| supersilenced |  | - |  |
| silencedimmunity |  | - |  |
| supersilencedimmunity |  | - |  |
| perplexed |  | - |  |
| perplexedimmunity |  | - |  |
| disarmed |  | - |  |
| disarmedimmunity |  | - |  |
| immobilized |  | - |  |
| immobilizedimmunity |  | - |  |
| immobilized2 |  | - |  |
| restrained |  | - |  |
| restrainedimmunity |  | - |  |
| invulnerable |  | - |  |
| Invulnerablekeeptarget |  | - |  |
| revealed |  | - |  |
| frozen |  | - |  |
| frozenimmunity |  | - |  |
| isolated |  | - |  |
| isolatedimmunity |  | - |  |
| freecast |  | - |  |
| clearvision |  | - |  |
| clearvision2 |  | - |  |
| deniable |  | - |  |
| deniablepercent |  | - |  |
| smackable |  | - |  |
| nothreat |  | - |  |
| truestrike |  | - |  |
| sighted |  | - |  |
| alwaystransmitdata |  | - |  |
| revealtype |  | - |  |
| revealrange |  | - |  |
| stealthtype |  | - |  |
| fadetime |  | - |  |
| stealthproximity |  | - |  |
| immunitytype |  | - |  |
| effecttype |  | - |  |
| itemtype |  | Normal |  |
| invulnerable |  | - |  |
| invulnerablekeeptarget |  | - |  |
| unitwalking |  | - |  |
| treewalking |  | - |  |
| cliffwalking |  | - |  |
| buildingwalking |  | - |  |
| antiwalking |  | - |  |
| shopaccess |  | - |  |
| stashaccess |  | - |  |
| maxcharges |  | -1, 0, 0 | TheChiprel: Check how it works |
| castcharges |  | false |  |
| hidecharges |  | false |  |
| counter |  | - |  |
| defaultactivemodifierkey |  | - |  |
| modifierkey |  | - |  |
| modifierkey2 |  | - |  |
| hidemodel |  | - |  |
| hideshadow |  | - |  |
| hideselectionring |  | - |  |
| hideindicator |  | - |  |
| norender |  | - |  |
| power |  | - |  |
| powermultiplier |  | - |  |
| powerratiomultiplier |  | - |  |
| supportmultiplier |  | - |  |
| purchasetrack |  | - |  |
| propagatetoillusions |  | - |  |
| unitcriticalchance |  | - |  |
| unitcriticalchancemultiplier |  | - |  |
| unitcriticalmultiplier |  | - |  |
| unitcriticalmultipliermultiplier |  | - |  |
| manacostreduction |  | - |  |
| manacostmultiplier |  | 1.0 |  |
| additionalrespawns |  | - |  |

### state
| attribute name | valid value | default value | description |
|---|---|---|---|
| ishidden |  | - |  |
| dispelondamage |  | - |  |
| dispelonaction |  | - |  |
| displaylevel |  | - |  |
| impactinterval |  | - |  |
| morphpriority |  | - |  |
| norefresh |  | - |  |
| deathpersist |  | - |  |
| serverentity |  | - |  |
| copyexperience |  | - |  |
| allowtransfer |  | - |  |
| nodispel |  | - |  |
| animchannel |  | - |  |
| ischanneling |  | - |  |
| ignorechannellinginterrupt |  | - |  |
| channeltime |  | - |  |
| channelrange |  | - |  |
| targetentityvalid |  | - |  |
| targetpositionvalid |  | - |  |
| durationunmodifiable |  | - |  |
| clearnontargetedactions |  | - |  |
| cleartargetedactions |  | - |  |
| allypassiveeffect |  | - |  |
| enemypassiveeffect |  | - |  |
| armor |  | - |  |
| magicarmor |  | - |  |
| mitigation |  | - |  |
| resistance |  | - |  |
| attacklifesteal |  | - |  |
| magiclifesteal |  | - |  |
| abilitymultiplier |  | - |  |
| movespeedslow |  | - |  |
| movespeed |  | - |  |
| minmovespeed |  | - |  |
| maxmovespeed |  | - |  |
| strength |  | - |  |
| agility |  | - |  |
| intelligence |  | - |  |
| maxhealth |  | - |  |
| healthregen |  | - |  |
| healthproportionregen |  | - |  |
| maxmana |  | - |  |
| manaregen |  | - |  |
| manaproportionregen |  | - |  |
| armor |  | - |  |
| magicarmor |  | - |  |
| mitigation |  | - |  |
| Resistance |  | - |  |
| attacklifesteal |  | - |  |
| magiclifesteal |  | - |  |
| abilitymultiplier |  | - |  |
| movespeed |  | - |  |
| minmovespeed |  | - |  |
| maxmovespeed |  | - |  |
| slowresistance |  | - |  |
| attackrange |  | - |  |
| lifesteal |  | - |  |
| healthregenreduction |  | - |  |
| manaregenreduction |  | - |  |
| revealrange |  | - |  |
| unittype |  | - |  |
| icon |  | - |  |
| portrait |  | - |  |
| model |  | - |  |
| mapicon |  | - |  |
| mapiconoutline |  | - |  |
| mapiconcolor |  | - |  |
| mapiconsize |  | - |  |
| skin |  | - |  |
| attackprojectile |  | - |  |
| criticalattackprojectile |  | - |  |
| attacktype |  | - |  |
| attackeffecttype |  | - |  |
| attackdamagetype |  | - |  |
| attackcooldown |  | - |  |
| attackduration |  | - |  |
| attackactiontime |  | - |  |
| attacktargetscheme |  | - |  |
| attacknonlethal |  | - |  |
| threateffecttype |  | - |  |
| threatscheme |  | - |  |
| aggrorange |  | - |  |
| aggroscheme |  | - |  |
| proximityrange |  | - |  |
| proximityscheme |  | - |  |
| leashaggroscheme |  | - |  |
| preglobalscale |  | - |  |
| effectscale |  | - |  |
| modelscale |  | - |  |
| infoheight |  | - |  |
| boundsheight |  | - |  |
| boundsradius |  | - |  |
| sightedradius |  | - |  |
| collisionradius |  | - |  |
| selectionradius |  | - |  |
| isselectable |  | - |  |
| isteamselectable |  | - |  |
| ignoreteamattackcommands |  | - |  |
| ignoreteammovecommands |  | - |  |
| nocorpse |  | - |  |
| attackrangebuffer |  | - |  |
| attackoffset |  | - |  |
| targetoffset |  | - |  |
| attackstarteffect |  | - |  |
| attackactioneffect |  | - |  |
| attackselfactioneffect |  | - |  |
| attackimpacteffect |  | - |  |
| critactioneffect |  | - |  |
| critselfactioneffect |  | - |  |
| critimpacteffect |  | - |  |
| deatheffect |  | - |  |
| passiveeffect |  | - |  |
| spawneffect |  | - |  |
| sightrangeday |  | - |  |
| sightrangenight |  | - |  |
| inventory0 |  | - |  |
| inventory1 |  | - |  |
| inventory2 |  | - |  |
| inventory3 |  | - |  |
| inventory4 |  | - |  |
| inventory5 |  | - |  |
| inventory6 |  | - |  |
| inventory7 |  | - |  |
| inventory8 |  | - |  |
| inventory9 |  | - |  |
| inventory10 |  | - |  |
| inventory11 |  | - |  |
| inventory12 |  | - |  |
| inventory13 |  | - |  |
| inventory14 |  | - |  |
| sharedinventory0 |  | - |  |
| sharedinventory1 |  | - |  |
| sharedinventory2 |  | - |  |
| invulnerable |  | - |  |
| invulnerablekeeptarget |  | - |  |
| clearvision |  | - |  |
| clearvision2 |  | - |  |
| deniable |  | - |  |
| deniablepercent |  | - |  |
| smackable |  | - |  |
| nothreat |  | - |  |
| truestrike |  | - |  |
| alwaystransmitdata |  | - |  |
| unitwalking |  | - |  |
| treewalking |  | - |  |
| cliffwalking |  | - |  |
| buildingwalking |  | - |  |
| antiwalking |  | - |  |
| shopaccess |  | - |  |
| stashaccess |  | - |  |
| defaultbehavior |  | - |  |
| hidemodel |  | - |  |
| hideshadow |  | - |  |
| hideselectionring |  | - |  |
| hideindicator |  | - |  |
| norender |  | - |  |
| power |  | - |  |
| attackdamagemin |  | - |  |
| attackdamagemax |  | - |  |
| basedamage |  | - |  |
| additionalrespawns |  | - |  |
| additionalrespawns |  | - |  |

### statenetaccum
It doesn't have its own attributes.

## tool
| attribute name | valid value | default value | description |
|---|---|---|---|
| areacastmaterial |  | - |  |
| conecastmaterial |  | - |  |
| targetmaterial |  | - |  |
| additionaltargetmaterial |  | - |  |
| targetradius |  | - |  |
| casteffect |  | - |  |
| actioneffect |  | - |  |
| selfactioneffect |  | - |  |
| impacteffect |  | - |  |
| critactioneffect |  | - |  |
| critselfactioneffect |  | - |  |
| critimpacteffect |  | - |  |
| bridgeeffect |  | - |  |
| actiontype |  | - |  |
| maxlevel |  | - |  |
| baselevel |  | - |  |
| nocooldownreduction |  | - |  |
| noentercombat |  | - |  |
| lifetime |  | - |  |
| nohidecursor |  | - |  |
| showlinecast |  | - |  |
| linecastrange |  | - |  |
| linecastmaxrange |  | - |  |
| linecastwidth |  | - |  |
| showareacast |  | - |  |
| additionalareaindicators |  | - |  |
| areacastrange |  | - |  |
| showconecast |  | - |  |
| conecastrange |  | - |  |
| conecastwidth |  | - |  |
| dontshowhovercast |  | - |  |
| hoverareacastrange |  | - |  |
| anim |  | - |  |
| animchannel |  | - |  |
| casttime |  | - |  |
| castactiontime |  | - |  |
| alwaysshowtimer |  | - |  |
| alwaysshowonskillbar |  | - |  |
| ischanneling |  | - |  |
| ignorechannellinginterrupt |  | - |  |
| channeltime |  | - |  |
| manacost |  | - |  |
| toggleoffmanacost |  | - |  |
| activemanacost |  | - |  |
| triggeredmanacost |  | - |  |
| cooldowntime |  | - |  |
| toggleoffcooldowntime |  | - |  |
| cooldownondamage |  | - |  |
| range |  | - |  |
| forcerange |  | - |  |
| minrange |  | - |  |
| forceminrange |  | - |  |
| forcedelta |  | - |  |
| maxdelta |  | - |  |
| rangebuffer |  | 300.0 |  |
| canusewhiledead |  | - |  |
| allowoutofrangecast |  | - |  |
| allowoutofboundscast |  | - |  |
| allowautocast |  | - |  |
| usepathforrange |  | - |  |
| casteffecttype |  | - |  |
| targetscheme |  | - |  |
| ignoreinvulnerable |  | - |  |
| projectile |  | - |  |
| queue |  | - |  |
| inheritmovement |  | false |  |
| statuseffecttooltip |  | - |  |
| statuseffecttooltip2 |  | - |  |
| preferrangeoverradiustooltip |  | - |  |
| useproxy |  | - |  |
| proxytargetscheme |  | - |  |
| proxyeffecttype |  | - |  |
| proxyselectionradius |  | - |  |
| proxyselectionmethod |  | 4 (TARGET_SELECT_RANDOM) |  |
| proxyallowinvulnerable |  | - |  |
| proxytargetmaterial |  | - |  |
| searchradius |  | - |  |
| disabled |  | - |  |
| nostun |  | - |  |
| noquickcast |  | - |  |
| activateimpacttime |  | - |  |
| notargetradius |  | - |  |
| notargetmaterial |  | - |  |
| nocasteffecttype |  | - |  |
| notargetscheme |  | - |  |
| notargetignoreinvulnerable |  | - |  |
| deferchannelcost |  | - |  |
| deferchannelimpact |  | - |  |
| channelrange |  | - |  |
| cooldowntype |  | - |  |
| noninterrupting |  | - |  |
| ignorecooldown |  | - |  |
| autotoggleoffwhendisabled |  | - |  |
| autotoggleoffwithtriggeredmanacost |  | - |  |
| nostopanim |  | - |  |
| noresponse |  | - |  |
| responsetype |  | - |  |
| novoiceresponse |  | - |  |
| needvision |  | - |  |
| noturntotarget |  | - |  |
| activatescheme |  | - |  |
| carryscheme |  | - |  |
| clonescheme |  | - |  |
| chargecost |  | - |  |
| attackeffecttype |  | Attack |  |
| attackdamagetype |  | AttackDamage |  |
| doubleactivate |  | - |  |
| clientuitrigger |  | - |  |
| doubleactivatenoninterrupting |  | - |  |
| norangeclamp |  | - |  |
| ignoredynamicactivation |  | - |  |
| disablesmarttarget |  | - |  |
| ispetultimate |  | - |  |
| defaultvectorrotation |  | -1.0 |  |

### ability
| attribute name | valid value | default value | description |
|---|---|---|---|
| requiredlevel |  | - |  |
| interface |  | - |  |
| subslot |  | 255 (INVALID_INVENTORY_SLOT) |  |
| keyslot |  | 255 (INVALID_INVENTORY_SLOT) |  |
| nosilence |  | - |  |

### proxyability
| attribute name | valid value | default value | description |
|---|---|---|---|
| castfromproxy |  | - |  |

### abilityattribute
It doesn't have its own attributes.

### item
| attribute name | valid value | default value | description |
|---|---|---|---|
| cost |  | - |  |
| costperpurchase |  | - |  |
| initialcharges |  | - |  |
| dropondeath |  | - |  |
| unkillable |  | - |  |
| destroyonempty |  | - |  |
| rechargeable |  | - |  |
| autorecharge |  | - |  |
| nopurchase |  | - |  |
| nosell |  | - |  |
| nostash |  | - |  |
| droppable |  | - |  |
| hidefromall |  | - |  |
| allowdisassemble |  | - |  |
| allowsharing |  | - |  |
| allowtransfer |  | - |  |
| components |  | - |  |
| autoassemble |  | - |  |
| initialstock |  | - |  |
| maxstock |  | - |  |
| restockdelay |  | - |  |
| maxowned |  | - |  |
| new |  | - |  |
| bindonpickup |  | - |  |
| passcharges |  | - |  |
| category |  | - |  |
| noperplex |  | - |  |
| botitem |  | - |  |
| filters |  | - |  |
| tome |  | - |  |
| showinpractice |  | - |  |
| destroyafterround |  | - |  |
| craftingcomponent |  | - |  |
| rarecomponent |  | - |  |
| craftingvalue |  | value of "cost" attribute |  |

### crafteditem
| attribute name | valid value | default value | description |
|---|---|---|---|
| legendaryicon |  | l_icon.tga |  |
| craftingcomponentcost |  | - |  |
| craftingrecipecost |  | value of "cost" attribute |  |
| legendaryeffect |  | - |  |
| empoweredeffects |  | - |  |
| legendaryoverride |  | - |  |

### spawner
| attribute name | valid value | default value | description |
|---|---|---|---|
| lifetime |  | - |  |
| icon |  | - |  |
| iconcolor |  | (1.00, 1.00, 1.00, 1.00) | TheChiprel: find out how to assign value from xml |
| iconsize |  | 1.0 |  |
| iconvisibility |  | - |  |
| alwaysannounceteamless |  | - |  |
| deathannouncementteamless |  | - |  |
| deathannouncementenemyteam |  | - |  |
| deathannouncementownteam |  | - |  |
| firstspawntime |  | 0 |  |
| spawninterval |  | - |  |
| spawnintervalvariation |  | - |  |
| spawnintervalpercharge |  | - |  |
| maxcharges |  | - |  |
| spawntimercondition |  | - |  |
| overrideunitguardrules |  | - |  |
| guardchasetime |  | - |  |
| guardchasedistance |  | - |  |
| guardreaggrochasetime |  | - |  |
| guardreaggrochasedistance |  | - |  |
| aggrorange |  | - |  |
| blockedbyunits |  | - |  |
| blockedbyunitcorpses |  | - |  |
| blockedbyunitsradius |  | - |  |
| pickmethod |  | - |  |
| maxspawnsuntildeath |  | - |  |
| ismanagedbyotherspawner |  | - |  |
| showinui |  | - |  |
| perteamherotapping |  | - |  |
| teamtapping |  | - |  |
| effect |  | - |  |

### unit
| attribute name | valid value | default value | description |
|---|---|---|---|
| unittype |  | - |  |
| icon |  | - |  |
| portrait |  | - |  |
| cutouticon |  | - |  |
| mapicon |  | - |  |
| mapiconoutline |  | - |  |
| mapiconcolor |  | - |  |
| mapiconsize |  | - |  |
| skin |  | - |  |
| model |  | - |  |
| drawonmap |  | true |  |
| hoveronmap |  | true |  |
| partialcontrolshare |  | - |  |
| idleani |  | idle |  |
| nointerpolateposition |  | - |  |
| deniedanim |  | - |  |
| gibanim |  | - |  |
| effectsignorefog |  | - |  |
| passiveeffect |  | - |  |
| spawneffect |  | - |  |
| selectedsound |  | - |  |
| selectedflavorsound |  | - |  |
| confirmmovesound |  | - |  |
| confirmattacksound |  | - |  |
| tauntedsound |  | - |  |
| tauntkillsound |  | - |  |
| nomanasound |  | - |  |
| cooldownsound |  | - |  |
| aggrosound |  | - |  |
| attacksound |  | - |  |
| showaggropopup |  | true |  |
| selectedsoundvolume |  | 1.0 |  |
| selectedflavorsoundvolume |  | 1.0 |  |
| confirmmovesoundvolume |  | 1.0 |  |
| confirmattacksoundvolume |  | 1.0 |  |
| tauntedsoundvolume |  | 1.0 |  |
| tauntkillsoundvolume |  | 1.0 |  |
| nomanasoundvolume |  | 1.0 |  |
| cooldownsoundvolume |  | 1.0 |  |
| rewardsoundself |  | - |  |
| rewardsoundteam |  | - |  |
| rewardsoundenemy |  | - |  |
| preglobalscale |  | 1.0 |  |
| effectscale |  | 1.0 |  |
| modelscale |  | 1.0 |  |
| infoheight |  | - |  |
| boundsradius |  | - |  |
| boundsheight |  | - |  |
| collisionradius |  | - |  |
| selectionradius |  | - |  |
| sightedradius |  | - |  |
| searchradius |  | - |  |
| minsearchradius |  | - |  |
| searchheight |  | - |  |
| isselectable |  | true |  |
| isteamselectable |  | - |  |
| ignoreteamattackcommands |  | - |  |
| ignoreteammovecommands |  | - |  |
| hidealtinfo |  | - |  |
| showaltinfowheninvulnerable |  | - |  |
| isdragselectablemulti |  | true |  |
| nocorpse |  | - |  |
| iscontrollable |  | true |  |
| noglobalselect |  | - |  |
| noblockneutralspawn |  | - |  |
| targetoffset |  | - |  |
| movespeed |  | - |  |
| minmovespeed |  | 100.0 |  |
| maxmovespeed |  | 600.0 |  |
| slowresistance |  | - |  |
| matchownermovespeed |  | - |  |
| turnrate |  | - |  |
| turnsmoothing |  | - |  |
| blocking |  | - |  |
| antiblocking |  | - |  |
| noallyblock |  | - |  |
| noallyheroblock |  | - |  |
| noallycreepblock |  | - |  |
| maxhealth |  | - |  |
| healthregen |  | - |  |
| healthproportionregen |  | - |  |
| maxmana |  | - |  |
| manaregen |  | - |  |
| manaproportionregen |  | - |  |
| showlifetime |  | - |  |
| armortype, normal |  | - |  |
| armor |  | - |  |
| magicarmortype |  | magic |  |
| magicarmor |  | - |  |
| mitigationarmortype |  | mitigation |  |
| mitigation |  | - |  |
| resistancearmortype |  | resistance |  |
| resistance |  | - |  |
| attacklifesteal |  | - |  |
| magiclifesteal |  | - |  |
| abilitymultiplier |  | - |  |
| immunity |  | - |  |
| lifesteal |  | - |  |
| healthregenreduction |  | - |  |
| manaregenreduction |  | - |  |
| dropitemsondeath |  | - |  |
| passiveinventory |  | - |  |
| inventory0 |  | - |  |
| inventory1 |  | - |  |
| inventory2 |  | - |  |
| inventory3 |  | - |  |
| inventory4 |  | - |  |
| inventory5 |  | - |  |
| inventory6 |  | - |  |
| inventory7 |  | - |  |
| inventory8 |  | - |  |
| inventory9 |  | - |  |
| inventory10 |  | - |  |
| inventory11 |  | - |  |
| inventory12 |  | - |  |
| inventory13 |  | - |  |
| inventory14 |  | - |  |
| sharedinventory0 |  | - |  |
| sharedinventory1 |  | - |  |
| sharedinventory2 |  | - |  |
| attacktype |  | - |  |
| attackeffecttype |  | Attack |  |
| distancetocleartargetsfrombrain |  | - |  |
| attackrange |  | - |  |
| attackprojectile |  | - |  |
| criticalattackprojectile |  | - |  |
| attackrangebuffer |  | 250.0 |  |
| attackoffset |  | - |  |
| attackdamagetype |  | AttackDamage |  |
| attackdamagemin |  | - |  |
| attackdamagemax |  | - |  |
| attackcooldown |  | - |  |
| attackduration |  | - |  |
| attackactiontime |  | - |  |
| attacktargetscheme |  | attack |  |
| attacknonlethal |  | - |  |
| attackstarteffect |  | - |  |
| attackactioneffect |  | - |  |
| attackselfactioneffect |  | - |  |
| attackimpacteffect |  | - |  |
| critactioneffect |  | - |  |
| critselfactioneffect |  | - |  |
| critimpacteffect |  | - |  |
| basedamage |  | - |  |
| threatscheme |  | - |  |
| threateffecttype |  | - |  |
| aggrorange |  | - |  |
| aggroscheme |  | - |  |
| proximityrange |  | - |  |
| proximityscheme |  | - |  |
| sightrangeday |  | - |  |
| sightrangenight |  | - |  |
| wanderrange |  | - |  |
| revealrange |  | - |  |
| revealtype |  | - |  |
| stealthtype |  | - |  |
| fadetime |  | - |  |
| occlusionstealthtype |  | - |  |
| stealthproximity |  | - |  |
| defaultbehavior |  | - |  |
| leashaggroscheme |  | - |  |
| goldbountymin |  | - |  |
| goldbountymax |  | - |  |
| goldbountyteam |  | - |  |
| goldbountyconsolation |  | - |  |
| goldbountypercentsplit |  | - |  |
| splitgoldbounty |  | - |  |
| maxdivisiblebountyperplayer |  | - |  |
| totaldivisiblebounty |  | - |  |
| experiencebounty |  | - |  |
| globalexperience |  | - |  |
| deadexperience |  | - |  |
| unsharedexperiencebounty |  | - |  |
| corpsetime |  | 10000 |  |
| corpsefadetime |  | 0 |  |
| corpsefadeeffect |  | - |  |
| occlusionfadeouteffect |  | - |  |
| occlusionfadeineffect |  | - |  |
| walkanim |  | walk_% |  |
| walknumanims |  | 1 |  |
| attackanim |  | attack_% |  |
| attacknumanims |  | 1 |  |
| deathanim |  | death_% |  |
| deathnumanims |  | 1 |  |
| altdeathanim |  | alt_death_% |  |
| altdeathnumanims |  | 1 |  |
| deathtime |  | 2000 |  |
| expireanim |  | - |  |
| expirenumanims |  | 0 |  |
| boredanim |  | bored_% |  |
| borednumanims |  | 1 |  |
| emoteanim |  | emote_% |  |
| emotenumanims |  | 1 |  |
| tiltfactor |  | 0.0 |  |
| tiltspeed |  | 90.0 |  |
| corpsetiltfactor |  | 1.0 |  |
| corpsetiltspeed |  | 30.0 |  |
| invulnerable |  | false |  |
| invulnerablekeeptarget |  | false |  |
| inheritvisibilityfromowner |  | - |  |
| combinevisibilitywithowner |  | - |  |
| alwaysvisible |  | false |  |
| hidden |  | false |  |
| alwaystargetable |  | false |  |
| cullentity |  | true |  |
| flying |  | false |  |
| flyheight |  | 300.0 |  |
| groundoffset |  | 0.0 |  |
| rememberinfothroughfog |  | - |  |
| unitwalking |  | - |  |
| treewalking |  | - |  |
| cliffwalking |  | - |  |
| buildingwalking |  | - |  |
| antiwalking |  | - |  |
| clearvision |  | - |  |
| clearvision2 |  | - |  |
| deniable |  | - |  |
| deniablepercent |  | - |  |
| smackable |  | - |  |
| nothreat |  | - |  |
| truestrike |  | - |  |
| alwaystransmitdata |  | - |  |
| shopaccess |  | - |  |
| stashaccess |  | - |  |
| diewithowner |  | - |  |
| relayexperience |  | - |  |
| maxdistancefromowner |  | - |  |
| largeunit |  | - |  |
| prefertouch |  | - |  |
| prefertouchtargettrait |  | all |  |
| touchrange |  | 64.0 |  |
| attackistouch |  | - |  |
| hidemodel |  | - |  |
| hideshadow |  | - |  |
| hideselectionring |  | - |  |
| hideindicator |  | - |  |
| norender |  | - |  |
| previewmodel |  | - |  |
| previewpassiveeffect |  | - |  |
| previewpos |  | - |  |
| previewangles |  | - |  |
| previewscale |  | - |  |
| storemodel |  | - |  |
| storepos |  | - |  |
| storeangles |  | - |  |
| storescale |  | - |  |
| storepassiveeffect |  | - |  |
| allowavatarchange |  | - |  |
| serverentity |  | - |  |
| power |  | 100.0, 0.0, 0.0 | TheChiprel: Check how it works |
| shadowsize |  | - |  |
| shadowwidth |  | - |  |
| shadowheight |  | - |  |
| unitcriticalchance |  | - |  |
| unitcriticalmultiplier |  | - |  |
| hazardradius |  | - |  |
| hazardthreat |  | - |  |
| hazardoffset |  | - |  |
| noaltinfo |  | - |  |
| showinpractice |  | - |  |
| additionalrespawns |  | - |  |

### building
| attribute name | valid value | default value | description |
|---|---|---|---|
| alwaystargetable |  | true |  |
| ismobile |  | - |  |
| canattack |  | - |  |
| canrotate |  | - |  |
| combattype |  | structure |  |
| cancarryitems |  | - |  |
| isshop |  | - |  |
| isbase |  | - |  |
| istower |  | - |  |
| israx |  | - |  |
| sharesinventory |  | - |  |
| noaltclickping |  | - |  |
| hideinfog |  | - |  |
| hideoutoffog |  | - |  |
| isphysical |  | - |  |
| lowhealtheffect |  | - |  |
| lowhealthsound |  | - |  |
| destroyedsound |  | - |  |
| defaultshop |  | - |  |
| maplocation |  | - |  |
| lifetime |  | - |  |
| noheroarmorreduction |  | - |  |
| aggromyheropassiveeffect |  | - |  |
| aggroteamheropassiveeffect |  | - |  |
| herothreatradiuspassiveeffect |  | - |  |
| herothreatradius |  | - |  |

### creep
| attribute name | valid value | default value | description |
|---|---|---|---|
| ismobile |  | true |  |
| canattack |  | true |  |
| canrotate |  | true |  |
| combattype |  | - |  |
| cancarryitems |  | - |  |

### critter
| attribute name | valid value | default value | description |
|---|---|---|---|
| ismobile |  | true |  |
| canattack |  | true |  |
| canrotate |  | true |  |
| combattype |  | - |  |
| cancarryitems |  | - |  |

### familiar
| attribute name | valid value | default value | description |
|---|---|---|---|
| enabled |  | true |  |
| ismobile |  | true |  |
| canattack |  | true |  |
| canrotate |  | true |  |
| cancarryitems |  | true |  |
| respawneffect |  | - |  |
| abilitypassive |  | - |  |
| abilitytriggered |  | - |  |
| abilityactive |  | - |  |
| petselectannouncement |  | - |  |
| evolitiondescription |  | - |  |
| corralmodelposition |  | - |  |
| corralmodelorient |  | - |  |
| corralmodelscale |  | - |  |
| heroselectmodelposition |  | - |  |
| heroselectmodelorient |  | - |  |
| heroselectmodelscale |  | - |  |

### gadget
| attribute name | valid value | default value | description |
|---|---|---|---|
| ismobile |  | - |  |
| canattack |  | - |  |
| canrotate |  | - |  |
| combattype |  | - |  |
| cancarryitems |  | - |  |
| lifetime |  | - |  |
| initialcharges |  | - |  |
| occlusionradius |  | - |  |
| power |  | 0.0, 0.0, 0.0 |  |

### attachablegadget
It doesn't have its own attributes.

### hero
| attribute name | valid value | default value | description |
|---|---|---|---|
| ismobile |  | true |  |
| canattack |  | true |  |
| canrotate |  | true |  |
| combattype |  | Hero |  |
| cancarryitems |  | true |  |
| team |  | - |  |
| primaryattribute |  | - |  |
| defaultfamiliar |  | - |  |
| strength |  | - |  |
| strengthperlevel |  | - |  |
| agility |  | - |  |
| agilityperlevel |  | - |  |
| intelligence |  | - |  |
| intelligenceperlevel |  | - |  |
| respawneffect |  | - |  |
| defaultbehavior |  | aggro |  |
| category |  | - |  |
| difficulty |  | - |  |
| newhero |  | - |  |
| rolesurvival |  | - |  |
| rolecrowdcontrol |  | - |  |
| rolephysicaldamage |  | - |  |
| rolemagicdamage |  | - |  |
| roleutility |  | - |  |
| itembuild |  | - |  |
| levelbuild |  | - |  |
| streaksound |  | - |  |
| heroselectannouncement |  | - |  |
| heroselectflavorannouncement |  | - |  |
| creepkillannouncement |  | - |  |
| herokillfrequentannouncement |  | - |  |
| herokillinfrequentannouncement |  | - |  |
| herolevelultannouncement |  | - |  |
| creepdamageannouncement |  | - |  |
| toweraggroannouncement |  | - |  |
| deathannouncement |  | - |  |
| respawnannouncement |  | - |  |
| itemacquireannouncement |  | - |  |
| itempurchaseannouncement |  | - |  |
| lowhealthannouncement |  | - |  |
| abilityflavorannouncement |  | - |  |
| assistannouncement |  | - |  |
| attackannouncement |  | - |  |
| attackcruxannouncement |  | - |  |
| attackenemyannouncement |  | - |  |
| attackgeneratorannouncement |  | - |  |
| attacktowerannouncement |  | - |  |
| backannouncement |  | - |  |
| carebottomannouncement |  | - |  |
| caremiddleannouncement |  | - |  |
| caretopannouncement |  | - |  |
| defendcruxannouncement |  | - |  |
| defendgeneratorannouncement |  | - |  |
| defendtowerannouncement |  | - |  |
| farmannouncement |  | - |  |
| helpannouncement |  | - |  |
| helpbottomannouncement |  | - |  |
| helpmiddleannouncement |  | - |  |
| helptopannouncement |  | - |  |
| krytosannouncement |  | - |  |
| missingannouncement |  | - |  |
| missingbottomannouncement |  | - |  |
| missingmiddleannouncement |  | - |  |
| missingtopannouncement |  | - |  |
| onmywayannouncement |  | - |  |
| onmywaybottomannouncement |  | - |  |
| onmywaymiddleannouncement |  | - |  |
| onmywaytopannouncement |  | - |  |
| pushannouncement |  | - |  |
| thanksannouncement |  | - |  |
| togetherannouncement |  | - |  |
| watchoutannouncement |  | - |  |
| wellannouncement |  | - |  |
| wellplayedannouncement |  | - |  |
| abilityreadyannouncement |  | - |  |
| abilitycooldownannouncement |  | - |  |
| abilitynomanaannouncement |  | - |  |
| abilitycooldownnomanaannouncement |  | - |  |
| enabled |  | true |  |
| ismobile |  | true |  |
| canattack |  | true |  |
| canrotate |  | true |  |
| cancarryitems |  | true |  |
| respawneffect |  | - |  |
| abilitypassive |  | - |  |
| abilitytriggered |  | - |  |
| abilityactive |  | - |  |
| petselectannouncement |  | - |  |
| evolitiondescription |  | - |  |
| corralmodelposition |  | - |  |
| corralmodelorient |  | - |  |
| corralmodelscale |  | - |  |
| heroselectmodelposition |  | - |  |
| heroselectmodelorient |  | - |  |
| heroselectmodelscale |  | - |  |

### heropet
| attribute name | valid value | default value | description |
|---|---|---|---|
| strength |  | - |  |
| strengthperlevel |  | - |  |
| agility |  | - |  |
| agilityperlevel |  | - |  |
| intelligence |  | - |  |
| intelligenceperlevel |  | - |  |
| primaryattribute |  | - |  |

### neutral
| attribute name | valid value | default value | description |
|---|---|---|---|
| ismobile |  | true |  |
| canattack |  | true |  |
| canrotate |  | true |  |
| combattype |  | - |  |
| cancarryitems |  | - |  |

### neutralboss
This type is exactly like neutral only transmits more health on network.
It doesn't have its own attributes.

### pet
| attribute name | valid value | default value | description |
|---|---|---|---|
| ismobile |  | true |  |
| canattack |  | true |  |
| canrotate |  | true |  |
| combattype |  | - |  |
| cancarryitems |  | - |  |
| ispersistent |  | - |  |
| lifetime |  | - |  |
| continuousmodifiers |  | - |  |
| defaultbehavior |  | guard |  |

### powerup
| attribute name | valid value | default value | description |
|---|---|---|---|
| ismobile |  | - |  |
| canattack |  | - |  |
| canrotate |  | - |  |
| cancarryitems |  | - |  |
| touchsound |  | - |  |
| touchtargetscheme |  | - |  |

### waypoint
| attribute name | valid value | default value | description |
|---|---|---|---|
| model |  | - |  |
| modelscale |  | 1.0 |  |

## Events
| event name | description |
|---|---|
| onframe | Processed once each frame |
| onframeimpact | Processed once each frame per target (affectors) |
| oninterval | Processed once each interval (affectors) |
| onbegin | The owner has activated this entity |
| onstart | Tool has begun to activate |
| onprecost | A chance for the tool to modifier its activation cost |
| onaction | This entity has reached its action time (called once per activatation) |
| onpreimpact |  |
| onpredamage |  |
| ondamageevent |  |
| ondoubleactivate | Tool has been double-activated |
| onimpact | This entity has reached its action time (called once per target) |
| onimpactinvalid | This entity has reached its action but the impact was invalid |
| oncomplete | Tool successfully activates |
| oncancel | Tool failed to activate |
| onactivatestart | The owner has activated this entity |
| onactivateprecost | This entity has reached its action time |
| onactivatepreimpact | This entity has reached its action time |
| onactivateimpact | Processed after an activated tool reaches the end of its cast time |
| onactivateend | The owner has activated an ability other than this entity |
| onabilitystart | An ability other than this entity has reached its action time |
| onabilityimpact |  |
| onabilityfinish |  |
| onabilityend | Processed after an activated ability other than this entity reaches the end of its cast time |
| ontoggleon | This tool with action type "toggle" has been turned on |
| ontoggleoff | This tool with action type "toggle" has been turned off |
| onchannelstart | The owner of this entity has activated a channeling tool |
| onchannelframe | Processed each frame the owner is channeling this tool |
| onchannelbreak | The owner has stopped channeling before the channel time completed |
| onchannelend | The owner has completed the full channel time of this entity |
| onchannelingstart | The owner of this entity has activated any channeling tool |
| onchannelingframe | Processed each frame the owner is channeling any tool |
| onchannelingbreak | The owner has stopped channeling his "tool" before the channel time completed |
| onchannelingend | The owner has completed the full channel time of any tool |
| onattackstart | Processed when the owner begins an attack |
| onattack | Processed when the owner reaches the attack action time |
| onattackpreimpact | Processed when the owner successfully attacks another entity, before damage and evasion |
| onattackpredamage | Processed when the owner successfully attacks another entity, before damage |
| onattackdamageevent |  |
| onattackimpact | Processed when the owner successfully attacks another entity and impacts |
| onattackimpactinvalid |  |
| onattackend | Processed when the owner completes an attack, successful or not |
| onattackedstart | An attack has been started on this entity |
| onattackedpreimpact | This entity has been attacked, but damage/effects/evasion have not yet been applied |
| onattackedpredamage | This entity has been attacked, but damage/effects have not yet been applied |
| onattackeddamageevent |  |
| onattackedpostimpact | This entity has been attacked and damage/effects have been applied (does not trigger on a miss/evade) |
| onattackingstart |  |
| onattackingpreimpact |  |
| onattackingpredamage |  |
| onattackingdamageevent |  |
| onattackingpostimpact |  |
| ondamage | This entity has dealt some amount of damage |
| ondamaged | This entity has taken some amount of damage |
| ondamageapplied | This entity will take some damage, here's your chance to modify it in script |
| onstunned | This entity has been stunned |
| onkilled | This entity has been killed |
| onsmackdowned | This entity has been smacked down |
| onexpired | This entity has died due to its lifetime expiring |
| ondeath | This entity has died :( |
| onkill | This entity killed another entity |
| preexperiencegain | This entity(hero is about to gain experience, ability to modify experience gained with ) |
| onexperiencegain | This entity(hero gained experience) |
| onindirectkill | This entity indirectly killed another entity |
| onassist | This entity assisted in killing another entity |
| ondisjointed |  |
| onorderdisjointed |  |
| onhealpre | The entity is healing another entity, but the heal hasn't been applied yet |
| onheal |  |
| onhealpost | The entity is healing another entity and the heal has been applied |
| onhealedpre | The entity has been healed, but the heal hasn't been applied yet |
| onhealed |  |
| onhealedpost | The entity has been healed and the heal has been applied |
| onspawn | Processed when spawn is called |
| onrespawn | Processed when respawn is called |
| onlevelup | Hero levelup |
| oninflict | New state applied to an entity |
| onrefresh | Resfreshed state on an entity |
| oninflicted | Entity has had a new state applied to it |
| onownerrespawn | This entity's owner has respawned |
| onrelease | This entity has lost its binding |
| ontouch | This entity collided with another entity |
| ontouched | This entity has been touched by another entity |
| onthink | Executed before neutral NPC "thinking" occurs |
| ontargetacquired | Executed when a unit changes or acquires a target |
| onlearn | This ability was just learned for the first time |
| onupgrade | This tool was leveluped |
| oncreate | Item was created |
| onbackpackacquire | Item was moved to backpack |
| onprepurchase | Item is about to be purchased |
| onpurchase | Item was just purchased |
| ontimer | Timer trigger |
| onpickup | Item was moved into a new inventory |
| onready | Tool has become ready (off cooldown) |
| onleash | A neutral has leashed |
| onspawnerdormant | All managed units have died and it has been issued a respawn time |
| onheroagression | When an agressive hero goes near a tower or becomes agressive under a tower. |
| onenterbrush | This entity entered a brush |
| onexitbrush | This entity exited a brush |
| onentercombat | This entity is going to enter combat, can be negated |
| onlobbystart |  |
| onaddplayer |  |
| onentergame |  |
| onexitgame |  |
| onprematchstart |  |
| onmatchstart |  |

## Actions

### print
| attribute name | valid value | default value | description |
|---|---|---|---|
| text |  | - |  |

### printdebuginfo
Has no attributes

### printpersistentmodifierkeys
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### printvalue
| attribute name | valid value | default value | description |
|---|---|---|---|
| label |  | value of "value" attribute |  |
| value |  | - |  |

### printpos
| attribute name | valid value | default value | description |
|---|---|---|---|
| label |  | value of "value" attribute |  |
| value |  | - |  |

### chance
| attribute name | valid value | default value | description |
|---|---|---|---|
| threshold |  | - |  |

### condition
| attribute name | valid value | default value | description |
|---|---|---|---|
| test |  | - |  |

### elsecondition
| attribute name | valid value | default value | description |
|---|---|---|---|
| test |  | - |  |

### else
Has no attributes

### compare
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### targetisbot
Has no attributes

### cantarget
| attribute name | valid value | default value | description |
|---|---|---|---|
| targetscheme |  | - |  |
| effecttype |  | - |  |
| ignoreinvulnerable |  | - |  |
| ignoredormant |  | - |  |

### canactivate
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### iscrafted
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### islegendary
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### iscritical
Has no attributes

### isready
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### isstealthed
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### hasbinds
Has no attributes

### testactivate
| attribute name | valid value | default value | description |
|---|---|---|---|
| distance |  | - |  |

### canattack
Has no attributes

### combatsupertype
| attribute name | valid value | default value | description |
|---|---|---|---|
| supertype |  | - |  |

### combateffecttype
| attribute name | valid value | default value | description |
|---|---|---|---|
| effecttype |  | - |  |

### damagesupertype
| attribute name | valid value | default value | description |
|---|---|---|---|
| supertype |  | - |  |

### damageeffecttype
| attribute name | valid value | default value | description |
|---|---|---|---|
| effecttype |  | - |  |

### currentdamagesupertype
| attribute name | valid value | default value | description |
|---|---|---|---|
| supertype |  | - |  |

### currentdamageeffecttype
| attribute name | valid value | default value | description |
|---|---|---|---|
| effecttype |  | - |  |

### casteffecttype
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| effecttype |  | - |  |

### consume
| attribute name | valid value | default value | description |
|---|---|---|---|
| item |  | - |  |
| count |  | 1 |  |
| userecipe |  | - |  |
| ignorecharges |  | - |  |

### addattackpreimpactactions
Has no attributes

### addattackpredamageactions
Has no attributes

### addattackdamageeventactions
Has no attributes

### addattackimpactactions
Has no attributes

### addattackimpactinvalidactions
Has no attributes

### testnearby
| attribute name | valid value | default value | description |
|---|---|---|---|
| radius |  | - |  |
| targetscheme |  | - |  |
| ignoreinvulnerable |  | false |  |
| origin |  | source_entity |  |

### screenflash
| attribute name | valid value | default value | description |
|---|---|---|---|
| healing |  | - |  |

### cleardistanttargetsfrombrain
| attribute name | valid value | default value | description |
|---|---|---|---|
| distance |  | - |  |

### damage
| attribute name | valid value | default value | description |
|---|---|---|---|
| min |  | 0 |  |
| max |  | 0 |  |
| effecttype |  | - |  |
| nonlethal |  | - |  |
| b |  | - |  |
| op |  | - |  |
| inflictor |  | this_entity |  |
| supertype |  | - |  |
| armorpierce |  | - |  |
| armorpiercepercent |  | - |  |
| magicarmorpierce |  | - |  |
| magicarmorpiercepercent |  | - |  |
| armor |  | - |  |
| magicarmor |  | - |  |
| mitigation |  | - |  |
| resistance |  | - |  |
| significant |  | - |  |

### splashdamage
| attribute name | valid value | default value | description |
|---|---|---|---|
| targetscheme |  | - |  |
| effecttype |  | - |  |
| radius |  | - |  |
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |
| nonlethal |  | - |  |
| centerontarget |  | - |  |
| supertype |  | - |  |

### heal
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |
| logged |  | - |  |
| significant |  | - |  |
| effecttype |  | - |  |

### changehealth
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### popup
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### playsound
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| sourceoverride |  | - |  |
| targetoverride |  | - |  |

### ping
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| position |  | target_position |  |

### givegold
| attribute name | valid value | default value | description |
|---|---|---|---|
| amount |  | - |  |
| b |  | - |  |
| op |  | - |  |
| position |  | target_entity |  |

### takegold
| attribute name | valid value | default value | description |
|---|---|---|---|
| amount |  | - |  |
| b |  | - |  |
| op |  | - |  |
| position |  | target_entity |  |

### spendgold
| attribute name | valid value | default value | description |
|---|---|---|---|
| amount |  | - |  |
| b |  | - |  |
| op |  | - |  |
| position |  | target_entity |  |

### giveexperience
| attribute name | valid value | default value | description |
|---|---|---|---|
| amount |  | - |  |
| b |  | - |  |
| op |  | - |  |
| position |  | target_entity |  |

### givemana
| attribute name | valid value | default value | description |
|---|---|---|---|
| amount |  | - |  |
| b |  | - |  |
| op |  | - |  |

### takemana
| attribute name | valid value | default value | description |
|---|---|---|---|
| amount |  | - |  |
| b |  | - |  |
| op |  | - |  |

### applystate
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| duration |  | - |  |
| charges |  | - |  |
| chargesmult |  | - |  |
| ischannel |  | - |  |
| istoggle |  | - |  |
| proxy |  | - |  |
| pushentity |  | - |  |
| stack |  | none |  |
| continuous |  | - |  |
| timeout |  | - |  |
| spawner |  | inflictor_entity |  |
| inflictor |  | source_entity |  |
| statelevel |  | - |  |


### expirestate
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### hasstate
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### transferstate
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### transferstates
| attribute name | valid value | default value | description |
|---|---|---|---|
| effecttype |  | - |  |
| ignoreeffecttype |  | - |  |
| inflictor |  | - |  |

### teleport
| attribute name | valid value | default value | description |
|---|---|---|---|
| interpolate |  | - |  |
| facetarget |  | - |  |
| specifyangle |  | - |  |
| angle |  | - |  |
| positionorigin |  | source_entity |  |
| positionvalue |  | - |  |
| positionmodifier |  | - |  |
| positionoffset |  | - |  |

### playanim
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| variations |  | - |  |
| channel |  | - |  |
| speed |  | 1.0 |  |
| length |  | - |  |
| seq |  | - |  |

### playeffect
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| effect |  | - |  |
| owner |  | source_entity |  |
| occlude |  | - |  |
| visibility |  | - |  |
| sightedradius |  | 0.f |  |

### queuelanepusher
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| lanename |  | - |  |
| lanespawnlocation |  | - |  |
| spawnposition |  | - |  |
| waypoint |  | - |  |
| announce |  | - |  |

### chain
| attribute name | valid value | default value | description |
|---|---|---|---|
| count |  | - |  |

### bounce
| attribute name | valid value | default value | description |
|---|---|---|---|
| count |  | - |  |
| range |  | - |  |
| damagemult |  | - |  |
| targetscheme |  | - |  |
| seek |  | - |  |
| maxbouncespertarget |  | - |  |

### split
| attribute name | valid value | default value | description |
|---|---|---|---|
| count |  | - |  |
| range |  | - |  |
| damagemult |  | - |  |
| targetscheme |  | - |  |
| fulldamageonmaintarget |  | - |  |
| clearcriticals |  | - |  |

### return
Has no attributes

### bind
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| vertical |  | - |  |
| turn |  | - |  |
| unbindondeath |  | - |  |
| nopush |  | - |  |
| position |  | true |  |
| verticaloverride |  | - |  |
| positionoverride |  | - |  |

### unbind
Has no attributes

### spawnunit
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| count |  | - |  |
| mount |  | - |  |
| bind |  | - |  |
| fixedposition |  | - |  |
| inheritmodifiers |  | true |  |
| ischannel |  | - |  |
| istoggle |  | - |  |
| maxactive |  | - |  |
| facing |  | - |  |
| angle |  | - |  |
| offset |  | - |  |
| offsetspace |  | target_entity |  |
| pushentity |  | - |  |
| lifetime |  | - |  |
| lifetimeb |  | - |  |
| lifetimeop |  | - |  |
| proxy |  | - |  |
| team |  | (TEAM_INVALID) |  |
| snaptargettogrid |  | - |  |
| teamshare |  | - |  |
| inheritpower |  | - |  |

### spawnaffector
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| target |  | target_entity |  |
| direction |  | target_position |  |
| firsttarget |  | target_entity |  |
| level |  | - |  |
| owner |  | source_entity |  |
| ischannel |  | - |  |
| istoggle |  | - |  |
| distance |  | - |  |
| count |  | 1 |  |
| countb |  | - |  |
| countop |  | - |  |
| distribute |  | - |  |
| proxy |  | - |  |
| pushentity |  | - |  |
| param |  | - |  |
| positionorigin |  | source_entity |  |
| positionvalue |  | - |  |
| positionmodifier |  | - |  |
| positionoffset |  | - |  |
| ignore |  | - |  |

### spawnlinearaffector
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| target |  | target_entity |  |
| irection |  | target_position |  |
| firsttarget |  | target_entity |  |
| level |  | - |  |
| owner |  | source_entity |  |
| ischannel |  | - |  |
| istoggle |  | - |  |
| proxy |  | - |  |
| pushentity |  | - |  |
| param |  | - |  |
| targetorigin |  | target_entity |  |
| targetvalue |  | - |  |
| targetmodifier |  | - |  |
| targetoffset |  | - |  |
| directionorigin |  | target_position |  |
| directionvalue |  | - |  |
| directionmodifier |  | - |  |
| directionoffset |  | - |  |

### spawnprojectile
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| source |  | source_entity |  |
| target |  | target_entity |  |
| bind |  | - |  |
| bindturn |  | - |  |
| bindnopush |  | - |  |
| unbindondeath |  | - |  |
| ignoretargetoffset |  | - |  |
| bindstate |  | - |  |
| proxy |  | - |  |
| offset |  | - |  |
| offsetspace |  | source_entity |  |
| ischannel |  | - |  |
| istoggle |  | - |  |
| pushentity |  | - |  |
| param |  | - |  |
| noresponse |  | - |  |
| responsetype |  | - |  |
| supertype |  | spell |  |
| targetscheme |  | - |  |
| effecttype |  | - |  |
| ignore |  | - |  |
| ignoreinvulnerable |  | - |  |
| orbit |  | - |  |
| orbitclockwise |  | - |  |
| orbitradius |  | - |  |
| orbitspeed |  | - |  |
| orbitacceleration |  | - |  |
| orbitmainspeed |  | - |  |
| orbitmaxspeed |  | - |  |
| orbitmaxtouches |  | - |  |
| orbitmaxtouchespertarget |  | - |  |
| orbitdieonmaxtouches |  | - |  |
| orbitdieonmaxtouchespertarget |  | - |  |
| orbitstartingtheta |  | - |  |
| orbitstartingthetatime |  | -1 |  |
| homing |  | - |  |
| homingseekrange |  | - |  |
| homingspeedmul |  | - |  |
| homingunlockrange |  | - |  |
| hominglocktarget |  | - |  |
| homingseekstealth |  | - |  |
| bezier |  | - |  |
| bezierpoint0 |  | - |  |
| bezierpoint1 |  | - |  |
| bezierpoint2 |  | - |  |
| bezierpoint3 |  | - |  |
| owner |  | source_entity |  |

### setprojectilebounds
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| radius |  | source_entity |  |

### getprojectiledistancetraveled
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### getprojectiletheta
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### getprojectileorbitradius
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### setprojectileorbitradius
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| value |  | - |  |

### pushprojectiletarget
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### getyaw
| attribute name | valid value | default value | description |
|---|---|---|---|
| getyaw |  | - |  |

### attack
| attribute name | valid value | default value | description |
|---|---|---|---|
| targetscheme |  | - |  |
| effecttype |  | - |  |
| facetarget |  | - |  |
| startcooldown |  | true |  |

### startattack
| attribute name | valid value | default value | description |
|---|---|---|---|
| targetscheme |  | - |  |
| effecttype |  | - |  |
| facetarget |  | - |  |

### attackaction
| attribute name | valid value | default value | description |
|---|---|---|---|
| targetscheme |  | - |  |
| effecttype |  | - |  |

### bonusdamageadd
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### bonusdamagemult
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### resetattackcooldown
Has no attributes

### setignoreattackcooldown
| attribute name | valid value | default value | description |
|---|---|---|---|
| value |  | - |  |

### startattackcooldown
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| duration |  | - |  |
| durationb |  | - |  |
| durationop |  | - |  |

### order
| attribute name | valid value | default value | description |
|---|---|---|---|
| command |  | - |  |
| parameter |  | - |  |
| queue |  | - |  |
| force |  | - |  |
| forceduration |  | - |  |
| restrict |  | - |  |
| ordername |  | - |  |
| value0 |  | - |  |
| duration |  | - |  |
| block |  | - |  |

### useability
| attribute name | valid value | default value | description |
|---|---|---|---|
| slot |  | INVALID_ITERATOR_SLOT |  |
| queue |  | front |  |
| force |  | - |  |
| forceduration |  | - |  |
| restrict |  | - |  |
| ordername |  | - |  |
| value0 |  | - |  |
| block |  | - |  |

### useitem
| attribute name | valid value | default value | description |
|---|---|---|---|
| queue |  | front |  |
| force |  | - |  |
| forceduration |  | - |  |
| restrict |  | - |  |
| ordername |  | - |  |
| value0 |  | - |  |
| block |  | - |  |

### selectentity
| attribute name | valid value | default value | description |
|---|---|---|---|
| request |  | - |  |
| centercamera |  | - |  |
| targets |  | - |  |

### killillusions
Has no attributes

### killtrees
| attribute name | valid value | default value | description |
|---|---|---|---|
| radius |  | - |  |
| usealtdeathanims |  | - |  |

### setdeathanim
| attribute name | valid value | default value | description |
|---|---|---|---|
| noanim |  | - |  |
| nocorpse |  | - |  |

### dispel
| attribute name | valid value | default value | description |
|---|---|---|---|
| type |  | - |  |

### takecontrol
| attribute name | valid value | default value | description |
|---|---|---|---|
| maxactive |  | - |  |
| inheritmodifiers |  | - |  |

### releasecontrol
| attribute name | valid value | default value | description |
|---|---|---|---|
| team |  | -4 |  |

### setactivemodifierkey
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| name |  | - |  |

### delete
Has no attributes

### kill
| attribute name | valid value | default value | description |
|---|---|---|---|
| experiencebountymult |  | 1.0 |  |
| goldbountymult |  | 1.0 |  |
| nocorpse |  | - |  |
| nodeathanim |  | - |  |

### spawnillusion
| attribute name | valid value | default value | description |
|---|---|---|---|
| count |  | 1 |  |
| lifetime |  | - |  |
| receivedamagemultiplier |  | 1.0 |  |
| inflictdamagemultiplier |  | 1.0 |  |
| spawneffect |  | - |  |
| deatheffect |  | - |  |
| owner |  | source_entity |  |
| uncontrollable |  | - |  |
| pushentity |  | - |  |
| playdeathanim |  | - |  |
| inheritactions |  | - |  |
| spawncircular |  | - |  |
| spawncircularradius |  | - |  |
| spawncircularnoshuffle |  | - |  |
| spawncircularrotate |  | - |  |
| nofamiliar |  | - |  |
| usegenerichealthbar |  | - |  |
| noaltinfo |  | - |  |

### clearteamtarget
Has no attributes

### refreshabilities
Has no attributes

### refreshinventoryitems
| attribute name | valid value | default value | description |
|---|---|---|---|
| noaltexcludedinfo |  | - |  |

### negate
| attribute name | valid value | default value | description |
|---|---|---|---|
| immunitytype |  | - |  |

### startcooldown
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| duration |  | - |  |
| durationb |  | - |  |
| durationop |  | - |  |
| toolname |  | - |  |

### resetcooldown
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### showchannelbar
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| duration |  | - |  |
| durationb |  | - |  |
| durationop |  | - |  |
| toolname |  | - |  |

### hidechannelbar
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| toolname |  | - |  |

### morph
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### disjoint
Has no attributes

### orderdisjoint
Has no attributes

### forgetattacks
Has no attributes

### protecteddeath
Has no attributes

### setrespawntimemultiplier
| attribute name | valid value | default value | description |
|---|---|---|---|
| value |  | 1.0 |  |

### setrespawntimebonus
| attribute name | valid value | default value | description |
|---|---|---|---|
| value |  | - |  |

### setrespawntime
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### setrespawnhealthmultiplier
| attribute name | valid value | default value | description |
|---|---|---|---|
| value |  | 1.0 |  |

### setrespawnmanamultiplier
| attribute name | valid value | default value | description |
|---|---|---|---|
| value |  | 1.0 |  |

### setrespawnposition
| attribute name | valid value | default value | description |
|---|---|---|---|
| position |  | target_position |  |

### setgoldlossmultiplier
| attribute name | valid value | default value | description |
|---|---|---|---|
| value |  | 1.0 |  |

### setgoldlossbonus
| attribute name | valid value | default value | description |
|---|---|---|---|
| value |  | - |  |

### addcharges
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| count |  | 1 |  |
| timed |  | - |  |
| duration |  | - |  |

### removecharges
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| count |  | 1 |  |

### removecharge
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### modifycharges
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| count |  | 0 |  |

### multcharges
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| value |  | 1.0 |  |

### setcharges
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### setquality
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### spawnitem
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| offset |  | - |  |
| offsetspace |  | target_entity |  |

### scaledamage
| attribute name | valid value | default value | description |
|---|---|---|---|
| scale |  | - |  |

### changedamage
| attribute name | valid value | default value | description |
|---|---|---|---|
| b |  | - |  |
| op |  | - |  |

### setdamage
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### changecurrentcombatdamage
| attribute name | valid value | default value | description |
|---|---|---|---|
| b |  | - |  |
| op |  | - |  |

### accumulatedamage
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| scale |  | - |  |

### setaccumulator
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| value |  | - |  |
| valueb |  | - |  |
| valueop |  | - |  |

### changeaccumulator
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| b |  | - |  |
| op |  | - |  |

### savehealth
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### expire
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### absorbdamage
| attribute name | valid value | default value | description |
|---|---|---|---|
| max |  | - |  |

### adjuststrength
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| value |  | - |  |

### adjustagility
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| value |  | - |  |

### adjustintelligence
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| value |  | - |  |

### retarget
Has no attributes

### recallpets
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### levelpets
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| value |  | - |  |

### push
| attribute name | valid value | default value | description |
|---|---|---|---|
| force |  | - |  |
| forceb |  | - |  |
| forceop |  | - |  |
| duration |  | - |  |
| perpendicular |  | - |  |
| frame |  | - |  |

### defer
| attribute name | valid value | default value | description |
|---|---|---|---|
| time |  | - |  |
| mult |  | - |  |

### evaluate
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### pushstack
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### popstack
Has no attributes

### peekstack
Has no attributes

### pushentity
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |
| searchfortarget |  | false |  |
| searchorigin |  | - |  |
| radius |  | - |  |
| targetscheme |  | - |  |
| ignoreinvulnerable |  | false |  |

### popentity
Has no attributes

### changeduration
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| b |  | - |  |
| op |  | - |  |

### changetotalduration
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| b |  | - |  |
| op |  | - |  |

### setproxy
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| searchfortarget |  | false |  |
| searchorigin |  | - |  |
| radius |  | - |  |
| targetscheme |  | - |  |
| ignoreinvulnerable |  | false |  |
| index |  | - |  |

### clearproxy
| attribute name | valid value | default value | description |
|---|---|---|---|
| index |  | - |  |

### foreachproxy
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### setparam
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### startfade
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### pushability
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| name |  | - |  |
| slot |  | (INVALID_INVENTORY_SLOT) |  |

### pushentitybyname
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### setvar0
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### setvar1
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### setvar2
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### setvar3
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### setpos0
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| name |  | - |  |
| position |  | - |  |
| offset |  | - |  |
| offsetspace | entity | target_entity |  |
| positionend |  | - |  |
| positionvalue |  | - |  |
| positionmodifier |  | start |  |
| positionoffset |  | - |  |
| snaptoterrain |  | - |  |

### setpos1
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |
| name |  | - |  |
| position |  | - |  |
| offset |  | - |  |
| offsetspace | entity | target_entity |  |
| positionend |  | - |  |
| positionvalue |  | - |  |
| positionmodifier |  | start |  |
| positionoffset |  | - |  |
| snaptoterrain |  | - |  |

### setpos2
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |
| name |  | - |  |
| position |  | - |  |
| offset |  | - |  |
| offsetspace | entity | target_entity |  |
| positionend |  | - |  |
| positionvalue |  | - |  |
| positionmodifier |  | start |  |
| positionoffset |  | - |  |
| snaptoterrain |  | - |  |

### setpos3
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |
| name |  | - |  |
| position |  | - |  |
| offset |  | - |  |
| offsetspace | entity | target_entity |  |
| positionend |  | - |  |
| positionvalue |  | - |  |
| positionmodifier |  | start |  |
| positionoffset |  | - |  |
| snaptoterrain |  | - |  |

### setent0
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |
| name |  | - |  |

### setent1
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |
| name |  | - |  |

### setent2
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |
| name |  | - |  |

### setent3
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |
| name |  | - |  |

### setattackprojectile
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### setcriticalattackprojectile
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### setattackactioneffect
| attribute name | valid value | default value | description |
|---|---|---|---|
| effect |  | - |  |

### setattackselfactioneffect
| attribute name | valid value | default value | description |
|---|---|---|---|
| effect |  | - |  |

### setattackimpacteffect
| attribute name | valid value | default value | description |
|---|---|---|---|
| effect |  | - |  |

### setcritactioneffect
| attribute name | valid value | default value | description |
|---|---|---|---|
| effect |  | - |  |

### setcritselfactioneffect
| attribute name | valid value | default value | description |
|---|---|---|---|
| effect |  | - |  |

### setcritimpacteffect
| attribute name | valid value | default value | description |
|---|---|---|---|
| effect |  | - |  |

### setappliedvalue
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### sethealthdamage
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### setshielddamage
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### setaccumulateddamage
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### resettouches
| attribute name | valid value | default value | description |
|---|---|---|---|

### toggleoff
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### breakchannel
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### aggression
Has no attributes

### setvalue
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### seteffecttype
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| effecttype |  | - |  |

### hasmodifier
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### areaofeffect
| attribute name | valid value | default value | description |
|---|---|---|---|
| targetscheme |  | - |  |
| effecttype |  | - |  |
| ignoreinvulnerable |  | - |  |
| center |  | target_position |  |
| targetselection |  | - |  |
| radius |  | - |  |
| arc |  | - |  |
| innerradiusoffset |  | - |  |
| maxtotalimpacts |  | - |  |
| maximpactspertarget |  | 1 |  |
| firsttarget |  | - |  |
| ignore |  | - |  |
| global |  | - |  |
| includetrees |  | - |  |

### propareaeffect
| attribute name | valid value | default value | description |
|---|---|---|---|
| center |  | target_position |  |
| radius |  | - |  |
| anim |  | - |  |

### calculatedamage
| attribute name | valid value | default value | description |
|---|---|---|---|
| amount |  | - |  |
| effecttype |  | - |  |
| supertype |  | - |  |

### transferitemstohero
Has no attributes

### transferitems
| attribute name | valid value | default value | description |
|---|---|---|---|
| sourceregion |  | - |  |
| targetregion |  | - |  |

### transferitemstocourier
Has no attributes

### transferitemsfromcourier
| attribute name | valid value | default value | description |
|---|---|---|---|
| targetregion |  | - |  |

### countslaves
| attribute name | valid value | default value | description |
|---|---|---|---|
| region |  | - |  |

### recordheroaggression
Has no attributes

### pushhero
Has no attributes

### pushentitysearch
| attribute name | valid value | default value | description |
|---|---|---|---|
| origin |  | source_position |  |
| radius |  | - |  |
| targetscheme |  | - |  |
| ignoreinvulnerable |  | false |  |
| global |  | - |  |

### getcurtimer
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### starttimer
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| duration |  | - |  |
| durationb |  | - |  |
| durationop |  | - |  |
| applycooldownreduction |  | - |  |

### pausetimer
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| paused |  | - |  |

### resettimer
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### invalidate
Has no attributes

### startexpire
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### pushentityproxy
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| index |  | - |  |

### complete
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### cancel
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### distance
| attribute name | valid value | default value | description |
|---|---|---|---|
| usepathing |  | - |  |

### passability
| attribute name | valid value | default value | description |
|---|---|---|---|
| width |  | - |  |

### clearcriticals
Has no attributes

### ignorecriticalsonnextattack
Has no attributes

### clonebackpack
Has no attributes

### lockbackpack
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### reducecooldown
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| duration |  | - |  |

### activatemodifierkey
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| name |  | - |  |

### deactivatemodifierkey
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| name |  | - |  |

### foreachplayer
| attribute name | valid value | default value | description |
|---|---|---|---|
| excludebots |  | - |  |

### setteamsize
| attribute name | valid value | default value | description |
|---|---|---|---|
| team |  | - |  |
| size |  | - |  |

### changeteam
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| team |  | - |  |
| slot |  | -1 |  |

### setinterface
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| name |  | - |  |

### setoverlayinterface
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| name |  | - |  |
| blocking |  | - |  |

### spawnthread
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| ignorepause |  | - |  |

### while
| attribute name | valid value | default value | description |
|---|---|---|---|
| test |  | - |  |

### loop
Has no attributes

### whilescriptcondition
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| value |  | - |  |
| owner |  | - |  |
| entity |  | - |  |

### wait
| attribute name | valid value | default value | description |
|---|---|---|---|
| duration |  | - |  |

### yield
Has no attributes

### terminate
Has no attributes

### waitforclient
Has no attributes

### waitforallclientsfirstsnapshot
Has no attributes

### waituntilcompare
| attribute name | valid value | default value | description |
|---|---|---|---|
| a |  | - |  |
| b |  | - |  |
| op |  | - |  |

### waituntilcondition
| attribute name | valid value | default value | description |
|---|---|---|---|
| test |  | - |  |

### waituntilmessage
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| value |  | - |  |
| owner |  | - |  |
| entity |  | - |  |

### setscriptvalue
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| value |  | - |  |
| owner |  | - |  |
| entity |  | - |  |

### createcamera
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| position |  | - |  |
| target_position |  | - |  |
| pushentity |  | - |  |
| source |  | - |  |

### setcamera
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| camera |  | - |  |
| source |  | - |  |

### movecamera
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| positionentity |  | - |  |
| positionname |  | - |  |
| position |  | - |  |
| duration |  | - |  |
| interpolate |  | - |  |
| block |  | - |  |
| clientmode |  | - |  |
| locktoentity |  | - |  |
| refreshendposition |  | - |  |
| useindirectheight |  | - |  |
| newheight |  | - |  |

### movecamera3d
| attribute name | valid value | default value | description |
|---|---|---|---|
| value |  | - |  |

### setentitycullrange
| attribute name | valid value | default value | description |
|---|---|---|---|
| value |  | - |  |

### spawn
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| owner |  | - |  |

### spawnclientthread
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| ignorepause |  | - |  |

### clientuitrigger
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| param |  | - |  |
| value |  | - |  |

### translatestring
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### setowner
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| player |  | this_entity |  |

### sethero
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| hero |  | this_entity |  |

### setlevel
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| value |  | - |  |

### getlevel
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### maxlevel
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### setexperience
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| value |  | - |  |

### setgold
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| value |  | - |  |

### openshop
Has no attributes

### closeshop
Has no attributes

### lockshop
Has no attributes

### unlockshop
Has no attributes

### scriptcondition
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| value |  | - |  |
| owner |  | - |  |
| entity |  | - |  |

### setgamephase
| attribute name | valid value | default value | description |
|---|---|---|---|
| phase |  | - |  |
| duration |  | - |  |

### startmatch
Has no attributes

### activatespawner
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### giveitem
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| recipe |  | - |  |
| stash |  | - |  |
| pushentity |  | - |  |

### foreachitem
Has no attributes

### foreachability
Has no attributes

### lockitem
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### unlockitem
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### giveability
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| slot |  | - |  |
| proxy |  | - |  |

### lockcontrol
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### unlockcontrol
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### setaicontroller
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| controller |  | - |  |


### entitytype
| attribute name | valid value | default value | description |
|---|---|---|---|
| type |  | - |  |

### targettype
| attribute name | valid value | default value | description |
|---|---|---|---|
| type |  | - |  |

### forceimpact
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| immediate |  | - |  |

### pointonpath0
| attribute name | valid value | default value | description |
|---|---|---|---|
| width |  | - |  |
| team |  | - |  |
| ignoreunits |  | - |  |
| ignoretrees |  | - |  |
| ignorecliffs |  | - |  |
| ignorebuildings |  | - |  |
| distance |  | - |  |
| enddistance |  | - |  |

### lineofeffect
| attribute name | valid value | default value | description |
|---|---|---|---|
| start |  | source_position |  |
| end |  | target_position |  |
| targetscheme |  | - |  |
| effecttype |  | - |  |
| ignoreinvulnerable |  | - |  |
| targetselection |  | - |  |
| radius |  | - |  |
| maxtotalimpacts |  | - |  |
| maximpactspertarget |  | 1 |  |
| ignore |  | - |  |

### hasmodel
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| model |  | - |  |

### isitem
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### isability
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### issplitprojectile
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### haseffecttype
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| matchall |  | - |  |

### adjustscore
| attribute name | valid value | default value | description |
|---|---|---|---|
| value |  | - |  |
| op |  | - |  |

### random
| attribute name | valid value | default value | description |
|---|---|---|---|
| min |  | - |  |
| max |  | - |  |

### checkrax
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |

### setpower
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| value |  | - |  |
| valueb |  | - |  |
| valueop |  | - |  |

### hasqueuedorders
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |

### getconstant
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| adjustmentsource |  | this_entity |  |
| name |  | - |  |
| nameb |  | - |  |
| op |  | - |  |

### spawnlanepusher
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| lane |  | - |  |
| team |  | - |  |

### pushfrontoflaneposition
| attribute name | valid value | default value | description |
|---|---|---|---|
| lane |  | - |  |
| team |  | - |  |

### attachtocreepspawner
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_owner_entity |  |

### placehazard
| attribute name | valid value | default value | description |
|---|---|---|---|
| radius |  | - |  |
| duration |  | - |  |
| threat |  | - |  |

### playconductorevent
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| entity |  | this_entity |  |

### starttutoriallook
| attribute name | valid value | default value | description |
|---|---|---|---|
| radius |  | - |  |
| entity |  | - |  |
| position |  | - |  |

### addbot
| attribute name | valid value | default value | description |
|---|---|---|---|
| team |  | - |  |
| botname |  | - |  |
| unitname |  | - |  |
| startinactive |  | - |  |
| personality |  | - |  |

### removebot
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |

### setbotactiveflag
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |
| active |  | - |  |

### setbotdifficulty
| attribute name | valid value | default value | description |
|---|---|---|---|
| difficulty |  | - |  |

### padminimap
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |
| top |  | - |  |
| right |  | - |  |
| bottom |  | - |  |
| left |  | - |  |

### removeloadscreen
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | - |  |

### setcompassposition
Has no attributes

### disablecompass
Has no attributes

### iscurrentanim
| attribute name | valid value | default value | description |
|---|---|---|---|
| entity |  | this_entity |  |
| anim |  | - |  |
| channel |  | 0 |  |
| print |  | - |  |

### givepet
| attribute name | valid value | default value | description |
|---|---|---|---|
| player |  | - |  |
| level |  | - |  |
| petname |  | - |  |

### attach
| attribute name | valid value | default value | description |
|---|---|---|---|
| boneslot |  | 0 |  |

### changekillcredit
Has no attributes

### endmatch
| attribute name | valid value | default value | description |
|---|---|---|---|
| losingteam |  | 1 |  |

### announcement
| attribute name | valid value | default value | description |
|---|---|---|---|
| name |  | - |  |
| delay |  | 0 |  |
