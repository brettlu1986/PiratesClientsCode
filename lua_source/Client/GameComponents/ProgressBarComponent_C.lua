local luaclass = require("luaclass")
local ProgressBarComponent = require("ProgressBarComponent")
local ProgressBarComponent_C = luaclass("ProgressBarComponent_C", ProgressBarComponent)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")
local AbortTypeDefine = require("AbortTypeDefine")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local ProgressBarTableNew = require("ProgressBarTableNew")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local SoundManager = require("SoundManager")
local HumanMovementStateType = require("HumanMovementStateType")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local SelfAnimationHelper = require("SelfAnimationHelper")
local UEActorHelper = require("UEActorHelper")
local ProgressBarStateType = require("ProgressBarStateType")
local SelfEventHelperClass = require("SelfEventHelper")
local ProtoDC = require("DungeonCommonProtoNames")
local DelayTimer = require("DelayTimer")
local HumanCommonIni = require("HumanCommonIni")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local CommonEventDef = require("CommonEventDef")
local BattleAbilitySystem = require("BattleAbilitySystem")
local UIManager = require("UIManager")
local AnimDef = require("AnimDef")
local ResourceManager = require("ResourceManager")

local NO_PROGRESSBAR = 0
ProgressBarComponent_C.pEffect = nil
ProgressBarComponent_C.bInProgress = nil
ProgressBarComponent_C.pAttachedActor = nil
ProgressBarComponent_C.EventHelper = nil
ProgressBarComponent_C.tbSound = nil
ProgressBarComponent_C.DelayTimer = nil
ProgressBarComponent_C.DelayPlaySoundTimer = nil
ProgressBarComponent_C.szActionKey = nil
ProgressBarComponent_C.nHoldWeapon = 0
ProgressBarComponent_C.ReholdDelayTimer = nil 
ProgressBarComponent_C.bServer = false 
ProgressBarComponent_C.nAttachedActorLoadHandler = nil
ProgressBarComponent_C.nEndSectionLength = nil

function ProgressBarComponent_C:Start(nTemplateId, tbParams, fnOnFinished, fnOnAborted, nNewTime)
    -- EventManager:OnFireEvent(CommonEventDef.EV_INTERRUPT_CONTINUOUS_RUN)
    if self.bServer then
        return ProgressBarComponent_C.super.Start(self,nTemplateId,tbParams, fnOnFinished, fnOnAborted, nNewTime)
    else
        NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_StartProgressBar, {template_id = nTemplateId})
        return true
    end
end

local function ReholdLastWeapon(self)
    local SelfPlayer = PlayerSelfHelper:Get()
    local nSelfInstanceId = SelfPlayer:GetServerInstanceId()
    local nInstanceId = self.Owner:GetServerInstanceId()

    local nHoldWeapon = self.nHoldWeapon
    if nInstanceId == nSelfInstanceId and self.Owner:IsHuman() and nHoldWeapon ~= 0 then
        log("[ProgressBarComponent] ReholdLastWeapon", nHoldWeapon)
        BattleHumanWeaponSystemNew:RequestSetCurrentWeapon(nHoldWeapon)
        self.nHoldWeapon = 0
    end
end

local function StartReholdLastWeapon(self)
    local SelfPlayer = PlayerSelfHelper:Get()
    local nSelfInstanceId = SelfPlayer:GetServerInstanceId()
    local nInstanceId = self.Owner:GetServerInstanceId()

    if nInstanceId ~= nSelfInstanceId or self.nHoldWeapon == 0 then 
        return 
    end

    if self.ReholdDelayTimer ~= nil then  
        log("[ProgressBarComponent] StartReholdLastWeapon ", self.Owner.szName)
        DelayTimer:ClearTimer(self.ReholdDelayTimer)
        self.ReholdDelayTimer = nil 
    end 
    log("[ProgressBarComponent] StartReholdLastWeapon StartTimer ", self.Owner.szName)
    local nDelayTime = HumanCommonIni.tbHumanCommonData.nDelayReholdTime
    if self.nEndSectionLength and nDelayTime < self.nEndSectionLength then 
        nDelayTime = self.nEndSectionLength
    end 
    self.ReholdDelayTimer = DelayTimer:DelayRun(function()
        log("[ProgressBarComponent] RequestSetCurrentWeapon TimerEnd ", self.Owner.szName)
        ReholdLastWeapon(self)
    end, nDelayTime)
