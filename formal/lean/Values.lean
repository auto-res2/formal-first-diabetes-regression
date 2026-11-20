import Spec
/-! 検証済みの値。parse_claims.py が生成する。手で編集しない。 -/
namespace Values
def dataSha256 : String := "4733febee697862c22139cdac87478a300ce0d101593deb07ed6c0f3328a99cd"
def fetchedSha256 : String := "4733febee697862c22139cdac87478a300ce0d101593deb07ed6c0f3328a99cd"
def nSamples : ℕ := 442
def nFeatures : ℕ := 10
def featureColumns : List String := ["AGE", "SEX", "BMI", "BP", "S1", "S2", "S3", "S4", "S5", "S6"]
def targetColumn : String := "Y"
def splitFunction : String := "sklearn.model_selection.train_test_split"
def splitSeed : ℕ := 0
def testFraction : ℚ := ((1 : ℚ) / 5)
def nTest : ℕ := 89
def trainIndex : List ℕ := [74, 26, 45, 389, 154, 4, 386, 225, 327, 264, 8, 190, 5, 371, 200, 313, 7, 325, 366, 22, 68, 437, 20, 353, 281, 14, 300, 240, 175, 405, 153, 75, 64, 55, 135, 329, 81, 316, 369, 328, 414, 421, 361, 415, 232, 224, 252, 254, 418, 106, 278, 63, 336, 378, 387, 430, 89, 93, 245, 272, 241, 92, 18, 145, 150, 322, 393, 297, 231, 66, 380, 412, 140, 101, 345, 247, 363, 17, 146, 315, 220, 30, 114, 235, 103, 219, 274, 176, 191, 116, 168, 367, 120, 218, 112, 303, 136, 308, 221, 126, 196, 332, 424, 133, 33, 419, 162, 34, 44, 97, 85, 61, 167, 199, 173, 229, 236, 433, 376, 250, 108, 407, 46, 357, 372, 263, 73, 137, 422, 246, 253, 29, 181, 374, 301, 51, 365, 391, 217, 432, 27, 2, 259, 156, 255, 417, 346, 138, 212, 104, 310, 306, 311, 215, 348, 189, 214, 35, 230, 204, 234, 293, 239, 210, 67, 24, 295, 216, 223, 129, 111, 166, 349, 40, 317, 79, 431, 350, 13, 364, 436, 228, 161, 83, 439, 416, 110, 149, 152, 16, 299, 109, 312, 139, 237, 260, 318, 355, 248, 342, 19, 269, 226, 340, 3, 309, 125, 280, 286, 77, 184, 354, 420, 275, 294, 384, 182, 395, 80, 307, 258, 11, 331, 86, 266, 36, 423, 58, 41, 270, 50, 209, 352, 351, 368, 123, 222, 62, 379, 130, 187, 23, 43, 0, 201, 377, 98, 304, 429, 178, 256, 94, 409, 95, 390, 169, 69, 305, 48, 341, 207, 279, 227, 148, 143, 334, 180, 356, 131, 425, 440, 262, 324, 203, 84, 121, 383, 406, 91, 82, 267, 119, 358, 291, 57, 321, 257, 394, 42, 105, 408, 273, 392, 38, 53, 385, 128, 290, 28, 183, 370, 163, 151, 244, 202, 31, 32, 127, 185, 413, 288, 398, 402, 147, 285, 410, 177, 99, 338, 335, 197, 243, 115, 404, 265, 72, 333, 25, 165, 337, 426, 174, 428, 39, 193, 314, 396, 88, 70, 87, 292, 242, 277, 211, 9, 359, 195, 251, 323, 192, 117, 47, 172]
def testIndex : List ℕ := [362, 249, 271, 435, 400, 403, 12, 399, 198, 205, 78, 144, 298, 171, 268, 21, 194, 1, 10, 208, 76, 37, 388, 411, 289, 100, 261, 401, 319, 206, 375, 283, 373, 344, 287, 360, 179, 238, 434, 302, 158, 118, 339, 397, 330, 296, 164, 54, 157, 71, 284, 6, 343, 326, 159, 15, 320, 60, 282, 142, 56, 124, 107, 132, 382, 102, 160, 141, 186, 441, 90, 59, 347, 233, 427, 65, 438, 155, 122, 276, 188, 96, 170, 113, 381, 213, 134, 49, 52]
def fitFunction : String := "sklearn.linear_model.LinearRegression.fit"
def predictFunction : String := "sklearn.linear_model.LinearRegression.predict"
def mseFunction : String := "sklearn.metrics.mean_squared_error"
def usedFeatureCount : ℕ := 10
def modelInputXSha256 : String := "ae560a6efb1b86fbce564225a40502c1f85dcbbc7acb6f5830bac71c5aa7bfec"
def loadedXSha256 : String := "ae560a6efb1b86fbce564225a40502c1f85dcbbc7acb6f5830bac71c5aa7bfec"
def fitInputSha256 : String := "7968ccfdb6b347591a4a86e80dc98088c8d74ccc118ef1c80694e02748c425e2"
def trainDataSha256 : String := "7968ccfdb6b347591a4a86e80dc98088c8d74ccc118ef1c80694e02748c425e2"
def scikitLearnVersion : String := "1.7.2"
def numpyVersion : String := "2.3.4"
def pythonVersion : String := "3.13.3"
def operatingSystem : String := "ubuntu-24.04"
def cpuArchitecture : String := "x86_64"
def testMse : ℚ := ((8560648335746739 : ℚ) / 2500000000000)
def specSha256AtRunCommit : String := "5190daec09122a5e233cc2bab2a8143f573a713945bd7aa3909672505ce4bfcc"
def specSha256AtVerifiedCommit : String := "5190daec09122a5e233cc2bab2a8143f573a713945bd7aa3909672505ce4bfcc"
def fullRunTestMses : List ℚ := [((8560648335746739 : ℚ) / 2500000000000)]
def repositoryPublic : Bool := true
def repositoryFiles : List String := [".github/workflows/run_experiment.yml", ".github/workflows/verify_claims.yml", ".gitignore", "README.md", "formal/claims.json", "formal/cli.py", "formal/declaration.json", "formal/lean/Spec.lean", "formal/lean/lake-manifest.json", "formal/lean/lakefile.toml", "formal/lean/lean-toolchain", "formal/parse_claims.py", "formal/verification.json", "formal/verifiers.py", "pyproject.toml", "src/download_data.py", "src/run_experiment.py", "uv.lock"]
def cpuModel : String := "Intel(R) Xeon(R) 6975P-C"
def memoryGib : ℚ := ((153 : ℚ) / 10)
def targetMean : ℚ := ((7606674208144797 : ℚ) / 50000000000000)
def targetStd : ℚ := ((1925143646736261 : ℚ) / 25000000000000)
def observed : Spec.RunFacts where
  dataSha256 := dataSha256
  nSamples := nSamples
  nFeatures := nFeatures
  featureColumns := featureColumns
  targetColumn := targetColumn
  splitFunction := splitFunction
  splitSeed := splitSeed
  testFraction := testFraction
  nTest := nTest
  fitFunction := fitFunction
  predictFunction := predictFunction
  mseFunction := mseFunction
  usedFeatureCount := usedFeatureCount
  scikitLearnVersion := scikitLearnVersion
  numpyVersion := numpyVersion
  pythonVersion := pythonVersion
  operatingSystem := operatingSystem
  cpuArchitecture := cpuArchitecture
end Values
