function t=gaussianFilter(s,sigma)
    ksize=bitor(round(5*sigma),1);
    g=fspecial('gaussian',[1,ksize],sigma);
    t=imfilter(s,g,'replicate');
end