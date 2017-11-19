function [Acc,Cls,Obj,U,Vs,Vt] = GTL2(Xs,Xt,Ys,Yt,options)

% Mingsheng Long, Jianmin Wang, Guiguang Ding, Dou Shen, Qiang Yang. 
% Transfer Learning with Graph Co-Regularization.
% IEEE Transactions on Knowledge and Data Engineering (TKDE), 2013.

if nargin < 5              % nargin��Number of function input arguments
    error('No algorithm parameters provided!');
end
if ~isfield(options,'p') %Output  1 (true) if �ṹ contains the field, or logical 0 (false) if not.
    options.p = 10;
end
if ~isfield(options,'lambda')  %ѡ���и���ΪĬ��ֵ
    options.lambda = 0.1;
end
if ~isfield(options,'gamma')
    options.gamma = 1.0;
end
if ~isfield(options,'sigma')
    options.sigma = 10.0;
end
if ~isfield(options,'iters')
    options.iters = 100;
end
if ~isfield(options,'data')
    options.data = 'default';
end
p = options.p;                %�������ýṹ�ļ�д
lambda = options.lambda;
gamma = options.gamma;
sigma = options.sigma;
iters = options.iters;
data = options.data;

fprintf('GTL2: data=%s  p=%d  lambda=%f  gamma=%f  sigma=%f\n',data,p,lambda,gamma,sigma);

%% Set predefined variables (Yt only for test)
Y = [Ys;Yt];                %���һά
m = size([Xs,Xt],1);        %size(a,1)����������
c = length(unique(Y));      %Y�۵�10��
ns = size(Xs,2);
nt = size(Xt,2);
YY = [];
for i = reshape(unique(Y),1,c)
    YY = [YY,Y==i];              %Y��1ά3800�еģ����forѭ��ִֻ����i=1��һ�Σ�ִ��10�λ��Ϊ����ġ��ֱ�ɾ����ˣ���
end
YYs = YY(1:ns,:);               %Դ��Ŀ�������پ����������
YYt = YY(ns+1:end,:);

%% Data normalization (for classification)  normalize data sets by X��X/||X||
Xs = Xs*diag(sparse(1./sqrt(sum(Xs.^2))));      %sum����256*1,sqrtΪ����ߵĸ�Ԫ�ؽ��п���
Xt = Xt*diag(sparse(1./sqrt(sum(Xt.^2))));      %����ƽ������Ӿ�Ϊ1

%% Construct graph Laplacian    
manifold.k = p;
manifold.Metric = 'Cosine';              % ����
manifold.NeighborMode = 'KNN';
manifold.WeightMode = 'Cosine';
manifold.bNormalizeGraph = 0;            %����������
[Wus,Dus] = laplacian(Xs,manifold);      % ǿ��ĺ���help affinity ��Wus����affinity(Xs,manifold)�õ���
[Wut,Dut] = laplacian(Xt,manifold);
[Wvt,Dvt] = laplacian(Xt',manifold);
%Metric:'Cosine' ��ʹ����������������ֵ����������֮��ġ����ܶȡ���һ������Ϣ������ʹ�õ����е������Զ�����
%NeighborMode - ָʾ��ι���ͼ�Ρ��������ڵ�֮�����һ���ߣ����ҽ��������ڱ˴˵�k�������С� ����Ҫ��ѡ�����ṩ����k�� Ĭ��k = 5��
%WeightMode: 'Cosine'����ڵ�i��j���ӣ������Ȩ�����ң�x_i��x_j���� ֻ���ڡ����ҡ�������ʹ�á�
% manifold.NeighborMode = 'Supervised';
% manifold.gnd = Ys;
% [Wvs,Dvs] = laplacian(Xs',manifold);

%% Initialization
U = rand(m,c);
Vs = 0.1 + 0.8*YYs;         %Ys, Vt by logistic regression trained on fXs; Ysg.
if isfield(options,'Yt0') && size(options.Yt0,1)==nt
    Vt = [];
    for i = reshape(unique(Y),1,c)
        Vt = [Vt,options.Yt0==i];
    end
    options.Yt0 = [];
    Vt = 0.1 + 0.8*Vt;
else
    Vt = rand(nt,c);
end

%% Graph Co-Regularized Transfer Learning (GTL)
Acc = [];
Obj = [];
for it = 0:iters
    
    %% Alternating Optimization
    if it>0
        U = U.*sqrt((Xs*Vs+Xt*Vt+lambda*Wus*U+lambda*Wut*U)./(U*(Vs'*Vs)+U*(Vt'*Vt)+lambda*Dus*U+lambda*Dut*U+eps));
        
        Vs = Vs.*sqrt(Vs./(Vs*(Vs'*Vs)+eps));

        Vt = Vt.*sqrt((Xt'*U+gamma*Wvt*Vt+sigma*Vt)./(Vt*(U'*U)+gamma*Dvt*Vt+sigma*Vt*(Vt'*Vt)+eps));
    end
    
    %% Compute accuracy
    [~,Cls] = max(Vt,[],2);     %����һ�����󲢼���ÿһ���е����Ԫ�ء�
    [~,Lbl] = max(YYt,[],2);
    acc = numel(find(Cls == Lbl))/nt;  %find: Find the nonzero elements,����������Ԫ�ص�λ��;n = numel(A) returns the number of elements
    Acc = [Acc;acc];
    
    %% Compute objective
    O = 0;
%     % Comment for fast evaluations
%     O = norm(Xs-U*Vs','fro')^2 + norm(Xt-U*Vt','fro')^2 ...
%         + sigma*norm(Vs'*Vs-eye(c,c),'fro')^2 + sigma*norm(Vt'*Vt-eye(c,c),'fro')^2 ...
%         + lambda*trace(U'*(Dus-Wus)*U) + lambda*trace(U'*(Dut-Wut)*U) ...
%         + gamma*trace(Vs'*(Dvs-Wvs)*Vs) + gamma*trace(Vt'*(Dvt-Wvt)*Vt);
    Obj = [Obj;O];
    
    if mod(it,10)==0
        fprintf('[%d]  objective=%0.10f  accuracy=%0.4f\n',it,O,acc);
    end
end

fprintf('Algorithm GTL2 terminated!!!\n\n\n');

end