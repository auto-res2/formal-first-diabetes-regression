import Mathlib
/-!
研究の指示: 糖尿病データセットに線形回帰モデルを当てはめ，テストデータに対する MSE が 3400 を下回るかを調べる。

実験の前に宣言するもの。メインの claim（D7）と，それが成り立つために要る定義（D1〜D8），
検証器が値を出す葉（V1〜V6），検証器が無いので信じる公理（A-コード，A-ライブラリ），
葉と公理からメインの claim までの連鎖を置く。値はまだ無いので，実験の出力は引数で受ける。
-/
open Matrix

namespace Spec

/-! ## 定義 -/

/-- D1 データ。ファイルの SHA-256。 -/
def dataSha256 : String := "4733febee697862c22139cdac87478a300ce0d101593deb07ed6c0f3328a99cd"
/-- D1。ファイルの 1 行目は列名，2 行目以降の 442 行が患者。1〜10 列目が説明変数。 -/
opaque features : Fin 442 → Fin 10 → ℝ
/-- D1。11 列目が目的変数。 -/
opaque target : Fin 442 → ℝ

/-- D2 分割。数学的な中身が無いので，関数と引数で固定する。 -/
def splitFunction : String := "sklearn.model_selection.train_test_split"
def splitSeed : ℕ := 0
def testFraction : ℚ := 1 / 5
/-- D2。`splitFunction` を `splitSeed`，`testFraction` で呼んで返ったテストデータの行。 -/
opaque testRows : Finset (Fin 442)
/-- D2。残りの行が訓練データ。 -/
def trainRows : Finset (Fin 442) := testRowsᶜ

/-- D3 モデル。切片と，10 個の説明変数すべての係数。 -/
def linearModel (coefficients : ℝ × (Fin 10 → ℝ)) (x : Fin 10 → ℝ) : ℝ :=
  coefficients.1 + coefficients.2 ⬝ᵥ x

/-- D4 当てはめ。訓練データ上の残差の二乗和。正則化の項は無い。 -/
def residualSumOfSquares (coefficients : ℝ × (Fin 10 → ℝ)) : ℝ :=
  ∑ i ∈ trainRows, (target i - linearModel coefficients (features i)) ^ 2
/-- D4。残差の二乗和を最小にする係数である。 -/
def IsLeastSquares (coefficients : ℝ × (Fin 10 → ℝ)) : Prop :=
  IsMinOn residualSumOfSquares Set.univ coefficients
/-- D4。最小にする係数。ただ 1 つに決まることは A-ライブラリに含める。 -/
noncomputable def leastSquaresCoefficients : ℝ × (Fin 10 → ℝ) := Classical.epsilon IsLeastSquares

/-- D5 MSE。 -/
noncomputable def meanSquaredError (rows : Finset (Fin 442)) (prediction : Fin 442 → ℝ) : ℝ :=
  (∑ i ∈ rows, (target i - prediction i) ^ 2) / rows.card

/-- D6 対象の量。最小二乗の係数で予測したときの，テストデータに対する MSE。 -/
noncomputable def targetMse : ℝ :=
  meanSquaredError testRows fun i => linearModel leastSquaresCoefficients (features i)

/-- D7 メインの claim。 -/
def Main : Prop := targetMse < 3400

/-- D8 使う関数と版。 -/
def fitFunction : String := "sklearn.linear_model.LinearRegression.fit"
def predictFunction : String := "sklearn.linear_model.LinearRegression.predict"
def mseFunction : String := "sklearn.metrics.mean_squared_error"
def scikitLearnVersion : String := "1.7.2"
def numpyVersion : String := "2.3.4"

/-! ## 実験の出力 -/

