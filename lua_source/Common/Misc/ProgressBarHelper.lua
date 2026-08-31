local HumanMovementStateType = require("HumanMovementStateType")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local ProgressBarStateType = require("ProgressBarStateType")
local ProgressBarTableNew = require("ProgressBarTableNew")
local HumanWeaponHelper = require("HumanWeaponHelper")
local ReplicateHelper = require("ReplicateHelper")
local PropName = require("PropName")
local AnimationResDataTable = require("AnimationResDataTableNew")

local GetValueFromRepComponent = ReplicateHelper.GetValueFromRepComponent
local NO_PROGRESSBAR = 0
local DEFAULT_HUMAN_TEMPLATE_ID = 100000

local ProgressBarHelper = {}

function ProgressBarHelper.CanStartHumanProgressBar(GamePlayer, bIngoreSwimming)
    local bCanStart = true
    if GamePlayer and GamePlayer:IsHuman() then
        local HumanMovementStateComponent = GamePlayer.HumanMovementStateComponent
        if not HumanMovementStateComponent then 
            return false
        end
        local nMovementState = HumanMovementStateComponent:GetCurrentState()
        if HumanMovementStateComponent.bIsCrouching and nMovementState == HumanMovementStateType.Crawl_State then  
            bCanStart = false 
        end 
        if bCanStart then
            if nMovementState == HumanMovementStateType.Jumping_SpeelWall
                or (not bIngoreSwimming and nMovementState == HumanMovementStateType.Swimming) then
                bCanStart = false
            end
        end
        if bCanStart then
            local nVehicleState = HumanMovementStateComponent:GetVehicleState()
            if nVehicleState == HumanVehicleStateDef.PreDetachFromVehicle or nVehicleState == HumanVehicleStateDef.PreAttachToVehicle then 
                bCanStart = false
            end
        end
        if bCanStart then
            local nWeaponState = GamePlayer.HumanWeaponComponent:GetCurrentState()
            if nWeaponState == HumanWeaponStateDef.ATTACKING or nWeaponState == HumanWeaponStateDef.HOLDING then
                bCanStart = false
            end
        end
    end
    if not bCanStart then
        UIUtils.ShowToast(UITextDef.CANNOT_START_PROGRESSBAR)
    end
    return bCanStart
end

function ProgressBarHelper.GetHumanProgressBarResClassPath(pRepComponent, nTemplatedId, tbOutPaths)
    local tbProgressBar = GetValueFromRepComponent(pRepComponent, PropName.ProgressBar)
    if tbProgressBar and tbProgressBar.nTemplateId then
        if tbProgressBar.nTemplateId ~= NO_PROGRESSBAR and tbProgressBar.nState == ProgressBarStateType.Start then
            local tbProgressBarTable = ProgressBarTableNew:GetTemplate(tbProgressBar.nTemplateId)

            local nCurrentState = GetValueFromRepComponent(pRepComponent, PropName.HumanMovementState)
            local szActionKey
            if nCurrentState == HumanMovementStateType.UpRight_State then
                szActionKey = tbProgressBarTable.nHumanStandActionKey
            elseif nCurrentState == HumanMovementStateType.Crouch_State then
                szActionKey = tbProgressBarTable.nHumanCrouchActionKey
            elseif nCurrentState == HumanMovementStateType.Crawl_State then
                szActionKey = tbProgressBarTable.nHumanCrawlActionKey
            else
                szActionKey = tbProgressBarTable.nHumanStandActionKey
            end
                -- if tbPlayer.HumanMovementStateComponent:IsInVehicle() then
                --     self.szActionKey = tbProgressBarTable.nHumanCarrierActionKey and tbProgressBarTable.nHumanCarrierActionKey or self.szActionKey
                -- end
            if szActionKey then
                local nWeaponTemplateId = GetValueFromRepComponent(pRepComponent, PropName.HumanMovementState)
                local nArmorId = GetValueFromRepComponent(pRepComponent, PropName.nCurrentArmorTemplateId)
                local nCategory = HumanWeaponHelper.GetWeaponCategory(nWeaponTemplateId)
                local tbParams = {}
                tbParams.nStateId = nCurrentState
                tbParams.nWeaponId = nWeaponTemplateId
                tbParams.nWeaponCategory = nCategory
                tbParams.nArmorId = nArmorId
                tbParams.nTemplateId = nTemplatedId
                tbParams.szAnimKey = szActionKey
                tbParams.nDefaultTemplateId = DEFAULT_HUMAN_TEMPLATE_ID

                local tbTemplate = AnimationResDataTable:GetTemplate(tbParams)
                if tbTemplate then  
                    if tbTemplate.szAnimation then 
                        table.insert(tbOutPaths, tbTemplate.szAnimation)
                    end 

                    if tbTemplate.szRootMotion then 
                        table.insert(tbOutPaths, tbTemplate.szRootMotion)
                    end         
                end
            end
        end
    end

end


return ProgressBarHelper