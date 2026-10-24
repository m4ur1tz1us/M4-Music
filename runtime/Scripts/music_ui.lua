-- Attach runtime widgets to the real ESC canvas. No original UI assets are replaced.
local UI={panels={},actions={},hooked=false}
local BUTTON='/Game/Pal/Blueprint/UI/UserInterface/Common/WBP_CommonButton.WBP_CommonButton_C'
local CLICK='BndEvt__WBP_CommonButton_WBP_PalInvisibleButton_K2Node_ComponentBoundEvent_3_CommonButtonBaseClicked__DelegateSignature'
local function valid(o)return o~=nil and o:IsValid()end
local function key(o)
    if not valid(o)then return nil end
    local address=o:GetAddress();if address==nil or address==0 then return nil end
    return tostring(address)
end
local function native(class,outer)
    local c=StaticFindObject('/Script/UMG.'..class)
    assert(valid(c),'UMG class missing: '..class)
    local o=StaticConstructObject(c,outer);assert(valid(o),'UMG construction failed: '..class);return o
end
local function text(outer,value,color,size)
    local o=native('TextBlock',outer)
    local font=o.Font
    o:SetFont({FontObject=font.FontObject,TypefaceFontName=font.TypefaceFontName,Size=size or 16,
        LetterSpacing=0,SkewAmount=0,OutlineSettings={OutlineSize=0,bSeparateFillAlpha=false,
        bApplyOutlineToDropShadows=false,OutlineColor={R=0,G=0,B=0,A=0}}})
    o:SetText(FText(value));o:SetAutoWrapText(false)
    if color then o:SetColorAndOpacity({SpecifiedColor=color,ColorUseRule=0})end
    return o
end
local function add(box,child,padding)
    local slot=box:AddChildToVerticalBox(child)
    slot:SetPadding({Left=0,Top=padding or 5,Right=0,Bottom=padding or 5})
    return slot
end
local function clock(ms)
    local s=math.max(0,math.floor((tonumber(ms)or 0)/1000));return string.format('%02d:%02d',math.floor(s/60),s%60)
end
local CYAN={R=.12,G=.8,B=1,A=1}
local MUTED={R=.48,G=.65,B=.72,A=1}
local function slider(tree,orientation)
    local s=native('Slider',tree)
    -- SetOrientation is C++ only in UE 5.1; write the reflected property
    -- before SetValue builds the Slate widget for the first time.
    if orientation then s.Orientation=orientation end
    s:SetSliderBarColor({R=.035,G=.19,B=.25,A=1})
    s:SetSliderHandleColor(CYAN);s:SetStepSize(.001);s:SetValue(0)
    return s
end
-- Animation uses real elapsed game time rather than a fixed amount per callback.
function UI.animate(now,onlyMenu)
    for _,p in pairs(UI.panels)do
        if valid(p.menu)and valid(p.title)and (not onlyMenu or key(p.menu)==key(onlyMenu))and p.menu:IsVisible()then
            if not p.titleSince then p.titleSince=now;p.title:ForceLayoutPrepass()end
            local width=p.title:GetDesiredSize().X
            local overflow=math.max(0,width-235)
            if overflow>0 then
                local travel=math.max(2,overflow/28)
                local phase=(now-(p.titleSince or now))%(2*travel+2)
                local x=0
                if phase>1 and phase<1+travel then
                    x=overflow*(.5-.5*math.cos(math.pi*(phase-1)/travel))
                elseif phase>=1+travel and phase<=2+travel then x=overflow
                elseif phase>2+travel then
                    x=overflow*(.5+.5*math.cos(math.pi*(phase-2-travel)/travel))
                end
                p.title:SetRenderTranslation({X=-x,Y=0})
                if x>0 and not p.motionReported then
                    p.motionReported=true
                    print('[M4 Music] Lauftitel bewegt; Textbreite '..tostring(width)..'\n')
                end
            else p.title:SetRenderTranslation({X=0,Y=0})end
        end
    end