/-- 検証器が GitHub から取る値。 -/
structure Observation where
  dataSha256 : String
  splitFunction : String
  splitSeed : ℕ
  testFraction : ℚ
  fitFunction : String
  predictFunction : String
  mseFunction : String
  scikitLearnVersion : String
  numpyVersion : String
  /-- V4。出力に書かれた，テストデータに対する MSE。 -/
  testMse : ℚ
  runIsFullRunOfDeclaredCommit : Bool
  runSucceeded : Bool
  artifactIsFromRun : Bool
  /-- このファイルの commit の時刻（UNIX 秒）。 -/
  declaredAt : ℕ
  /-- 本番の run が始まった時刻（UNIX 秒）。 -/
  fullRunStartedAt : ℕ

/-! ## 葉（GitHub の検証器） -/

/-- V1。出力に記録されたファイルの SHA-256 が，宣言と一致する。 -/
abbrev DataFileIsDeclared (o : Observation) : Prop := o.dataSha256 = dataSha256
/-- V2。出力に記録された分割の関数，シード，割合が，宣言と一致する。 -/
abbrev SplitIsDeclared (o : Observation) : Prop :=
  o.splitFunction = splitFunction ∧ o.splitSeed = splitSeed ∧ o.testFraction = testFraction
/-- V3。出力に記録された関数と版が，宣言と一致する。 -/
abbrev FunctionsAreDeclared (o : Observation) : Prop :=
  o.fitFunction = fitFunction ∧ o.predictFunction = predictFunction ∧ o.mseFunction = mseFunction ∧
  o.scikitLearnVersion = scikitLearnVersion ∧ o.numpyVersion = numpyVersion
/-- V5 値の来歴。run は宣言した commit の本番の run で成功し，artifact はその run のものである。 -/
abbrev ValuesComeFromDeclaredRun (o : Observation) : Prop :=
  o.runIsFullRunOfDeclaredCommit = true ∧ o.runSucceeded = true ∧ o.artifactIsFromRun = true
/-- V6 研究公正。宣言は，本番の run より前である。 -/
abbrev DeclaredBeforeRun (o : Observation) : Prop := o.declaredAt < o.fullRunStartedAt

structure Leaves (o : Observation) : Prop where
  dataFile : DataFileIsDeclared o
  split : SplitIsDeclared o
  functions : FunctionsAreDeclared o
  provenance : ValuesComeFromDeclaredRun o
  -- 連鎖の中では使わない。値を使う判定には必ず付ける，という決まりで置く
  declaredBeforeRun : DeclaredBeforeRun o

/-! ## 公理（検証器が無い）

ここでは命題だけを置く。公理としての宣言は，検証された値が定義として置かれた後に，その値 1 組に対してだけ行う
（任意の値の組に対して宣言すると，MSE だけが違う 2 組から真と偽の両方が導けてしまう）。 -/

/-- 実行は，宣言したデータを，宣言した分割で分け，宣言した関数で当てはめ，予測し，評価した。 -/
opaque RunFollowsSpec (o : Observation) : Prop

/-- A-コード。実験コードは，この仕様を満たす。宣言したことをし，宣言していないことで結果に影響することをせず，
使った値をそのまま出力に記録する。 -/
def CodeSatisfiesSpec (o : Observation) : Prop :=
  ValuesComeFromDeclaredRun o → DataFileIsDeclared o → SplitIsDeclared o → FunctionsAreDeclared o →
  RunFollowsSpec o

/-- A-ライブラリ。D8 の関数は，ここで定義した量を計算する（当てはめは D4，予測は D3，MSE は D5）。
浮動小数点の丸めは無視する。最小にする係数がただ 1 つに決まることも含む。 -/
def LibraryComputesDefinitions (o : Observation) : Prop := RunFollowsSpec o → (o.testMse : ℝ) = targetMse

/-! ## 連鎖 -/

/-- 葉と公理が成り立てば，メインの claim は，出力に書かれた MSE と 3400 の比較で決まる。 -/
theorem main_iff_observed (o : Observation) (leaves : Leaves o)
    (code : CodeSatisfiesSpec o) (library : LibraryComputesDefinitions o) : Main ↔ o.testMse < 3400 := by
  unfold Main
  rw [← library (code leaves.provenance leaves.dataFile leaves.split leaves.functions)]
  exact_mod_cast Iff.rfl

end Spec
