% --------------------------------------------------------------------
function inputs = getBatch(vbdb, batch)
% --------------------------------------------------------------------
% [vocabSize, batchSize, phraseLength].

ref = zeros(numel(batch),1);

for b = 1:numel(batch)
   im(:,:,:,b) = vbdb.Data(batch(b)).amat; 
   ref(b) = vbdb.Data(batch(b)).ref; 
end

lb = single(ref);
im(isnan(im)) = 0;

im = permute(im,[3 4 1 2]);

inputs = {'x', single(im), 'idx', single(im)} ;
