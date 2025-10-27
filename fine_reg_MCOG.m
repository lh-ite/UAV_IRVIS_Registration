function [matchedPoints1, matchedPoints2]=fine_reg_MCOG(im1_gray, im2_gray, batch_size, point_refine)
% size(im1_gray);
% size(im2_gray)
% feature_Ref = CFOG(single(im1_gray));
% feature_Sen = CFOG(single(im2_gray));
tic
feature_Ref = MCOG(single(im1_gray));

feature_Sen = MCOG(single(im2_gray));
toc

[p_num,~] = size(point_refine);
kpoint_2 = point_refine;
kpoint_1 = point_refine;
 for i = 1:p_num
    x_start = round(point_refine(i,1)-batch_size/2);
    x_end = round(point_refine(i,1)+batch_size/2);
    y_start = round(point_refine(i,2) - batch_size/2);
    y_end = round(point_refine(i,2) + batch_size/2);
    
    x_start = max(x_start, 1);  % 起始位置不能小于1
    x_end = min(x_end, size(feature_Ref, 1));  % 结束位置不能超过图像的高度
    y_start = max(y_start, 1);  % 起始位置不能小于1
    y_end = min(y_end, size(feature_Ref, 2));  % 结束位置不能超过图像的宽度
    im1_batch = feature_Ref(x_start:x_end,y_start:y_end,:);
    im2_batch = feature_Sen(x_start:x_end,y_start:y_end,:);
    [mm,nm, kk] = fftmatch(im2_batch,im1_batch,1);
    max_i = mm(1);
    max_j = nm(1);
    % max_i = round(max(mm));
    % max_j = round(max(nm));
    kpoint_1(i,:) = [point_refine(i,1)+max_i,point_refine(i,2)+max_j];
 end
 
matchedPoints1 = [kpoint_1(:,2),kpoint_1(:,1)];
matchedPoints2 = [kpoint_2(:,2),kpoint_2(:,1)];

