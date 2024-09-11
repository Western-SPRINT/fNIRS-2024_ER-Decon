% Performs a "nirs.modules.MixedEffects" on each channel indepentently and
% merges the results.
%
% Suitable for cases where there is too much data to run everything together.
%
% The input files must be "ChannelStats" from a "nirs.modules.GLM" with a
% DECON basis.
%
function Decon_MixedEffects_ForLargeDatasets(bids_info, suffix_in, suffix_out)

%% Generate Output Filepath

% filepath_out = [bids_info.root_directory 'derivatives' filesep 'group_' upper(suffix_out)];
filepath_out = ['..' filesep 'group_' upper(suffix_out)];

%% Define MixedEffects Job

jobs = nirs.modules.MixedEffects;
jobs.formula = 'beta ~ -1 + cond + (1|subject)';
jobs.robust = true;

%% Get Channels

channel_info = bids_info.first_channel_set_LDC;
channels_count = height(channel_info);

%% Find Input Files

[filepaths_input,exists_input] = fNIRSTools.bids.io.getFilepath(suffix_in, bids_info, true);

if sum(exists_input~=0) < 2
    error('Fewer than 2 valid input files were found!')
end

if any(~exists_input)
    warning('%d input files were not found and will ignored:\n%s', sum(exists_input==0), sprintf('* %s\n', filepaths_input{~exists_input}))
end

filepaths_input = filepaths_input(exists_input~=0);
files_count = length(filepaths_input);

%% Prepare Channel Data (faster alternative to loading each time, but uses more memory)

fprintf('Loading channel data...\n');
for fid = files_count:-1:1
    fprintf('\tPreparing file %d of %d...\n', 1+files_count-fid, files_count);

    %load
    data = getfield(load(filepaths_input{fid}),'data');

    %extract each channel
    for c = channels_count:-1:1
        %get source/detector
        source = channel_info.source(c);
        detector = channel_info.detector(c);

        %make a copy
        channel_data(c,fid) = data;

        %find channel
        ind_probe_link = find(channel_data(c,fid).probe.link.source==source & channel_data(c,fid).probe.link.detector==detector);
        ind_vars = find(channel_data(c,fid).variables.source==source & channel_data(c,fid).variables.detector==detector);

        %reduce to 1 channel
        channel_data(c,fid).probe.link = channel_data(c,fid).probe.link(ind_probe_link,:);
        channel_data(c,fid).variables = channel_data(c,fid).variables(ind_vars,:);
        channel_data(c,fid).beta = channel_data(c,fid).beta(ind_vars);
        channel_data(c,fid).covb = channel_data(c,fid).covb(ind_vars,ind_vars);
    end

    %cleanup
    clear data
end


%% Run Single-Channel MixedEffects

fprintf('Running MixedEffects on channels...\n');
for c = 1:channels_count
    %get source/detector
    source = channel_info.source(c);
    detector = channel_info.detector(c);

    %display
    fprintf('\tProcessing channel %d of %d: S%d-D%d...\n', c, channels_count, source, detector);
    
    %run MixedEffects
    channel_info.glm(c) = jobs.run(channel_data(c,:));
end

%% Merge Results

fprintf('Merging results...\n');

%start with an input as a template
data = getfield(load(filepaths_input{fid}),'data');
data.beta(:) = nan;
data.covb(:) = nan;
data.dfe = nan;
data.demographics = Dictionary;

%set name
[~,name,~] = fileparts(filepath_out);
data.description = name;

%use dfe from Mixed Effects (same df as if everthing was run together)
data.dfe = channel_info.glm(1).dfe;

%populate from channel GLMs...
for c = 1:channels_count
    for i = 1:height(channel_info.glm(c).variables)
        %find index
        ind = find(data.variables.source == channel_info.glm(c).variables.source(i) & ...
                data.variables.detector == channel_info.glm(c).variables.detector(i) & ...
                strcmp(data.variables.type, channel_info.glm(c).variables.type{i}) & ...
                strcmp(data.variables.cond, channel_info.glm(c).variables.cond{i}));

        %checks
        if length(ind)~=1 %should find exactly one match
            error('Too many matches during merging')
        elseif ~isnan(data.beta(ind)) %beta at this index should still be NaN
            error('Duplicate during merging')
        end

        %copy beta and covb
        data.beta(ind) = channel_info.glm(c).beta(i);
        data.covb(ind,ind) = channel_info.glm(c).covb(i,i);
    end
end

%% Save

fprintf('Saving: %s\n', filepath_out);
cond_order = {'Lift' 'Grasp' 'Touch' 'View'};
info = OrganizeDeconData(data, cond_order);
save(filepath_out, 'data', 'info')
% save(filepath_out, 'data', 'channel_info', '-v7.3')

%% Done

disp Done.