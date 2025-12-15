function[m,n,k]=fftMatch(ref,sen,flag);

FTsmall=(fftn(double(ref)));
FTbig=(fftn(double(sen)));
FTsmall_C=conj(FTsmall);
FTR=(FTbig.*FTsmall_C);
peak_correlation=abs((ifftn(FTR)));
max_n=max(peak_correlation(:));
s=size(peak_correlation);
Lax=find(peak_correlation==max_n);
[m,n,k]=ind2sub(s,Lax);

if m>size(ref,1)/2
    m=m-(size(ref,1));
end
if n>size(sen,2)/2
    n=n-(size(ref,2));
end

m=m-1;
n=n-1;

end