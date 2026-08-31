local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULWatchBattleProgressBar = luaclass("ULWatchBattleProgressBar", UILogicBase)

local CommonEventDef = require("CommonEventDef")
local ProgressBarTableNew = require("ProgressBarTableNew")
local SoundManager = require("SoundManager")
local DelayTimer = require("DelayTimer")

ULWatchBattleProgressBar.tbSound = nil
ULWatchBattleProgressBar.DelayPlaySoundTimer = nil



local function PlaySound(self, tbPlayer, tbProgressBarTable)
    local nSoundId = nil
    local nSoundDelay = 0
    if tbPlayer:IsHuman() then
        nSoundId = tbProgressBarTable.nHumanSoundId
        -- logdebug("sound bar id :", nSoundId)
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
            -- logdebug("play sound now", self.tbSound)
        end
        if nSoundDelay > 0 then
            self.DelayPlaySoundTimer = DelayTimer:DelayRun(DelayPlaySound, nSoundDelay)
        else
            DelayPlaySound()
        end
    end
end

--bStart = true 就是开始 false代表结束或者被打断
local function OnMateProgressBarChanged(self, nInstanceId, bStart, nProgressBarId, nTime)
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    if tbCurrentWatchObj:GetServerInstanceId() == nInstanceId then 
        local pProgressBar = self.Owner.pbProgressBar 
        if bStart then  
            local tbProgressBarTable = ProgressBarTableNew:GetTemplate(nProgressBarId)
            if tbProgressBarTable then  
                -- logdebug("progress bar start", nProgressBarId)
                self:ClearProgressBar()
                PlaySound(self, tbCurrentWatchObj, tbProgressBarTable)
                pProgressBar:OnProgressBarChanged(nInstanceId, bStart,nProgressBarId, nTime)
            end

            log("[WatchProgress] : OnMateProgressBarChanged Enter")
        else  
            -- logdebug("progress bar end", nProgressBarId)
            self:ClearProgressBar()
            pProgressBar:OnEndProgressBar(nProgressBarId)
            log("[WatchProgress] : OnMateProgressBarChanged Out")
        end
    end
end

function ULWatchBattleProgressBar:ClearProgressBar()
    -- logdebug("clear progress bar sound ", self.tbSound)

    log("[WatchProgress] : ClearProgressBar Enter")
    if self.tbSound then
        log("[WatchProgress] : ClearProgressBar SoundStop")
        self.tbSound:Stop()
        SoundManager:DeleteSound(self.tbSound)
        self.tbSound = nil
    end
end

function ULWatchBattleProgressBar:RefreshCurrentProgressBarState()
    local Owner = self.Owner
    if Owner.tbLastWatchObj == nil or Owner.tbCurrrentWatchObj == nil then
        self.Owner.pbProgressBar:SetVisible(ESlateVisibility.Collapsed)
    end

    if Owner.tbLastWatchObj and Owner.tbCurrrentWatchObj then  
        local bIsChangeDisplay = Owner.tbLastWatchObj:IsShip() ~= Owner.tbCurrrentWatchObj:IsShip()  
        if bIsChangeDisplay then  
            self.Owner.pbProgressBar:SetVisible(ESlateVisibility.Collapsed)
        end
    end
    self:ClearProgressBar()
end

function ULWatchBattleProgressBar:OnLoad()
    -- bind prefab
end  

function ULWatchBattleProgressBar:OnEnter() 
    --Owner is UIWatchBattle
    --local Owner = self.Owner
end


function ULWatchBattleProgressBar:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_PROGRESS_CHANGED, self, OnMateProgressBarChanged)
end

function ULWatchBattleProgressBar:OnUnload()
    --unload res
end

return ULWatchBattleProgressBar