end
function UI.attach(menu,onAction,log)
    if not valid(menu)then return end
    local id=key(menu);if not id then return end
    if UI.panels[id]and valid(UI.panels[id].border)then return end
    local tree=menu.WidgetTree;assert(valid(tree),'ESC WidgetTree missing')
    local canvas=tree.RootWidget;assert(valid(canvas)and canvas:IsA(StaticFindObject('/Script/UMG.CanvasPanel')),'ESC root is not a CanvasPanel')
    if not valid(StaticFindObject(BUTTON))then LoadAsset('/Game/Pal/Blueprint/UI/UserInterface/Common/WBP_CommonButton')end
    local cls=StaticFindObject(BUTTON);assert(valid(cls),'Common button class missing')
    if not UI.hooked then
        RegisterHook(BUTTON..':'..CLICK,function(context)
            local b=context:get();if not valid(b)then return end
            local action=UI.actions[key(b)]
            -- Actions are scoped to our own widget instances; other menus are untouched.
            if action and valid(action.menu)and action.menu:IsVisible() then onAction(action.name)end
        end)
        UI.hooked=true
    end
    local panel={menu=menu,buttons={},buttonKeys={},onAction=onAction,lastProgress=0,lastVolume=0}
    local border=native('Border',tree);panel.border=border
    local ok,err=pcall(function()
        border:SetBrushColor({R=0,G=0,B=0,A=1})
        border:SetPadding({Left=1,Top=1,Right=1,Bottom=1});border:SetClipping(1)
        local scale=native('ScaleBox',tree);scale:SetStretch(2);border:SetContent(scale)
        local design=native('SizeBox',tree);design:SetWidthOverride(430);design:SetHeightOverride(174);scale:SetContent(design)
        local face=native('CanvasPanel',tree);design:SetContent(face)
        local function place(o,x,y,w,h)
            local slot=face:AddChildToCanvas(o);slot:SetPosition({X=x,Y=y});slot:SetSize({X=w,Y=h});return o
        end
        local function line(x,y,w,h)
            local o=native('Border',tree);o:SetBrushColor({R=.55,G=.65,B=.67,A=.65});place(o,x,y,w,h)
        end
        line(1,1,428,1);line(1,172,428,1);line(1,1,1,172);line(428,1,1,172);line(1,30,428,1)
        for _,corner in ipairs({{1,1},{427,1},{1,171},{427,171}})do
            local dot=native('Border',tree);dot:SetBrushColor({R=.92,G=.98,B=1,A=1})
            dot:SetVisibility(3);place(dot,corner[1],corner[2],2,2)
        end
        place(text(tree,'M4 | Music',{R=.8,G=.9,B=.92,A=1},16),14,4,270,25)
        place(text(tree,'MP3/WAV',MUTED,15),321,4,103,25)
        local titleClip=native('Border',tree);titleClip:SetBrushColor({R=0,G=0,B=0,A=0})
        titleClip:SetPadding({Left=0,Top=0,Right=0,Bottom=0});titleClip:SetClipping(1)
        local titleCanvas=native('CanvasPanel',tree);titleClip:SetContent(titleCanvas);place(titleClip,22,45,235,44)
        panel.title=text(tree,'Deine Musik. Überall.',nil,23)
        panel.titleSlot=titleCanvas:AddChildToCanvas(panel.title);panel.titleSlot:SetAutoSize(true)
        panel.titleSlot:SetPosition({X=0,Y=0})
        panel.info=place(text(tree,'',MUTED,10),22,88,240,20)
        panel.progress=place(slider(tree),15,111,244,16)
        local album=native('Border',tree);album:SetBrushColor({R=.012,G=.04,B=.05,A=1})
        album:SetPadding({Left=0,Top=0,Right=0,Bottom=0})
        local coverLayer=native('CanvasPanel',tree);album:SetContent(coverLayer)
        panel.coverPlaceholder=text(tree,'M4\nMUSIC',CYAN,15)
        local placeholderSlot=coverLayer:AddChildToCanvas(panel.coverPlaceholder)
        placeholderSlot:SetPosition({X=12,Y=28});placeholderSlot:SetSize({X=77,Y=60})
        panel.coverImage=native('Image',tree);panel.coverImage:SetVisibility(1)
        local coverSlot=coverLayer:AddChildToCanvas(panel.coverImage)
        coverSlot:SetPosition({X=2.5,Y=0});coverSlot:SetSize({X=84,Y=84})
        place(album,271,44,89,84)
        panel.volume=slider(tree,1);panel.volume:SetStepSize(.01)
        place(panel.volume,386,40,18,99)
        panel.volumeLabel=place(text(tree,'VOLUME',{R=1,G=1,B=1,A=1},6),374,156,44,13)
        panel.volumeLabel:SetJustification(1)
        panel.volumeText=place(text(tree,'10%',CYAN,8),379,143,32,15)
        panel.volumeText:SetJustification(1)
        local lib=StaticFindObject('/Script/UMG.Default__WidgetBlueprintLibrary')
        local pc=menu:GetOwningPlayer();assert(valid(pc),'ESC owning player missing')
        panel.icons={}
        for i,item in ipairs({{'toggle',''},{'previous',''},{'next',''},{'scan',''},{'shuffle',''}})do
            local button=lib:Create(menu,cls,pc);assert(valid(button),'Button creation failed');button:Setup(false)
            local x=2+(i-1)*43
            button:SetText(FText(item[2]));place(button,x,141,43,31)
            local function icon(kind)
                local group=native('CanvasPanel',tree);group:SetVisibility(3);place(group,x+11.5,149,20,16)
                local function rect(xx,yy,w,h)
                    local pixel=native('Border',tree);pixel:SetBrushColor({R=.8,G=.9,B=.92,A=1})
                    local slot=group:AddChildToCanvas(pixel);slot:SetPosition({X=xx,Y=yy});slot:SetSize({X=w,Y=h})
                end
                if kind=='pause'then rect(5,0,3,16);rect(12,0,3,16)
                elseif kind=='play'then
                    for yy=0,15 do rect(4,yy,math.max(1,12-math.abs(yy-7.5)*1.5),1)end
                elseif kind=='previous'or kind=='next'then
                    for yy=0,15 do
                        local inset=math.floor(math.abs(yy-7.5))
                        rect(kind=='previous'and 5+inset or 3,yy,12-inset,1)
                    end
                    rect(kind=='previous'and 1 or 18,0,2,16)
                elseif kind=='scan'then
                    for yy=0,11 do local half=yy*.75;rect(10-half,yy,math.max(1,half*2),1)end
                    rect(1,14,18,2)
                elseif kind=='shuffle'then
                    for xx=1,16 do
                        local t=(xx-1)/15;local y=4+7*(3*t*t-2*t*t*t)
                        rect(xx,y,1.5,1.5);rect(xx,15-y,1.5,1.5)
                    end
                    for yy=-3,3 do
                        local length=4-math.abs(yy)
                        rect(15,4+yy,length,1);rect(15,11+yy,length,1)
                    end
                end
                return group
            end
            if item[1]=='toggle'then panel.icons.pause=icon('pause');panel.icons.play=icon('play');panel.icons.play:SetVisibility(1)
            else panel.icons[item[1]]=icon(item[1])end
            local bid=key(button);UI.actions[bid]={name=item[1],menu=menu};panel.buttonKeys[#panel.buttonKeys+1]=bid;panel.buttons[item[1]]=button
        end
        panel.elapsed=place(text(tree,'00:00',CYAN,19),244,141,70,29)
        place(text(tree,'/',nil,14),315,146,10,22)
        panel.duration=place(text(tree,'00:00',nil,9),324,155,45,16)
        panel.notice=place(text(tree,'',MUTED,9),15,126,245,12)
        -- Decorative overlays must not intercept dragging/clicks on the sliders.
        local function frame(x,y,w,h)
            local function stroke(xx,yy,ww,hh,bright)
                local piece=native('Border',tree)
                piece:SetBrushColor({R=1,G=1,B=1,A=bright and 1 or .72})
                piece:SetVisibility(3);place(piece,xx,yy,ww,hh)
            end
            stroke(x,y,w,1);stroke(x,y+h-1,w,1)
            stroke(x,y,1,h);stroke(x+w-1,y,1,h)
            for _,corner in ipairs({{x,y},{x+w-2,y},{x,y+h-2},{x+w-2,y+h-2}})do
                stroke(corner[1],corner[2],2,2,true)
            end
        end
        frame(270,43,91,86)
        frame(383,38,24,103)
        frame(14,109,246,20)
        local slot=canvas:AddChildToCanvas(border)
        slot:SetAnchors({Minimum={X=.132,Y=.558},Maximum={X=.349,Y=.716}})
        slot:SetAlignment({X=0,Y=0});slot:SetOffsets({Left=0,Top=0,Right=0,Bottom=0});slot:SetZOrder(100)
        border:SetVisibility(0)
    end)
    if not ok then
        if valid(border)then border:RemoveFromParent()end
        for _,bid in ipairs(panel.buttonKeys)do UI.actions[bid]=nil end
        error(err)
    end
    UI.panels[id]=panel;log('ESC-Player angehaengt.')
end
function UI.remove(menu)
    if not valid(menu)then return end
    local id=key(menu);if not id then return end
    local panel=UI.panels[id]
    if panel then
        for _,bid in ipairs(panel.buttonKeys)do UI.actions[bid]=nil end
        if valid(panel.border)then panel.border:RemoveFromParent()end
        UI.panels[id]=nil
    end
end
function UI.clear()
    for _,panel in pairs(UI.panels)do if valid(panel.border)then panel.border:RemoveFromParent()end end
    UI.panels={};UI.actions={}
end
function UI.refresh(state,status,healthy)
    for id,p in pairs(UI.panels)do
        if not valid(p.menu)or not valid(p.border)then
            for _,bid in ipairs(p.buttonKeys)do UI.actions[bid]=nil end;UI.panels[id]=nil
        elseif p.menu:IsVisible()then
            local coverKey=status.cover_path or ''
            if p.coverKey~=coverKey then
                p.coverKey=coverKey
                p.coverImage:SetVisibility(1);p.coverPlaceholder:SetVisibility(3)
                if coverKey~=''then
                    local ok,err=pcall(function()
                        local rendering=StaticFindObject('/Script/Engine.Default__KismetRenderingLibrary')
                        local texture=rendering:ImportFileAsTexture2D(p.menu,coverKey)
                        if valid(texture)then
                            -- The Image brush owns the live texture. No stale UObject cache.
                            p.coverImage:SetBrushFromTexture(texture,false)
                            p.coverImage:SetVisibility(3);p.coverPlaceholder:SetVisibility(1)
                        end
                    end)
                    if not ok then print('[M4 Music] Cover nicht lesbar; Platzhalter verwendet: '..tostring(err)..'\n')end
                end
            end
            local mode=not healthy and 'Audiobegleiter startet ...'or
                not state.active and 'Warte auf Spielwelt' or state.combat and 'Kampfpause' or
                not state.wanted and 'Pausiert' or status.mode=='startup_delay'and 'Musik startet gleich ...'or status.mode=='empty'and 'Keine MP3/WAV-Dateien gefunden'or
                status.mode=='error'and 'Datei nicht abspielbar'or 'Wiedergabe'
            local title=status.track~=''and status.track or 'Deine Musik. Überall.'
            if p.currentTitle~=title then
                p.currentTitle=title;p.title:SetText(FText(title));p.titleSince=nil
                p.title:SetRenderTranslation({X=0,Y=0});p.motionReported=false
                p.title:ForceLayoutPrepass()
            end
            p.elapsed:SetText(FText(clock(status.position_ms)));p.duration:SetText(FText(clock(status.duration_ms)))
            p.info:SetText(FText(mode..'  •  '..tostring(status.index or 0)..'/'..tostring(status.count or 0)))
            p.buttons.toggle:SetText(FText(''))
            p.icons.pause:SetVisibility(state.wanted and 3 or 1)
            p.icons.play:SetVisibility(state.wanted and 1 or 3)
            p.buttons.shuffle:SetColorAndOpacity(state.shuffle and CYAN or {R=.4,G=.5,B=.55,A=1})
            p.buttons.previous:SetText(FText(''));p.buttons.next:SetText(FText(''))
            p.buttons.shuffle:SetText(FText(''));p.buttons.scan:SetText(FText(''))
            p.icons.shuffle:SetRenderOpacity(state.shuffle and 1 or .4)
            local v=p.volume:GetValue()
            if math.abs(v-p.lastVolume)>.004 then p.onAction('volume',v*100)end
            p.lastVolume=state.volume/100;p.volume:SetValue(p.lastVolume);p.volumeText:SetText(FText(state.volume..'%'))
            local duration=tonumber(status.duration_ms)or 0
            local progress=p.progress:GetValue()
            if duration>0 and math.abs(progress-p.lastProgress)>.002 then
                p.onAction('seek',progress*duration);p.waitSeek=state.seek_seq;p.lastProgress=progress
            end
            if not p.waitSeek or (tonumber(status.seek_ack)or 0)>=p.waitSeek then
                p.waitSeek=nil;p.lastProgress=duration>0 and math.max(0,math.min(1,(tonumber(status.position_ms)or 0)/duration))or 0
                p.progress:SetValue(p.lastProgress)
            end
            local notice=status.error and status.error~=''and status.error or
                (status.mode=='empty'and 'MP3/WAV in M4Music/Music ablegen.'or '')
            p.notice:SetText(FText(notice))
        end
    end
end
return UI
