classdef ImdbCalvin < handle
    %IMDBCALVIN
    % Base image database that holds information about the
    % dataset and various retrieval functions, such as getBatch(..).
    %
    % Copyright by Holger Caesar & Jasper Uijlings, 2015
    
    properties
        numClasses
        datasetMode % train, val or test

        data        % data.train data.val data.test
        
        flipLR = false;  % Flag if data will be flipped or not
    end
    
    methods (Abstract)
        % This is the main method which needs to be implemented.
        % It is used by CalvinNN.train()
        [inputs, numElements] = getBatch(obj, batchInds, net);
    end
    
    methods
        
        function setDatasetMode(obj, datasetMode)
            % 'train', 'val', or 'test' set
            if ~ismember(datasetMode, {'train', 'val', 'test'}),
                error('Unknown datasetMode');
            end
            
            obj.datasetMode = datasetMode;
        end
        
        function allBatchInds = getAllBatchInds(obj)
            % Obtain the indices and ordering of all batches (for this epoch)
            switch obj.datasetMode
                case 'train'
                    allBatchInds = randperm(size(obj.data.train,1));
                otherwise
                    allBatchInds = 1:size(obj.data.(obj.datasetMode),1);
            end
        end
        
        
        function switchFlipLR(obj)
            % Switch the flipLR switch
            obj.flipLR = mod(obj.flipLR+1, 2);                
        end
    end
end
