grid = [24 24 ];
d = prod(grid);
t.data = rand([1400 d]);
t.labels = randi(70, [1400 1]);
t.name = 'rand_data';
t.distMatrices = {construct_dist_matrix(grid)};
t.multires_i = [1 d];
t.dimensions = [70 20];
datasets = {t};
