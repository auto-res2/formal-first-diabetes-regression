import Mathlib
/-!
研究の指示: 糖尿病データセットに線形回帰モデルを当てはめ，テストデータに対する MSE が 3400 を下回るかを調べる。

実験の前に宣言する claims。claim 1 つが命題 1 つで，命題の名前が claim の ID。
ID は書いた順（メインの claim → 検証方法 → 定義 → 公理 → GitHub の検証器で検証する claims → 検証に使わない claims）に振る。
ファイルの中の並びは，Lean が使う前に宣言を求めるので，この順ではない。
値はまだ無いので，実験の出力は命題の引数で受ける。検証方法と公理（C02，C09）では，まとめて RunFacts で受ける。

既存のライブラリにある計算は，数学的な定義を書かず，そのライブラリの関数として置く。
Lean に書くのは，どのデータをどの関数に渡すか，というこの研究の手続きだけ。
-/

namespace Spec

/-! ## データとライブラリの関数（中身の無い記号） -/

/-- Efron ら [1] が用いた糖尿病データセットのファイルの，2 行目以降の 442 行の 1〜10 列目（説明変数）。 -/
opaque features : Fin 442 → Fin 10 → ℝ
/-- 同じファイルの 11 列目（目的変数）。 -/
opaque target : Fin 442 → ℝ

/-- sklearn.model_selection.train_test_split（scikit-learn 1.7.2，NumPy 2.3.4）。442 行を分け，テストデータの行を返す。 -/
opaque trainTestSplit (seed : ℕ) (testFraction : ℚ) : Finset (Fin 442)

/-- sklearn.linear_model.LinearRegression を当てはめた結果。 -/
opaque FittedModelType : NonemptyType
def FittedModel : Type := FittedModelType.type
instance : Nonempty FittedModel := FittedModelType.property

/-- sklearn.linear_model.LinearRegression.fit（scikit-learn 1.7.2）。指定した行の説明変数と目的変数に当てはめる。 -/
noncomputable opaque fit (rows : Finset (Fin 442)) (features : Fin 442 → Fin 10 → ℝ) (target : Fin 442 → ℝ) : FittedModel
/-- sklearn.linear_model.LinearRegression.predict（scikit-learn 1.7.2）。 -/
opaque predict (model : FittedModel) (x : Fin 10 → ℝ) : ℝ
/-- sklearn.metrics.mean_squared_error（scikit-learn 1.7.2）。指定した行の，目的変数と予測値に対する値。 -/
opaque meanSquaredError (rows : Finset (Fin 442)) (target prediction : Fin 442 → ℝ) : ℝ

/-! ## 定義（定義と，それを述べる命題の組） -/

def testRows : Finset (Fin 442) := trainTestSplit 0 (1 / 5)
/-- テストデータの行は，sklearn.model_selection.train_test_split を，シード 0，テストデータの割合 1/5 で呼んで返る行である。 -/
abbrev C07 : Prop := testRows = trainTestSplit 0 (1 / 5)
theorem C07_holds : C07 := rfl

def trainRows : Finset (Fin 442) := testRowsᶜ
/-- 訓練データの行は，テストデータ以外の行である。 -/
abbrev C06 : Prop := trainRows = testRowsᶜ
theorem C06_holds : C06 := rfl

noncomputable def fittedModel : FittedModel := fit trainRows features target
/-- 当てはめたモデルは，訓練データの説明変数と目的変数に，sklearn.linear_model.LinearRegression.fit を適用したものである。
- 説明変数は 10 個すべてを，加工せずに渡す -/
abbrev C05 : Prop := fittedModel = fit trainRows features target
theorem C05_holds : C05 := rfl

noncomputable def prediction (i : Fin 442) : ℝ := predict fittedModel (features i)
/-- 予測値は，当てはめたモデルと各行の説明変数に，sklearn.linear_model.LinearRegression.predict を適用した値である。 -/
abbrev C04 : Prop := ∀ i, prediction i = predict fittedModel (features i)
theorem C04_holds : C04 := fun _ => rfl

