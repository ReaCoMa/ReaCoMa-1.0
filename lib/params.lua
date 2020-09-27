params = {}

params.archetype = {

    nmf = {
        name = "fluidParamNMF",
        fftsettings = "1024 -1 -1",
        components = "2",
        iterations = "100",
    },

    transients = {
        name = "fluidParamTransients",
        blocksize = "256",
        clumplength = "25",
        order = "20",
        padsize = "128",
        skew = "0.0",
        threshback = "1.1",
        threshfwd = "2.0",
        windowsize = "14"
    },

    hpss = {
        name = "fluidParamHPSS",
        fftsettings = "1024 -1 -1",
        harmfiltersize = "17",
        harmthresh = "0.0 1.0 1.0 1.0",
        percfiltersize = "31",
        percthresh = "0.0 1.0 1.0 1.0",
        maskingmode = "0"
    },

    sines = {
        name = "fluidParamSines",
        birthhighthreshold = "-60",
        birthlowthreshold = "-24",
        detectionthreshold = "-96",
        trackfreqrange = "50.0",
        trackingmethod = "0",
        trackmagrange = "15.0",
        trackprob = "0.5",
        bandwidth = "76",
        fftsettings = "1024 -1 -1",
        mintracklen = "15"
    },

    transientslice = {
        name = "fluidParamTransientSlice",
        blocksize = "256",
        clumplength = "25",
        minslicelength = "1000",
        order = "20",
        padsize = "128",
        skew = "0.0",
        threshback = "1.1",
        threshfwd = "2.0",
        windowsize = "14",
        markers = "0",
        slicemode = "1",
        label = "transient",
        colour = "252 140 3"
    },

    onsetslice = {
        name = "fluidParamOnsetSlice",
        metric = "0",
        threshold = "0.5",
        minslicelength = "2",
        filtersize = "5",
        framedelta = "0",
        fftsettings = "1024 -1 -1",
        markers = "0",
        slicemode = "1",
        label = "onset",
        colour = "166 51 78"
    },

    noveltyslice = {
        name = "fluidParamNoveltySlice",
        feature = "0",
        fftsettings = "1024 -1 -1",
        filtersize = "1",
        kernelsize = "3",
        threshold = "0.5",
        minslicelength = "2",
        markers = "0",
        slicemode = "1",
        label = "novelty",
        colour = "3 127 252"
    },

    ampslice = {
        name = "fluidParamAmpSlice",
        fastrampup = "1",
        fastrampdown = "1",
        slowrampup = "100",
        slowrampdown = "100",
        onthreshold = "144",
        offthreshold = "-144",
        floor = "-145",
        minslicelength = "2",
        highpassfreq = "85",
        markers = "0",
        slicemode = "1",
        label = "amplitude",
        colour = "60 207 65"
    },

    ampgate = {
        name = "fluidParamAmpGate",
        rampup = "100",
        rampdown = "100",
        onthreshold = "144",
        offthreshold = "-144",
        minslicelength = "2",
        minsilencelength = "100",
        minlengthabove = "100",
        minlengthbelow = "100",
        lookback = "5",
        lookahead = "5",
        highpassfreq = "100",
        mute = "1",
        onsetsonly = "0",
        markers = "0",
        slicemode = "1",
        label = "ampgate"
    }
}

params.experimental = {
    centroid_sort = {
        name = "fluidCentroidSort",
        fftsettings = "4096 1024 4096"
    },
    loudness_sort = {
        name = "fluidLoudnessSort",
        windowsize = "17640",
        hopsize = "4410"
    },
    auto_novelty = {
        name = "fluidAutoNovelty",
        feature = "0",
        threshold = "0.5",
        kernelsize = "3",
        filtersize = "1",
        fftsettings = "1024 -1 -1",
        minslicelength = "2",
        target_slices = "10",
        tolerance = "2",
        max_iterations = "100"
    }
}

params.check_params = function(param_table)
    -- This should only really once per REAPER install
    -- Otherwise most of this will just run and pass over every check...
    -- ... deferring to a getter that retrieves what we need
    local name = param_table.name
    for parameter, value in pairs(param_table) do
        if not reaper.HasExtState(name, parameter) then
            reaper.SetExtState(name, parameter, value, true)
        end
    end
end

params.parse_params = function(parameter_names, processor)
    -- Provide captions in,
    -- turn this into a string of parameter values to be provided to the user
    -- We do this because iterating tables is not deterministic
    local split_params = utils.commasplit(parameter_names)
    local param_values = {}
    for i=1, #split_params do
        param_values[#param_values+1] = reaper.GetExtState(processor.name, split_params[i])
    end
    return table.concat(param_values, ",")
end

params.store_params = function(processor, parameter_names, parameter_values)
    -- Taking two strings that are CSV of params and values
    -- This lets you re-use non, hardcoded values to store
    -- Store the numbers in the external state of reaper
    -- Processor tells you what the name of the object is and where to store
    local n = utils.commasplit(parameter_names)
    local v = utils.commasplit(parameter_values)

    for i=1, #n do
        reaper.SetExtState(processor.name, n[i], v[i], true)
    end
end

return params