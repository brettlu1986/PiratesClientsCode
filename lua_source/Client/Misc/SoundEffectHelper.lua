local SoundManager = require("SoundManager")

local SoundEffectHelper = {}

SoundEffectHelper.SoundEffect = nil

function SoundEffectHelper:PlayGuideSoundEffect(nSoundEffectId)
    if(self.SoundEffect ~= nil)then
        self.SoundEffect:Stop()
        self.SoundEffect = nil
    end
    self.SoundEffect = SoundManager:PlaySoundEffect(nSoundEffectId, false)
end

function SoundEffectHelper:StopCurrentGuideSoundEffect()
    if(self.SoundEffect ~= nil)then
        self.SoundEffect:Stop()
        self.SoundEffect = nil
    end
end

return SoundEffectHelper
