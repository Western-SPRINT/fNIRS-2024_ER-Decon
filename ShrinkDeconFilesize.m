classdef ShrinkDeconFilesize < nirs.modules.AbstractModule
    properties
    end
    
    methods
        function obj = ShrinkDeconFilesize( prevJob )
           obj.name = 'Removes unnecessary cells in covb to shrink the filesize. Intended for use with Decon_MixedEffects_ForLargeDatasets';
           if nargin > 0
               obj.prevJob = prevJob;
           end
        end
        
        function data = runThis( obj, data )
            for i = 1:numel(data)
                %keep within-channel cells only
                cells_needed = (data(i).variables.source == data(i).variables.source') & (data(i).variables.detector == data(i).variables.detector');
                data(i).covb(~cells_needed) = nan;
            end
        end
        
    end
end