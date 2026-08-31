local BattleVolumeHelper = {}

local tbVolumes = nil

function BattleVolumeHelper:Init(tbJsonData)
    tbVolumes = {}
    
    if(not tbJsonData) then
        return
    end

    local Volumes = tbJsonData.Volumes
    if(Volumes) then
        for _, v in ipairs(Volumes) do
            tbVolumes[v.TransformId] = v
        end
    end
end

function BattleVolumeHelper:Uninit()
    tbVolumes = nil
end

function BattleVolumeHelper:GetVolume(nId)
    return tbVolumes and tbVolumes[nId]
end

return BattleVolumeHelper