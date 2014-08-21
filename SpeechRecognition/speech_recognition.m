function speech_recognition

clear all

num_cepst=12; %Number of cepstral coefficients needed num_cepst%
num_filt=2;  %number of mel-filters to be used num_filt,%
win_size=30;  %window size for analysis win_size (in ms)%
overlap=10; %overlap between subsequent windows overlap (in ms)%
Maletrain_num=50 ;%The number of Train male samples in each class %
Femaletrain_num=50 ;%The number of Train female samples in each class %
Maletest_num=25 ;%The number of Test male samples in each class %
Femaletest_num=25 ;%The number of Test female samples in each class %
threshold=0.001; %energy threshold%

% find mel-cepstral coefficient of train set
for word=1:9
    cepst=[];
    index=[];
    index=[index;1];
    for male=1:Maletrain_num
        male_path=sprintf('Train\\wav\\male\\spk%d\\%dA',male,word);
        [s,fs]=wavread(male_path);
        %removes the silence frames from the speech signal using energy
        %threshold.
        frame=(fs/1000)*20; %every frame is 20ms%
        f=enframe(s,frame);
        x=s;
        number=size(f,1); %the number of frames in the data%
        k=1;
        energy(1:number)=0;
        for i=1:number
            sum=0;
            for j=1:frame
                sum=sum+f(i,j)*f(i,j);
            end
            energy(i)=sum;
            if energy(i)>threshold
                x(((k-1)*frame+1):k*frame)=f(i,:)';
                k=k+1;
            end
        end
        x=x(1:(k-1)*frame);
        np=(fs/1000)*win_size;
        inc=(fs/1000)*overlap;
        c=melcepst(x,fs,'Mt',num_cepst,num_filt,np,inc,0,0.5);
        cepst=[cepst;c];
        index=[index;size(cepst,1)+1];
        clear c;
        
        male_path=sprintf('Train\\wav\\male\\spk%d\\%dB',male,word);
        [s,fs]=wavread(male_path);
        frame=(fs/1000)*20; %every frame is 20ms%
        f=enframe(s,frame);
        x=s;
        number=size(f,1); %the number of frames in the data%
        k=1;
        energy(1:number)=0;
        for i=1:number
            sum=0;
            for j=1:frame
                sum=sum+f(i,j)*f(i,j);
            end
            energy(i)=sum;
            if energy(i)>threshold
                x(((k-1)*frame+1):k*frame)=f(i,:)';
                k=k+1;
            end
        end
        x=x(1:(k-1)*frame);
        np=(fs/1000)*win_size;
        inc=(fs/1000)*overlap;
        c=melcepst(x,fs,'Mt',num_cepst,num_filt,np,inc,0,0.5);
        cepst=[cepst;c];
        index=[index;size(cepst,1)+1];
        clear c;
    end
    output_path1=sprintf('Train\\cepst\\Maleword%d',word);
    save(output_path1,'cepst');
    output_path2=sprintf('Train\\cepst\\Maleindex%d',word);
    save(output_path2,'index');
    fprintf(2,'mel-cepstral coefficient of male train set word %d is written\n',word);
    clear cepst index;
end
for word=1:9   
    cepst=[];
    index=[];
    index=[index;1];
    for female=1:Femaletrain_num
        female_path=sprintf('Train\\wav\\female\\spk%d\\%dA',female,word);
        [s,fs]=wavread(female_path);
        frame=(fs/1000)*20; %every frame is 20ms%
        f=enframe(s,frame);
        x=s;
        number=size(f,1); %the number of frames in the data%
        k=1;
        energy(1:number)=0;
        for i=1:number
            sum=0;
            for j=1:frame
                sum=sum+f(i,j)*f(i,j);
            end
            energy(i)=sum;
            if energy(i)>threshold
                x(((k-1)*frame+1):k*frame)=f(i,:)';
                k=k+1;
            end
        end
        x=x(1:(k-1)*frame);
        np=(fs/1000)*win_size;
        inc=(fs/1000)*overlap;
        c=melcepst(x,fs,'Mt',num_cepst,num_filt,np,inc,0,0.5);
        cepst=[cepst;c];
        index=[index;size(cepst,1)+1];
        clear c;
        
        female_path=sprintf('Train\\wav\\female\\spk%d\\%dB',female,word);
        [s,fs]=wavread(female_path);
        frame=(fs/1000)*20; %every frame is 20ms%
        f=enframe(s,frame);
        x=s;
        number=size(f,1); %the number of frames in the data%
        k=1;
        energy(1:number)=0;
        for i=1:number
            sum=0;
            for j=1:frame
                sum=sum+f(i,j)*f(i,j);
            end
            energy(i)=sum;
            if energy(i)>threshold
                x(((k-1)*frame+1):k*frame)=f(i,:)';
                k=k+1;
            end
        end
        x=x(1:(k-1)*frame);
        np=(fs/1000)*win_size;
        inc=(fs/1000)*overlap;
        c=melcepst(x,fs,'Mt',num_cepst,num_filt,np,inc,0,0.5);
        cepst=[cepst;c];
        index=[index;size(cepst,1)+1];
        clear c;
    end
    output_path1=sprintf('Train\\cepst\\Femaleword%d',word);
    save(output_path1,'cepst');
    output_path2=sprintf('Train\\cepst\\Femaleindex%d',word);
    save(output_path2,'index');
    fprintf(2,'mel-cepstral coefficient of female train set word %d is written\n',word);
    clear cepst index;
