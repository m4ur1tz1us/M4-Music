-- M4 | Music v0.7. Native GUI launch, mounted-player tracking and compact player.
local Protocol=require('music_protocol')
local State=require('music_state')
local UI=require('music_ui')
local Helpers=require('UEHelpers')
local GameAudio=require('music_gameaudio')
local Launcher=require('music_launch')
local source=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/')
local root=source:match('^(.*)/[Ss]cripts/[^/]+$') or 'ue4ss/Mods/M4Music'
local settings=Protocol.read(root..'/Settings.ini')or {}
local state=State.new(settings)
local ESC='/Game/Pal/Blueprint/UI/UserInterface/ESCMenu/WBP_MenuESC.WBP_MenuESC_C'
local status={track='',count='0',index='0'}
local statusAck,lastAckAt,lastLaunch,clock=0,-100,-100,0
local pending=false
local localPlayer,pc,lastPlayerKey
local menus,hooks,reported,attempts={},{},{},{}
local function log(s)print('[M4 Music] '..tostring(s)..'\n')end
local function once(key,s)if not reported[key]then reported[key]=true;log(key..': '..tostring(s))end end
local function valid(o)
    if o==nil then return false end
    local ok,result=pcall(function()return o:IsValid()end);return ok and result
end
local function unwrap(p)
    local ok,v=pcall(function()return p:get()end);return ok and v or p
end
local function identity(o)
    if not valid(o)then return nil end
    local ok,address=pcall(function()return o:GetAddress()end)
    if not ok or address==nil or address==0 then return nil end
    return tostring(address)
end
local function flush()
    local ok,err=Protocol.write(root..'/control.ini',State.snapshot(state))
    if not ok then once('Steuerdatei nicht schreibbar',err)end
end
local function action(name,value)
    State.action(state,name,value)
    if not state.wanted then pcall(GameAudio.restore)end
    flush();log('Player: '..name)
end
local function launch()
    if clock-lastLaunch<15 then return end
    lastLaunch=clock
    local ok,why=pcall(Launcher.start,root)
    if not ok then once('Audiobegleiter konnte nicht starten',why)end
end
local function hook(path,callback)
    if hooks[path]then return end
    if not valid(StaticFindObject(path))then return end
    local ok,err=pcall(RegisterHook,path,callback)
    if ok then hooks[path]=true else once('Hook '..path,err)end
end
local function attach(menu)
    if not valid(menu)then return end
    local id=identity(menu);if not id then return end
    menus[id]=menu
    local retry=attempts[id]
    if retry and (retry.count>=3 or clock<retry.after)then return end
    local ok,err=pcall(UI.attach,menu,action,log)
    if not ok then
        attempts[id]={count=(retry and retry.count or 0)+1,after=clock+2}
        once('ESC-Player',err)
    end
end
local function installMenuHooks()
    hook(ESC..':Construct',function(context)attach(unwrap(context))end)
    hook(ESC..':Destruct',function(context)
        local menu=unwrap(context)
        local id=identity(menu)
        if id then menus[id]=nil;attempts[id]=nil;pcall(UI.remove,menu)end
    end)
    -- Let UMG drive animation on its own game-thread Tick. No second async queue.
    hook(ESC..':Tick',function(context)
        local menu=unwrap(context)
        if not identity(menu)then return end
        local ok,err=pcall(function()
            local gameplay=StaticFindObject('/Script/Engine.Default__GameplayStatics')
            UI.animate(gameplay:GetRealTimeSeconds(menu),menu)
        end)
        if not ok then once('Menueanimation',err)end
    end)
end
local function detectBattle(player)
    local ok,rank,count=pcall(function()
        local situation=player.PlayerBattleSituation
        if not valid(situation)then return nil,nil end
        return tonumber(situation.CurrentMaxRank),situation.EnemyList:GetArrayNum()
    end)
    if not ok or rank==nil or count==nil then return nil end
    return rank~=0 or count>0
