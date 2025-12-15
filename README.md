# 多模态图像配准系统 (Multi-modal Image Registration System)

## 项目简介

这是一个基于MATLAB的多模态图像配准系统，主要用于实现可见光图像与红外图像的自动配准。通过粗配准和精配准相结合的方式，实现高精度的图像对齐，并提供多种输出形式和评估指标。

## 主要特性

- **多模态配准**: 支持可见光-红外等不同模态图像的配准
- **两阶段配准**: 粗配准 + 精配准，确保配准精度和效率
- **多种变换模型**: 支持相似变换、仿射变换、投影变换
- **多种输出形式**: 参考图像、重叠显示、拼接显示等
- **客观评估**: 提供RMSE、平均误差等量化评估指标
- **可视化展示**: 丰富的可视化结果展示

## 项目结构

```
Measurement_demo/
├── main.m                          # 主程序入口
├── Functions/                      # 函数库
│   ├── coarseRegistrationBySsimRmse.m    # 粗配准函数
│   ├── fineRegistrationByMcog.m          # 精配准函数
│   ├── imageTransformation.m              # 图像变换函数
│   ├── elasticTransformation.m             # 弹性变换函数
│   ├── mcogFeature.m                      # MCOG特征提取
│   ├── phaseCongruency3.m                 # 相位一致性特征
│   ├── homographyRansac.m                 # 单应性RANSAC
│   ├── robustKernelResidual.m             # 鲁棒核残差
│   ├── dealWithExtremes.m                 # 极值处理
│   ├── visualizeImage.m                   # 图像可视化
│   ├── mosaicMapping.m                    # 拼接映射
│   ├── fftMatch.m                         # FFT匹配
│   ├── guidedTotalVariation.m             # 引导总变分
│   ├── gaussianFilter.m                   # 高斯滤波
│   └── lowPassFilter.m                    # 低通滤波
├── images/                        # 测试图像
│   ├── vis4_v2.jpg               # 可见光图像
│   └── ir4.JPG                   # 红外图像
├── c_points.mat                  # 参考点数据
└── Measurement_registration.pdf  # 技术文档
```

## 算法流程

1. **图像预处理**: 读取可见光和红外图像，转换为灰度图
2. **粗配准阶段**:
   - 基于SSIM和RMSE的相似性度量
   - 提取粗略的特征点对应关系
   - 估计初始变换矩阵
3. **精配准阶段**:
   - 使用MCOG特征进行精确匹配
   - FFT相关性计算子像素精度
   - 优化特征点对应关系
4. **图像变换**:
   - 支持多种空间变换模型
   - 生成不同形式的输出结果
5. **弹性变形**: 使用弹性变换进行非线性配准
6. **客观评估**: 计算配准精度指标

## 使用方法

### 环境要求
- MATLAB R2018b 或更高版本
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox

### 运行步骤

1. **配置参数**:
   ```matlab
   % 在main.m中修改参数
   pointNum = 100;              % 特征点数量
   transForm = 'affine';        % 变换模型
   outForm = 'union';           % 输出形式
   ```

2. **准备数据**:
   - 将待配准的图像放入 `images/` 文件夹
   - 确保有对应的参考点数据 `c_points.mat`

3. **运行程序**:
   ```matlab
   % 直接运行main.m
   main
   ```

## 参数说明

### 主要参数

- `pointNum`: 粗配准阶段提取的特征点数量
- `batchSize`: 精配准阶段的批处理窗口大小
- `transForm`: 空间变换模型
  - `'similarity'`: 相似变换
  - `'affine'`: 仿射变换
  - `'projective'`: 投影变换
- `outForm`: 输出形式
  - `'reference'`: 参考图像坐标系
  - `'union'`: 并集区域
  - `'inter'`: 交集区域

### 可视化选项

- `isFlag`: 是否显示配准可视化结果
- `i3Flag`: 是否显示重叠形式
- `i4Flag`: 是否显示拼接形式

## 评估指标

程序运行结束后会输出以下评估指标:

- **RMSE**: 均方根误差
- **平均误差**: 所有点的平均配准误差
- **最大误差**: 最大配准误差
- **准确率**: 5像素和10像素内的点占比

## 技术特点

### 配准算法
- **粗配准**: 基于图像相似性度量的快速配准
- **精配准**: 基于MCOG特征的亚像素精度配准
- **鲁棒性**: RANSAC算法去除异常点
- **非线性配准**: 弹性变换处理复杂变形

### 特征提取
- **MCOG特征**: 多通道梯度特征，适用于多模态图像
- **相位一致性**: 提取边缘和纹理信息
- **尺度不变性**: 多尺度特征金字塔



## 扩展应用

该系统不仅适用于可见光-红外配准，还可以扩展到:

- 医学图像配准 (CT/MRI, PET/CT等)
- 遥感图像配准 (多光谱, SAR/光学等)


## 作者信息与联系方式

**论文作者**: Li, Hao; Liu, Chenhua; Li, Maoyong; Deng, Lei; Dong, Mingli; Zhu, Lianqing

**论文标题**: Cross-scale infrared and visible image registration based on phase consistency feature for UAV scenario

**联系方式**:
- Email: lh_010625@163.com 或 imagevisioner@outlook.com



所有代码将在论文发表后发布。

## 项目成果展示

### 可视化对比结果
我们方法与其他方法的可视化结果对比：

![image](https://github.com/user-attachments/assets/22ebcf70-77ae-47bc-a128-2e5c94e0c4f0)

![image](https://github.com/user-attachments/assets/227f6a71-16ea-49f3-85e1-f7e2928c93b6)

### GUI软件
我们使用MATLAB App Designer设计了一个应用程序，帮助用户快速操作。软件将在论文发表后发布。

<img width="690" alt="311d953a92230e4170fb11abdd470f4" src="https://github.com/user-attachments/assets/72052758-d69b-41c3-9d26-84cd3a6d1691" />

## 参考文献

### 本文引用
如果我们的工作对您有帮助，请引用我们的论文：

```bibtex
@article{li2025cross,
  title={Cross-scale infrared and visible image registration based on phase consistency feature for UAV scenario},
  author={Li, Hao and Liu, Chenhua and Li, Maoyong and Deng, Lei and Dong, Mingli and Zhu, Lianqing},
  journal={Measurement},
  pages={119340},
  year={2025},
  publisher={Elsevier}
}
```

```bibtex
@article{li2026ecpcs,
  title={ECPCS: Enhanced contrast phase consistency space for visible and infrared image registration},
  author={Li, Hao and Liu, Chenhua and Li, Maoyong and Deng, Lei and Dong, Mingli and Zhu, Lianqing},
  journal={Optics and Lasers in Engineering},
  volume={197},
  pages={109472},
  year={2026},
  publisher={Elsevier}
}
```