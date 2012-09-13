load('bdryHalo_0.mdat', '-ascii');
%load('heat_2D_P_hotPar_3D_pl.mdat', '-ascii');
%load('heat_2D_P_hotPar_3D_pochoir.mdat', '-ascii');
% load('heat_2D_P_hotPar_3D_pochoir_bt.mdat', '-ascii');
size = bdryHalo_0(:, 1);
%y = [200:200:3200];
z = (size .^ 2) .* 200;
bdry = bdryHalo_0(:, 2);
halo = bdryHalo_0(:, 3);

%semilogy(z, z' ./ sLoop, 'gx-', z, z' ./ pLoop, 'b+-', z, z' ./ pochoir, 'ro-');
%plot(z, z' ./ macro, 'gx-', z, z' ./ pointer, 'b+-', z, z' ./ optPointer, 'ro-');
loglog(z, bdry, 'bx-', z, halo, 'ro-');
xlabel('Grid Points');
ylabel('execution time in ms');
legend('boundary function', 'Halo');
grid off;
% hold on;
% plot(x, y_parallel_for ./ y_iter);
% hold on;
% plot(x, pfor1 ./ pointer, x, pfor2 ./ iter, x, pfor1 ./ macro);
% hold on;
% plot(x, pfor2 ./ iter);