classdef LDALVQ1_4UpdateRule < UpdateRule
    
    methods (Static = true)
        
        function Mod = update(Algo, Mod, Data, iData, varargin)

            %% LDALVQ1 (LVQ1 with LDA based relevance determination) update...
            if Mod.ClassLabels(Mod.BMUs(1)) == find(Data.ClassLabels(Data.GroundTruthLabelIndices, iData))

                % Update the BMU codebook vector (LVQ)...
                Mod.SOM.codebook(Mod.BMUs(1),Mod.known) =...
                    Mod.SOM.codebook(Mod.BMUs(1),Mod.known) +...
                        Mod.a * (Mod.x(Mod.known) - Mod.SOM.codebook(Mod.BMUs(1),Mod.known));
                    
                % If the BMU classified the sample correctly, increment its
                % score...
                Mod.AccuracyHist(Mod.BMUs(1)) = Mod.AccuracyHist(Mod.BMUs(1)) + 1;
                
                % Record running stats of correctly classified samples for
                % each node...
                Mod.NodeStats{Mod.BMUs(1)}.push(Mod.x);

            else

                % Update the BMU codebook vector (LVQ)...
                Mod.SOM.codebook(Mod.BMUs(1),Mod.known) =...
                    Mod.SOM.codebook(Mod.BMUs(1),Mod.known) -...
                        Mod.a * (Mod.x(Mod.known) - Mod.SOM.codebook(Mod.BMUs(1),Mod.known));
                    
                % If the BMU classified the sample incorrectly, decrement its
                % score...
                % Mod.AccuracyHist(Mod.BMUs(1)) = Mod.AccuracyHist(Mod.BMUs(1)) - 1;

            end
            
            iClass = 1;
            for iNode = 1:size(Mod.NodeStats, 2)
                
                if ~isnan(Mod.NodeStats{iNode}.mean())                    
                    ClassMeans(iClass,:) = Mod.NodeStats{iNode}.mean();                    
                    
                    if isnan(Mod.NodeStats{iNode}.var())
                        ClassVars(iClass,:) = zeros(size(Mod.NodeStats{iNode}.mean()));
                    else
                        ClassVars(iClass,:) = Mod.NodeStats{iNode}.var();
                    end
                        
                    iClass = iClass + 1;
                end
            end
            
            % For each class, calculate a weighted mean and variance based
            % on the accuracy histogram as calculated above...
%             for iClass = 1:max(Mod.ClassLabels(:))
% 
%                 ClassData = Mod.SOM.codebook(Mod.ClassLabels == iClass, :);
%                 ClassNodeAccuracies = Mod.AccuracyHist(Mod.ClassLabels == iClass);
%                 if sum(ClassNodeAccuracies) == 0
%                     ClassNodeAccuracies = ones(size(ClassNodeAccuracies));
%                 end
%                 ClassNodeWeights = ClassNodeAccuracies + abs(min(ClassNodeAccuracies));
%                 ClassNodeWeights = ClassNodeWeights ./ norm(ClassNodeWeights,1);
%                 ClassNodeWeights(isnan(ClassNodeWeights)) = 0;
% 
%                 % Just in case the class only contains
%                 % one node...
%                 if size(ClassData,1) == 1
%                     ClassMeans(iClass,:) = ClassData;
%                     ClassVars(iClass,:) = zeros(size(ClassData));
%                 else
%                     % Calculate the weighted mean...
%                     ClassMeans(iClass,:) = sum(repmat(ClassNodeWeights,1,size(ClassData,2)) .* ClassData,1);
%                     % Calculate the weighted variance...
%                     ClassVars(iClass,:) = sum(repmat(ClassNodeWeights,1,size(ClassData,2)) .* (ClassData - repmat(ClassMeans(iClass,:), size(ClassData,1), 1)).^2);
%                 end
%                 
%             end
            
            if size(ClassMeans,1) > 1
                
                % Fisher Criterion =
                %  (Between Class Variance)
                % --------------------------
                %  (Within Class Variance)
                if any(sum(ClassVars) == 0)
                    FisherCriterion = var(ClassMeans);
                else
                    FisherCriterion = var(ClassMeans) ./ sum(ClassVars);
                end

                % Watch out for nasty NaNs...
                FisherCriterion(isnan(FisherCriterion)) = 0;

                % Make the mask a weight distribution (unit norm)...
                % Mask = (FisherCriterion ./ norm(FisherCriterion,1))';
                Mask = (FisherCriterion ./ max(FisherCriterion))';

                % Calculate running average of mask...
                Mod.MaskStats.push(Mask);

                % Save the mask for later...
                Mod.SOM.mask = Mod.MaskStats.mean();
                
            end
            
        end
        
    end
    
end