#!/bin/bash
# ================================================================
#  penet7: DKT-P 实验（DRM的Predicate-level Knowledge Transfer）
#  预期结果: mR@50=44.3 (DRM Table 10验证), R@50=未知(可能<58)
#  预计时间: 搭建2h + 训练12h
#  论文: Li et al., CVPR 2024 "Leveraging Predicate and Triplet Learning"
#  代码: github.com/jkli1998/DRM
#  ⚠️ 高风险方案：mR@50极高但R@50可能崩塌
# ================================================================
set -e

echo "================================================================"
echo "  Step 0: 环境准备"
echo "================================================================"

WORK_DIR="/path/to/your/workdir"
PENET_DIR="${WORK_DIR}/penet7"
DATASET_DIR="${PENET_DIR}/datasets/vg"
GLOVE_DIR="${DATASET_DIR}"
DETECTOR_CKPT="${PENET_DIR}/checkpoints/pretrained_faster_rcnn/model_final.pth"
GPU_ID=0

# ================================================================
echo "  Step 1: 克隆 DRM 代码库"
echo "================================================================"

cd ${WORK_DIR}
if [ ! -d "DRM" ]; then
    git clone https://github.com/jkli1998/DRM.git
    cd DRM
    pip install -r requirements.txt 2>/dev/null || true
    python setup.py build develop
else
    echo "DRM already exists, skipping clone"
    cd DRM
fi

# ================================================================
echo "  Step 2: 理解 DKT-P Pipeline"
echo "================================================================"
echo ""
echo "DKT-P的核心步骤:"
echo "  1. 训练标准PE-NET → 你已有checkpoint"
echo "  2. 提取训练集所有relation特征 → per-class统计量(μ_k, Σ_k)"
echo "  3. 找head→tail的class mapping → 基于特征空间距离"
echo "  4. 用head class协方差校准tail class协方差"
echo "  5. 从校准后分布采样合成tail特征"
echo "  6. 用原始+合成特征重新训练分类器"
echo ""
echo "DRM代码基于PySGG框架(SHA-GCL)，和你的PE-NET代码结构有差异"
echo "需要手动适配以下内容:"
echo "  - 特征提取: 需要适配PE-NET的project_head输出(4096维)"
echo "  - 统计量计算: 直接用PE-NET输出的rel_rep做per-class Gaussian fitting"
echo "  - 合成样本生成: DKT的核心，从DRM代码中提取"
echo "  - 分类器微调: 用合成+真实特征重训PE-NET的prototype匹配"
echo ""

# ================================================================
echo "  Step 3: 链接数据集"
echo "================================================================"

cd ${WORK_DIR}/DRM
ln -sf ${DATASET_DIR}/../.. ./datasets 2>/dev/null || true

# ================================================================
echo "  Step 4: 预训练检查"
echo "================================================================"

echo -n "DRM代码: "
ls ./tools/ 2>/dev/null && echo "✅" || echo "❌"

echo -n "数据集: "
ls ./datasets/vg/VG-SGG-with-attri.h5 2>/dev/null && echo "✅" || echo "❌"

echo -n "GPU: "
python3 -c "import torch; print(f'✅ {torch.cuda.get_device_name(${GPU_ID})}')" 2>/dev/null || echo "❌"

# ================================================================
echo "  Step 5: DKT-P 适配说明"
echo "================================================================"
echo ""
echo "由于DRM基于PySGG框架，直接运行需要手动适配。"
echo "建议的适配方案："
echo ""
echo "方案A（推荐）: 提取PE-NET特征，在DRM框架中做DKT"
echo "  1. 用你的PE-NET跑inference，保存所有training样本的rel_rep (4096维)"
echo "  2. 在DRM代码中加载这些特征，做per-class Gaussian fitting"
echo "  3. 运行DKT的distribution calibration"
echo "  4. 生成合成特征"
echo "  5. 回到PE-NET，用合成+真实特征微调prototype"
echo ""
echo "方案B: 直接在DRM框架中训练PE-NET"
echo "  DRM的configs/目录下应该有PE-NET相关配置"
echo "  参考 DRM Table 10 的设置"
echo ""
echo "请查看 DRM 仓库的 README 和 scripts/ 目录获取更多细节。"
echo ""
echo "================================================================"
echo "  ⚠️ 风险提醒"
echo "================================================================"
echo ""
echo "DKT-P在PE-NET上的mR@50=44.3（极高），但R@50未报告。"
echo "DRM自身backbone的R@50=43.9（极低），暗示严重的R@50崩塌。"
echo "本实验的核心目的是验证R@50到底是多少。"
echo "如果R@50 < 58，本方案不满足约束条件。"
echo "================================================================"
