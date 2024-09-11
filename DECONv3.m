classdef DECONv3
    properties
        samples_pre = 2;
        samples_post = 20;
    end

    methods
        function [out] = convert( obj, s, t )
            %find trial onsets in units of samples
            onsets = find([s(1); diff(s)==1]);
            trial_num = length(onsets);

            %samples to model
            spike_offsets = -obj.samples_pre : +obj.samples_post;
            spikes_num = length(spike_offsets);

            %init
            samples_num = length(t);
            out = zeros(samples_num, spikes_num);

            %add samples
            for trial = 1:trial_num
                for spike = 1:spikes_num
                    %spike index
                    ind = onsets(trial) + spike_offsets(spike);
                    if (ind<1) || (ind>samples_num)
                        continue
                    end

                    %add samples
                    out(ind,spike) = 1;
                end
            end
        end
    end
end