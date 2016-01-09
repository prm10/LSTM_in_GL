function [delta_down,dW]=LSTM_step_bp_fast(delta_up,W,x,in2,f2,z2,c,o2,y)
    %% weight initial
    % input gates
    w_i=W.w_i;
    r_i=W.r_i;
    p_i=W.p_i;
    % forget gates
    w_f=W.w_f;
    r_f=W.r_f;
    p_f=W.p_f;
    % cells
    w_z=W.w_z;
    r_z=W.r_z;
    % output gates
    w_o=W.w_o;
    r_o=W.r_o;
    p_o=W.p_o;
    %%
    T=size(delta_up,1);
    t=T;
    delta_y(t,:)=delta_up(t,:);
    delta_o(t,:)=delta_y(t,:).*tanh(c(t,:)).*dsigmoid(o2(t,:));
    delta_c(t,:)=delta_y(t,:).*o2(t,:).*dtanh(tanh(c(t,:)))+p_o.*delta_o(t,:);
    delta_f(t,:)=delta_c(t,:).*c(t-1,:).*dsigmoid(f2(t,:));
    delta_i(t,:)=delta_c(t,:).*z2(t,:).*dsigmoid(in2(t,:));
    delta_z(t,:)=delta_c(t,:).*in2(t,:).*dtanh(z2(t,:));
    delta_x(t,:)=delta_z(t,:)*w_z'+delta_i(t,:)*w_i'+delta_f(t,:)*w_f'+delta_o(t,:)*w_o';
    for t=T-1:-1:1
        delta_y(t,:)=delta_up(t,:)+delta_z(t+1,:)*r_z'+delta_i(t+1,:)*r_i'+delta_f(t+1,:)*r_f'+delta_o(t+1,:)*r_o';
        delta_o(t,:)=delta_y(t,:).*tanh(c(t,:)).*dsigmoid(o2(t,:));
        delta_c(t,:)=delta_y(t,:).*o2(t,:).*dtanh(tanh(c(t,:)))+p_o.*delta_o(t,:)+p_i.*delta_i(t+1,:)...
            +p_f.*delta_f(t+1,:)+delta_c(t+1,:).*f2(t+1,:);
        if t==1
            delta_f(t,:)=0;
        else
            delta_f(t,:)=delta_c(t,:).*c(t-1,:).*dsigmoid(f2(t,:));
        end
        delta_i(t,:)=delta_c(t,:).*z2(t,:).*dsigmoid(in2(t,:));
        delta_z(t,:)=delta_c(t,:).*in2(t,:).*dtanh(z2(t,:));
        delta_x(t,:)=delta_z(t,:)*w_z'+delta_i(t,:)*w_i'+delta_f(t,:)*w_f'+delta_o(t,:)*w_o';
    end
    
%     delta_o=restrict(delta_o);
%     delta_f=restrict(delta_f);
%     delta_i=restrict(delta_i);
%     delta_z=restrict(delta_z);
    
    delta_down=delta_x(:,1:end-1);

    dw_o=x'*delta_o;
    dw_f=x'*delta_f;
    dw_i=x'*delta_i;
    dw_z=x'*delta_z;

    dr_o=y(1:end-1,:)'*delta_o(2:end,:);
    dr_f=y(1:end-1,:)'*delta_f(2:end,:);
    dr_i=y(1:end-1,:)'*delta_i(2:end,:);
    dr_z=y(1:end-1,:)'*delta_z(2:end,:);

    dp_i=sum(c(1:end-1,:).*delta_i(2:end,:));
    dp_f=sum(c(1:end-1,:).*delta_f(2:end,:));
    dp_o=sum(c.*delta_o);
    
    dW.w_o=dw_o;
    dW.w_f=dw_f;
    dW.w_i=dw_i;
    dW.w_z=dw_z;
    dW.r_o=dr_o;
    dW.r_f=dr_f;
    dW.r_i=dr_i;
    dW.r_z=dr_z;
    dW.p_o=dp_o;
    dW.p_f=dp_f;
    dW.p_i=dp_i;


function y=dsigmoid(z)
    y=z.*(1-z);
function y=dtanh(z)
    y=1-z.^2;
function delta_out=restrict(delta)
%     delta_out=delta;
    delta_out=max(-1*ones(size(delta)),min(1*ones(size(delta)),delta));