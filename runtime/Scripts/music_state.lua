-- Player intent and the combat gate are independent: combat must never undo Pause.
local M={}
function M.new(settings)
    settings=settings or {}
    return {wanted=settings.wanted~='0',volume=math.max(0,math.min(100,tonumber(settings.volume) or 35)),
        shuffle=settings.shuffle~='0',active=false,combat=true,step=0,scan=0,seq=0,
        seek_seq=0,seek_ms=0,seek_step=0,safeSince=nil,session=tostring(os.time())..'-'..tostring(math.random(100000,999999))}
end
function M.observe(s,active,battle,now)
    s.active=active==true
    if not s.active or battle==nil or battle==true then
        s.combat=true;s.safeSince=nil
    else
        if not s.safeSince then s.safeSince=now end
        -- A brief calm interval avoids restarting between enemies/boss phases.
        if now-s.safeSince>=1.5 then s.combat=false end
    end
end
function M.action(s,name,value)
    if name=='toggle' then s.wanted=not s.wanted
    elseif name=='next' then s.step=s.step+1
    elseif name=='previous' then s.step=s.step-1
    elseif name=='quieter' then s.volume=math.max(0,s.volume-5)
    elseif name=='louder' then s.volume=math.min(100,s.volume+5)
    elseif name=='shuffle' then s.shuffle=not s.shuffle
    elseif name=='scan' then s.scan=s.scan+1
    elseif name=='volume'and tonumber(value)then s.volume=math.max(0,math.min(100,math.floor(value+.5)))
    elseif name=='seek'and tonumber(value)then
        s.seek_seq=s.seek_seq+1;s.seek_ms=math.max(0,math.floor(value));s.seek_step=s.step
    end
end
function M.snapshot(s)
    s.seq=s.seq+1
    return {version=1,session=s.session,seq=s.seq,active=s.active and 1 or 0,
        combat=s.combat and 1 or 0,wanted=s.wanted and 1 or 0,volume=s.volume,
        shuffle=s.shuffle and 1 or 0,step=s.step,scan=s.scan,seek_seq=s.seek_seq,seek_ms=s.seek_ms,seek_step=s.seek_step}
end
return M
