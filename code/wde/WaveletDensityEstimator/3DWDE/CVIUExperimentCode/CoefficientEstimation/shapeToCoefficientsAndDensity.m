%--------------------------------------------------------------------------
% Function:    shapesToCoeffients
% Description: This functions computes the 3D square-root wavelet density
%              coefficients of 3D shape data. 
% Inputs:
%   samples         - Nx3 vertices of the shape, or the smallest 3
%                     eigenfunctions of the Laplace-Beltrami Operator. 
% 
%   wName           - Name of wavelet to use for density approximation.
%                     Use matlab naming convention for wavelets.
%                     Default: 'db1' - Haar
%                     Pick wavelet family.  Currently supports:
%                     db1-10, e.g. 'db2', Note: 'db1' is Haar
%                     coif1-5, e.g. 'coif4'
%                     sym4-10, e.g. 'sym4'
% 
%   startLevel      - Starting level for the the father wavelet
%                     (i.e. scaling function).  
%                     Default: 0
% 
%   stopLevel       - Last level for mother wavelet scaling.  The start
%                     level is same as the father wavelet's.
%                     Default: 5
% 
%   domain          - 3x2 matrix containing the lower bounds of the three
%                     coordinate basis.
%
%   erThr           - Error value to determine which coefficients need to
%                     be recomputed. 
% 
% 
% Outputs:
%   coefficients    - Coefficient vector of the shape. nts.
%
%   checkVar        - 1 if the coefficients did not converge.
%
% Usage: Used in the 3D shape matching framework. 
%
% Authors(s):
%   Mark Moyou - markmmoyou@gmail.com
%   Adrian Peter - adrian.peter@gmail.com
%   Koffi Eddy Ihou - eddyson007@hotmail.com
%
% Affiliation: Florida Institute of Technology. Information
%              Characterization and Exploitation Laborartory.
%              http://research2.fit.edu/ice/
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
function [coefficients, pdf, convCheck] = shapeToCoefficientsAndDensity(...
           sample, wdeSet)
                                        

stCoeff = tic;
% Estimate the density.  The returned 'coeffs' has the set of coefficients
% for each of the optimization iterations.  The last column is the most
% recent.                                          
[coefficients, coeffsIdx, iter] = mlWDE3D_Par(sample, wdeSet);  

stopStCoeff = toc(stCoeff);
disp(['Coefficient Estimation in minutes: ' num2str(stopStCoeff/60)]);

coefficients = coefficients(:,end);

% Uncomment this section if you want to normalize coefficients.
% Check if coefficients converged.  If not they can be easily normalized.
% % diffCoeff = abs(1 - (sum(coefficients(:,end).^2)));
if(norm(coefficients(:,end))~= 1)

    disp('Coefficients did not converge to 1.  Renormalizing manually!'); 
    D = norm(coefficients(:,end))^2;
    disp(['Off by ' num2str(abs(1-D)) ]);
    coefficients(:,end) = coefficients(:,end)/sqrt(D);
    
    if (iter == wdeSet.maxIterWhile)
        convCheck = [1, abs(1-D)];
    else
        convCheck = [0, abs(1-D)];
    end
else
    convCheck = [0,0];
end  

% Density Reconstruction. 
st = tic;
isovalue = (max(sample(:))- min(sample(:)))/2;

sp = plotWDE_Par(isovalue, wdeSet.densityPts, wdeSet, coefficients, coeffsIdx);                        
  
pdf = sp.^2;
pdf = pdf + max(pdf(:))*wdeSet.scaleFac;
pdf = pdf/sum(pdf(:));    

stopTime = toc(st);
disp(['Density reconstruction in minutes : ' num2str(stopTime/60)]);

                                        