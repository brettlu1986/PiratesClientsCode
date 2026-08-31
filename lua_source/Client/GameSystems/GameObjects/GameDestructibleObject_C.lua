local luaclass = require("luaclass")
local GameDestructibleObject = require("GameDestructibleObject")
local GameDestructibleObject_C = luaclass("GameDestructibleObject_C", GameDestructibleObject)
local DestructibleObjectNewDataTable = require("DestructibleObjectNewDataTable")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameDestructibleObjectType = require("GameDestructibleObjectType")
local SoundEffectData = require("SoundEffectData")

function GameDestructibleObject_C:OnActorCreated(pUEActor)
    GameDestructibleObject_C.super.OnActorCreated(self, pUEActor)
    
    local tbDestructibleObjectData = DestructibleObjectNewDataTable:GetTemplate(self.nTemplateId)
    if tbDestructibleObjectData == nil then
        return
    end
    if tbDestructibleObjectData.szBreakEffect then
        self.pUEActor:SetEffect(tbDestructibleObjectData.szBreakEffect)
    end
    local szBreakSoundPath = SoundEffectData:GetSoundPath(tbDestructibleObjectData.nBreakSoundId)
    if szBreakSoundPath ~= nil and string.len(szBreakSoundPath) > 0 then
        pUEActor:SetBreakSound(szBreakSoundPath)
    end

    local tbDestructibleData = DestructibleObjectNewDataTable:GetTemplate(self.nTemplateId)
    if tbDestructibleData ~= nil and tbDestructibleData.nType == GameDestructibleObjectType.Door then
        local nState = enumtoint(pUEActor:GetCurState())
        if nState ~= 0 then
            pUEActor:SynStateAnimation()
        end
        local szOpenSoundPath = SoundEffectData:GetSoundPath(tbDestructibleObjectData.nOpenSoundId)
        local szCloseSoundPath = SoundEffectData:GetSoundPath(tbDestructibleObjectData.nCloseSoundId)
        if (szOpenSoundPath ~= nil and string.len(szOpenSoundPath) > 0) or (szCloseSoundPath ~= nil and string.len(szCloseSoundPath) > 0) then
            pUEActor:SetSound(szOpenSoundPath, szCloseSoundPath)
        end
    end

    -- 性能测试使用
    if not GlobalVariableSystem.bDestructibleObjectVisible then
        pUEActor:SetActorHiddenInGame(true)
    end
end

return GameDestructibleObject_C