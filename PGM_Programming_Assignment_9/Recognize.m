% File: RecognizeActions.m
%
% Copyright (C) Daphne Koller, Stanford Univerity, 2012

function [predicted_labels] = Recognize(datasetTrain, datasetTest, G, maxIter)

% INPUTS
% datasetTrain: dataset for training models, see PA for details
% datasetTest: dataset for testing models, see PA for details
% G: graph parameterization as explained in PA decription
% maxIter: max number of iterations to run for EM

% OUTPUTS
% accuracy: recognition accuracy, defined as (#correctly classified examples / #total examples)
% predicted_labels: N x 1 vector with the predicted labels for each of the instances in datasetTest, with N being the number of unknown test instances


% Train a model for each action
% Note that all actions share the same graph parameterization and number of max iterations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% YOUR CODE HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Action=length(datasetTrain);
for i=1:Action
[P{i} loglikelihood{i} ClassProb{i} PairProb{i}] = EM_HMM(datasetTrain(i).actionData,datasetTrain(i).poseData, G,datasetTrain(i).InitialClassProb,datasetTrain(i).InitialPairProb, maxIter);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Classify each of the instances in datasetTrain
% Compute and return the predicted labels and accuracy
% Accuracy is defined as (#correctly classified examples / #total examples)
% Note that all actions share the same graph parameterization

accuracy = 0;
predicted_labels = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% YOUR CODE HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
testAction=length(datasetTest.actionData);
N=size(datasetTest.poseData, 1);
K = size(datasetTrain(1).InitialClassProb, 2);
predict=zeros(testAction,Action);
for ac=1:Action;
 for i=1:N
    for k=1:K
        p=0;
        for j=1:size(G,1)
         if(length(size(G))>2)
            flag=G(j,1,k);
            parent=G(j,2,k);
         else
            flag=G(j,1);
            parent=G(j,2);
         end
         if(flag==0)
            p=p+lognormpdf(datasetTest.poseData(i,j,1),P{ac}.clg(j).mu_y(k),P{ac}.clg(j).sigma_y(k));
            p=p+lognormpdf(datasetTest.poseData(i,j,2),P{ac}.clg(j).mu_x(k),P{ac}.clg(j).sigma_x(k));
            p=p+lognormpdf(datasetTest.poseData(i,j,3),P{ac}.clg(j).mu_angle(k),P{ac}.clg(j).sigma_angle(k));
         else
            p=p+lognormpdf(datasetTest.poseData(i,j,1),P{ac}.clg(j).theta(k,1)+P{ac}.clg(j).theta(k,2)*datasetTest.poseData(i,parent,1)+P{ac}.clg(j).theta(k,3)*datasetTest.poseData(i,parent,2)+P{ac}.clg(j).theta(k,4)*datasetTest.poseData(i,parent,3),P{ac}.clg(j).sigma_y(k));
            p=p+lognormpdf(datasetTest.poseData(i,j,2),P{ac}.clg(j).theta(k,5)+P{ac}.clg(j).theta(k,6)*datasetTest.poseData(i,parent,1)+P{ac}.clg(j).theta(k,7)*datasetTest.poseData(i,parent,2)+P{ac}.clg(j).theta(k,8)*datasetTest.poseData(i,parent,3),P{ac}.clg(j).sigma_x(k));
            p=p+lognormpdf(datasetTest.poseData(i,j,3),P{ac}.clg(j).theta(k,9)+P{ac}.clg(j).theta(k,10)*datasetTest.poseData(i,parent,1)+P{ac}.clg(j).theta(k,11)*datasetTest.poseData(i,parent,2)+P{ac}.clg(j).theta(k,12)*datasetTest.poseData(i,parent,3),P{ac}.clg(j).sigma_angle(k));
         end
        end
      logEmissionProb{ac}(i,k)=p; 
    end
 end
end
 
for i=1:testAction
    for l=1:Action
    factornum=length(datasetTest.actionData(i).marg_ind)+length(datasetTest.actionData(i).pair_ind)+1;
    factors=repmat(struct('var', [], 'card', [], 'val', []), factornum, 1);
    factors(1).var=1;
    factors(1).card=K;
    factors(1).val=log(P{l}.c);
    for j=1:length(datasetTest.actionData(i).marg_ind)
        factors(1+j).var=j;
        factors(1+j).card=K;
        factors(1+j).val=logEmissionProb{l}(datasetTest.actionData(i).marg_ind(j),:);
    end
     for j=1:length(datasetTest.actionData(i).pair_ind)
        factors(1+length(datasetTest.actionData(i).marg_ind)+j).var=[j j+1];
        factors(1+length(datasetTest.actionData(i).marg_ind)+j).card=[K K];
        for k=1:K*K
        assign=IndexToAssignment(k,[K K]);
        factors(1+length(datasetTest.actionData(i).marg_ind)+j).val(k)=log(P{l}.transMatrix(assign(1),assign(2)));
        end
     end
    [M, PCalibrated] = ComputeExactMarginalsHMM(factors);
    predict(i,l)=logsumexp(PCalibrated.cliqueList(1).val);
    end
end

[m predicted_labels]=max(predict,[],2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