noncomputable def specifiedTestMse : ℝ := meanSquaredError testRows target prediction
/-- 比べる量は，テストデータの目的変数と予測値に，sklearn.metrics.mean_squared_error を適用した値である。 -/
abbrev C03 : Prop := specifiedTestMse = meanSquaredError testRows target prediction
theorem C03_holds : C03 := rfl

/-! ## メインの claim -/

/-- 比べる量（C03。訓練データに sklearn.linear_model.LinearRegression を当てはめ，テストデータを予測し，sklearn.metrics.mean_squared_error で計算した値）は，3400 を下回る。 -/
abbrev C01 : Prop := specifiedTestMse < 3400

/-! ## 本番の run が実際に使ったもの -/

/-- 実行が使うものの一覧。 -/
structure RunFacts where
  dataSha256 : String
  nSamples : ℕ
  nFeatures : ℕ
  featureColumns : List String
  targetColumn : String
  splitFunction : String
  splitSeed : ℕ
  testFraction : ℚ
  nTest : ℕ
  fitFunction : String
  predictFunction : String
  mseFunction : String
  usedFeatureCount : ℕ
  scikitLearnVersion : String
  numpyVersion : String
  pythonVersion : String
  operatingSystem : String
  cpuArchitecture : String
  deriving Inhabited

/-- 本番の run が実際に使ったもの（中身の無い記号）。 -/
opaque actualFacts : RunFacts
/-- 本番の run が実際に得た，テストデータに対する MSE（中身の無い記号）。 -/
opaque actualTestMse : ℝ
/-- Efron ら [1] が用いた糖尿病データセットのファイルの SHA-256（中身の無い記号）。 -/
opaque efronDatasetSha256 : String

/-! ## GitHub の検証器で検証する claims

検証器は，値を返す前に，成功した本番の run であること，artifact がその run のものであること，
artifact の中身が GitHub の記録した digest と一致することを確かめる。
「観測した」は，検証器が本番の run の artifact などから取った値を指す。 -/

/-! ### データセット -/

/-- 宣言したデータセットの SHA-256 と，観測したデータセット（artifact にあるデータのファイル）の SHA-256 は，一致する。
- 宣言した値: 4733febee697862c22139cdac87478a300ce0d101593deb07ed6c0f3328a99cd -/
abbrev C11 (dataSha256 : String) : Prop := dataSha256 = "4733febee697862c22139cdac87478a300ce0d101593deb07ed6c0f3328a99cd"

/-- 宣言したデータセットの SHA-256 と，配布元の URL から取得したファイルの SHA-256 は，一致する。
- 配布元の URL: https://www4.stat.ncsu.edu/~boos/var.select/diabetes.tab.txt -/
abbrev C12 (fetchedSha256 : String) : Prop := fetchedSha256 = "4733febee697862c22139cdac87478a300ce0d101593deb07ed6c0f3328a99cd"

/-- C08（公理），C11，C12 より，Efron ら [1] が用いたデータセットが，観測したデータセットである。 -/
abbrev C13 (dataSha256 : String) : Prop := dataSha256 = efronDatasetSha256

/-- 宣言したデータの行数と，観測した行数は，一致する。
- 宣言した値: 442 -/
abbrev C14 (nSamples : ℕ) : Prop := nSamples = 442
/-- 宣言した説明変数の数と，観測した説明変数の数は，一致する。
- 宣言した値: 10 -/
abbrev C15 (nFeatures : ℕ) : Prop := nFeatures = 10
/-- 宣言した説明変数の列名と，観測した列名は，一致する。
- 宣言した値: AGE，SEX，BMI，BP，S1，S2，S3，S4，S5，S6 -/
abbrev C16 (featureColumns : List String) : Prop := featureColumns = ["AGE", "SEX", "BMI", "BP", "S1", "S2", "S3", "S4", "S5", "S6"]
/-- 宣言した目的変数の列名と，観測した列名は，一致する。
- 宣言した値: Y -/
abbrev C17 (targetColumn : String) : Prop := targetColumn = "Y"

/-! ### 分割 -/

