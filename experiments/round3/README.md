# penet7: DKT-P 实验（Predicate-level Knowledge Transfer）

## 实验信息
- **方法**: DKT-P from DRM (Dual-granularity Representation and Knowledge Transfer)
- **论文**: Li et al., CVPR 2024 "Leveraging Predicate and Triplet Learning for SGG"
- **代码**: https://github.com/jkli1998/DRM
- **验证数据**: mR@50=44.3 (Table 10), R@50=未知（⚠️高风险，可能<58）

## CB-Loss正交性
DKT-P通过特征分布校准和合成样本生成来提升尾类，不使用per-class loss reweighting。
与CB-Loss正交，但两者都帮助尾类，叠加时CB-Loss增益可能减小。

## 运行方式
```bash
bash experiments/round3/run_dktp.sh
```
需要手动适配DRM代码到PE-NET，详见脚本中的说明。
