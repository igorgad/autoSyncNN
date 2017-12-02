% --------------------------------------------------------------------
function inputs = getBatch(vbdb, batch)
% --------------------------------------------------------------------

ref = zeros(numel(batch),1);

for b = 1:numel(batch)
   im(:,:,b) = vbdb.Data(batch(b)).amat; % [N iDim bsize]
   ir(:,:,b) = vbdb.Data(batch(b)).rmat; % [N 1 bsize]
   ref(b) = vbdb.Data(batch(b)).ref; 
end

im(isnan(im)) = 0;
ir(isnan(ir)) = 0;

imx = permute(im,[2 3 1]);  % [iDim bsize N]
imdx = permute(ir,[2 3 1]); % [1 bsize N] % Synchronized Signals

inputs = {'x', single(imx), 'idx', single(imdx)} ;