/-- 宣言した分割の関数と，観測した分割の関数は，一致する。
- 宣言した値: sklearn.model_selection.train_test_split -/
abbrev C18 (splitFunction : String) : Prop := splitFunction = "sklearn.model_selection.train_test_split"
/-- 宣言した分割の乱数のシードと，観測したシードは，一致する。
- 宣言した値: 0 -/
abbrev C19 (splitSeed : ℕ) : Prop := splitSeed = 0
/-- 宣言したテストデータの割合と，観測した割合は，一致する。
- 宣言した値: 1/5 -/
abbrev C20 (testFraction : ℚ) : Prop := testFraction = 1 / 5
/-- 宣言したテストデータの件数と，観測した件数は，一致する。
- 宣言した値: 89（442 件の 1/5 を切り上げた数） -/
abbrev C21 (nTest : ℕ) : Prop := nTest = 89
/-- 観測した訓練データの行とテストデータの行は，重ならず，合わせると全 442 件になる。 -/
abbrev C22 (trainIndex testIndex : List ℕ) : Prop :=
  Disjoint trainIndex.toFinset testIndex.toFinset ∧
  trainIndex.toFinset ∪ testIndex.toFinset = Finset.range 442

/-! ### 当てはめ，予測，評価 -/

/-- 宣言した当てはめの関数と，観測した当てはめの関数は，一致する。
- 宣言した値: sklearn.linear_model.LinearRegression.fit -/
abbrev C23 (fitFunction : String) : Prop := fitFunction = "sklearn.linear_model.LinearRegression.fit"
/-- 宣言した予測の関数と，観測した予測の関数は，一致する。
- 宣言した値: sklearn.linear_model.LinearRegression.predict -/
abbrev C24 (predictFunction : String) : Prop := predictFunction = "sklearn.linear_model.LinearRegression.predict"
/-- 宣言した MSE の計算の関数と，観測した MSE の計算の関数は，一致する。
- 宣言した値: sklearn.metrics.mean_squared_error -/
abbrev C25 (mseFunction : String) : Prop := mseFunction = "sklearn.metrics.mean_squared_error"
/-- 宣言した，当てはめに使う説明変数の数と，観測した数は，一致する。
- 宣言した値: 10（すべての説明変数） -/
abbrev C26 (usedFeatureCount : ℕ) : Prop := usedFeatureCount = 10
/-- 観測した，モデルに渡した説明変数の SHA-256 は，読み込んだ説明変数の SHA-256 と一致する（加工していない）。 -/
abbrev C27 (modelInputXSha256 loadedXSha256 : String) : Prop := modelInputXSha256 = loadedXSha256
/-- 観測した，当てはめに渡したデータの SHA-256 は，訓練データの SHA-256 と一致する。 -/
abbrev C28 (fitInputSha256 trainDataSha256 : String) : Prop := fitInputSha256 = trainDataSha256

/-! ### ライブラリの版 -/

/-- 宣言した scikit-learn の版と，観測した版は，一致する。
- 宣言した値: 1.7.2 -/
abbrev C29 (scikitLearnVersion : String) : Prop := scikitLearnVersion = "1.7.2"
/-- 宣言した NumPy の版と，観測した版は，一致する。
- 宣言した値: 2.3.4 -/
abbrev C30 (numpyVersion : String) : Prop := numpyVersion = "2.3.4"

/-! ### 実行環境 -/

/-- 宣言した Python の版と，観測した版は，一致する。
- 宣言した値: 3.13.3 -/
abbrev C31 (pythonVersion : String) : Prop := pythonVersion = "3.13.3"
/-- 宣言した OS（GitHub Actions の runner の種類）と，観測した OS は，一致する。
- 宣言した値: ubuntu-24.04 -/
abbrev C32 (operatingSystem : String) : Prop := operatingSystem = "ubuntu-24.04"
/-- 宣言した CPU のアーキテクチャと，観測したアーキテクチャは，一致する。
- 宣言した値: x86_64 -/
abbrev C33 (cpuArchitecture : String) : Prop := cpuArchitecture = "x86_64"

/-! ### 研究公正 -/

