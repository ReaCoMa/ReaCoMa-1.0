local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()
if reacoma.settings.fatal then return end

obj = reacoma.hpss
reacoma.params.get(obj)

ctx = reaper.ImGui_CreateContext(obj.info.algorithm_name, 494, 149)
viewport = reaper.ImGui_GetMainViewport(ctx)

reaper.defer(
    function()
        reacoma.imgui_wrapper.loop(ctx, viewport, state, obj, preview)
    end
)