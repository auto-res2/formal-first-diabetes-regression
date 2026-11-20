# formal-first-diabetes-regression

研究の指示から、メインの claim と、それを検証するための claims を先に Lean で宣言し、実験して検証してから論文にする試行。

研究の指示: 糖尿病データセットに線形回帰モデルを当てはめ、テストデータに対する MSE が 3400 を下回るかを調べる。

- claims の宣言: [`formal/lean/Spec.lean`](formal/lean/Spec.lean)（claim 1 つが命題 1 つで、命題の名前が claim の ID）
- 値の取り方: [`formal/verification.json`](formal/verification.json)（どの値を、どの検証器のどの取り方で取るか）
- スキーマ: [`formal/claims.json`](formal/claims.json)（上の 2 つから生成する。検証の結果もここに書く）
- 実験コード: [`src/run_experiment.py`](src/run_experiment.py)
- 論文: [`report/report.pdf`](report/report.pdf)（検証の後に、claims から作る）

## 流れ

```bash
python3 formal/cli.py schema          # Spec.lean と verification.json から claims.json を作る
gh workflow run run_experiment.yml -f mode=full   # 実験（GitHub Actions）
gh workflow run verify_claims.yml -f mode=full    # 検証（GitHub Actions）。結果は artifact の claims.json
```