end

% find mel-cepstral coefficient of test set
for word=1:9
    utterance=1;
    for male=1:25
        male_path=sprintf('Test\\wav\\male\\spk%d\\%dA',male,word);
        [s,fs]=wavread(male_path);
        frame=(fs/1000)*20; %every frame is 20ms%
        f=enframe(s,frame);
        x=s;
        number=size(f,1); %the number of frames in the data%
        k=1;
        energy(1:number)=0;
        for i=1:number
            sum=0;
            for j=1:frame
                sum=sum+f(i,j)*f(i,j);
            end
            energy(i)=sum;
            if energy(i)>threshold
                x(((k-1)*frame+1):k*frame)=f(i,:)';
                k=k+1;
            end
        end
        x=x(1:(k-1)*frame);
        np=(fs/1000)*win_size;
        inc=(fs/1000)*overlap;
        c=melcepst(x,fs,'Mt',num_cepst,num_filt,np,inc,0,0.5);
        out_path=sprintf('Test\\cepst\\word%d_%d',word,utterance);
        save(out_path,'c');
        utterance=utterance+1;
        clear c male_path out_path;
        
        male_path=sprintf('Test\\wav\\male\\spk%d\\%dA',male,word);
        [s,fs]=wavread(male_path);
        frame=(fs/1000)*20; %every frame is 20ms%
        f=enframe(s,frame);
        x=s;
        number=size(f,1); %the number of frames in the data%
        k=1;
        energy(1:number)=0;
        for i=1:number
            sum=0;
            for j=1:frame
                sum=sum+f(i,j)*f(i,j);
            end
            energy(i)=sum;
            if energy(i)>threshold
                x(((k-1)*frame+1):k*frame)=f(i,:)';
                k=k+1;
            end
        end
        x=x(1:(k-1)*frame);
        np=(fs/1000)*win_size;
        inc=(fs/1000)*overlap;
        c=melcepst(x,fs,'Mt',num_cepst,num_filt,np,inc,0,0.5);
        out_path=sprintf('Test\\cepst\\word%d_%d',word,utterance);
        save(out_path,'c');
        utterance=utterance+1;
        clear c male_path out_path;
    end
    clear male
    for female=1:25
        female_path=sprintf('Test\\wav\\female\\spk%d\\%dA',female,word);
        [s,fs]=wavread(female_path);
        frame=(fs/1000)*20; %every frame is 20ms%
        f=enframe(s,frame);
        x=s;
        number=size(f,1); %the number of frames in the data%
        k=1;
        energy(1:number)=0;
        for i=1:number
            sum=0;
            for j=1:frame
                sum=sum+f(i,j)*f(i,j);
            end
            energy(i)=sum;
            if energy(i)>threshold
                x(((k-1)*frame+1):k*frame)=f(i,:)';
                k=k+1;
            end
        end
        x=x(1:(k-1)*frame);       
        np=(fs/1000)*win_size;
        inc=(fs/1000)*overlap;
        c=melcepst(x,fs,'Mt',num_cepst,num_filt,np,inc,0,0.5);
        out_path=sprintf('Test\\cepst\\word%d_%d',word,utterance);
        save(out_path,'c');
        utterance=utterance+1;
        clear c female_path out_path;
        
        female_path=sprintf('Test\\wav\\female\\spk%d\\%dA',female,word);
        [s,fs]=wavread(female_path);
        frame=(fs/1000)*20; %every frame is 20ms%
        f=enframe(s,frame);
        x=s;
        number=size(f,1); %the number of frames in the data%
        k=1;
        energy(1:number)=0;
        for i=1:number
            sum=0;
            for j=1:frame
                sum=sum+f(i,j)*f(i,j);
            end
            energy(i)=sum;
            if energy(i)>threshold
                x(((k-1)*frame+1):k*frame)=f(i,:)';
                k=k+1;
            end
        end
        x=x(1:(k-1)*frame);
        np=(fs/1000)*win_size;
        inc=(fs/1000)*overlap;
        c=melcepst(x,fs,'Mt',num_cepst,num_filt,np,inc,0,0.5);
        out_path=sprintf('Test\\cepst\\word%d_%d',word,utterance);
        save(out_path,'c');
        utterance=utterance+1;
        clear c female_path out_path;
    end
    fprintf(2,'mel-cepstral coefficient of test set word %d is written\n',word);
