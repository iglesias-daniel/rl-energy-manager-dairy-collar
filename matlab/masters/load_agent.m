function agent = load_agent(n_ag, agentDir)
%LOAD_AGENT Load trained agent number n_ag for simulation in Simulink.
%
%   agent = load_agent(n_ag)            uses the actors in ./agents
%   agent = load_agent(n_ag, agentDir)  uses another folder
%
%   If agentDir contains a full agent saved by train() (AgentXXXX.mat with
%   the variable `saved_agent`, e.g. after re-training with train_agents.m)
%   it is used directly. Otherwise the agent is rebuilt from the exported
%   actor (agentNN_actor.mat). Only the actor is used when the RL Agent
%   block runs in simulation, so a new (untrained) critic is attached just
%   to build a valid rlTD3Agent object.

if nargin < 2
    agentDir = fullfile(fileparts(mfilename("fullpath")), "agents");
end

full = dir(fullfile(agentDir, sprintf("Agente%d_*", n_ag), "Agent*.mat"));
if ~isempty(full)
    s = load(fullfile(full(1).folder, full(1).name));
    agent = s.saved_agent;
    return
end

s = load(fullfile(agentDir, sprintf("agent%02d_actor.mat", n_ag)), "actor");
actor = s.actor;
tmp = rlTD3Agent(actor.ObservationInfo, actor.ActionInfo);
agent = rlTD3Agent(actor, getCritic(tmp));
agent.AgentOptions.DiscountFactor = 0.9;
end
