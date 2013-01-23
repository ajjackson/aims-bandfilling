%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%  fill_correct.m: MATLAB routine for calculating band filling correction %
%                  for supercell calculations with FHI-aims               %
%                                                                         %
%  Usage: Set "directory" and "file" variables to appropriate strings.    %
%         Execute script without arguments.                               %
%                                                                         %
%                                                                         %
%  Requirements: MATLAB, Unix-like system with SED, TAIL, and SPLIT -p    %
%                (i.e. OSX)                                               %
%                                                                         %
%  Author: Adam Jackson, Walsh Materials Design Group, University of Bath %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
directory = '../S_72';
file = '0207.out';


%% Extract final eigenvalues and split into separate k-points
%  sed -n '/K-point:       1/=' 0207.out 
%  sed -n '/Highest occupied state (VBM)/=' 0207.out 

%  sed -n -e "$FIRST_LINE,$(echo $LAST_LINE)p" 0207.out | sed '$d' > eigs2.txt

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
systemcall4 = sprintf('split -p \"K-point\" %s/eigs.tmp \"%s/kpoint-\"' ...
                ,directory,directory); 
system(systemcall4);

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
