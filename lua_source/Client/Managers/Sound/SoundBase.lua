local luaclass = require("luaclass")
local SoundBase = luaclass("SoundBase")

SoundBase.nAudioComponentID = nil
SoundBase.nID = nil
SoundBase.bOneShot = nil
SoundBase.tbParams = nil
SoundBase.tbStopDelegateHandler = nil
SoundBase.Owner = nil
SoundBase.nDuration = 0

function SoundBase:OnCreate(nID, bOneShot, tbParams)
    self.nID = nID
    self.bOneShot = bOneShot
    self.tbParams = tbParams
    -- 如果是OneShot（一次性音效），则不用创建pAudioComponent
end

function SoundBase:OnDestroy()
    --self:UnbindStopEvent()
        
    -- 因为AudioComponent会自动销毁，所以这里不需要管它
    self.nAudioComponentID = nil
end

function SoundBase:GetID()
    return self.nID
end

function SoundBase:Play()
    --self:BindStopEvent()
end

function SoundBase:Stop()
    --self:UnbindStopEvent()

    local Shell = ClientShell.GetClient(GWorld):GetSoundShell()
    local pAudioComponent = Shell:FindComponent(self.nAudioComponentID)
    if(pAudioComponent) then
        pAudioComponent:Stop()
        if not self.bOneShot and self.Owner then
            self.Owner:DeleteSound(self)
        end
    end
end

--[[
function SoundBase:BindStopEvent()
    self:UnbindStopEvent()
    if(self.nAudioComponentID ~= nil) then
        local Delegate = ClientShell.GetClient(GWorld):GetSoundShell().OnSoundFinished
        local fnFunc = function(nID)
            if(nID == self.nAudioComponentID) then
                self:OnStopEvent()
            end
        end
        self.tbStopDelegateHandler = CppDelegate:Bind(Delegate, fnFunc)
    end
end

function SoundBase:UnbindStopEvent()
    if(self.tbStopDelegateHandler) then
        self.tbStopDelegateHandler:Unbind()
        self.tbStopDelegateHandler = nil
    end
end

function SoundBase:OnStopEvent()
    self:UnbindStopEvent()
    if(self.Owner) then
        local fnFunc = function()
            self.Owner:DeleteSound(self)
        end
        DelayTimer:RunNextTick(fnFunc)
    end
end
]]

return SoundBase