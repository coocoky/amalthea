% -------------------------------------------------------------------------
% Script: supervised_hierarchy_demo
% Author:   Mark Moyou (mmoyou@my.fit.edu)
%       Yixin Lin (yixin1996@gmail.com)
%       Glizela Taino (glizentaino@gmail.com)
% Affiliation: Florida Institute of Technology. Information
%              Characterization and Exploitation Laboratory.
%              http://research2.fit.edu/ice/
% Description: This illustrates the uselessness of specifying different
%                 number of children at each level.
% Usage: Used in hierarchical clustering on the unit hypersphere.
% -------------------------------------------------------------------------

DEBUG = 1;

datasets = getDatasets({'shrec11_125'});

D = datasets{1}.data;
[n d] = size(D);
L = datasets{1}.labels;

T = struct;
T.children = [];
T.num = n;
T.mean = sum(D);
T.mean = T.mean / norm(T.mean);
for i = 1:30
  curr = struct;
  start = (i-1) * (20) + 1;
  curr.ids = start:(start + 19);
  curr.num = 20;
  curr.children = [];
  curr.mean = sum(D(curr.ids, :));
  curr.mean = curr.mean / norm(curr.mean);
  T.children = [T.children curr];
end

distMatrix = zeros(n);

if DEBUG textprogressbar('Retrieving tree: '); end;
for i = 1:n
  if DEBUG textprogressbar(100 * i / n); end;
  [ids dists] = t_retrieve(T, D(i,:), n);
  for j = 1:n
    distMatrix(i, ids(j)) = j;
  end
end
if DEBUG textprogressbar(' done.'); end;

metricObject = metrics_shrec(distMatrix, L, 1);

