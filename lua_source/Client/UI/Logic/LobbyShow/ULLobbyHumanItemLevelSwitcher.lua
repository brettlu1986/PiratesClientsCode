local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULLobbyHumanItemLevelSwitcher = luaclass("ULLobbyHumanItemLevelSwitcher", UILogicBase)

local ClientEventDef                        = require("ClientEventDef")
local LobbyCaptainMiscDef                   = require("LobbyCaptainMiscDef")
local SelfCheckBoxGroupHelper               = require("SelfCheckBoxGroupHelper")
local UITextDef                             = require("UITextDef")

ULLobbyHumanItemLevelSwitcher.tbParam = nil
-- lifecycle callback
local Levels = LobbyCaptainMiscDef.Levels
local LevelToIndex = LobbyCaptainMiscDef.LevelToIndex
local IndexToLevel = LobbyCaptainMiscDef.IndexToLevel

local function OnLevelCheckBoxSelect(self, nSelectIndex)
    self.nCurrentLevel = IndexToLevel[nSelectIndex]
    self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_HUMAN_LEVEL_SWITCHED, self.nCurrentLevel)
end

function ULLobbyHumanItemLevelSwitcher:Enable(bEnable)
    if bEnable then
        self.pWidgetRef.vboxLevel:SetVisibility(ESlateVisibility.Visible)
    else
        self.pWidgetRef.vboxLevel:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function ULLobbyHumanItemLevelSwitcher:SelectLevel(nLevel)
    self.LevelCheckBoxGroupHelper:SelectByIndex(LevelToIndex[nLevel], true)
end

function ULLobbyHumanItemLevelSwitcher:OnLoad()
    self.LevelCheckBoxGroupHelper = SelfCheckBoxGroupHelper()
    local nCurrentLevelIndex = LevelToIndex[self.nCurrentLevel]
    self.LevelCheckBoxGroupHelper:Init(self, self.pWidgetRef.vboxLevel, nCurrentLevelIndex)
    self.LevelCheckBoxGroupHelper.OnSelectedChangedDelegate:Bind(OnLevelCheckBoxSelect, self)
    for nLevel, nIndex in pairs(LobbyCaptainMiscDef.LevelToIndex) do
        self.LevelCheckBoxGroupHelper:SetCheckBoxText(nIndex, UITextDef.SHIP_GRADE_TEXT[nLevel])
    end
end

function ULLobbyHumanItemLevelSwitcher:OnUnload()
    if self.LevelCheckBoxGroupHelper then
        self.LevelCheckBoxGroupHelper:Uninit()
    end
end



function ULLobbyHumanItemLevelSwitcher:OnShow()
    self.LevelCheckBoxGroupHelper:SelectByIndex(LevelToIndex[Levels.Level3], true)
end



return ULLobbyHumanItemLevelSwitcher