/-- 判定に使う宣言（このファイル）は，run が実行した commit にあった宣言と同じである。
- HARKing の検査。run の後に，メインの claim や定義を書き換えていないことを示す
- 宣言が run より前にあったことも，これに含まれる -/
abbrev C34 (specSha256AtRunCommit specSha256AtVerifiedCommit : String) : Prop :=
  specSha256AtRunCommit = specSha256AtVerifiedCommit

/-- 成功した本番の run は，すべて，同じ MSE を出力している。
- チェリーピッキングの検査。何度も走らせて，都合のよい run だけを選んでいないことを示す
- CPU の型番やメモリが違う run で MSE が違えば，C10（公理）が反証される -/
abbrev C35 (fullRunTestMses : List ℚ) (testMse : ℚ) : Prop := ∀ mse ∈ fullRunTestMses, mse = testMse

/-! ## メインの claim の検証に使わない claims -/

/-- 実験コードと出力は，公開している。
- リポジトリは public で，実験コード（src/run_experiment.py）を含む -/
abbrev C36 (repositoryPublic : Bool) (repositoryFiles : List String) : Prop :=
  repositoryPublic = true ∧ "src/run_experiment.py" ∈ repositoryFiles

/-! ## 公理 -/

/-- Efron ら [1] が用いた糖尿病データセットは，配布元の URL から取得したファイルである。
- [1] B. Efron, T. Hastie, I. Johnstone, R. Tibshirani. Least angle regression. Annals of Statistics, 2004
- 値が入った後に，その値に対して公理として宣言する -/
abbrev C08 (fetchedSha256 : String) : Prop := efronDatasetSha256 = fetchedSha256

theorem C13_of_C08_C11_C12 (dataSha256 fetchedSha256 : String) :
    C08 fetchedSha256 → C11 dataSha256 → C12 fetchedSha256 → C13 dataSha256 :=
  fun efron c11 c12 => c11.trans (c12.symm.trans efron.symm)

/-- 実験コードは，データを定義（C03〜C07）のとおりに関数へ渡し，宣言していない加工をしない。 -/
opaque RunWiredAsSpec : Prop

/-- run が実行した commit の実験コードは，その commit の宣言を満たす。
- この宣言と，この値に当てはめるには，次が要る: 判定に使う宣言がその commit の宣言と同じ（C34），本番の run の MSE が 1 つに決まる（C35），訓練データとテストデータが全件を重なりなく分けている（C22），説明変数を加工していない（C27），当てはめに訓練データを渡している（C28）
- 出力に書く値は，実行が実際に使った値，実際に得た値である
- データを定義（C03〜C07）のとおりに関数へ渡し，宣言していない加工をしない
- 値が入った後に，その値に対して公理として宣言する（任意の値に対して宣言すると，すべての値が等しいことになってしまう） -/
abbrev C09 (specSha256AtRunCommit specSha256AtVerifiedCommit : String) (fullRunTestMses : List ℚ)
    (trainIndex testIndex : List ℕ) (modelInputXSha256 loadedXSha256 fitInputSha256 trainDataSha256 : String)
    (observed : RunFacts) (testMse : ℚ) : Prop :=
  C34 specSha256AtRunCommit specSha256AtVerifiedCommit → C35 fullRunTestMses testMse →
  C22 trainIndex testIndex → C27 modelInputXSha256 loadedXSha256 → C28 fitInputSha256 trainDataSha256 →
  observed = actualFacts ∧ (testMse : ℝ) = actualTestMse ∧ RunWiredAsSpec

/-- 実行は，Efron ら [1] が用いた糖尿病データセットと，宣言した分割，関数，版，実行環境で行われた（実行が実際に使ったものについて，C13〜C33 が成り立つ）。 -/
def RunUsedDeclared : Prop :=
  C13 actualFacts.dataSha256 ∧ C14 actualFacts.nSamples ∧ C15 actualFacts.nFeatures ∧
  C16 actualFacts.featureColumns ∧ C17 actualFacts.targetColumn ∧ C18 actualFacts.splitFunction ∧
  C19 actualFacts.splitSeed ∧ C20 actualFacts.testFraction ∧ C21 actualFacts.nTest ∧
  C23 actualFacts.fitFunction ∧ C24 actualFacts.predictFunction ∧ C25 actualFacts.mseFunction ∧
  C26 actualFacts.usedFeatureCount ∧ C29 actualFacts.scikitLearnVersion ∧ C30 actualFacts.numpyVersion ∧
  C31 actualFacts.pythonVersion ∧ C32 actualFacts.operatingSystem ∧ C33 actualFacts.cpuArchitecture