end 
-- 主动打断
function ProgressBarComponent_C:Abort()
    StartReholdLastWeapon(self)
    local SelfPlayer = PlayerSelfHelper:Get()
    self:ClientClearProgressBar(SelfPlayer)
    self:ClearDisplay(SelfPlayer)

    if self.bServer then
        ProgressBarComponent_C.super.Abort(self)
    else
        -- log("ProgressBarComponent Abort", self.Owner.szName, debug.traceback())
        NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_AbortProgressBar, {abort_type = AbortTypeDefine.CANCEL})
    end
end

function ProgressBarComponent_C:OnActorCreated(pUEActor)
    ProgressBarComponent_C.super.OnActorCreated(self, pUEActor)

    self.bServer = GlobalVariableSystem:IsServerLogic()
    local tbProgressBar = self.rProgressBar:Get()
    if tbProgressBar and tbProgressBar.nTemplateId then
        log("[ProgressBarComponent] on actor created ", self.Owner.szName, tbProgressBar.nTemplateId, tbProgressBar.nState)
    end
    if tbProgressBar and tbProgressBar.nTemplateId and tbProgressBar.nTemplateId ~= NO_PROGRESSBAR 
        and tbProgressBar.nState == ProgressBarStateType.Start then
        local tbProgressBarTable = ProgressBarTableNew:GetTemplate(tbProgressBar.nTemplateId)
        if tbProgressBarTable then
            self:Display(self.Owner, tbProgressBarTable)
        end
    end

    if not self.EventHelper then 
        self.EventHelper = SelfEventHelperClass()
    end
    
    self.EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_STATE_CHANGED_CLIENT, self, self.OnWeaponStateChanged)  
    if self.ReholdDelayTimer ~= nil then  
        DelayTimer:ClearTimer(self.ReholdDelayTimer)
        self.ReholdDelayTimer = nil 
    end 
end

function ProgressBarComponent_C:PlaySound(tbPlayer, tbProgressBarTable)
    local nSoundId = nil
    local nSoundDelay = 0
    if tbPlayer:IsHuman() then
        nSoundId = tbProgressBarTable.nHumanSoundId
        nSoundDelay = tbProgressBarTable.nHumanSoundDelay
    else
        nSoundId = tbProgressBarTable.nShipSoundId
        nSoundDelay = tbProgressBarTable.nShipSoundDelay
    end
    if nSoundId > 0 then
        if self.tbSound then
            SoundManager:DeleteSound(self.tbSound)
            self.tbSound = nil
        end
        if self.DelayPlaySoundTimer then
            DelayTimer:ClearTimer(self.DelayPlaySoundTimer)
            self.DelayPlaySoundTimer = nil
        end

        local DelayPlaySound = function()
            self.tbSound = SoundManager:PlaySoundEffect(nSoundId, false)
        end
        if nSoundDelay > 0 then
            self.DelayPlaySoundTimer = DelayTimer:DelayRun(DelayPlaySound, nSoundDelay)
        else
            DelayPlaySound()
        end
    end
end
local function UnHoldWeapon(self, bForce)
    local Owner = self.Owner
    local HumanWeaponComponent = Owner.HumanWeaponComponent
    if not HumanWeaponComponent then  
        return 
    end 
    local nCurrnetWeapon = HumanWeaponComponent:GetCurrentWeaponInstanceId()
    if nCurrnetWeapon == self.nHoldWeapon then 
        return 
    end
    
    -- if self.ReholdDelayTimer then  
    --     DelayTimer:ClearTimer(self.ReholdDelayTimer)
    --     self.ReholdDelayTimer = nil 
    -- end 
    
    if nCurrnetWeapon ~= 0 then 
        -- 先存，这个为了变船处理的
        -- BattleHumanWeaponSystemNew:SaveCurrentWeaponToOwner(Owner)
        -- 具体cancelattack的操作客户端自己处理
        BattleHumanWeaponSystemNew:RequestSetCurrentWeapon(0, true)
        if bForce then 
            local StateHelper = HumanWeaponComponent.StateHelper
            StateHelper:ChangeState(HumanWeaponStateDef.UNHOLDED, true)        
        end
        
        if not HumanWeaponComponent:FindWeaponById(self.nHoldWeapon) then  
            self.nHoldWeapon = nCurrnetWeapon
        end
        log("[ProgressBarComponent] UnHoldWeapon", self.Owner.szName, nCurrnetWeapon)
    end 
