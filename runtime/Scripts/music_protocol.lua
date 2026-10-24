-- M4 | Music - deliberately small, data-only IPC. No Lua is read from disk.
local P = {}
function P.decode(s)
    return (s or ''):gsub('%%(%x%x)', function(x) return string.char(tonumber(x,16)) end)
end
function P.encode(s)
    return tostring(s):gsub('[%%\r\n=]', function(c) return string.format('%%%02X',c:byte()) end)
end
function P.parse(s)
    local out={}
    for line in (s or ''):gmatch('[^\r\n]+') do
        local k,v=line:match('^([%w_]+)=(.*)$')
        if k then out[k]=P.decode(v) end
    end
    return out
end
function P.serialize(t)
    local keys,out={},{}
    for k in pairs(t) do if k~='complete' then keys[#keys+1]=k end end
    table.sort(keys)
    for _,k in ipairs(keys) do out[#out+1]=k..'='..P.encode(t[k]) end
    out[#out+1]='complete='..tostring(t.seq)
    return table.concat(out,'\n')..'\n'
end
function P.read(path)
    local f=io.open(path,'rb');if not f then return nil end
    local s=f:read('*a');f:close();return P.parse(s)
end
function P.write(path,t)
    local f,err=io.open(path,'wb');if not f then return false,err end
    local ok,why=f:write(P.serialize(t));f:close();return ok~=nil,why
end
return P
