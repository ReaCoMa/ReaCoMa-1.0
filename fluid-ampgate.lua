local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local exe = reacoma.utils.doublequote(
    reacoma.settings.path .. "/fluid-ampgate"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    local processor = reacoma.params.archetype.ampgate
    reacoma.params.check_params(processor)
    local param_names = "rampup,rampdown,onthreshold,offthreshold,minslicelength,minsilencelength,minlengthabove,minlengthbelow,lookback,lookahead,highpassfreq,mute,onsetsonly,markers,slicemode,label"
    param_values = reacoma.params.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Ampgate Parameters", 16, param_names, param_values)
    if confirm then
        reacoma.params.store_params(processor, param_names, user_inputs)
        
        local params = reacoma.utils.commasplit(user_inputs)
        local rampup = params[1]
        local rampdown = params[2]
        local onthreshold = params[3]
        local offthreshold = params[4]
        local minslicelength = params[5]
        local minsilencelength = params[6]
        local minlengthabove = params[7]
        local minlengthbelow = params[8]
        local lookback = params[9]
        local lookahead = params[10]
        local highpassfreq = params[11]
        local mute = tonumber(params[12])
        local onsetsonly = tonumber(params[13])
        local markers = tonumber(params[14])
        local slicemode = tonumber(params[15])
        local label = params[16]
        local colour = "0 0 0"

        local data = reacoma.slicing.container

        for i=1, num_selected_items do
            reacoma.slicing.get_data(i, data)

            local cmd = exe .. 
            " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
            " -indices " .. reacoma.utils.doublequote(data.tmp[i]) ..
            " -maxsize "  .. math.max(tonumber(minlengthabove) + tonumber(lookback), math.max(tonumber(minlengthbelow),tonumber(lookahead))) ..
            " -rampup " .. rampup ..
            " -rampdown " .. rampdown ..
            " -onthreshold " .. onthreshold ..
            " -offthreshold " .. offthreshold ..
            " -minslicelength " .. minslicelength ..
            " -minsilencelength " .. minsilencelength ..
            " -minlengthabove " .. minlengthabove ..
            " -minlengthbelow " .. minlengthbelow ..
            " -lookback " .. lookback ..
            " -lookahead " .. lookahead ..
            " -highpassfreq " .. highpassfreq ..
            " -numframes " .. data.item_len_samples[i] .. 
            " -startframe " .. data.take_ofs_samples[i]
            table.insert(data.cmd, cmd)
        end

        for i=1, num_selected_items do
            reacoma.utils.cmdline(data.cmd[i])
            local var = reacoma.utils.readfile(data.tmp[i])
            local channel_split = reacoma.utils.linesplit(var)
            local onsets = reacoma.utils.commasplit(channel_split[1])
            local offsets = reacoma.utils.commasplit(channel_split[2])
            local laced = nil
            if onsetsonly == 1 then
                laced = onsets
                mute = 0
            else 
                laced = reacoma.utils.lacetables(onsets, offsets)
            end
            local dumb_string = ""
            local state_state = nil
            
            if laced[1] == data.take_ofs_samples[i] then 
                start_state = 0 -- if there is a 0 at the start we start 'off/unmuted'
            else 
                start_state = 1 -- if there is something else at the start we start muted and prepend a 0
            end

            for j=1, #laced do
                dumb_string = dumb_string .. laced[j] .. ","
            end
            table.insert(data.slice_points_string, dumb_string)
            
            if mute == 1 then
                reacoma.slicing.process_gate(i, data, start_state, markers, slicemode, label, colour)
            else
                reacoma.slicing.process(i, data, markers, slicemode, label, colour)
            end
        end

        reacoma.utils.arrange("reacoma-ampgate")
        reacoma.utils.cleanup(data.tmp)
    end
end