end
local function tick()
    -- All UObject access happens on the game thread. A single outstanding callback
    -- prevents a growing queue when the game is loading or stalls.
    local gameplay=StaticFindObject('/Script/Engine.Default__GameplayStatics')
    if not valid(pc)then pc=Helpers.GetPlayerController()end
    local active=false
    if valid(pc)then
        local ok,isLocal,pawn=pcall(function()
            -- Pawn may be the ridden Pal. The character still owns battle state.
            local character=pc:GetDefaultPlayerCharacter()
            if not valid(character)then character=pc:GetRiderCharacter()end
            if not valid(character)then character=pc.Pawn end
            return pc:IsLocalController(),character
        end)
        if ok and isLocal and valid(pawn)then
            local cls=StaticFindObject('/Script/Pal.PalPlayerCharacter')
            if valid(cls)and pawn:IsA(cls)then localPlayer=pawn;active=true end
        end
    end
    local now=clock
    if active and valid(gameplay)then
        local ok,value=pcall(function()return gameplay:GetRealTimeSeconds(localPlayer)end)
        if ok and type(value)=='number'then now=value end
    end
    local playerKey=active and identity(localPlayer)or nil
    if playerKey~=lastPlayerKey then
        state.safeSince=nil;state.combat=true;lastPlayerKey=playerKey
        if active then log('Lokaler Spieler erkannt; Kampfstatus wird geprueft.')end
    end
    local battle
    if active then battle=detectBattle(localPlayer)end
    local wasCombat=state.combat
    State.observe(state,active,battle,now)
    if active and battle==nil then once('Kampfstatus','Nicht lesbar; eigene Musik bleibt pausiert.')end
    if wasCombat~=state.combat then log(state.combat and 'Kampfpause.'or 'Kampf beendet; Player freigegeben.')end
    flush()
    local fresh=Protocol.read(root..'/status.ini')
    if fresh and fresh.session==state.session then
        status=fresh
        -- Only accept a cache filename produced by our own host, never a supplied path.
        status.cover_path=nil
        if fresh.cover and #fresh.cover==68 and fresh.cover:match('^[a-f0-9]+%.png$')then
            status.cover_path=root..'/CoverCache/'..fresh.cover
        end
        local ack=tonumber(fresh.ack)or 0
        if ack~=statusAck then statusAck=ack;lastAckAt=clock end
    end
    local healthy=clock-lastAckAt<3
    local mix=healthy and state.active and state.wanted and (tonumber(status.music_mix)or 0)or 0
    local audioOK,audioError=pcall(GameAudio.level,localPlayer,1-math.max(0,math.min(1,mix)))
    if not audioOK then once('Originalmusik',audioError)end
    if active and not healthy then launch()end
    installMenuHooks()
    -- Notify is early in construction: attaching is retried from this safe tick.
    for id,menu in pairs(menus)do
        if not valid(menu)then menus[id]=nil
        elseif menu:IsVisible()then attach(menu)end
    end
    UI.refresh(state,status,healthy)
    -- Also drive from the established player tick if the animation timer stalls.
    local animationOK,animationError=pcall(UI.animate,now)
    if not animationOK then once('Lauftitel',animationError)end
end
NotifyOnNewObject(ESC,function(menu)
    local id=identity(menu);if id then menus[id]=menu end
end)
hook('/Script/Pal.PalPlayerCharacter:OnChangeBattleBGM',function(context,rank)
    if valid(localPlayer)and identity(unwrap(context))==identity(localPlayer)then
        local value=tonumber(unwrap(rank))
        if value and value~=0 then state.combat=true;state.safeSince=nil;flush();log('Kampfmusik erkannt; Ueberblendung gestartet.')end
    end
end)
hook('/Script/Engine.PlayerController:ClientRestart',function(context)
    local controller=unwrap(context)
    if valid(controller)and controller:IsLocalController()then
        local ok,character=pcall(function()return controller:GetDefaultPlayerCharacter()end)
        if ok and valid(character)and identity(character)==identity(localPlayer)then pc=controller;return end
        pcall(GameAudio.restore);pc=nil;localPlayer=nil;state.active=false;state.combat=true;state.safeSince=nil;flush()
    end
end)
if type(RegisterLoadMapPreHook)=='function'then
    RegisterLoadMapPreHook(function()
        pcall(GameAudio.restore)
        state.active=false;state.combat=true;state.safeSince=nil;pc=nil;localPlayer=nil;lastPlayerKey=nil;flush()
        pcall(UI.clear);menus={};attempts={}
    end)
end
flush();log('M4 | Music v0.7 geladen. MP3-Ordner: '..root..'/Music')
LoopAsync(250,function()
    clock=clock+.25
    if pending then return end
    pending=true
    ExecuteInGameThread(function()
        local ok,err=pcall(tick)
        if not ok then
            state.active=false;state.combat=true;state.safeSince=nil;pcall(GameAudio.restore);pcall(flush)
            once('Player-Tick',err)
        end
        pending=false
    end)
end)
return {state=state,action=action,tick=tick,detectBattle=detectBattle,root=root}
