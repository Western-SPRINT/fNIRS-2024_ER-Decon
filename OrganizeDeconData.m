% Organizes a decon ChannelStats info 4D: [spike] x [condition] x [datatype] x [channel]
% 
% Output fields:
%   channels
%   channels_count
%   datatypes
%   datatypes_count
%   conditions
%   conditions_count
%   spike_num
%   beta
%   tstat
%   p
%   q
%   dfe
function [info] = OrganizeDeconData(data, cond_order)

%% Organize General Info

info.channels = unique(data.variables(:,["source" "detector"]));
info.channels_count = height(info.channels);

info.datatypes = unique(data.variables.type)';
info.datatypes_count = length(info.datatypes);

%spike names
re = regexp(data.conditions, '(?<cond>.+):(?<spike>.+)', 'names');
pred_cond = cellfun(@(c) c.cond, re, UniformOutput=false);
pred_spike = cellfun(@(c) str2num(c.spike), re);

if exist('cond_order', 'var')
    info.conditions = cond_order;
else
    info.conditions = unique(pred_cond)';
end
info.conditions_count = length(info.conditions);
pred_cond_num = cellfun(@(c) find(strcmp(info.conditions, c)), pred_cond);

info.spike_times = unique(pred_spike);
info.spike_num = length(info.spike_times);

%% Organize Data

info.beta = nan(info.spike_num, info.conditions_count, info.datatypes_count, info.channels_count);
info.tstat = nan(size(info.beta));
info.p = nan(size(info.beta));
info.q = nan(size(info.beta));
info.dfe = data.dfe;

%add each row
for row = 1:height(data.variables)
    %find predictor
    ind_predictor = find(strcmp(data.conditions, data.variables.cond{row}));
    if length(ind_predictor)~=1, error; end
    ind_condition = pred_cond_num(ind_predictor);
    ind_spike = find(info.spike_times == pred_spike(ind_predictor));

    %find channel
    ind_channel = find((info.channels.source == data.variables.source(row)) & (info.channels.detector == data.variables.detector(row)));
    if length(ind_channel)~=1, error; end

    %find datatype
    ind_datatype = find(strcmp(info.datatypes, data.variables.type{row}));
    if length(ind_datatype)~=1, error; end

    %store values
    for f = ["beta" "tstat" "p" "q"]
        info.(f)(ind_spike, ind_condition, ind_datatype, ind_channel) = data.(f)(row);
    end
end