/-- scikit-learn 1.7.2（NumPy 2.3.4）は信用できる。
- 宣言した版と実行環境のもとで，宣言した関数（train_test_split，LinearRegression.fit，LinearRegression.predict，mean_squared_error）は，同じ入力にいつも同じ値を返す。CPU の型番やメモリには依らない
- Lean に置いた記号（trainTestSplit，fit，predict，meanSquaredError）は，その関数を指す
- したがって，宣言したデータ・分割・関数・版・実行環境で，定義のとおりに計算した実行が得る MSE は，C03 の量である
- 関数の中身（何を計算するか）は主張しない -/
abbrev C10 : Prop := RunUsedDeclared → RunWiredAsSpec → actualTestMse = specifiedTestMse
axiom C10_axiom : C10

/-! ## メインの claim の検証方法 -/

/-- C08〜C35 が成り立つなら，メインの claim（C01）は，出力に書かれた MSE を 3400 と比べることで検証できる。
- 値に関係なく成り立つ。実験の前に，何を確かめれば C01 の真偽が決まるかが確定する
- 保証するのは，検証のやり方の正しさである。C08〜C35 が実際に成り立つことと，出力に書かれた MSE が 3400 を下回ることは，保証しない
- C08〜C35 のどれかが成り立たなければ，C01 は真とも偽とも言えない
- C08，C11，C12 は，C13 を通して使う -/
abbrev C02 : Prop :=
  ∀ (specSha256AtRunCommit specSha256AtVerifiedCommit : String) (fullRunTestMses : List ℚ)
    (trainIndex testIndex : List ℕ) (modelInputXSha256 loadedXSha256 fitInputSha256 trainDataSha256 : String)
    (observed : RunFacts) (testMse : ℚ),
  C09 specSha256AtRunCommit specSha256AtVerifiedCommit fullRunTestMses trainIndex testIndex
    modelInputXSha256 loadedXSha256 fitInputSha256 trainDataSha256 observed testMse →
  C10 →
  C13 observed.dataSha256 →
  C14 observed.nSamples → C15 observed.nFeatures → C16 observed.featureColumns → C17 observed.targetColumn →
  C18 observed.splitFunction → C19 observed.splitSeed → C20 observed.testFraction → C21 observed.nTest →
  C22 trainIndex testIndex →
  C23 observed.fitFunction → C24 observed.predictFunction → C25 observed.mseFunction →
  C26 observed.usedFeatureCount → C27 modelInputXSha256 loadedXSha256 → C28 fitInputSha256 trainDataSha256 →
  C29 observed.scikitLearnVersion → C30 observed.numpyVersion →
  C31 observed.pythonVersion → C32 observed.operatingSystem → C33 observed.cpuArchitecture →
  C34 specSha256AtRunCommit specSha256AtVerifiedCommit → C35 fullRunTestMses testMse →
  (C01 ↔ testMse < 3400)
theorem C02_holds : C02 := by
  intro _ _ _ _ _ _ _ _ _ observed testMse code library c13 c14 c15 c16 c17 c18 c19 c20 c21 c22 c23 c24
    c25 c26 c27 c28 c29 c30 c31 c32 c33 c34 c35
  obtain ⟨facts, observedMse, wired⟩ := code c34 c35 c22 c27 c28
  have used : RunUsedDeclared := by
    unfold RunUsedDeclared
    rw [← facts]
    exact ⟨c13, c14, c15, c16, c17, c18, c19, c20, c21, c23, c24, c25, c26, c29, c30, c31, c32, c33⟩
  have observedIsSpecified : (testMse : ℝ) = specifiedTestMse := by rw [observedMse, library used wired]
  unfold C01
  rw [← observedIsSpecified]
  exact_mod_cast Iff.rfl

end Spec