end
function ProgressBarComponent_C:OnProgressBarChanged(Property, tbNewProgressBar)
    ProgressBarComponent_C.super.OnProgressBarChanged(self, Property, tbNewProgressBar)
    if tbNewProgressBar == nil or tbNewProgressBar.nTemplateId == nil then
        log("[ProgressBarComponent] change but no progressbar ")
        return
    end
    if tbNewProgressBar.nState == nil then
        self:ClearDisplay(Property._tbObject.Owner)
        log("[ProgressBarComponent] change but progressbar state is nil ", tbNewProgressBar.nTemplateId)
        return
    end
    local SelfPlayer = PlayerSelfHelper:Get()
    local nSelfInstanceId = SelfPlayer:GetServerInstanceId()
    if Property == nil then
        return
    end
    local TargetPlayer = Property._tbObject.Owner
    local nInstanceId = TargetPlayer:GetServerInstanceId()
    local nProgressBarId = tbNewProgressBar.nTemplateId
    local nEffectId = 0
    local tbProgressBarTable = ProgressBarTableNew:GetTemplate(nProgressBarId)
    if nProgressBarId ~= NO_PROGRESSBAR and tbNewProgressBar.nState < ProgressBarStateType.Abort then
        if(tbProgressBarTable == nil) then
            error("ProgressBarComponent_C:OnProgressBarChanged GetTemplate Error. nTemplateId: "..tostring(nProgressBarId))
        end

        local Owner = self.Owner
        if nInstanceId == nSelfInstanceId and Owner:IsHuman() then
            self:ClearRehold()
            UnHoldWeapon(self)
        end

        self:ClearDisplay(TargetPlayer)
        self:Display(TargetPlayer, tbProgressBarTable)

        -- 是自己
        if nInstanceId == nSelfInstanceId then
            self:ClientClearProgressBar(TargetPlayer)
            self:RegisterAbortEvent(tbProgressBarTable, tbProgressBarTable.bHumanCrawlToCrouch, tbProgressBarTable.bIgnoreAbortByMove)
            self:PlaySound(TargetPlayer, tbProgressBarTable)
            self.bInProgress = true
        else
            self.bInProgress = true
        end

        EventManager:OnFireEvent(CommonEventDef.EV_PROGRESS_CHANGED, nInstanceId, true, nProgressBarId, tbNewProgressBar.nTime)
    else
        self.bInProgress = false
        StartReholdLastWeapon(self)
        self:ClearDisplay(TargetPlayer)
        EventManager:OnFireEvent(CommonEventDef.EV_PROGRESS_CHANGED, nInstanceId, false, nProgressBarId, tbNewProgressBar.nTime)
        if nInstanceId == nSelfInstanceId then
            self:ClientClearProgressBar(TargetPlayer)
            if tbNewProgressBar.nState == ProgressBarStateType.Finish then
                if tbProgressBarTable.szFinishUIName then
                    UIManager:OpenWnd(tbProgressBarTable.szFinishUIName)
                end

                if tbProgressBarTable.nFinishSoundId > 0 then
                    SoundManager:PlaySoundEffect(tbProgressBarTable.nFinishSoundId, true)
                end
            end
        end
        if tbNewProgressBar.nState == ProgressBarStateType.Abort then
            nEffectId = tbProgressBarTable.nAbortEffectId
        end
    end

    if nEffectId > 0 then
        if self.pEffect then
            log("[ProgressBarComponent] changed and stop effect ", TargetPlayer and TargetPlayer.szName)
            BattleAbilitySystem:StopParticleEffect(TargetPlayer, self.pEffect)
            self.pEffect = nil
        end
        log("[ProgressBarComponent] changed and play effect ", TargetPlayer and TargetPlayer.szName, nEffectId)
        self.pEffect = BattleAbilitySystem:PlayParticleEffect(TargetPlayer, nEffectId)
    end    
end

