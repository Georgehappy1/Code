function [W,D] = laplacian(X,manifold)

W = affinity(X,manifold);   % X����fea��: Rows of vectors of data points. Each row is x_i
                            %affinity���������Ĺ�����ͼ��������˹
if manifold.bNormalizeGraph         %chuan����������0��������Ҫ��W��ֵ
    D = 1./sqrt(sum(W));
    D(isinf(D)) = 0;
    D = diag(sparse(D));
    W = D*W*D;
    D(D>0) = 1;
else
    D = diag(sparse(sum(W)));
end

end