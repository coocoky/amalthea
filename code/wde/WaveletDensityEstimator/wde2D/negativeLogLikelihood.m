%--------------------------------------------------------------------------
% Function:    negativeLogLikelihood
% Description: Calculates the negative log likelihood of the currents set
%              samples using the given coefficients for WDE. (2D specific)
%
% Inputs:
%   samps             - Nx2 matrix of 2D samples to use for density 
%                       estimation.  The first column is x and second y.
%   wName             - name of wavelet to use for density approximation.
%                       Use matlab naming convention for wavelets.
%                       Default: 'db1' - Haar
%   startLevel        - starting level for the the father wavelet
%                       (i.e. scaling function).
%   stopLevel         - last level for mother wavelet scaling.  The start
%                       level is same as the father wavelet's.
%   coeffs            - Nx1 vector of coefficients for the basis functions.
%                       N depends on the number of levels and translations.
%   coeffsIdx         - Lx2 matrix containing the start and stop index
%                       locations of the coeffients for each level in the
%                       coefficient vector.  L is the number of levels.
%                       For example, the set of coefficients for the
%                       starting level can be obtained from the
%                       coefficients vector as:
%                       coeffs(coeffsIdx(1,1):coeffsIdx(1,2),1)
%                       NOTE: This will be (L+1)x2 whenever we use more
%                             than just scaling coefficients.
%   scalingOnly       - flag indicating if we only want to use scaling
%                       functions for the density estimation.
%   sampleSupport     - 2x2 matrix of the sample support.
%                       First row gives min x value and max x value
%                       Second row gives min y value and max y value
%
% Outputs:
%   currCost          - Negative log likelihood value over all samples.
%   currGrad          - Nx1 vector of gradient values for the log
%                       likelihood. N is the number of coefficients.
%   currHessian       - NxN Hessian matrix of the log likelihood.
%
% Usage:
%
% Authors(s):
%   Adrian M. Peter
%
% Reference:
% A. Peter and A. Rangarajan, �Maximum likelihood wavelet density estimation
% with applications to image and shape matching,� IEEE Trans. Image Proc.,
% vol. 17, no. 4, pp. 458�468, April 2008.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Copyright (C) 2009 Adrian M. Peter (adrian.peter@gmail.com)
%
%     This file is part of the WDE package.
%
%     The source code is provided under the terms of the GNU General
%     Public License as published by the Free Software Foundation version 2
%     of the License.
%
%     WDE package is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with WDE package; if not, write to the Free Software
%     Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301
%     USA
%--------------------------------------------------------------------------

function [currCost, currGrad, currHessian] = negativeLogLikelihood(samps,...
    wName,...
    startLevel,...
    stopLevel,...
    coeffs,...
    coeffsIdx,...
    scalingOnly,...
    sampleSupport)

numSamps      = size(samps,1);%length(goodSampsIdx);

% Translation range for the starting level scaling function.  Need both x
% and y values since 2D.
scalingTransRX    = translationRange(sampleSupport(1,:), wName, startLevel);
scalingShiftValsX = [scalingTransRX(1):scalingTransRX(2)]; %all the points from -59 to 52
scalingTransRY    = translationRange(sampleSupport(2,:), wName, startLevel);
scalingShiftValsY = [scalingTransRY(1):scalingTransRY(2)];

% Set up correct basis functions. Now that we have all the translation
[father, mother] = basisFunctions(wName);
waveSupp = waveSupport(wName);

loglikelihood     = zeros(numSamps,1);

% Determine if we need to count up or down.
if(startLevel <= stopLevel)
    inc = 1;
else
    inc = -1;
end


%%%%%%
translations_x = length(scalingShiftValsX);
translations_y = length(scalingShiftValsY);
scalValsSum = zeros(translations_x,translations_y);