end
%%
% collect the parameters of Male train set
MaleT=[];
MA=[];
mmax=70;
for word=1:9
    cepst_path=sprintf('Train\\cepst\\Maleword%d',word);
    index_path=sprintf('Train\\cepst\\Maleindex%d',word);
    load(cepst_path);
    load(index_path);
    for i=2:length(index)
        v(i-1)=index(i)-index(i-1);
    end
    cepst=cepst';
    for i=1:length(v)
        tmp=cepst(1,index(i):index(i+1)-1);
%         dd(i)=length(tmp);
        while length(tmp)<mmax
            tmp=[tmp 0];
        end
        MA=[MA;tmp];
        MaleT=[MaleT;word];
        clear tmp;
    end  
%     ff(word)=max(dd);
%     dd=[];
end
% collect the parameters of Female train set
FemaleT=[];
FA=[];
fmax=80;
for word=1:9
    cepst_path=sprintf('Train\\cepst\\Femaleword%d',word);
    index_path=sprintf('Train\\cepst\\Femaleindex%d',word);
    load(cepst_path);
    load(index_path);
    for i=2:length(index)
        v(i-1)=index(i)-index(i-1);
    end
    cepst=cepst';
    for i=1:length(v)
        tmp=cepst(1,index(i):index(i+1)-1);
%         dd(i)=length(tmp);
        while length(tmp)<fmax
            tmp=[tmp 0];
        end
        FA=[FA;tmp];
        FemaleT=[FemaleT;word];
        clear tmp;
    end   
%     ff(word)=max(dd);
%     dd=[];
end
%collect the parameters of Male test set
MB=[];
MaleTT=[];
for word=1:9
    for j=1:2*Maletest_num
        cepst_path=sprintf('Test\\cepst\\word%d_%d',word,j);
        load(cepst_path);
        tmp=c(:,1);
%         dd(j)=length(tmp);
        while length(tmp)<mmax
            tmp=[tmp;0];
        end
        MB=[MB;tmp'];
        MaleTT=[MaleTT;word];
        clear tmp;
    end
%     ff(word)=max(dd);
%     dd=[];
end
%collect the parameters of Female test set
FB=[];
FemaleTT=[];
for word=1:9
    for j=2*Maletest_num+1:2*(Maletest_num+Femaletest_num)
        cepst_path=sprintf('Test\\cepst\\word%d_%d',word,j);
        load(cepst_path);
        tmp=c(:,1);
%         dd(j)=length(tmp);
        while length(tmp)<fmax
            tmp=[tmp;0];
        end
        FB=[FB;tmp'];
        FemaleTT=[FemaleTT;word];
        clear tmp;
    end
%     ff(word)=max(dd);
%     dd=[];
end
FA=FA';
MA=MA';
FB=FB';
MB=MB';
FemaleT=FemaleT';
MaleT=MaleT';
FemaleTT=FemaleTT';
MaleTT=MaleTT';

%%
%               Trainning  the neural network for male speakers%
for i=1:mmax
    PR(i,1)=min (MA(1,:));
    PR(i,2)=max (MA(1,:));   
end
net = newff(PR,[150, 1], {'tansig','purelin'},'trainrp'); 
net = init(net);  
net.trainParam.epochs = 5000;
net.trainParam.goal = 1e-4;
net.trainParam.minstep = 1e-10;
net.trainParam.gradient = 1e-10;
net = train(net, MA, MaleT);

%Test  the neural network for male speakers%
OutputValue = sim(net, MB);
OutputValue = round(OutputValue);
right=0;
for i=1:length(OutputValue)
    if (OutputValue(i)==MaleTT(i))
        right=right+1;
    end
end
ans1=right/length(OutputValue);
clear PR;

%               Trainning  the neural network for female speakers%
for i=1:fmax
    PR(i,1)=min (FA(1,:));
    PR(i,2)=max (FA(1,:));   
end
net = newff(PR,[180, 1], {'tansig','purelin'},'trainrp'); 
net = init(net);  
net.trainParam.epochs = 5000;
net.trainParam.goal = 1e-4;
net.trainParam.minstep = 1e-10;
net.trainParam.gradient = 1e-10;
net = train(net, FA, FemaleT);

%Test  the neural network for female speakers%
OutputValue = sim(net, FB);
OutputValue = round(OutputValue);
right=0;
for i=1:length(OutputValue)
    if (OutputValue(i)==FemaleTT(i))
        right=right+1;
    end
end

ans2=right/length(OutputValue);

fprintf('The accuracy of speech recognition of male speakers is %f\n', ans1);

fprintf('The accuracy of speech recognition of female speakers is %f\n', ans2);