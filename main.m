% ============================================================================
% 多模态图像配准主程序
% 实现可见光和红外图像的自动配准
% ============================================================================

clc;
clear all;
close all;
warning off;
addpath Functions\
addpath images\
tic;

% ==================== 参数配置 ====================
% 粗配准参数
pointNum = 100;              % 特征点数量
batchSize = 80;              % 批处理大小

% 图像对编号
imNum = 4;

% 图像差异标志
intFlag = 1;                 % 是否存在明显的强度差异（多模态）1=是，0=否
rotFlag = 1;                 % 是否存在明显的旋转差异
sclFlag = 1;                 % 是否存在明显的尺度差异

% 变换模型配置
transForm = 'affine';        % 空间变换模型: similarity, affine, projective

% 输出形式配置
outForm = 'union';           % 输出形式: reference, union, inter

% 可视化配置
isFlag = 1;                  % 是否显示配准结果可视化
i3Flag = 1;                  % 是否显示重叠形式
i4Flag = 1;                  % 是否显示拼接形式
% ==================== 图像读取 ====================
% 读取可见光和红外图像
im1 = imread('./images/vis4_v2.jpg');  % 可见光图像
im2 = imread('./images/ir4.JPG');     % 红外图像

% 备份原始图像
im1Original = im1;
im2Original = im2;

% 转换为灰度图像用于特征提取
im1Gray = im2gray(im1);

% ==================== 粗配准阶段 ====================
% 显示红外图像
figure(1);
imshow(im2);
title("红外图像");

% 执行基于SSIM和RMSE的粗配准
[im2, roughPoints, H_init] = coarseRegistrationBySsimRmse(im1, im2, pointNum);
im2Gray = im2gray(im2);

% 显示粗配准特征点
hold on;
plot(roughPoints(:,1), roughPoints(:,2), '.r');
title("粗配准特征点");

% 准备精配准的输入点
pointRefine = [roughPoints(:,2), roughPoints(:,1)];

% 显示配准后的图像融合效果
fusedImage = im1.*0.5 + im2.*0.5;
figure, imshow(fusedImage);
title("粗配准后的图像融合");
% ==================== 精配准阶段 ====================
% 使用MCOG特征进行精配准
[cleanedPoints1, cleanedPoints2] = fineRegistrationByMcog(im1Gray, im2Gray, batchSize, pointRefine);

% ==================== 图像变换 ====================
% 执行图像配准变换
tic;
[I1_r, I2_r, I1_rs, I2_rs, I3, I4, t_form, ~] = imageTransformation(im1, im2, ...
    cleanedPoints1, cleanedPoints2, transForm, outForm, 1, isFlag, i3Flag, i4Flag);

transformTime = toc;
fprintf(['已完成图像变换，用时 ', num2str(transformTime), 's\n']);
fprintf(['Done image transformation，time: ', num2str(transformTime), 's\n\n']);

% 显示结果
if i3Flag
    figure, imshow(I3), title('重叠形式 (Overlap Form)'); drawnow
end
if i4Flag
    figure, imshow(I4), title('拼接形式 (Mosaic Form)'); drawnow
end

% ==================== 弹性变换和插值 ====================
% 恢复原始图像
im2Registered = im2;
im1 = im1Original;
im2 = im2Original;

% 准备特征点数据用于TPS变换
X1 = cleanedPoints1';
X2 = cleanedPoints2';
X1 = [X1; ones(1, size(X1, 2))];
X2 = [X2; ones(1, size(X2, 2))];

% 显示匹配特征点
figure;
showMatchedFeatures(im1Original, im2Registered, (X1(1:2,:))', (X2(1:2,:))', 'montage');
title('初始匹配特征点');

% 应用初始变换
X2 = (inv(H_init)) * X2;
figure;
showMatchedFeatures(im1Original, im2, (X1(1:2,:))', (X2(1:2,:))', 'montage');
title('变换后的匹配特征点');

% 执行弹性变换
[mosaicImg, regImg, u_, v_] = elasticTransformation(im1, im2, X1, X2);

% 显示最终拼接结果
figure, imshow(mosaicImg);
title('弹性变换拼接结果');
% 计算总运行时间
totalTime = toc;
disp(['总运行时间: ', num2str(totalTime), ' 秒']);

% ==================== 客观评估 ====================
% 加载参考点数据
load c_points.mat

% 获取当前图像对的参考点
eval(['IR_ = round(IR_', num2str(imNum), ')']);
eval(['VIS_ = round(VIS_', num2str(imNum), ')']);

% 初始化统计变量
pointsWithin5 = 0;   % 5像素内点数
pointsWithin10 = 0;  % 10像素内点数

% 计算每个点的配准误差
for i = 1:50
    % 获取预测位置
    predX = u_(VIS_(i,2), VIS_(i,1));
    predY = v_(VIS_(i,2), VIS_(i,1));

    % 计算欧几里得距离
    distance(i) = sqrt((IR_(i,1) - predX)^2 + (IR_(i,2) - predY)^2);
    distSum(i) = (IR_(i,1) - predX)^2 + (IR_(i,2) - predY)^2;

    % 统计落在误差阈值内的点数
    if distance(i) < 10
        pointsWithin10 = pointsWithin10 + 1;
        if distance(i) < 5
            pointsWithin5 = pointsWithin5 + 1;
        end
    end
end

% 计算评估指标
meanDistance = mean(distance(:));
maxDistance = max(distance(:));
rmse = sqrt(mean(distSum(:)));

% 输出评估结果
fprintf('\n================ 配准精度评估 ================\n');
fprintf('RMSE: %.4f 像素\n', rmse);
fprintf('平均误差: %.4f 像素\n', meanDistance);
fprintf('最大误差: %.4f 像素\n', maxDistance);
fprintf('5像素内准确点数: %d/50 (%.1f%%)\n', pointsWithin5, pointsWithin5/50*100);
fprintf('10像素内准确点数: %d/50 (%.1f%%)\n', pointsWithin10, pointsWithin10/50*100);