local function DetachFromAnimation(self)
    if self.nAttachedActorLoadHandler then
        ResourceManager:CancelLoadAsync(self.nAttachedActorLoadHandler)
        self.nAttachedActorLoadHandler = nil
    end    
    if self.pAttachedActor ~= nil then
        self.pAttachedActor:OnDetached()
        self.pAttachedActor = nil
    end
end

local function AttachToAnimation(self, tbPlayer, szAttachedActor)
    if tbPlayer == nil or tbPlayer.pUEActor == nil or szAttachedActor == nil then
        return
    end
    self.nAttachedActorLoadHandler = ResourceManager:LoadAsync(szAttachedActor, function()
        local _, pActor = UEActorHelper:CreateActor(szAttachedActor)
        if pActor ~= nil then
            local IsMale = true
            if tbPlayer.pUEActor.Gender ~= ENUM_HumanGender.Male then  
                IsMale = false 
            end
            pActor:OnAttached(nil, tbPlayer.pUEActor.Mesh, IsMale)

            DetachFromAnimation(self)
            self.pAttachedActor = pActor
        end
    end)
end

function ProgressBarComponent_C:OnActorDestroyed(pUEActor)
    if self.bInProgress then  
        local tbProgressBar = self.rProgressBar:Get()
        local nInstanceId = self.Owner:GetServerInstanceId()
        if tbProgressBar then 
            local tbPlayerSelf = PlayerSelfHelper:Get()
            if tbPlayerSelf and nInstanceId == tbPlayerSelf:GetServerInstanceId() then
                local tbProgressBarTable = ProgressBarTableNew:GetTemplate(tbProgressBar.nTemplateId)
                if tbProgressBarTable.szFinishUIName then
                    UIManager:OpenWnd(tbProgressBarTable.szFinishUIName)
                end

                if tbProgressBarTable.nFinishSoundId > 0 then
                    SoundManager:PlaySoundEffect(tbProgressBarTable.nFinishSoundId, true)
                end
            end
            EventManager:OnFireEvent(CommonEventDef.EV_PROGRESS_CHANGED, nInstanceId, false, tbProgressBar.nTemplateId, tbProgressBar.nTime)
        end
    end
    self.bInProgress = nil

    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end
    if self.DelayTimer then
        DelayTimer:ClearTimer(self.DelayTimer)
        self.DelayTimer = nil
    end
    if self.DelayPlaySoundTimer then
        DelayTimer:ClearTimer(self.DelayPlaySoundTimer)
        self.DelayPlaySoundTimer = nil
    end

    if self.ReholdDelayTimer ~= nil then  
        DelayTimer:ClearTimer(self.ReholdDelayTimer)
        self.ReholdDelayTimer = nil 
    end 
        
    self.szActionKey = nil
    DetachFromAnimation(self)
    ProgressBarComponent_C.super.OnActorDestroyed(self, pUEActor)
end

function ProgressBarComponent_C:ClearRehold()
    self.nHoldWeapon = 0
    if self.ReholdDelayTimer then  
        DelayTimer:ClearTimer(self.ReholdDelayTimer)
        self.ReholdDelayTimer = nil 
    end 
end
function ProgressBarComponent_C:ClearDisplay(TargetPlayer)
    if self.pEffect then
        log("[ProgressBarComponent] clear display ", TargetPlayer and TargetPlayer.szName)
        BattleAbilitySystem:StopParticleEffect(TargetPlayer, self.pEffect)
        self.pEffect = nil
    end
    DetachFromAnimation(self)
    if TargetPlayer and self.szActionKey then
        if TargetPlayer:IsHuman() then
            if self.pHumanMontage then 
                SelfAnimationHelper:JumpToMontageSection(TargetPlayer.pUEActor.Mesh, self.pHumanMontage, AnimDef.SectionName.PROGRESS_END)
            end 
            self.pHumanMontage = nil
            -- SelfAnimationHelper:HumanJumpToMontageSection(TargetPlayer, AnimDef.SectionName.PROGRESS_END, self.szActionKey, self)
        else
            SelfAnimationHelper:ShipJumpToMontageSection(TargetPlayer, AnimDef.SectionName.PROGRESS_END, self.szActionKey)
        end
    end

    SelfAnimationHelper:ClearOwnerCache(self)
    self.szActionKey = nil
    -- if self.EventHelper then
    --     self.EventHelper:UnregisterAll()
    --     self.EventHelper = nil
    -- end
    if self.DelayTimer then
        DelayTimer:ClearTimer(self.DelayTimer)
        self.DelayTimer = nil
    end
    if self.DelayPlaySoundTimer then
        DelayTimer:ClearTimer(self.DelayPlaySoundTimer)
        self.DelayPlaySoundTimer = nil
    end
