function [coefficients] = getheTensorProductsPerSample( indices,oneSample,...
                               supp,phi,startLevel,...
                               dim,dims,transCel,domain,sampleCount,coefficients,waveletFlag)
                       
                           
 samp = oneSample;   % before it wsas samp=sample(j,:);
    sampleCount = [sampleCount;samp];
    numbSamp = size(sampleCount,1);
    
    %1 select the relvant translates neededed for reconstructing the
    %sample!  EXPENSIVE PROCESS!!!! TOO SLOW!
    
    [ coefficients,...
        indexofRelevantTrans,...
        linearIndOfRelevantTrans,...
        sampleLattice,...
        remeBerBigTrans ] = accessLatticePointsOnline( dim,...
                               dims,indices,...
                               transCel,samp,...
                               startLevel,...
                               waveletFlag,...
                               coefficients,...
                               supp,phi );
    
    %2 checking if translates matches and retain inedxes
     CheckUniqIndexces = [ sampleLattice,remeBerBigTrans,linearIndOfRelevantTrans' ];
    
    % the corresponding coefficients to the sublattice of the one sample
    [ coeffMatrixForm,correspCoeff ] = selectRelevantCoefficients(coefficients,...
                     indexofRelevantTrans,linearIndOfRelevantTrans,sampleLattice);   
    
  
    %3 update the coefficients based on relevant translates
    [ coefficients ] = estimatingCoeffs( samp,...
                                            domain,...
                                            startLevel,...
                                            coefficients,...
                                            waveletFlag,...
                                            sampleLattice,...
                                            indexofRelevantTrans,...
                                            linearIndOfRelevantTrans,...
                                            correspCoeff,...
                                            supp,phi );
                                        
    %