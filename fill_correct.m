%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%  fill_correct.m: MATLAB routine for calculating band filling correction %
%                  for supercell calculations with FHI-aims               %
%                                                                         %
%  Usage: correction = fill_correct('directory','file')                   %
%         where 'directory' and 'file' are the location and filename of   %
%         an FHI-aims output file. The FHI-aims run must be executed with %
%         the "output k_eigenvalue n" option to obtain data for each      %
%         k-point. The k-point weighting must be set up manually in the   %
%         first section of this code ("Define k-point weighting").        %
%                                                                         %
%  Requirements: MATLAB, Unix-like system with SED, TAIL, and AWK         %
%                                                                         %
%  Author: Adam Jackson, Walsh Materials Design Group, University of Bath %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function correction = fill_correct(directory,file)

%% Define k-point weighting

% Using time reversal symmetry and setting non-symmetric points

% % For [3 3 3] k-point grid (S_72)
% k_weight(1,1) = 1;
% k_weight(2:14,1) = 2;

% % For [2 3 2] k-point grid (S_128)
% k_weight(1,1) = 1;
% k_weight(2:10,1) = 2;
% k_weight(3,1) = 1;

% % For [2 2 2] k-point grid (S_300)
% k_weight(1:8) = 1;


%% Extract final eigenvalues and split into separate k-points

systemcall1 = sprintf( ... 
    'sed -n "/K-point:       1 /=" %s/%s | tail -1' ...
        ,directory,file);
systemcall2 = sprintf( ...
    'sed -n "/Highest occupied state (VBM)/=" %s/%s %s' ...    
        ,directory,file,'| tail -1');

%%%%%%%%% Get line numbers for last set of eigenvalues %%%%%%%%%    
[dummy, first_line] = system(systemcall1);
[dummy, last_line] = system(systemcall2);

%%%%%%%%% Write to eigs.tmp %%%%%%%%%%
systemcall3 = sprintf( ...
    'sed -n "%d,%dp" %s/%s | sed "/Highest/d" > %s/eigs.tmp' ...
    ,str2num(first_line),str2num(last_line),directory,file ...
    ,directory);
system(systemcall3);        

%%%%%%%%% Split to individual k-point files %%%%%%%%%%

systemcall4 = sprintf('awk ''BEGIN{i=0} %s%s/kpoint-" i; %s %s/eigs.tmp',...
  '/K-point/{++i}{filename = "',directory,'print >filename }''',directory);
system(systemcall4);

%%%%%%%%% Count k-points %%%%%%%%%
systemcall5=sprintf('grep -c ''K-point'' %s/eigs.tmp',directory);
[dummy, n_kpoints] = system(systemcall5);
n_kpoints = str2num(n_kpoints);

%% Import data

for i=1:n_kpoints
kpoints(i)=importdata(sprintf('%s/kpoint-%d',directory,i));
i = i+1;
end

%% Identify reference energy
for i = 1:n_kpoints
   max_filled(i) = max(kpoints(i).data(kpoints(i).data(:,2)~=0,4));   
end
% Assuming minimum at gamma point
ref_e = max_filled(1);

%% Calculate band filling correction energy

for i = 1:length(kpoints)
    high_energies = kpoints(i).data(kpoints(i).data(:,4)>=ref_e, 4);
    band_occupancy = kpoints(i).data(kpoints(i).data(:,4)>=ref_e, 2);
    contributions(i) = sum((high_energies-ref_e).*band_occupancy*k_weight(i));
    kp_occupancy(i,1) = sum(band_occupancy);
end

correction = -sum(contributions)/sum(k_weight);
         
fprintf('Band filling correction: %f eV\n', correction);
         
%% Check occupancy is sane
total_occupation = sum(kp_occupancy.*k_weight)/sum(k_weight);

fprintf('Conduction band occupation: %f electrons\n',total_occupation);
