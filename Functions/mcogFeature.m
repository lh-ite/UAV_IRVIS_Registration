function descriptors = mcogFeature(im, num_bins, sigma, clip)
% 参数默认值
if nargin < 4, clip = 0.2; end
if nargin < 3, sigma = 0.8; end
if nargin < 2, num_bins = 20; end

% 转换为灰度图
if size(im,3) == 3, im = rgb2gray(im); end
im = im2single(im);
[h, w] = size(im);

% 多尺度参数
scales = [0.45, 1, 2]; 
n_scales = numel(scales);
descriptors = zeros(h, w, num_bins*n_scales, 'single');

% ------------------ 关键修改：预计算固定高斯核 ------------------
gauss_kernel = fspecial('gaussian', ceil(3*sigma)*2+1, sigma); % 所有尺度共享

% 多尺度并行处理
temp_feats = cell(n_scales, 1);
for s = 1:n_scales
    scale = scales(s);
    
    % 尺度空间构建（直接缩放）
    im_scaled = imresize(im, scale); % 注意：scale=0.5缩小，scale=2放大
    
    % 单尺度特征计算（使用固定高斯核）
    feat = SingleScaleFastCFOG(im_scaled, num_bins, gauss_kernel);
    
    % 上采样回原尺寸
    feat_upsampled = imresize(feat, [h w], 'bicubic');
    temp_feats{s} = feat_upsampled;
end

% 合并特征
for s = 1:n_scales
    start_idx = (s-1)*num_bins + 1;
    end_idx = s*num_bins;
    descriptors(:,:,start_idx:end_idx) = temp_feats{s};
end

% 后处理
descriptors = min(descriptors, clip);
descriptors = bsxfun(@rdivide, descriptors, sum(descriptors,3) + eps);
end

function feat = SingleScaleFastCFOG(im, N, gauss_kernel)
% 单尺度快速CFOG（修正分箱索引）
[h, w] = size(im);
feat = zeros(h, w, N, 'single');

% 1. 梯度计算
[gx, gy] = gradient(im);
g_mag = sqrt(gx.^2 + gy.^2);
g_ori = atan2(-gy, gx); 

% 转换为无符号方向[0, pi)
g_ori(g_ori < 0) = g_ori(g_ori < 0) + pi;

% 2. 分箱参数
bin_width = pi / N;

% 3. 双线性插值分箱（修正索引计算）
theta = g_ori / bin_width;
lower_bin = floor(theta);
upper_bin = lower_bin + 1;

% 处理边界条件
lower_bin = mod(lower_bin - 1, N) + 1;
upper_bin = mod(upper_bin - 1, N) + 1;
weight = theta - floor(theta);         % 上分箱权重

% 4. 幅值分配
for k = 1:N
    % 下分箱分配
    mask_lower = (lower_bin == k);
    feat(:,:,k) = feat(:,:,k) + g_mag .* (mask_lower .* (1 - weight));
    
    % 上分箱分配
    mask_upper = (upper_bin == k);
    feat(:,:,k) = feat(:,:,k) + g_mag .* (mask_upper .* weight);
end

% 5. 高斯平滑
for k = 1:N
    feat(:,:,k) = imfilter(feat(:,:,k), gauss_kernel, 'replicate');
end
end