coeffs = reshape(coeffs', translations_x,translations_y);

% OPTIMIZATION THREE: Single loop along translations
% Gives back new sample points (x,y) along each translate K
x = bsxfun(@minus, (2^startLevel)*samps(:,1), scalingShiftValsX);
y = bsxfun(@minus, (2^startLevel)*samps(:,2), scalingShiftValsY);

% For each translate, sample values (x,y) that live under wavelet's support --> 1
valid_x = (x >= waveSupp(1) & x <= waveSupp(2));
valid_y = (y >= waveSupp(1) & y <= waveSupp(2));

scalVals_eachPoint = zeros(4007,576);

% Loop along translations in x
for i = 1 : translations_x

    % Find where points x and y exist together or intersect --> 1
    intersections = bsxfun(@times, valid_x(:,i), valid_y);
    
    % Sample indices are represented by rows.
    % Relevant y translations are represented by columns
    [sampleIndex, yTranslateIndex] = find(intersections == 1);
    relevant_points = unique(sampleIndex);
    relevant_yTrans = unique(yTranslateIndex);
    
    % Calculate father wavelet for relevant points that fall under current x translation
    x_at_translate = x(sampleIndex,i);
    father_x = father(x_at_translate);
    
    % Calculate father wavelet for relevant points that fall under all y translations
    y_at_translate = y(logical(intersections));
    father_y = father(y_at_translate);
    
    % Calculate the father wavelet for all relevant points that fall under current translations
    fatherWav = bsxfun(@times, 2^startLevel * father_x, father_y);
    
    [sampleIndex_sorted, sampleIndex_order] = sort(sampleIndex);
    fatherWavAfter = size(fatherWav);
    for j = relevant_yTrans : relevant_yTrans(end)
        relevant_yTransIndex = find(yTranslateIndex == j);
        fatherWavAfter(relevant_yTransIndex) = fatherWav(relevant_yTransIndex) .* coeffs(j,i);
    end
    
    newFatherWav = fatherWav(sampleIndex_order,:);
    newyTranlateIndex = yTranslateIndex(sampleIndex_order,:);
    newyTranlateIndex = newyTranlateIndex + (i-1) * 24;
    [n, m] = size(scalVals_eachPoint);
    linearIndex = sub2ind([n,m], sampleIndex_sorted, newyTranlateIndex);
    scalVals_eachPoint(linearIndex) = newFatherWav;
    
    fatherWav_eachPoint = accumarray(sampleIndex, fatherWavAfter);
    loglikelihood(relevant_points) = loglikelihood(relevant_points)+ fatherWav_eachPoint(relevant_points);
    
    % Assign scaling basis to correspoding x translation and y translations
    %scalingBasisGrid(i,translateIndex) = fatherWav_per_translation(translateIndex);
    
end % for i = 1 : translations_x

scalingBasisPerSample = bsxfun(@rdivide, scalVals_eachPoint, loglikelihood);
scalValsSum = sum(scalingBasisPerSample,1);
loglikelihood = log(loglikelihood.^2);













% 
% 
% 
% 
% 
% 
% 
% savedScalVals = zeros(translations_x, translations_y);
% multipliedScal = zeros(translations_x, translations_y);
% 
% 
% %%%%%%
% 
% for s = 1 : numSamps
%     
%     %sampX = samps(goodSampsIdx(s),1); sampY = samps(goodSampsIdx(s),2);
%     sampX = samps(s,1); sampY = samps(s,2);
%     
%     % Compute father value for all scaled and translated samples
%     % over our entire 2D sampling grid.
%     x         = 2^startLevel*sampX - scalingShiftValsX; % This is the wavelet basis argument (x = 2^j x - k)
%     y         = 2^startLevel*sampY - scalingShiftValsY;
%     
%     % Set sample support values
%     xIndex = find(x <= 7 & x >= 0);
%     yIndex = find( y <= 7 & y >= 0);
%     
%     scalVals  = 2^startLevel*kron(father(x(xIndex)),father(y(yIndex))); %if non zero, then is true and x falls under wavelete basis
%     scalVals = reshape(scalVals, [length(yIndex), length(xIndex)]);
%     
%     % Weight the basis functions with the coefficients.
%     scalingBasis = coeffs(yIndex,xIndex).*scalVals; %if scal vals are zero, then no coeff
%     scalingSum   = sum(sum(scalingBasis));
%     
%     savedScalVals(yIndex, xIndex) = savedScalVals(yIndex, xIndex) + scalVals;
%     multipliedScal(yIndex,xIndex) = multipliedScal(yIndex,xIndex) + scalingBasis;
%     
%     %     basisSumPerSample = scalingSum + waveletSum; % Dep.
%     basisSumPerSample = scalingSum; % Dep.
%     
%     %     loglikelihood     = loglikelihood + log(basisSumPerSample^2); % Dep.
%     
%     loglikelihood(s)  = log(basisSumPerSample^2); % Dep.   equation 15
%     
%     scalVals  = scalVals/basisSumPerSample;
%     
%     % For the gradient we keep summing this up for all samples.
%     %     scalValsSum = scalValsSum + scalVals;
%     
%     scalValsSum(yIndex,xIndex) = scalValsSum(yIndex,xIndex) + scalVals;
%     
%     
% end % for s = 1 : numSamps

coeffs = reshape(coeffs.', [numel(coeffs),1]);
%scalValsSum = reshape(scalValsSum, [1, numel(scalValsSum)]);

%this is what tells
currCost = -(1/numSamps)*sum(loglikelihood);    %equation 15 this is negative loglikelihood
% currCost = -(1/numSamps)*loglikelihood;

if(~scalingOnly)
    currGrad = -2*(1/numSamps)*[scalValsSum mothValsSum]';
else
    currGrad = -2*(1/numSamps)*[scalValsSum]';
end
