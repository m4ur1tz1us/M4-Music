local M={}
local start
function M.start(root)
    if not start then
        local err
        start,err=package.loadlib(root..'/Scripts/M4MusicStart.dll','m4music_start')
        assert(start,'Native launcher: '..tostring(err))
  end
    start()
end
return M
