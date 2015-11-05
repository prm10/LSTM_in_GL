function [y,aa]=LSTM_ff(varargin)
% clc;clear;close all;
if nargin==0
    aa.input=rand(10,3);
    aa.label=[mean(aa.input,2)<=0.5 mean(aa.input,2)>0.5];
    aa.numblocks=5;

    % weight initial
%     % input gates
%     aa.w_il=rand(numdims);
%     aa.w_hl=rand(numdims);
%     aa.w_cl=rand(numdims);
%     % forget gates
%     aa.w_if=rand(numdims);
%     aa.w_hf=rand(numdims);
%     aa.w_cf=rand(numdims);
%     % cells
%     aa.w_ic=rand(numdims);
%     aa.w_hc=rand(numdims);
%     % output gates
%     aa.w_iw=rand(numdims);
%     aa.w_hw=rand(numdims);
%     aa.w_cw=rand(numdims);
    
end
[T,M]=size(aa.input);
label=aa.label;
outdims=size(label,2);
x=[aa.input ones(T,1)];
N=aa.numblocks;
%% weight initial
% input gates
w_i=rand(M+1,N);
r_i=rand(N,N);
p_i=rand(1,N);
% forget gates
w_f=rand(M+1,N);
r_f=rand(N,N);
p_f=rand(1,N);
% cells
w_z=rand(M+1,N);
r_z=rand(N,N);
% output gates
w_o=rand(M+1,N);
r_o=rand(N,N);
p_o=rand(1,N);
% output
w_k=rand(N,outdims);
%% value initial
in1=zeros(T,N);in2=zeros(T,N);
f1=zeros(T,N);f2=zeros(T,N);
z1=zeros(T,N);c=zeros(T,N);
o1=zeros(T,N);o2=zeros(T,N);
%% first time-step
% input gates
t=1;
in1(t,:)=x(t,:)*w_i;
in2(t,:)=sigmoid(in1(t,:));
% forget gates
f1(t,:)=x(t,:)*w_f;
f2(t,:)=sigmoid(f1(t,:));
% cells
z1(t,:)=x(t,:)*w_z;
c(t,:)=in2(t,:).*tanh(z1(t,:));
% output gates
o1(t,:)=x(t,:)*w_o+c(t,:).*p_o;
o2(t,:)=sigmoid(o1(t,:));
y(t,:)=o2(t,:).*tanh(c(t,:));
%% the rest time-step
for t=2:T
    % input gates
    in1(t,:)=x(t,:)*w_i+y(t-1,:)*r_i+c(t-1,:).*p_i;
    in2(t,:)=sigmoid(in1(t,:));
    % forget gates
    f1(t,:)=x(t,:)*w_f+y(t-1,:)*r_f+c(t-1,:).*p_f;
    f2(t,:)=sigmoid(f1(t,:));
    % cells
    z1(t,:)=x(t,:)*w_z+y(t-1,:)*r_z;
    c(t,:)=f2(t,:).*c(t-1,:)+in2(t,:).*tanh(z1(t,:));
    % output gates
    o1(t,:)=x(t,:)*w_o+y(t-1,:)*r_o+c(t,:).*p_o;
    o2(t,:)=sigmoid(o1(t,:));
    y(t,:)=o2(t,:).*tanh(c(t,:));
end
temp=y*w_k;
temp=exp(temp-max(temp,[],2)*ones(1,size(temp,2)));
data_out =temp./(sum(temp,2)*ones(1,size(temp,2)));
err=-sum(sum(label.* log(data_out)))/T;
%% ���򴫲�
delta_k=-(label-data_out);
delta_y(T,:)=delta_k(T,:)*w_k';

for t=T-1:1
    delta_y(t,:)=delta_k(t,:)*w_k'+delta_z(t+1,:)*r_z'+delta_i(t+1,:)*r_i'+delta_f(t+1,:)*r_f'+delta_o(t+1,:)*r_o';
    delta_o(t,:)=delta_y(t,:).*tanh(c(t,:)).*dsigmoid(o2(t,:));
    delta_c(t,:)=delta_y(t,:).*o2(t,:).*dtanh(tanh(c(t,:)))+p_o.*delta_o(t,:)+p_i.*delta_i(t+1,:)...
        +p_f.*delta_f(t+1,:)+delta_c(t+1,:).*f2(t+1,:);
end

    function y=sigmoid(x)
        y=1./(1+exp(-x));
    end
    function y=dsigmoid(z)
        y=z.*(1-z);
    end
    function y=dtanh(z)
        y=1-z.^2;
    end
end