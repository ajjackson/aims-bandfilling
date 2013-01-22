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

%% Calculate energy level contributions and sum

for i=1:length(kpoints)
kpoints(i).contrib = kpoints(i).data(:,2).*kpoints(i).data(:,4);
end

for i = 1:length(kpoints)
kpoints(i).sum = sum(kpoints(i).contrib);
end

%% Get eigenvalues of lowest filled energy levels

for i = 1:length(kpoints)
eigs(:,i) = kpoints(i).data(:,4);
end

eigs_trim=eigs(kpoints(1).data(:,2)~=0,:);
low_eigs = eigs_trim(end,:);

%% Calculate band filling correction energy

correction = min(low_eigs) - ...
             (low_eigs(1) + 2*sum(low_eigs(2:end)))/(length(low_eigs)*2-1);
         
         fprintf('Band filling correction: %f eV\n', correction);