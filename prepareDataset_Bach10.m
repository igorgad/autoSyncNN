clear;

N = 512;
nwin = 1;
nsigs = 2;
OR = 4;
init_discard = 1;
nexpand = 10;
maxDelay = 512;
downSampleRate = 2;

mode = 'autotest'
datasetdir = '/media/pepeu/582D8A263EED4072/DATASETS/Bach10/audio/'
medMat = sprintf('/media/pepeu/582D8A263EED4072/DATASETS/Bach10/autoSyncNN_AUTOTEST_N%d_NW%d.dat',N,nwin);

%medmatfile = matfile(medMat,'Writable',true);

exp = {' ', '''', '(', ')','1930s_','80s_','_-_','\.'};
rep = {'_','', '', '', '','','_','_'};

datadir = dir(datasetdir);

rng('default');

for xpan = 1:nexpand
    dircount = 1;
    
    for d=1:length(datadir)
        if (datadir(d).isdir == 0)
            continue;
        end
        if (strcmp(datadir(d).name,'.') == 1 || strcmp(datadir(d).name,'..') == 1)
            continue;
        end

        subdir = dir([datasetdir, datadir(d).name]);

        disp (['Analyzing folder ', datadir(d).name, ' | ', num2str(dircount), ' from ', num2str(length(datadir)-2), ' EXPAN ', num2str(xpan)]);
        din = 1;
        for d0=1:length(subdir)
            if (subdir(d0).isdir == 1)
                continue;
            end

            filename = [datasetdir, datadir(d).name, '/', subdir(d0).name];

            [p,n,e] = fileparts (filename);

            if (strcmp(e,'.ana') == 1 || strcmp(e,'.pktana') == 1 || strcmp(e,'.rtxt') == 1 || strcmp(e,'.mat') == 1)
    %             disp (['discarding file ', filename]);
                %break;
                continue;
            end

            sample_delays = [];

           if (strcmp(e,'.wav') == 1)
               sample_delay = floor(rand(1) * maxDelay) + 1;
               
               matfilename = [p, '/', n, '_adelay', num2str(sample_delay), '.mat'];
               
                if (~exist(matfilename,'file'))
                    
                    [adata, Fs] = audioread(filename);
                    adata = mean(adata',1);
                    audiodata = [zeros(1,sample_delay) , adata(sample_delay:end)] ;
                    save(matfilename, 'audiodata');
                end

                disp (['reading file ', filename]);
                
                dir_metadata.audio.(sprintf('S%02d',din)).matfile = matfilename;
                dir_metadata.audio.(sprintf('S%02d',din)).delay = sample_delay ;

                din = din + 1;
            else
                continue;
            end 
        end

        data.(sprintf('exp%02d',xpan)).(sprintf('dir%d',dircount)) = dir_metadata;

        dircount = dircount + 1;
    end
end

delete(medMat);
fileID = fopen(medMat,'w');


ac = 1;
for xpan = 1:nexpand
    fprintf ('******************************************** XPAN %d *********************************************\n', xpan);
    varlist = fieldnames(data.(sprintf('exp%02d',1)));
    for v = 1:size(varlist,1);
        str = data.(sprintf('exp%02d',1)).(varlist{v});

        v2list = fieldnames(str.audio);
        nfls = size(v2list);

        disp (['Gathering comb of song ', varlist{v}]);

        for st1=1:nfls
            for st2=st1+1:nfls

                a1 = load(str.audio.(v2list{st1}).matfile);
                a1 = downsample(a1.audiodata,downSampleRate);
                a2 = load(str.audio.(v2list{st2}).matfile);
                a2 = downsample(a2.audiodata,downSampleRate);
                
                ref   = str.audio.(v2list{st2}).delay - str.audio.(v2list{st1}).delay;
                
                if strcmp(mode,'autotest')
                    
                    a1 = a1(init_discard:end);

                    mb1 = vec2mat(a1,25);

                    a1 = reshape(mb1(std(mb1,0,2)  >= 0.1,:)',1,[]);
                    a2 = zeros(size(a1));

                    if (ref <= 0)
                        a2(abs(ref)+1:end) = a1(1:end-abs(ref));
                    else
                        a2(1:end-abs(ref)) = a1(abs(ref)+1:end);
                    end
                end
                
                if strcmp(mode,'reftest')
                    
                    a1 = a1(init_discard:end);
                    a2 = a2(init_discard:end);

                    mb1 = vec2mat(a1,25);
                    mb2 = vec2mat(a2,25);

                    a1 = reshape(mb1(std(mb1,0,2)  >= 0.1 & std(mb2,0,2)  >= 0.1,:)',1,[]);
                    a2 = reshape(mb2(std(mb1,0,2)  >= 0.1 & std(mb2,0,2)  >= 0.1,:)',1,[]);

                end
                
                a1mat = vec2mat(a1,N)';
                a2mat = vec2mat(a2,N)';
                
                if min(size(a1mat,2),size(a2mat,2)) < nwin
                    continue;
                end
                
                win = randi(min(size(a1mat,2),size(a2mat,2)), nwin,1);
                
                amat(:,:,1) = single(a2mat(:,win));
                amat(:,:,2) = single(a1mat(:,win));
                                
                fwrite(fileID,amat,'single');
                fwrite(fileID,int32(ref),'int32');
                
                ac = ac + 1;
            end
        end
    end
end

fclose(fileID);