end

function ProgressBarComponent_C:ClientClearProgressBar(bDestroyed)
    if self.EventReciever and self.EventReciever.Uninit then
        self.EventReciever:Uninit()
    end

    if self.tbSound then
        SoundManager:DeleteSound(self.tbSound)
        self.tbSound = nil
    end
    self.bInProgress = nil
end

function ProgressBarComponent_C:ClearProgressBar(bDestroyed)
    ProgressBarComponent_C.super.ClearProgressBar(self,bDestroyed)
    
    self:ClientClearProgressBar(bDestroyed)
end

local function OnMovementStateChanged(nState)
    local PlayerSelf = PlayerSelfHelper:Get()
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    local nCurState = HumanMovementStateComponent:GetCurrentState() 
    if nCurState == HumanMovementStateType.Parachutine_State
        or nCurState == HumanMovementStateType.Falling_State then
        logerror("ProgressBarComponent_C:OnMovementStateChanged:", debug.traceback(  ))
        return
    end

    local c2d_ChangeMovementState =
    {
        movement_state = nState
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_ChangeMovementState, c2d_ChangeMovementState)
end

local DisplayImp = function(self, tbPlayer, tbProgressBarTable)
    local nEffectId = nil
    self.nEndSectionLength = 0
    if tbPlayer:IsHuman() then
        if tbPlayer.HumanMovementStateComponent then
            local nCurrentState = tbPlayer.HumanMovementStateComponent:GetCurrentState()
            if nCurrentState == HumanMovementStateType.UpRight_State then
                self.szActionKey = tbProgressBarTable.nHumanStandActionKey
            elseif nCurrentState == HumanMovementStateType.Crouch_State then
                self.szActionKey = tbProgressBarTable.nHumanCrouchActionKey
            elseif nCurrentState == HumanMovementStateType.Crawl_State then
                self.szActionKey = tbProgressBarTable.nHumanCrawlActionKey
            else
                self.szActionKey = tbProgressBarTable.nHumanStandActionKey
            end
            if tbPlayer.HumanMovementStateComponent:IsInVehicle() then
                self.szActionKey = tbProgressBarTable.nHumanCarrierActionKey and tbProgressBarTable.nHumanCarrierActionKey or self.szActionKey
            end
        end
        self.bPlayAnimation = false
        nEffectId = tbProgressBarTable.nHumanEffectId
        -- 收枪完成后播放
        if self.szActionKey then
            local nCurrentState = HumanWeaponStateDef.NONE
            if tbPlayer.HumanWeaponComponent then
                nCurrentState = tbPlayer.HumanWeaponComponent:GetCurrentState()
            end
            -- 此处为了处理时序改为当存在读条时一直监听武器状态改变事件。
            -- 当读条中收到UNHOLDED状态时候强制再播放一遍动作。
            -- UNHOLDING状态时候把之前手中绑定的消耗品清理除。以免随着枪械播放。
            if nCurrentState == HumanWeaponStateDef.UNHOLDED
            or nCurrentState == HumanWeaponStateDef.NONE then
                AttachToAnimation(self, tbPlayer, tbProgressBarTable.szAttachedActor)
                SelfAnimationHelper:PlayHumanAnimation(tbPlayer, self.szActionKey, 1, true, self)
                self.bPlayAnimation = true
                local szMontage = SelfAnimationHelper:GetHumanAnimation(tbPlayer, self.szActionKey)
                if szMontage then 
                    self.pHumanMontage = SelfAnimationHelper:GetCacheMontage(self, szMontage)
                    self.nEndSectionLength = ExtendBlueprintFunctions.GetMontageSectionLength(self.pHumanMontage, AnimDef.SectionName.PROGRESS_END)
                end
            end
        end
    else
        self.szActionKey = tbProgressBarTable.nShipActionKey
        nEffectId = tbProgressBarTable.nShipEffectId

        if self.szActionKey then
            AttachToAnimation(self, tbPlayer, tbProgressBarTable.szAttachedActor)
            SelfAnimationHelper:PlayShipAnimation(tbPlayer, nil, self.szActionKey)
        end
    end

    if nEffectId > 0 then
        if self.pEffect then
            log("[ProgressBarComponent] stop old effect ", tbPlayer.szName)
            BattleAbilitySystem:StopParticleEffect(tbPlayer, self.pEffect)
            self.pEffect = nil
        end
        
        log("[ProgressBarComponent] play effect ", tbPlayer.szName, nEffectId, tbProgressBarTable.nID)
        self.pEffect = BattleAbilitySystem:PlayParticleEffect(tbPlayer, nEffectId)
    end
