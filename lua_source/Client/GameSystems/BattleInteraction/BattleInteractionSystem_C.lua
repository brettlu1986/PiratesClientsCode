-- Register Managers those used for Common module

local luaclass = require("luaclass")
local BattleInteractionSystemClass = require("BattleInteractionSystem")
local BattleInteractionSystem_C = luaclass("BattleInteractionSystem_C", BattleInteractionSystemClass)
local UEClientActorHelper = require("UEClientActorHelper")
local UIManager = require("UIManager")
local InteractionHelper = require("InteractionHelper")

local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")
local SelfEventHelper = require("SelfEventHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")
local UIStateDef = require("UIStateDef")
local NpcDialogBoardHelper = require("NpcDialogBoardHelper")
local MatineeDataTable = require("MatineeDataTable")

BattleInteractionSystem_C.EventHelper = nil
BattleInteractionSystem_C.nVisiblityFactor = nil
BattleInteractionSystem_C.bHideActors = nil

local STATE_BATTLE  = 0
local STATE_MATINEE = 1
local STATE_DIALOG  = 2

BattleInteractionSystem_C.State = nil

function BattleInteractionSystem_C:Init()
    local bRet = BattleInteractionSystem_C.super.Init(self)

    self.nVisiblityFactor = UEClientActorHelper:AllocateObjectVisiblityFactor()

    self.EventHelper = SelfEventHelper()
    self.State = STATE_BATTLE

    if bRet then
        self.EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_PORTRAIT_END, self, self.DialogEnd)
        self.EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_EXIT, self, self.CloseInteractionDlg)
        return true 
    else
        return false
    end
end

function BattleInteractionSystem_C:Uninit()
    self.nVisiblityFactor = nil
    self.bHideActors = nil

    self.EventHelper:UnregisterAll()
    BattleInteractionSystem_C.super.Uninit(self)
end

function BattleInteractionSystem_C:OnPlayMatinee(nMatineeId, tbParent, fnOnComplete, bClientOnly, bPause)
    local matinee = BattleInteractionSystem_C.super.OnPlayMatinee(self, nMatineeId, tbParent, fnOnComplete, bClientOnly, bPause)

    if matinee ~= nil then
        self.State = STATE_MATINEE
        --UIManager:SetCinematicMode(true)
        UIManager:PushState(UIStateDef.StateName.UI_MATINEE_STATE, nil)

        local tbMatineeData = MatineeDataTable:GetTemplate(nMatineeId)
        if tbMatineeData ~= nil and not tbMatineeData.bShowActor then
            local tbTypes = {}
            tbTypes[GameObjectTypeDef.PlayerSelf] = true
            tbTypes[GameObjectTypeDef.PlayerOther] = true
            tbTypes[GameObjectTypeDef.Trigger] = true
            tbTypes[GameObjectTypeDef.Dummy] = true    

            UEClientActorHelper:SetAllObjectVisibilityFactor(self.nVisiblityFactor, tbTypes, false)
            -- UEClientActorHelper:SetPlayerVisible(tbTypes, false)
            self.bHideActors = true
        end

        local BlockActos = ExtendBlueprintFunctions.GetLevelActorsByTag(GWorld, "BlockActor")	
        if BlockActos then 
            for _,v in ipairs(BlockActos) do
                v:SetActorHiddenInGame(true)
            end
        end         

        if bClientOnly then
            local tbOpenArgs = {}
            tbOpenArgs.fnMethod = function() self:OnStopMatinee() end
            UIManager:OpenWnd(UIDef.UI_MATINEE_PANEL, tbOpenArgs)
        end
    end
    return matinee
end

function BattleInteractionSystem_C:OnStopMatinee()
    BattleInteractionSystem_C.super.OnStopMatinee(self)
    if self.State == STATE_MATINEE then
        -- 恢复状态，而非延迟到 MatineeEnd，因为MatineeEnd会在 Matinee Level 卸载之后才会触发
        --UIManager:SetCinematicMode(false)
        UIManager:PopState()
        self.State = STATE_BATTLE
    end
end

function BattleInteractionSystem_C:MatineeEnd()
    BattleInteractionSystem_C.super.MatineeEnd(self)

    if self.State == STATE_MATINEE then
        --UIManager:SetCinematicMode(false)
        UIManager:PopState(UIStateDef.StateName.UI_MATINEE_STATE)
        self.State = STATE_BATTLE
    end

    if self.bHideActors then
        local tbTypes = {}
        tbTypes[GameObjectTypeDef.PlayerSelf] = true
        tbTypes[GameObjectTypeDef.PlayerOther] = true
        tbTypes[GameObjectTypeDef.Trigger] = true    
        tbTypes[GameObjectTypeDef.Dummy] = true  

        UEClientActorHelper:SetAllObjectVisibilityFactor(self.nVisiblityFactor, tbTypes, true)
        -- UEClientActorHelper:SetPlayerVisible(tbTypes, true)
        self.bHideActors = nil
    end

	local BlockActos = ExtendBlueprintFunctions.GetLevelActorsByTag(GWorld, "BlockActor")	
	if BlockActos then 
		for _,v in ipairs(BlockActos) do
			v:SetActorHiddenInGame(false)
		end
	end     
    UIManager:CloseWnd(UIDef.UI_MATINEE_PANEL)
end

function BattleInteractionSystem_C:OnShowDialog(nDialogId, bDialogBoard)
    if self.State == STATE_MATINEE then
        return
    end
    BattleInteractionSystem_C.super.OnShowDialog(self, nDialogId)
    self.State = STATE_DIALOG
    -- UIManager:SetCinematicMode(true)
    if bDialogBoard then
        NpcDialogBoardHelper:OpenDialogBoard(nDialogId)
    else
        InteractionHelper:CreateBattlePortrait(nDialogId)
    end
end

function BattleInteractionSystem_C:DialogEnd()
    BattleInteractionSystem_C.super.DialogEnd(self)
    if self.State == STATE_DIALOG then
        self.State = STATE_BATTLE
    end
end

function BattleInteractionSystem_C:CloseInteractionDlg()
     NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_CloseDialog)
end

return BattleInteractionSystem_C()
