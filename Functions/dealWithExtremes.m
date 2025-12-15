




function[I,resample]=dealWithExtremes(I,A,B,trans_flag)
    [M,N,~]=size(I);









    A=A*A;B=B*B;picN=M*N;
    if picN>=B
        resample=1/min(ceil(picN/A),floor(picN/B));
    elseif picN<=A
        resample=min(floor(A/picN),ceil(B/picN));
    else
        resample=1;
    end
    resample=sqrt(resample);

    if trans_flag
        I=imresize(I,resample);
    end