function [im_res, Points, H_init] = coarseRegistrationBySsimRmse(im1, im2, point_num)
%%im1 可见光
%%im2 红外
tic;
im1_in = im1;
im2_in = im2;
[x_im1,y_im1,band] = size(im1);
[x_im2_in,y_im2_in,band2] = size(im2_in);
i = 1;
step = 0.01;
if band == 3
    im1_gray = im2gray(im1);
else
    im1_gray = im1;
    im2_gray = im2;
end
H_init = [1.000 0 y_im1/2
    0 1.000 x_im1/2
    0 0 1.000];
tform_translate = maketform('affine', (H_init)');
T = affine2d(tform_translate.tdata.T);
Points_IR = [];
if x_im1~=x_im2_in && y_im1~=y_im2_in
    for S = 1:step:1.5
    
        cent_x = round((x_im1/2)-((x_im2_in*S)/2));
        cent_y = round((y_im1/2)-((y_im2_in*S)/2));
        H_init = [S  0  cent_y
            0  S  cent_x
            0  0  1.000];
        tform_translate = maketform('affine', (H_init)');
        T = affine2d(tform_translate.tdata.T);
    
        im2 = imwarp(im2_in,T,'OutputView',imref2d(size(im1)));
    
        if band2 == 3
            im2_gray = im2gray(im2);
        else
            im2_gray = im2;
        end
        % im1_gray = im1_gray - guidedTotalVariation(im1_gray);
        % im2_gray = im2_gray - guidedTotalVariation(im2_gray);
        S
        cut_im1 = im1_gray(cent_x:cent_x+round(x_im2_in*S),cent_y:cent_y+round(y_im2_in*S));
        cut_im2 = im2_gray(cent_x:cent_x+round(x_im2_in*S),cent_y:cent_y+round(y_im2_in*S));
    
        cut_im1 = imresize(cut_im1,[x_im2_in/4,y_im2_in/4]);
        cut_im2 = imresize(cut_im2,[x_im2_in/4,y_im2_in/4]);
        % figure,imshow(cut_im1);title('cut_im1')
        % figure,imshow(cut_im2);title('cut_im2')
        [m_c1,~,~,~,~,eo_c1,~] = phaseCongruency3(cut_im1);
        % disp(eo_c1)
        [m_c2,~,~,~,~,eo_c2,~] = phaseCongruency3(cut_im2);
        % figure,imshow(m_c1);title('m_c1')
        % figure,imshow(m_c2);title('m_c2')
        
        m_c1 =m_c1 - guidedTotalVariation(m_c1,5,0.01,0.1,4);
        m_c2 = m_c2 - guidedTotalVariation(m_c2,5,0.01,0.1,4);
        % m_c1 =m_c1 - guidedTotalVariation(m_c1);
        % m_c2 = m_c2 - guidedTotalVariation(m_c2);
        % m_c1 =m_c1 - tsmooth(m_c1,0.001,1);
        % m_c2 = m_c2 - tsmooth(m_c2,0.001,1);
        % m_c1 = m_c1 - RollingGuidanceFilter_Guided(m_c1,2,0.05,4);
        % m_c2 = m_c2 - RollingGuidanceFilter_Guided(m_c2,2,0.05,4);
        % m_c1 = m_c1 - imgaussfilt(m_c1);
        % m_c2 = m_c2 - imgaussfilt(m_c2);
        % m_c1 = bilateralFilter(m_c1);
        % m_c2 = bilateralFilter(m_c1);

        [ssimval,~] = ssim(m_c1,m_c2, 'Exponents', [0, 1, 1]);
        ss_1(i) = ssimval;
        diff = m_c1 - m_c2;
        mse = mean(diff(:).^2);
        rmseval = sqrt(mse);
        rr_1(i) = rmseval;
        i = i+1;
    end
    %%
% [~,p] = max(ss_1(:));
alpha = 0.3; % 设定权重
% 归一化RMSE
max_rr = max(rr_1);
rmse_norm = 1 - (rr_1 / max_rr);
% 计算综合得分
composite_scores = alpha * ss_1 + (1 - alpha) * rmse_norm;
% [~,p] = min(rr_1)
% 找到最大综合得分的索引
[~, p] = max(composite_scores);
% [~,p] = max(ss_1(:));
[~,p] = min(rr_1);
final_S = 1 + step*(p - 1);
% [~,p] = min(rr_1(:));
% [~,p] = max(ssimval);
% final_S = 1+step*p;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cent_x = (x_im1/2)-((x_im2_in*final_S)/2);
cent_y = (y_im1/2)-((y_im2_in*final_S)/2);
H_init = [final_S  0  cent_y
    0  final_S  cent_x
    0  0  1.000];
tform_translate = maketform('affine', (H_init)');
T = affine2d(tform_translate.tdata.T);
end

[m1,m2,~,~,~,eo1,~] = phaseCongruency3(im2_in);

num_cut = 6;
p_num = point_num*num_cut*num_cut;
step_x = x_im2_in/num_cut;
step_y = y_im2_in/num_cut;

% SIFT detector on the maximum moment maps to extract edge feature points (Local patch).
for c_x = 1:num_cut
    for c_y = 1:num_cut
        if c_x == 1
            point_l_u_x = 1;
        else
            point_l_u_x = (c_x-1)*step_x;
        end

        if c_y == 1
            point_l_u_y = 1;
        else
            point_l_u_y = (c_y-1)*step_y;
        end

        point_l_u = [point_l_u_x, point_l_u_y];

        m1_cut = m1(point_l_u_x:point_l_u_x+step_x-1,point_l_u_y:point_l_u_y+step_y-1);

        % m1_points = detectFASTFeatures(m1_cut,'MinContrast',0.05);
        % m1_points = detectHarrisFeatures(m1_cut,'FilterSize',3);
        % Harris and SIFT is better than FAST,SURF can't find corner,ORB also can't
        % find corner
        % m1_points = detectSURFFeatures(m1_cut);
        % ContrastThreshold 越小越多，EdgeThreshold无影响，NumLayerInOCtave
        % 越小越多,sigma越小越多
        m1_cut = m1_cut - guidedTotalVariation(m1_cut,5,0.01,0.1,4);
        % m1_cut = m1_cut - guidedTotalVariation(m1_cut);
        % m1_cut = m1_cut - bilateralFilter(m1_cut);
        % m1_cut = m1_cut - imgaussfilt(m1_cut);
        % m1_cut = m1_cut - RollingGuidanceFilter_Guided(m1_cut,2,0.05,4);
        % m1_cut = m1_cut - tsmooth(m1_cut,0.001,1);
        % m1_points = detectSURFFeatures(m1_cut);
        % m1_points = detectFASTFeatures(m1_cut);
        % m1_points = detectHarrisFeatures(m1_cut,"MinQuality",0.1);
        m1_points = detectSIFTFeatures(m1_cut,'ContrastThreshold',0.01,'NumLayersInOctave',2,'sigma',0.8);
        % m1_points = detectSIFTFeatures(m1_cut, 'ContrastThreshold', 0.005, 'NumLayersInOctave', 2, 'Sigma', 1.1,'EdgeThreshold',15);
        m1_points = m1_points.selectStrongest(point_num);

        % m1_points(find(m1_points.Metric<10))=[];
        m1_points(find(m1_points.Metric<0.001))=[];
        % figure,imshow(m1_cut,[])
        % hold on;
        % plot(m1_points.Location(:,1),m1_points.Location(:,2),'.r');


        P = [m1_points.Location(:,1)+point_l_u_y-1,m1_points.Location(:,2)+point_l_u_x-1,ones(m1_points.Count,1)];
        Points_IR = [Points_IR; P(:,1:2)];
        PP = (H_init)*P';
        PPP = PP';
        if c_x==1 && c_y==1
            Points = PPP;
        else
            Points = [Points;PPP];
        end
                % figure,imshow(m1)
                % hold on;
                % plot(m1_points.Location(:,1)+point_l_u_x-1,m1_points.Location(:,2)+point_l_u_y-1,'.r');

    end
end

im_res = imwarp(im2_in,T,'OutputView',imref2d(size(im1)));
%% 在代码最后（end语句前）添加以下内容
figure('Name','特征点可视化');
imshow(im1_in); % 显示原始可见光图像
hold on;
% 使用红色实心圆点标注，调整点大小和透明度
scatter(Points(:,1), Points(:,2), 5, 'r', 'filled', 'MarkerEdgeAlpha',0.7, 'MarkerFaceAlpha',0.7);

figure('Name','红外图像上的特征点可视化');
imshow(im2_in);
hold on;
scatter(Points_IR(:,1), Points_IR(:,2), 5, 'r', 'filled', 'MarkerEdgeAlpha',0.7, 'MarkerFaceAlpha',0.7);

disp(final_S)
toc;
% disp('The total time spent in the coarse registration phase is:'+time);
end
