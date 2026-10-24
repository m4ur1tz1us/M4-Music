-- A separate neutral/mute multiplier, never the user's saved music setting.
local A={service=nil,muted=false,gain=1}
local function valid(o)return o~=nil and o:IsValid()end
function A.level(player,gain)
    gain=math.max(0,math.min(1,gain))
    if A.service and not valid(A.service)then A.service=nil;A.muted=false;A.gain=1 end
    if not A.service and valid(player)then
        local utility=StaticFindObject('/Script/Pal.Default__PalUtility')
        if valid(utility)then
            local service=utility:GetAudioSettingSystem(player)
            if valid(service)then A.service=service end
        end
    end
    if math.abs(A.gain-gain)<.0001 then return end
    if not valid(A.service)then return end
    A.service:SetAudioBusVolume(2,FName('M4Music'),gain)
    A.gain=gain;A.muted=gain==0
end
function A.set(player,mute)A.level(player,mute and 0 or 1)end
function A.restore()A.set(nil,false)end
return A
