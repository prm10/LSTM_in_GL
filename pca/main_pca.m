%% import data
clc;close all;clear;
No=[2,3,5];
GL=[7,1,5];
ipt=[7;8;13;17;20;24];
plotvariable;
gl_no=2;%高炉编号
filepath=strcat('..\..\GL_data\',num2str(No(gl_no)),'\');


hours=24*5;
minutes=30;
opt=struct(...
    'date_str_begin','2013-02-19 23:57', ... %开始时间
    'date_str_end','2013-02-25 16:45:14', ...   %结束时间
    'len',360*hours, ...%计算PCA所用时长范围
    'step',6*minutes ...
    );

load(strcat(filepath,'data.mat'));
data0=data0(:,commenDim{GL(gl_no)});% 选取共有变量
% load(strcat('..\..\GL_data\',num2str(No(i1)),'\sv.mat'));
% sv=(smooth(double(sv),30)>0.1);
% sv=false(size(sv));
%{
17  热风压力<0.34
8   冷风流量<20
20  顶温东北>350
7   富氧流量<5000
%}
normalState=...
    data0(:,17)>0.32    ...
    & data0(:,8)>20     ...
    & data0(:,20)<450   ...
    & data0(:,7)>2000;

% M0=mean(data0(~sv,:));%除去换炉扰动后的均值方差
% S0=std(data0(~sv,:),0,1);

sIndex=find(date0>datenum(opt.date_str_begin),1);  % start index
eIndex=find(date0>datenum(opt.date_str_end),1);    % end index
disp('begin to calculate PCA');
loc=opt.step:opt.step:(eIndex-sIndex);
T=eIndex-sIndex;% from eIndex to sIndex
T2=zeros(T,1);
SPE=zeros(T,1);
T2_lim=zeros(T,1);
SPE_lim=zeros(T,1);
abnormal=false(T,1);
% for model similarity
T=length(loc);
numDims=size(data0,2);
model_P=zeros(numDims,numDims,T);
model_E=zeros(numDims,T);
model_D=zeros(T,1);

trainset=data0(sIndex-opt.len+1:sIndex,:);
M1=mean(trainset);
S1=std(trainset,0,1);
trainset_st=(trainset-ones(size(trainset,1),1)*M1)./(ones(size(trainset,1),1)*S1);
[P,E]=pca(trainset_st);
% sv_train=sv(sIndex-opt.len+1:sIndex);
% trainset=trainset(~sv_train,:);
N=size(data0,2);
% pH=zeros(N,N,T);
% eH=zeros(N,T);
tic;
for i1=1:length(loc)
    t1=sIndex+loc(i1)-opt.step+1;
    t2=sIndex+loc(i1);
    data1=data0(t1:t2,:);
    ns=normalState(t1:t2,:);
%     sv1=sv(t1:t2,:);
    testset=data1;         % no filter
    date1=date0(t1:t2);
    
%     testset=testset(~sv1,:); % remove stove change
%     ns=ns(~sv1,:);      
    
%     testset=testset(ns,:);     % filter abnormal state
    M2=mean(trainset);
    S2=std(trainset,0,1);

    testset_st=(testset-ones(size(testset,1),1)*M2)./(ones(size(testset,1),1)*S1);
    data1_st=(data1-ones(size(data1,1),1)*M1)./(ones(size(data1,1),1)*S1);

    [P2,E2]=pca(testset_st);
    model_P(:,:,i1)=P2;
    model_E(:,i1)=E2;
    model_D(i1)=date0(t2);
    k=7;
    [spe,t_2]=pca_indicater(data1_st,P,E,k);%用于记录
    [spe2,t_22]=pca_indicater(testset_st,P,E,k);%用于判断是否异常                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
    if i1==13
        i1;
    end
    F_a=2;
    t2_limit=(N-1)*(N+1)*k/N/(N-k)*F_a;
    theta1=sum(E(k+1:end));
    theta2=sum(E(k+1:end).^2);
    theta3=sum(E(k+1:end).^3);
    h0=1-2/3*theta1*theta3/theta2^2;
    c_a=3.7;%2.58;
    spe_limit=theta1*(c_a*h0*sqrt(2*theta2)/theta1+1+theta2*h0*(h0-1)/theta1^2).^(1/h0);
    rate=0.8;
    normal=(spe2<spe_limit*rate)&(t_22<t2_limit*rate);
    n2=sum(normal);
    if n2>0
%         trainset=[trainset(n2+1:end,:);testset(normal,:)];
%         M1=mean(trainset);
%         S1=std(trainset,0,1);
%         trainset_st=(trainset-ones(size(trainset,1),1)*M1)./(ones(size(trainset,1),1)*S1);
%         [P,E]=pca(trainset_st);
    end
    abnormal((t1:t2)-sIndex,1)=~normal;
    T2((t1:t2)-sIndex,1)=t_2;
    SPE((t1:t2)-sIndex,1)=spe;
    T2_lim((t1:t2)-sIndex,1)=t2_limit;
    SPE_lim((t1:t2)-sIndex,1)=spe_limit;
end
toc;

model_P=cat(3,P,model_P);
model_E=cat(2,E,model_E);
sim0=calculate_sim(model_P,model_E,3);
%% 矩阵相似度分析
k_sim=4;
sim=sim0(:,:,k_sim);
n=size(sim,1);
figure;
imagesc(sim);
title('互相相似度');
axis equal;
axis([.5,n+.5,.5,n+.5]);

sim=sim0(2:end,1,k_sim);
figure;
plot(1:size(sim,1),sim);
title('与训练集相似度');
%% test
%{
i2=10;%1:length(input0)
data1=input0{i2}(:,commenDim{GL(i1)});
T=size(data1,1)-timeLen;
numDims=size(data1,2);
pH2=zeros(numDims,numDims,T);
for t1=1:T
    data2=data1(t1:t1+timeLen-1,:);
    M2=mean(data2);
    S2=std(data2,0,1);
    data3=(data2-ones(size(data2,1),1)*M2)./(ones(size(data2,1),1)*S2);
    [P,te]=pca(data3);
    pH2(:,:,t1)=P;
end
pH2=directionUnify(pH2);
simi=simiMat(pH2(:,:,1:60:end));
figure;
plot(simi);
%}
%% 画统计量
%
T2=min(T2,5*max(T2_lim)*ones(size(T2)));
SPE=min(SPE,5*max(SPE_lim)*ones(size(SPE)));

ns=normalState(sIndex+1:eIndex);
% sv1=sv(sIndex+1:eIndex);
T=size(T2,1);
% range1=(1:T)/360/24;
range1=(1:T);
figure;
subplot(211);
plot(range1,T2,range1,T2_lim,'--');
% plot(range1,T2,range1(abnormal),T2(abnormal),'.',range1,T2_lim,'--');
% plot(range1(ns&~sv1),T2(ns&~sv1),range1(ns&~sv1),T2_lim(ns&~sv1),'--');
title('t2');
subplot(212);
plot(range1,SPE,range1,SPE_lim,'--');
% plot(range1(ns&~sv1),SPE(ns&~sv1),range1(ns&~sv1),SPE_lim(ns&~sv1),'--');
title('spe');
%}
%% original data
%
data1=data0(sIndex+1:eIndex,:);
date1=date0(sIndex+1:eIndex,:);
figure;
T=size(data1,1);
% range2=(1:T)/360/24;
range2=(1:T);
for i1=1:6
    subplot(3,2,i1);
    plot(1:T,data1(:,ipt(i1)));
    title(commenVar{ipt(i1)});
end
%}