end


function ProgressBarComponent_C:OnWeaponStateChanged(nState, Owner)
    local tbPlayer = self.Owner
    local SelfPlayer = PlayerSelfHelper:Get()
    local nSelfInstanceId = SelfPlayer:GetServerInstanceId()
    local nInstanceId = Owner:GetServerInstanceId()
    if tbPlayer == Owner then 
        if self:IsInProgress() and nState == HumanWeaponStateDef.UNHOLDED then
            local tbProgressBar = self.rProgressBar:Get()
            if tbProgressBar and tbProgressBar.nTemplateId and tbProgressBar.nTemplateId ~= NO_PROGRESSBAR and not self.bPlayAnimation then
                local tbProgressBarTable = ProgressBarTableNew:GetTemplate(tbProgressBar.nTemplateId)
                if tbProgressBarTable then
                    AttachToAnimation(self, tbPlayer, tbProgressBarTable.szAttachedActor)
                    SelfAnimationHelper:PlayHumanAnimation(tbPlayer, self.szActionKey, 1, true, self)
                    self.bPlayAnimation = true
                    local szMontage = SelfAnimationHelper:GetHumanAnimation(tbPlayer, self.szActionKey)
                    if szMontage then 
                        self.pHumanMontage = SelfAnimationHelper:GetCacheMontage(self, szMontage)
                        self.nEndSectionLength = ExtendBlueprintFunctions.GetMontageSectionLength(self.pHumanMontage, AnimDef.SectionName.PROGRESS_END)
                    end                    
                end
            end
        elseif nInstanceId == nSelfInstanceId and nState == HumanWeaponStateDef.HOLDED then
            if self:IsInProgress() or self.nHoldWeapon ~= 0 then 
                UnHoldWeapon(self, true)
            else  
                if self.ReholdDelayTimer then  
                    log("[ProgressBarComponent] OnWeaponStateChanged", self.Owner.szName)
                    DelayTimer:ClearTimer(self.ReholdDelayTimer)
                    self.ReholdDelayTimer = nil 
                end 
                self.nHoldWeapon = 0
            end 
        end
        if self:IsInProgress() and nState == HumanWeaponStateDef.UNHOLDING then
            DetachFromAnimation(self)
        end
    end
end

function ProgressBarComponent_C:Display(tbPlayer, tbProgressBarTable)
    if tbPlayer:IsHuman() then
        if tbPlayer.HumanMovementStateComponent then
            local nCurrentState = tbPlayer.HumanMovementStateComponent:GetCurrentState()
            if tbProgressBarTable.bHumanCrawlToCrouch
                and nCurrentState == HumanMovementStateType.Crawl_State then
                local SelfPlayer = PlayerSelfHelper:Get()
                if SelfPlayer == tbPlayer then
                    OnMovementStateChanged(HumanMovementStateType.Crouch_State)
                    EventManager:OnFireEvent(ClientEventDef.EV_FFA_HUMAN_CRAWL_TO_CROUCH)
                end
                self.DelayTimer = DelayTimer:DelayRun(function()
                    DisplayImp(self, tbPlayer, tbProgressBarTable)
                end, 1)
            else
                DisplayImp(self, tbPlayer, tbProgressBarTable)
            end
        end
    else
        DisplayImp(self, tbPlayer, tbProgressBarTable)
    end
end

function ProgressBarComponent_C:IsInProgress()
    return self.bInProgress
end

return ProgressBarComponent_C