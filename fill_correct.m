clear

%% Split eigenvalue output into separate k-points
system('split -p "K-point" ../S_72/eigs.txt "kpoint-"'); 

%% Import data
j = 1;
for name='a':'n'
kpoints(j)=importdata(sprintf('kpoint-a%s',name));
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
eigs(:,i) = kpoints(i).data((kpoints(i).data(:,2)~=0),4);
end
%low_eigs = eigs(end,:);