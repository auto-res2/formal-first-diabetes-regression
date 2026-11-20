import Spec
import Values
open Spec Values
/-! 各命題の判定。parse_claims.py が生成する。手で編集しない。 -/
axiom C09_axiom : C09 specSha256AtRunCommit specSha256AtVerifiedCommit fullRunTestMses trainIndex testIndex modelInputXSha256 loadedXSha256 fitInputSha256 trainDataSha256 observed testMse
axiom C08_axiom : C08 fetchedSha256
theorem C11_holds : C11 dataSha256 := by decide +kernel
theorem C12_holds : C12 fetchedSha256 := by decide +kernel
theorem C14_holds : C14 nSamples := by decide +kernel
theorem C15_holds : C15 nFeatures := by decide +kernel
theorem C16_holds : C16 featureColumns := by decide +kernel
theorem C17_holds : C17 targetColumn := by decide +kernel
theorem C18_holds : C18 splitFunction := by decide +kernel
theorem C19_holds : C19 splitSeed := by decide +kernel
theorem C20_holds : C20 testFraction := by decide +kernel
theorem C21_holds : C21 nTest := by decide +kernel
theorem C22_holds : C22 trainIndex testIndex := by decide +kernel
theorem C23_holds : C23 fitFunction := by decide +kernel
theorem C24_holds : C24 predictFunction := by decide +kernel
theorem C25_holds : C25 mseFunction := by decide +kernel
theorem C26_holds : C26 usedFeatureCount := by decide +kernel
theorem C27_holds : C27 modelInputXSha256 loadedXSha256 := by decide +kernel
theorem C28_holds : C28 fitInputSha256 trainDataSha256 := by decide +kernel
theorem C29_holds : C29 scikitLearnVersion := by decide +kernel
theorem C30_holds : C30 numpyVersion := by decide +kernel
theorem C31_holds : C31 pythonVersion := by decide +kernel
theorem C32_holds : C32 operatingSystem := by decide +kernel
theorem C33_holds : C33 cpuArchitecture := by decide +kernel
theorem C34_holds : C34 specSha256AtRunCommit specSha256AtVerifiedCommit := by decide +kernel
theorem C35_holds : C35 fullRunTestMses testMse := by decide +kernel
theorem C36_holds : C36 repositoryPublic repositoryFiles := by decide +kernel
theorem C13_holds : C13 dataSha256 := C13_of_C08_C11_C12 _ _ C08_axiom C11_holds C12_holds
theorem C01_fails : ¬ (C01) := by rw [C02_holds _ _ _ _ _ _ _ _ _ _ _ C09_axiom C10_axiom C13_holds C14_holds C15_holds C16_holds C17_holds C18_holds C19_holds C20_holds C21_holds C22_holds C23_holds C24_holds C25_holds C26_holds C27_holds C28_holds C29_holds C30_holds C31_holds C32_holds C33_holds C34_holds C35_holds]; decide +kernel
