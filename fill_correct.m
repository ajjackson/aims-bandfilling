%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%  fill_correct.m: MATLAB routine for calculating band filling correction %
%                  for supercell calculations with FHI-aims               %
%                                                                         %
%  Usage: Extract eigenvalues from FHI-aims output file, save to file     %
%         "eigs.txt". Change "directory" variable to working directory.   %
%                                                                         %
%  Requirements: MATLAB, Unix-like system with "split -p" option (i.e.OSX)%
%                                                                         %
%  Author: Adam Jackson, Walsh Materials Design Group, University of Bath %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
directory = '../S_72';

%% Split eigenvalue output into separate k-points
systemcall = sprintf('split -p \"K-point\" %s/eigs.txt \"%s/kpoint-\"' ...
                ,directory,directory); 
system(systemcall);

%% Import data
j = 1;
for name='a':'n'
kpoints(j)=importdata(sprintf('%s/kpoint-a%s',directory,name));
j = j+1;
end

% Using time reversal symmetry and assuming first k-point is gamma point
k_weight(1,1) = 1;
k_weight(2:length(kpoints),:) = 2;

%% Get eigenvalues and occupancies of lowest filled energy levels

min_point = 1; % Assume that minimum is at gamma point

for i = 1:length(kpoints)
eigs(:,i,1) = kpoints(i).data(:,4);
eigs(:,i,2) = kpoints(i).data(:,2);
end

eigs_trim=eigs(kpoints(min_point).data(:,2)~=0,:,:);
band(:,1) = eigs_trim(end,:,1)';
occupancy(:,1) = eigs_trim(end,:,2)';

%% Calculate band filling correction energy

contributions = (band-band(min_point)).*occupancy.*k_weight;
    correction = sum(contributions)/sum(k_weight);
         
fprintf('Band filling correction: %f eV\n', correction);
         
%% Check occupancy is sane
total_occupation = sum(occupancy.*k_weight)/sum(k_weight);

fprintf('Conduction band occupation: %f electrons\n',total_occupation);
