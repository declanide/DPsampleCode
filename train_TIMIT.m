%Needs the following files:
%gram
%configTIMIT
%config
%proto
%monophones0
clear all
clc
tic

homedir=['D:\work\TrainTIMIT\']; %Set the current directory of running MatLab
traindir=['D:\database\TIMIT\TIMIT\TRAIN\'];%Point to the TIMIT database train sets
testdir=['D:\database\TIMIT\TIMIT\TEST\'];%Point to the TIMIT databasee test sets
maindir=['D:\work\'];
%%
type=2;%1,Hcopy 2,filters
%%%%%%%%%%%%%%%%%%
t=cputime;
fs=16000;
w='MedD';
nc=12;
p=23;
n=128;
%%%%%%%%%%%%%%%%%%%%
%% make folders 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Generating useful directories under the current directory               %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mkdir label;
mkdir mfcc;
mkdir model;
for i=0:23
    newdir=['model\hmm',num2str(i)];
    mkdir(newdir);
end

disp('Generating directories completed!');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Generating the word net, which is the low level notation that each word %
    % instance and each word-to-word transition is listed explicity.          %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% eval(['HParse gram wdnet']);
% HParse (gram wdnet);
system('HParse gram wdnet');

disp('Generating word net completed!');

%%  mfcc
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % % Generating the codetr.scp and train.scp.                                %
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid1=fopen('codetr.scp','w');
 fid2=fopen('train.scp','w');
% 
 for n0=1:8 %1:8
     D=dir([traindir,'dr',num2str(n0)]);
     for n1=3:size(D,1) %3:size(D,1)
         D2=dir([traindir,'dr',num2str(n0),'\',D(n1).name,'\*.wav']);
         D3=dir([traindir,'dr',num2str(n0),'\',D(n1).name,'\*.phn']);
         for n2=1:size(D2,1)
             filename=[traindir,'dr',num2str(n0),'\',D(n1).name,'\' D2(n2).name];
             handdefname=[traindir,'dr',num2str(n0),'\',D(n1).name,'\' D3(n2).name];
             newfname=D2(n2).name; 
             newfname=[newfname(1:end-4) '_tr.mfc'];
             mfcfname=[homedir,'mfcc\','dr',num2str(n0),'_',D(n1).name,'_',newfname];
             fprintf(fid1, '%s\n', [filename,' ',mfcfname]);
             fprintf(fid2, '%s\n', mfcfname);
             newlname=D3(n2).name; 
             newlname=[newlname(1:end-4) '_tr.lab'];
             labfname=[homedir,'label\','dr',num2str(n0),'_',D(n1).name,'_',newlname];
             %-----------dp-----------------
             eval(['!copy ',handdefname,' ',labfname]);
         end
     end
 end
% 
fclose(fid1);
fclose(fid2);
 
disp('Generating the codetr.scp and train.scp completed!');



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Generating MFCC file                                                    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if type==1
    eval(['!HCopy -C configTIMIT -S codetr.scp']);
else
    calculate_mfcc_tr(1);
end 
 disp( 'Generating the MFCC for codetr completed!');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Generating the codete.scp and test.scp.                                 %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid1=fopen('codete.scp','w');
 fid2=fopen('test.scp','w');
for n0=1:8 %1:8
    D=dir([testdir,'dr',num2str(n0)]);
    for n1=3:size(D,1) %3:size(D,1)
        D2=dir([testdir,'dr',num2str(n0),'\',D(n1).name,'\*.wav']);
        D3=dir([testdir,'dr',num2str(n0),'\',D(n1).name,'\*.phn']);
        for n2=1:size(D2,1)
            filename=[testdir,'dr',num2str(n0),'\',D(n1).name,'\' D2(n2).name];
            handdefname=[testdir,'dr',num2str(n0),'\',D(n1).name,'\' D3(n2).name];
            newfname=D2(n2).name; 
            newfname=[newfname(1:end-4) '_te.mfc'];
            mfcfname=[homedir,'mfcc\','dr',num2str(n0),'_',D(n1).name,'_',newfname];
            fprintf(fid1, '%s\n', [filename,' ',mfcfname]);
            fprintf(fid2, '%s\n', mfcfname);
            newlname=D3(n2).name; 
            newlname=[newlname(1:end-4) '_te.lab'];
            labfname=[homedir,'label\','dr',num2str(n0),'_',D(n1).name,'_',newlname];
            eval(['!copy ',handdefname,' ',labfname]);
        end
    end
end
fclose(fid1);
fclose(fid2);
disp( 'Generating the codete.scp and test.scp.completed!' )
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating MFCC file                                                    %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if type==1
    eval(['!HCopy -C configTIMIT -S codete.scp']);
else
     calculate_mfcc_te(1);
end
 
disp( 'Generating the MFCC for codete completed!');
 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the proto                                                    %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 eval(['!HCompV -C config -f 0.01 -m -S train.scp -M model\hmm0 proto']);
 disp('Generating the proto completed!');

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Reading the proto for generating the macros and hmmdefs                 %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid = fopen('model\hmm0\proto','r');
% 
 F = fread(fid);
 S = char(F');
 SHMM=S( strfind(upper(S),'<BEGINHMM>') :end);
 S1st3=S(1: strfind(S,'~h') -1);
% 
 fclose(fid);
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %  Reading the vFloors for generating the macros and hmmdefs              %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid = fopen('model\hmm0\vFloors','r');
% 
 F = fread(fid);
 SvFloors = char(F');
% 
 fclose(fid);
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the HMM macros                                               %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid=fopen('model\hmm0\macros','w');
% 
 fprintf(fid,S1st3);
 fprintf(fid,SvFloors);
% 
 fclose(fid);
% 
disp( 'Generating HMM macro completed!');


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the hmmdefs                                                  %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid1=fopen('monophones0','r');
 fid4=fopen('monophones1','w');
 fid2=fopen('model\hmm0\hmmdefs','w');
 fid3=fopen('dict','w');
% 
while 1
     tline = fgetl(fid1); if ~ischar(tline), break, end;
     fprintf(fid2,['~h "',tline,'"\n']);
     fprintf(fid2,SHMM);
     fprintf(fid2,'\n');
     fprintf(fid3,[tline,' ',tline,'\n']);
     fprintf(fid4,[tline,'\n']);
end
% end
 fprintf(fid4,['!ENTER\n']);
 fprintf(fid4,['!EXIT\n']);
% 
 fprintf(fid3,['!ENTER []\n']);
 fprintf(fid3,['!EXIT []\n']);
% 
 fclose(fid1);
 fclose(fid4);
 fclose(fid2);
 fclose(fid3);
% 
disp( 'Generating HMM hmmdefs completed!');
% 
%%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the phones0.mlf and HLStatslist                              %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid1=fopen('phones0.mlf','w');
 fid3=fopen('HLStatslist','w');
 fprintf(fid1,'%s\n',['#!MLF!#']);
 D=dir(['label\*tr.lab']);
 for n=1:size(D,1)
     fprintf(fid1,'%s\n',['"*/',D(n).name,'"']);
     fprintf(fid3,[D(n).name,'\n']);
     fid2=fopen(['label\',D(n).name],'r');
     while 1
         tline=fgetl(fid2); if ~ischar(tline), break, end;
         if (tline(1)=='#')|(tline(1)=='"')
             fprintf(fid1,'%s\n',tline);
         else
             Tmat=sscanf(tline,'%d %d %s');
             Tstring=[char(Tmat(3:end))]';
             fprintf(fid1,'%s\n',Tstring);
         end
     end
     fprintf(fid1,'%s\n','.');
     fclose(fid2);
 end
 fprintf(fid1,'\n');
 fclose(fid1);
 fclose(fid3);
 
 disp('Generating the phones0.mlf and HLStatslist completed!');
 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Computing the bigram statistics                                         %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 eval(['!HLStats -b bigfn -o -I phones0.mlf monophones0 -S HLStatslist']);
 
disp( 'Computing the bigram statistics completed!');
 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Converting the bigram to HTK lattice format                             %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 eval(['!HBuild -n bigfn monophones1 outLatFile']);
 
 disp('Converting the bigram to HTK lattice format completed!');
 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Creating the testref.mlf file                                           %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid1=fopen('testref.mlf','w');
 
 fprintf(fid1,'%s\n',['#!MLF!#']);
 D=dir(['label\*te.lab']);
 for n=1:size(D,1)
     fprintf(fid1,'%s\n',['"*/',D(n).name,'"']);
     
     fid2=fopen(['label\',D(n).name],'r');
     while 1
         tline=fgetl(fid2); if ~ischar(tline), break, end;
         if (tline(1)=='#')|(tline(1)=='"')
             fprintf(fid1,'%s\n',tline);
         else
             Tmat=sscanf(tline,'%d %d %s');
             Tstring=[char(Tmat(3:end))]';
             fprintf(fid1,'%s\n',Tstring);
         end
     end
     fprintf(fid1,'%s\n','.');
     fclose(fid2);
 end
 fprintf(fid1,'\n');
 fclose(fid1);
 
 disp('Creating the testref.mlf file compeleted!');
 %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Performing single re-estimation of the parameters of HMMs (1-3)         %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 for i=1:3
     eval(['!HERest -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H model\hmm',num2str(i-1),'\macros -H model\hmm',num2str(i-1),'\hmmdefs -M model\hmm',num2str(i),' monophones0']);
 end
 
 disp('Performing single re-estimation of the parameters of HMMs (1-3)completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the sil.hed file (HMM editting commands file)                %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid=fopen('sil.hed','w');
 
 fprintf(fid,['AT 2 4 0.2 {pau.transP}\n']);
 fprintf(fid,['AT 4 2 0.2 {pau.transP}\n']);
 fprintf(fid,['AT 2 4 0.2 {h#.transP}\n']);
 fprintf(fid,['AT 4 2 0.2 {h#.transP}\n']);
 
 fclose(fid);
 
 disp('Generating the sil.hed file completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the HMM4 files by editting the HMM3 files                    %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 eval(['!HHEd -H model\hmm3\macros -H model\hmm3\hmmdefs -M model\hmm4 sil.hed monophones0']);
% 
disp( 'Generating the HMM4 files completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %  Performing single re-estimation of the parameters of HMMs (5-7)        %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 for i=5:7
     eval(['!HERest -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H model\hmm',num2str(i-1),'\macros -H model\hmm',num2str(i-1),'\hmmdefs -M model\hmm',num2str(i),' monophones0']);
 end
% 
 disp('Performing single re-estimation of the parameters of HMMs (5-7)completed!');
 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the MU2.hed file (HMM editting commands file)                %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid=fopen('MU2.hed','w');
 fprintf(fid,['MU 2 {*.state[2-4].mix}\n']);
 fclose(fid);
 
 disp('Generating the MU2.hed file completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the HMM8 files by editting the HMM7 files                    %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 eval(['!HHEd -H model\hmm7\macros -H model\hmm7\hmmdefs -M model\hmm8 MU2.hed monophones0']);
 
disp( 'Generating the HMM8 files completed!');
 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %  Performing single re-estimation of the parameters of HMMs (9-11)       %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 for i=9:11
     eval(['!HERest -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H model\hmm',num2str(i-1),'\macros -H model\hmm',num2str(i-1),'\hmmdefs -M model\hmm',num2str(i),' monophones0']);
 end
 
 disp('Performing single re-estimation of the parameters of HMMs (9-11)completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the MU4.hed file (HMM editting commands file)                %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid=fopen('MU4.hed','w');
 fprintf(fid,['MU 4 {*.state[2-4].mix}\n']);
 fclose(fid);
% 
 disp('Generating the MU4.hed file completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the HMM12 files by editting the HMM11 files                  %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 eval(['!HHEd -H model\hmm11\macros -H model\hmm11\hmmdefs -M model\hmm12 MU4.hed monophones0']);
% 
 disp('Generating the HMM12 files completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %  Performing single re-estimation of the parameters of HMMs (13-15)      %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 for i=13:15
     eval(['!HERest -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H model\hmm',num2str(i-1),'\macros -H model\hmm',num2str(i-1),'\hmmdefs -M model\hmm',num2str(i),' monophones0']);
 end
% 
 disp('Performing single re-estimation of the parameters of HMMs (13-15)completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the MU8.hed file (HMM editting commands file)                %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 fid=fopen('MU8.hed','w');
 fprintf(fid,['MU 8 {*.state[2-4].mix}\n']);
 fclose(fid);
% 
 disp('Generating the MU8.hed file completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Generating the HMM16 files by editting the HMM15 files                  %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 eval(['!HHEd -H model\hmm15\macros -H model\hmm15\hmmdefs -M model\hmm16 MU8.hed monophones0']);
 
 disp('Generating the HMM16 files completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %  Performing single re-estimation of the parameters of HMMs (17-23)      %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 for i=17:23
     eval(['!HERest -C config -I phones0.mlf -t 250.0 150.0 1000.0 -S train.scp -H model\hmm',num2str(i-1),'\macros -H model\hmm',num2str(i-1),'\hmmdefs -M model\hmm',num2str(i),' monophones0']);
 end
% 
 disp('Performing single re-estimation of the parameters of HMMs (17-23)completed!');

 
%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Testing by using the wdnet (single word network)                        %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 eval(['!HVite -H model\hmm23\macros -H model\hmm23\hmmdefs -S test.scp -i recout.mlf -w wdnet -p 0.0 -s 5.0 dict monophones0']);
% 
disp( 'Testing by using the wdnet (single word network) completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Testing by using the outLatFile (bigram word network)                   %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 eval(['!HVite -H model\hmm23\macros -H model\hmm23\hmmdefs -S test.scp -i recout_bigram.mlf -w outLatFile -p 0.0 -s 5.0 dict monophones0']);
 
disp( 'Testing by using the outLatFile (bigram word network) completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Analyzing the single word network's performance                         %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %eval(['!HResults -I testref.mlf monophones0 recout.mlf > results']);
 eval(['!HResults -e n en -e aa ao -e ah ax-h -e ah ax -e ih ix -e l el -e sh zh -e uw ux -e er axr -e m em -e n nx -e ng eng -e hh hv -e pau pcl -e pau tcl -e pau kcl -e pau q -e pau bcl -e pau dcl -e pau gcl -e pau epi -e pau h# -I testref.mlf monophones0 recout.mlf > results']);
% 
disp( 'Analyzing the single word networks performance completed!');
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Analyzing the bigram word network's performance                         %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %eval(['!HResults -I testref.mlf monophones0 recout_bigram.mlf > results_bigram']);
 eval(['!HResults -e n en -e aa ao -e ah ax-h -e ah ax -e ih ix -e l el -e sh zh -e uw ux -e er axr -e m em -e n nx -e ng eng -e hh hv -e pau pcl -e pau tcl -e pau kcl -e pau q -e pau bcl -e pau dcl -e pau gcl -e pau epi -e pau h# -I testref.mlf monophones0 recout_bigram.mlf > results_bigram']);
% 
disp( 'Analyzing the bigram word networks performance completed!');

toc
% quit;