clear;

N = 256;
nwin = 64;
nsigs = 2;
OR = 4;
init_discard = 1;
nexpand = 1;
maxDelay = 1024;

mode = 'autotest'
datasetdir = '/media/pepeu/582D8A263EED4072/DATASETS/MedleyDB/dset_cor/'
ymldir = '/media/pepeu/582D8A263EED4072/DATASETS/MedleyDB/METADATA/'
medMat = sprintf('/media/pepeu/582D8A263EED4072/DATASETS/MedleyDB/autoSyncNN_AUTOTEST_N%d_NW%d_XPAN%d.dat',N,nwin,nexpand);
bsize = 1152

%medmatfile = matfile(medMat,'Writable',true);

exp = {' ', '''', '(', ')','1930s_','80s_','_-_','\.'};
rep = {'_','', '', '', '','','_','_'};

rythm = {'auxiliary percussion', 'bass drum', 'bongo', 'chimes','claps', 'cymbal', 'drum machine', 'darbuka', 'glockenspiel','doumbek', 'drum set', 'kick drum', 'shaker', 'snare drum', 'tabla', 'tambourine', 'timpani', 'toms', 'vibraphone' };
eletronic = {'Main System', 'fx/processed sound', 'sampler','scratches' };
strings = {'acoustic guitar', 'banjo', 'cello', 'cello section', 'clean electric guitar', 'distorted electric guitar', 'double bass','lap steel guitar','mandolin','string section','viola','viola section','violin','violin section','yangqin', 'zhongruan'};
brass = {'alto saxophone', 'bamboo flute', 'baritone saxophone', 'bass clarinet', 'bassoon','brass section', 'clarinet', 'clarinet section','dizi', 'flute','flute section', 'french horn', 'french horn section','oboe','oud','tenor saxophone','trombone', 'trombone section','trumpet','trumpet section' ,'tuba' };
voice = {'female singer', 'male rapper','male singer','male speaker'};
melody = {'accordion','piano', 'synthesizer','tack piano'};

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


        ymlfilename = [ymldir, datadir(d).name(1:end-5), 'METADATA.yaml'];
        dir_metadata = YAML.read(ymlfilename);   
        %medmatfile.(regexprep(dir_metadata.title,' ','_')) = dir_metadata;

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

                if (find(strcmp(dir_metadata.stems.(sprintf('S%02d',din)).instrument,rythm)) > 0)
                    dir_metadata.audio.(sprintf('S%02d',din)).type = 'rythm';
                else
                    if (find(strcmp(dir_metadata.stems.(sprintf('S%02d',din)).instrument,eletronic)) > 0)
                        dir_metadata.audio.(sprintf('S%02d',din)).type = 'eletronic';
                    else
                        if (find(strcmp(dir_metadata.stems.(sprintf('S%02d',din)).instrument,strings)) > 0)
                            dir_metadata.audio.(sprintf('S%02d',din)).type = 'strings';
                        else
                            if (find(strcmp(dir_metadata.stems.(sprintf('S%02d',din)).instrument,brass)) > 0)
                                dir_metadata.audio.(sprintf('S%02d',din)).type = 'brass';
                            else
                                if (find(strcmp(dir_metadata.stems.(sprintf('S%02d',din)).instrument,voice)) > 0)
                                    dir_metadata.audio.(sprintf('S%02d',din)).type = 'voice';
                                else
                                    if (find(strcmp(dir_metadata.stems.(sprintf('S%02d',din)).instrument,melody)) > 0)
                                        dir_metadata.audio.(sprintf('S%02d',din)).type = 'melody';
                                    else
                                        dir_metadata.audio.(sprintf('S%02d',din)).type = 'unknow';
                                    end
                                end
                            end
                        end
                    end
                end
                
                dir_metadata.audio.(sprintf('S%02d',din)).matfile = matfilename;
                dir_metadata.audio.(sprintf('S%02d',din)).inst = dir_metadata.stems.(sprintf('S%02d',din)).instrument;
                %dir_metadata.audio.(sprintf('S%02d',din)).fs = Fs;
                dir_metadata.audio.(sprintf('S%02d',din)).delay = sample_delay ;

                din = din + 1;
            else
                continue;
            end 
        end
        dir_metadata.bsize = bsize;
        data.(sprintf('exp%02d',xpan)).(regexprep(dir_metadata.title,exp,rep)) = dir_metadata;

        dircount = dircount + 1;
    end
end

cbac = 1;
for xpan = 1:nexpand
    varlist = fieldnames(data.(sprintf('exp%02d',1)));
    for v = 1:size(varlist,1);
        str = data.(sprintf('exp%02d',1)).(varlist{v});

        v2list = fieldnames(str.vbr);
        nfls = size(v2list);

        for st1=1:nfls
            for st2=st1+1:nfls
                
                % combClass: 5 - same instruments, 4 - same type
                % combClass: 3 - mixed types without voice
                % combClass: 2 - mixed types with voice
                % combClass: 1 - unknow 
                
                inst1 = str.audio.(v2list{st1}).inst;
                type1 = str.audio.(v2list{st1}).type;
                
                inst2 = str.audio.(v2list{st2}).inst;
                type2 = str.audio.(v2list{st2}).type;
                
                if strcmp(inst1, inst2)
                    combClass = 5;
                else
                    if strcmp(type1, type2)
                        combClass = 4;
                    else
                        if ~strcmp(type1, 'voice') && ~strcmp(type2,'voice')
                            combClass = 3;
                        else
                            if strcmp(type1, 'voice') || strcmp(type2,'voice')
                                combClass = 2;
                            else
                                combClass = 1;
                            end
                        end
                    end
                end

                cbarray(cbac) = combClass;

                cbac = cbac + 1;
            end
        end
    end
end

delete(medMat);
fileID = fopen(medMat,'w');

fwrite(fileID,int32(cbac),'int32');
fwrite(fileID,int32(cbarray),'int32');

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

                datacomb.inst1 = str.audio.(v2list{st1}).inst;
                datacomb.inst2 = str.audio.(v2list{st2}).inst;
                a1 = load(str.audio.(v2list{st1}).matfile);
                a2 = load(str.audio.(v2list{st2}).matfile);
                ref   = str.audio.(v2list{st2}).delay - str.audio.(v2list{st1}).delay;
                
                allcomb.(sprintf('C%d',ac)) = datacomb;
                
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
                
                [a1mat, nws1] = overlapData(a1,N,OR);
                [a2mat, nws2] = overlapData(a2,N,OR);
                
                if min(nws1,nws2) < nwin
                    continue;
                end
                
                amat(:,:,1) = single(a2mat(1:nwin,:)');
                amat(:,:,2) = single(a1mat(1:nwin,:)');
                                
                fwrite(fileID,matvb,'single');
                fwrite(fileID,int32(datacomb.ref),'int32');
                
                ac = ac + 1;
            end
        end
    end
end

fclose(fileID);

[p,n,e] = fileparts (medMat);
save([p,n,'_CINFO.mat'], allcomb);


