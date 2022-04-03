local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local exe = reacoma.utils.wrap_quotes(
    reacoma.settings.path .. "/fluid-noveltyslice"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = reacoma.params.archetype.noveltyslice
    reacoma.params.check_params(processor)
    local param_names = "algorithm,threshold,kernelsize,filtersize,fftsettings,minslicelength"
    local param_values = reacoma.params.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Noveltyslice Parameters", 6, param_names, param_values)
    if confirm then
        reacoma.params.store_params(processor, param_names, user_inputs)

        local params = reacoma.utils.split_comma(user_inputs)
        local algorithm = params[1]
        local threshold = params[2]
        local kernelsize = params[3]
        local filtersize = params[4]
        local fftsettings = params[5]
        local minslicelength = params[6]
        
        local data = reacoma.slicing.container

        for i=1, num_selected_items do
            reacoma.slicing.get_data(i, data)
            
            local cmd = exe .. 
            " -source " .. reacoma.utils.wrap_quotes(data.full_path[i]) .. 
            " -indices " .. reacoma.utils.wrap_quotes(data.tmp[i]) .. 
            " -maxfftsize " .. reacoma.utils.get_max_fft_size(fftsettings) ..
            " -maxkernelsize " .. kernelsize ..
            " -maxfiltersize " .. filtersize ..
            " -algorithm " .. algorithm .. 
            " -kernelsize " .. kernelsize .. 
            " -threshold " .. threshold .. 
            " -filtersize " .. filtersize .. 
            " -fftsettings " .. fftsettings .. 
            " -minslicelength " .. minslicelength ..
            " -numframes " .. data.item_len_samples[i] .. 
            " -startframe " .. data.take_ofs_samples[i]
            table.insert(data.cmd, cmd)
            reaper.ShowConsoleMsg(cmd)
        end

        for i=1, num_selected_items do
            reacoma.utils.cmdline(data.cmd[i])
            table.insert(data.slice_points_string, reacoma.utils.readfile(data.tmp[i]))
            reacoma.slicing.process(i, data)
        end

        reacoma.utils.arrange("reacoma-noveltyslice")
        reacoma.utils.cleanup(data.tmp)
    end
end

