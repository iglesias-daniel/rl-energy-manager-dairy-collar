function export_actors(agentFiles, outNames, outDir)
%EXPORT_ACTORS Extract the actor network from trained RL agents.
%
%   export_actors(agentFiles, outNames, outDir)
%
%   agentFiles : cell array of paths to MAT files saved by train()
%                (each one holds a variable called `saved_agent`)
%   outNames   : cell array with the base name for each output
%   outDir     : output folder
%
%   For each agent this writes:
%     <name>_actor.mat     -> `actor` (RL Toolbox actor object) and
%                             `actorNet` (the underlying network)
%     <name>_weights.json  -> weights and biases of every learnable layer,
%                             ready to be pasted into the firmware
%
%   The full agent files also contain the critics and the experience
%   buffer (~10 MB each). Only the actor is needed to run the energy
%   manager, so this keeps the repository small.
%
%   SaturationLayer.m (in matlab/masters) must be on the MATLAB path.

if ~exist(outDir, "dir"); mkdir(outDir); end

for k = 1:numel(agentFiles)
    s = load(agentFiles{k});
    if isfield(s, "saved_agent")
        agent = s.saved_agent;
    else
        fn = fieldnames(s);
        agent = s.(fn{1});
    end

    actor = getActor(agent);
    actorNet = getModel(actor);

    save(fullfile(outDir, outNames{k} + "_actor.mat"), "actor", "actorNet");

    % Learnables -> JSON
    out = struct();
    out.agent = outNames{k};
    out.algorithm = class(agent);
    L = actorNet.Learnables;
    layers = struct("layer", {}, "parameter", {}, "size", {}, "value", {});
    nParams = 0;
    for i = 1:height(L)
        v = L.Value{i};
        if isa(v, "dlarray"); v = extractdata(v); end
        v = double(gather(v));
        layers(end+1) = struct( ...
            "layer", L.Layer(i), ...
            "parameter", L.Parameter(i), ...
            "size", size(v), ...
            "value", {v}); %#ok<AGROW>
        nParams = nParams + numel(v);
    end
    out.numLearnables = nParams;
    out.learnables = layers;

    fid = fopen(fullfile(outDir, outNames{k} + "_weights.json"), "w");
    fprintf(fid, "%s", jsonencode(out, PrettyPrint=true));
    fclose(fid);

    fprintf("%s: %s, %d learnables\n", outNames{k}, class(agent), nParams);
end
end
