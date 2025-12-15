




function I=visualizeImage(I)


    I=I-min(I(:));I=I/max(I(:));






















end



function I=LinearPercent(I,percent)
    percent(percent<1)=percent(percent<1)*100;
    percent=[percent(1),100-percent(2)];

    [rows,cols,bands]=size(I);
    I_sum=sum(I,3);I_sum(I_sum==0)=eps;
    valid=rmoutliers(I_sum(:),'percentiles',percent);
    A=min(valid(:));B=max(valid(:));
    maskA=ones(rows,cols);maskA(I_sum<A)=0;
    maskB=zeros(rows,cols);maskB(I_sum>B)=1;
    valid=maskA.*(1-maskB);
    ratioA=1-A./I_sum;
    ratioB=B./I_sum;
    for i=1:bands
        aaa=I(:,:,i).*maskB.*ratioB;
        I(:,:,i)=I(:,:,i).*ratioA.*valid+aaa;
    end
    I=I*bands/(B-A);
end