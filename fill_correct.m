%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%  fill_correct.m: MATLAB routine for calculating band filling correction %
%                  for supercell calculations with FHI-aims               %
%                                                                         %
%  Usage: Set "directory" and "file" variables to appropriate strings.    %
%         Execute script without arguments.                               %
%         k-point weighting must be set manually.                         %
%                                                                         %
%                                                                         %
%  Requirements: MATLAB, Unix-like system with SED, TAIL, and AWK         %
%                                                                         %
%  Author: Adam Jackson, Walsh Materials Design Group, University of Bath %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
directory = '../S_128';
file = '0210.out';


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

% Using time reversal symmetry and setting non-symmetric points
k_weight(1,1) = 1;
k_weight(2:length(kpoints),:) = 2;
k_weight(3,1) = 1;

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
