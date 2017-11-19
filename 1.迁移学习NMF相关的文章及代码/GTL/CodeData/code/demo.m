clear all;
addpath(genpath('../liblinear/matlab'));    %����ϼ�Ŀ¼�ļ����ļ��е��ļ�

algorithm = 'GTL2';             % 'GTL2' | 'GTL3'

if strcmp(algorithm,'GTL2')
    options.p = 10;             % insensitive, keep default
    options.lambda = 0.1;       % insensitive, keep default
    options.gamma = 10.0;       % 1<=gamma<=100

    
    
    options.sigma = 100.0;      % gamma<=sigma<=10*gamma
elseif strcmp(algorithm,'GTL3')
    options.p = 10;             % insensitive, keep default
    options.lambda = 0.1;       % insensitive, keep default
    options.gamma = 10.0;       % 1<=gamma<=100
    options.sigma = 100.0;      % gamma<=sigma<=10*gamma
else
    error('Unsupported algorithm!\n');
end
options.iters = 200;

runs = 1;
result = [];
for dataStr = {'USPS_vs_MNIST','MNIST_vs_USPS'}
    
    data = char(dataStr);
    options.data = data;
    load(strcat('../data/',data)); %�ַ���ճ�����������ַ������ո������һ��,�ҵ�data������ļ���load�������빤����

    % Initialize target predictions
    model_linear = train(Y_src,sparse(X_src'),'-s 0 -c 1 -q 1');
    [Yt0,~] = predict(Y_tar,sparse(X_tar'),model_linear,'-b 1');
    options.Yt0 = Yt0;

    Accs = [];
    for i = 1:runs
        Acc = feval(algorithm,X_src,X_tar,Y_src,Y_tar,options);   %�������ǹ��������
        Accs = [Accs;Acc(end)];
    end
    average = mean(Accs);
    stderr = std(Accs);
    result = [result;[average,stderr]];
end
