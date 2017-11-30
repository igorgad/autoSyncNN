% --------------------------------------------------------------------
function inputs = getBatch(vbdb, batch)
% --------------------------------------------------------------------

ref = zeros(numel(batch),1);

for b = 1:numel(batch)
   im(:,:,:,b) = vbdb.Data(batch(b)).amat; % [N 1 iDim bsize]
   ref(b) = vbdb.Data(batch(b)).ref; 
end

lb = single(ref);
im(isnan(im)) = 0;

imx = permute(im,[3 4 1 2]);  % [iDim bsize N]
imdx = permute(sum(im,3),[3 4 1 2]); % [1 bsize N] % Mixes two signals without correcting time offset

inputs = {'x', single(imx), 'idx', single(imdx)} ;
