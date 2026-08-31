
local AnimDef = {
    -- 受伤
    ON_HIT_CRAWL                = "OnHitCrawl", 
    ON_HIT_FORWARD              = "OnHitForward",
    ON_HIT_BACK                 = "OnHitBack",
    ON_HIT_LEFT                 = "OnHitLeft",
    ON_HIT_RIGHT                = "OnHitRight",

    -- 拾取
    PICK_UP                     = "Pickup",
    UN_ARMED_PICK               = "UnArmedPick",

    BATTLE_VICTORY              = "SettlementVictory",
    
    -- Vehicle
    IN_VEHICLE_LEFT             = "InVehicleLeft",
    IN_VEHICLE_RIGHT            = "InVehicleRight",
    LEAVE_VEHICLE               = "GetOutVehicle",
    
    -- Human Dead
    HUMAN_DEAD                  = "HumanDead",

    -- Jump
    JUMP_LOW                    = "JumpLow",
    JUMP_MID                    = "JumpMid",
    JUMP_HEIGHT                 = "JumpHeight",
    JUMP_MID_STAND              = "JumpMiddleStand",
    JUMP_HEIGHT_STAND           = "JumpHeightStand",

    -- JumpNew
    JUMP_LOW_NEW                = "JumpLowNew",
    JUMP_MID_NEW                = "JumpMidNew",
    JUMP_HEIGHT_NEW             = "JumpHeightNew",
    JUMP_MID_STAND_NEW          = "JumpMiddleStandNew",
    JUMP_HEIGHT_STAND_NEW       = "JumpHeightStandNew",

    -- StateChange
    UPRIGHT_TO_CRAWL            = "UpRightToCrawl",
    UPRIGHT_TO_CROUCH           = "UpRightToCrouch",

    CROUCH_TO_CRAWL             = "CrouchToCrawl",
    CROUCH_TO_UPRIGHT           = "CrouchToUpRight",

    CRAWL_TO_UPRIGHT            = "CrawlToUpRight",
    CRAWL_TO_CROUCH             = "CrawlToCrouch",

    AIM_UPRIGHT_TO_CRAWL        = "AimUpRightToCrawl",
    AIM_UPRIGHT_TO_CROUCH       = "AimUpRightToCrouch",

    AIM_CROUCH_TO_CRAWL         = "AimCrouchToCrawl",
    AIM_CROUCH_TO_UPRIGHT       = "AimCrouchToUpRight",

    AIM_CRAWL_TO_UPRIGHT        = "AimCrawlToUpRight",
    AIM_CRAWL_TO_CROUCH         = "AimCrawlToCrouch",   
    
    MEAIM_UPRIGHT_TO_CRAWL      = "MeAimUpRightToCrawl",
    MEAIM_UPRIGHT_TO_CROUCH     = "MeAimUpRightToCrouch",

    MEAIM_CROUCH_TO_CRAWL       = "MeAimCrouchToCrawl",
    MEAIM_CROUCH_TO_UPRIGHT     = "MeAimCrouchToUpRight",

    MEAIM_CRAWL_TO_UPRIGHT      = "MeAimCrawlToUpRight",
    MEAIM_CRAWL_TO_CROUCH       = "MeAimCrawlToCrouch",

    -- weapon
    LONG_GUN_PRIMARY_HOLDED     = "LongGunPrimaryHoldedMontage",
    LONG_GUN_PRIMARY_UNHOLDED   = "LongGunPrimaryUnholdedMontage",
    LONG_GUN_SECONDARY_HOLDED   = "LongGunSecondaryHoldedMontage",
    LONG_GUN_SECONDARY_UNHOLDED = "LongGunSecondaryUnholdedMontage",
    LONG_GUN_RELOAD             = "LongGunReloadMontage",

    HAND_GUN_PRIMARY_HOLDED     = "HandGunPrimaryHoldedMontage",
    HAND_GUN_PRIMARY_UNHOLDED   = "HandGunPrimaryUnholdedMontage",
    HAND_GUN_SECONDARY_HOLDED   = "HandGunSecondaryHoldedMontage",
    HAND_GUN_SECONDARY_UNHOLDED = "HandGunSecondaryUnholdedMontage",
    HAND_GUN_RELOAD             = "HandGunReloadMontage",

    MELEE_PRIMARY_HOLDED        = "MeleePrimaryHoldedMontage",
    MELEE_PRIMARY_UNHOLDED      = "MeleePrimaryUnholdedMontage",
    MELEE_SECONDARY_HOLDED      = "MeleeSecondaryHoldedMontage",
    MELEE_SECONDARY_UNHOLDED    = "MeleeSecondaryUnholdedMontage",

    EXPLOSIVE_HOLDED            = "ExplosiveHoldedMontage",
    EXPLOSIVE_UNHOLDED          = "ExplosiveTakeBackMontage",

    ON_GUN_FIRE                 = "HumanAttack",
    ON_GUN_AIM_FIRE             = "AimHumanAttack",
    ON_GUN_HOLD_TO_AIM          = "HoldToAim",

    ON_BOW_PRE_ATTACK           = "BowPreAttack",
    ON_BOW_POST_ATTACK          = "BowPostAttack",
    ON_BOW_AIM_PRE_ATTACK       = "AimBowPreAttack",
    ON_BOW_AIM_POST_ATTACK      = "AimBowPostAttack",
 
    -- SHIP
    SHIP_TO_HUMAN               = "ShipToHuman",
}

AnimDef.SectionName = {
    ON_SPEEL_END                = "OnSpeelEnd", -- speel_end
    ATTACH_SECTION_KEY          = "attach",

    END_ROOTMOTION_TIME         = "end_rootmotion",

    -- weapon
    --melee
    MELEE_ATTACK_END            = "end",
    MELEE_HIT_TIME              = "hit_time",
    --bow
    BOW_ATTACK_START            = "Default", -- start
    BOW_ATTACK_LOOP             = "Loop", -- loop

    --wand
    WAND_FIRE                   = "Fire",

    --throw
    THROW_ATTACK_LOOP           = "loop",

    -- vehicle
    LEAVE_VEHICLE_END           = "end_section",
    IN_VEHICLE_END              = "end_section",

    ROOTMOTION_STARTPOS_CORRECTION = "start_correctsection",
    ROOTMOTION_FINALPOS_CORRECTION = "final_correctsection",

    --progress
    PROGRESS_END                = "End" -- end
}

return AnimDef