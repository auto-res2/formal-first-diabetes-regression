"""検証器。確かめてから値を返す。claims の形は知らない。

問い合わせは (repository, mode, 変数名, **args) を受ける。mode は "full"（本番）か "sanity"（試運転）。
値の元になる run は、その mode の成功した最新の run。番号は claims に書かない。
"""
import functools
import hashlib
import io
import json
import subprocess
import zipfile
from fractions import Fraction
from pathlib import Path

BRANCH = "main"
EXPERIMENT_WORKFLOW = "run_experiment.yml"
ARTIFACT = "run-output"
OUTPUT_PATH = "outputs/results/metrics.json"


def _gh(*args: str) -> str:
    return subprocess.run(["gh", *args], check=True, capture_output=True, text=True).stdout


@functools.cache
def _succeeded_runs(repository: str, mode: str) -> list[dict]:
    """実験のワークフローの、その mode の成功した run。新しい順。mode は起動時の入力で、run の名前の末尾に入っている。"""
    runs = json.loads(_gh("api", f"repos/{repository}/actions/workflows/{EXPERIMENT_WORKFLOW}/runs?branch={BRANCH}&per_page=100"))
    succeeded = [run for run in runs["workflow_runs"]
                 if run["display_title"].split()[-1] == mode and run["conclusion"] == "success"]
    if not succeeded:
        raise ValueError(f"成功した {mode} の run が無い")
    return succeeded


def _evidence_run(repository: str, mode: str) -> dict:
    return _succeeded_runs(repository, mode)[0]


@functools.cache
def _artifact(repository: str, run: int) -> zipfile.ZipFile:
    """artifact がその run のもので、中身が GitHub の記録した digest と一致することを確かめて開く。"""
    artifacts = json.loads(_gh("api", f"repos/{repository}/actions/runs/{run}/artifacts"))["artifacts"]
    matches = [a for a in artifacts if a["name"] == ARTIFACT and not a["expired"]]
    if len(matches) != 1:
        raise ValueError(f"run {run} に artifact {ARTIFACT!r} が {len(matches)} 個ある")
    archive = subprocess.run(["gh", "api", f"repos/{repository}/actions/artifacts/{matches[0]['id']}/zip"],
                             check=True, capture_output=True).stdout
    if "sha256:" + hashlib.sha256(archive).hexdigest() != matches[0]["digest"]:
        raise ValueError(f"artifact {ARTIFACT!r} の中身が、GitHub の記録した digest と一致しない")
    return zipfile.ZipFile(io.BytesIO(archive))


def _output(repository: str, run: int) -> dict:
    """実験の出力。小数は書かれた桁のままの有理数で読む。"""
    return json.loads(_artifact(repository, run).read(OUTPUT_PATH), parse_float=Fraction)


def experiment_output(repository: str, mode: str, variable: str):
    """実験の出力の、変数名と同じキーの値。"""
    return _output(repository, _evidence_run(repository, mode)["id"])[variable]


def all_runs_experiment_output(repository: str, mode: str, variable: str, key: str) -> list:
    """その mode の成功した run すべての、実験の出力のキーの値。"""
    return [_output(repository, run["id"])[key] for run in _succeeded_runs(repository, mode)]


def artifact_file_sha256(repository: str, mode: str, variable: str, path: str) -> str:
    """artifact にあるファイルの SHA-256。"""
    return hashlib.sha256(_artifact(repository, _evidence_run(repository, mode)["id"]).read(path)).hexdigest()


def artifact_json(repository: str, mode: str, variable: str, path: str, key: str):
    """artifact にある JSON の、キーの値。"""
    return json.loads(_artifact(repository, _evidence_run(repository, mode)["id"]).read(path), parse_float=Fraction)[key]


def runner_label(repository: str, mode: str, variable: str) -> str:
    """run の job が走った runner の種類。"""
    run = _evidence_run(repository, mode)["id"]
    jobs = json.loads(_gh("api", f"repos/{repository}/actions/runs/{run}/jobs"))["jobs"]
    labels = {label for job in jobs for label in job["labels"]}
    if len(labels) != 1:
        raise ValueError(f"run {run} の runner の種類が 1 つに決まらない: {sorted(labels)}")
    return labels.pop()


def file_sha256_at_run_commit(repository: str, mode: str, variable: str, path: str) -> str:
    """run が実行した commit にあったファイルの SHA-256。"""
    commit = _evidence_run(repository, mode)["head_sha"]
    content = subprocess.run(["gh", "api", f"repos/{repository}/contents/{path}?ref={commit}",
                              "-H", "Accept: application/vnd.github.raw"], check=True, capture_output=True).stdout
    return hashlib.sha256(content).hexdigest()


def local_file_sha256(repository: str, mode: str, variable: str, path: str) -> str:
    """判定に使う（いま手元にある）ファイルの SHA-256。"""
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def repository_public(repository: str, mode: str, variable: str) -> bool:
    """リポジトリが公開されているか。"""
    return json.loads(_gh("api", f"repos/{repository}"))["visibility"] == "public"


def repository_files(repository: str, mode: str, variable: str) -> list[str]:
    """リポジトリのファイルの一覧。"""
    tree = json.loads(_gh("api", f"repos/{repository}/git/trees/{BRANCH}?recursive=1"))
    return [entry["path"] for entry in tree["tree"] if entry["type"] == "blob"]


QUERIES = {"GitHub": {f.__name__: f for f in (
    experiment_output, all_runs_experiment_output, artifact_file_sha256, artifact_json, runner_label,
    file_sha256_at_run_commit, local_file_sha256, repository_public, repository_files)}}
