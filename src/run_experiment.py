"""糖尿病データセットに線形回帰を当てはめ、formal/lean/Spec.lean の claims が求める値を results/metrics.json に書く。

出力のキーは、Lean の変数名と同じにする（formal/verification.json の variables）。
--sanity を付けると、同じ形の合成データで実行する。仕組みの試運転用で、結果は証拠にしない。
"""
import hashlib
import json
import platform
import sys
from pathlib import Path

import numpy as np
import sklearn
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split

from download_data import DATA_PATH, download_data

SEED = 0
TEST_FRACTION = 0.2
RESULTS_PATH = Path("results/metrics.json")
COLUMNS = ["AGE", "SEX", "BMI", "BP", "S1", "S2", "S3", "S4", "S5", "S6", "Y"]


def write_sanity_data() -> Path:
    """本番のデータと同じ形（442 行、11 列）の乱数の表を、本番のデータと同じ場所に書く。"""
    table = np.random.default_rng(0).normal(100.0, 20.0, size=(442, len(COLUMNS))).round(1)
    DATA_PATH.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(DATA_PATH, table, fmt="%.1f", delimiter="\t", header="\t".join(COLUMNS), comments="")
    return DATA_PATH


def public_name(target) -> str:
    """関数やクラスの、下線で始まる内部のモジュールを除いた名前。"""
    modules = [part for part in target.__module__.split(".") if not part.startswith("_")]
    return ".".join(modules + [target.__qualname__])


def sha256(array: np.ndarray) -> str:
    return hashlib.sha256(np.ascontiguousarray(array).tobytes()).hexdigest()


def first_line(path: str, prefix: str) -> str:
    return next(line.split(":", 1)[1].strip() for line in Path(path).read_text().splitlines() if line.startswith(prefix))


def main() -> None:
    data_path = write_sanity_data() if "--sanity" in sys.argv else download_data()
    columns = data_path.read_text().splitlines()[0].split("\t")
    table = np.loadtxt(data_path, skiprows=1)
    features, target = table[:, :-1], table[:, -1]
    train_index, test_index = train_test_split(np.arange(len(target)), test_size=TEST_FRACTION, random_state=SEED)
    loaded_train_features = features[train_index]
    train_data = np.column_stack([loaded_train_features, target[train_index]])
    fit_input = train_data
    model_input = fit_input[:, :-1]
    model = LinearRegression()
    LinearRegression.fit(model, model_input, fit_input[:, -1])
    prediction = LinearRegression.predict(model, features[test_index])
    result = {
        "nSamples": int(len(target)), "nFeatures": int(features.shape[1]),
        "featureColumns": columns[:-1], "targetColumn": columns[-1],
        "splitFunction": public_name(train_test_split), "splitSeed": SEED, "testFraction": TEST_FRACTION,
        "nTest": int(len(test_index)),
        "trainIndex": [int(i) for i in train_index], "testIndex": [int(i) for i in test_index],
        # predict は親クラスで定義されているので、関数の名前ではなく、モデルのクラスの名前に付けて記録する
        "fitFunction": f"{public_name(type(model))}.fit", "predictFunction": f"{public_name(type(model))}.predict",
        "mseFunction": public_name(mean_squared_error),
        "usedFeatureCount": int(model.n_features_in_),
        "loadedXSha256": sha256(loaded_train_features), "modelInputXSha256": sha256(model_input),
        "trainDataSha256": sha256(train_data), "fitInputSha256": sha256(fit_input),
        "scikitLearnVersion": sklearn.__version__, "numpyVersion": np.__version__,
        "pythonVersion": platform.python_version(), "cpuArchitecture": platform.machine(),
        "cpuModel": first_line("/proc/cpuinfo", "model name"),
        "memoryGib": round(int(first_line("/proc/meminfo", "MemTotal").split()[0]) / 1024**2, 1),
        "targetMean": float(target.mean()), "targetStd": float(target.std()),
        "testMse": float(mean_squared_error(target[test_index], prediction)),
    }
    RESULTS_PATH.parent.mkdir(parents=True, exist_ok=True)
    RESULTS_PATH.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({key: value for key, value in result.items() if not key.endswith("Index")}, indent=2))


if __name__ == "__main__":
    main()
