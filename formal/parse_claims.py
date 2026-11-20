"""パーサー。Spec.lean（claims の宣言）と verification.json（値の取り方）からスキーマを作り、
検証器を呼び、Lean の値と定理のファイルを書き、Lean の出力から判定を読む。"""
import json
import re
from fractions import Fraction
from pathlib import Path

from verifiers import QUERIES

FORMAL = Path(__file__).parent
LEAN = FORMAL / "lean"
STANDARD_AXIOMS = ["propext", "Classical.choice", "Quot.sound"]
LITERAL = {
    "String": lambda value: json.dumps(value, ensure_ascii=False),
    "Bool": lambda value: str(bool(value)).lower(),
    "ℕ": lambda value: str(int(value)),
    "ℚ": lambda value: f"(({Fraction(value).numerator} : ℚ) / {Fraction(value).denominator})",
}
HEADER = ["import Spec", "import Values", "open Spec Values"]


def lean_literal(lean_type: str, value) -> str:
    if lean_type.startswith("List "):
        return "[" + ", ".join(lean_literal(lean_type.removeprefix("List "), item) for item in value) + "]"
    return LITERAL[lean_type](value)


def _binders(signature: str) -> list[tuple[str, str]]:
    """明示の引数 (a b : T) を、(名前, 型) の組にする。"""
    return [(name, binder_type.strip()) for names, binder_type in re.findall(r"\(([^():]+):([^()]+)\)", signature)
            for name in names.split()]


def read_spec() -> list[dict]:
    """Spec.lean から、claims（abbrev C01 など）を、ID の順に読む。"""
    text = (LEAN / "Spec.lean").read_text(encoding="utf-8")
    claims = []
    for match in re.finditer(r"/-- ((?:(?!-/).)*?) -/\nabbrev (C\d\d)\b(.*?) : Prop :=(.*?)(?=\n\n|\n/--|\ntheorem |\naxiom )", text, re.S):
        explanation, claim_id, signature, body = match.groups()
        headings = re.findall(r"^/-! (#{2,3}) ([^\n]*?)(?: -/)?$", text[:match.start()], re.M)
        group = headings[-1][1] if headings and headings[-1][0] == "###" else ""
        claims.append({
            "id": claim_id, "group": group, "explanation": explanation,
            "proposition": f"abbrev {claim_id}{signature} : Prop :={body}",
            "arguments": [{"name": name, "type": binder_type} for name, binder_type in _binders(signature)],
            "proved_in_spec": f"theorem {claim_id}_holds" in text,
            "axiom_in_spec": f"axiom {claim_id}_axiom" in text,
        })
    return sorted(claims, key=lambda claim: claim["id"])


def build_schema() -> dict:
    """宣言の部分のスキーマ。手で書かず、Spec.lean と verification.json から作る。"""
    verification = json.loads((FORMAL / "verification.json").read_text(encoding="utf-8"))
    claims = read_spec()
    for claim in claims:
        claim_id = claim["id"]
        if claim_id == verification["main_claim"]:
            claim["kind"], claim["verifier"] = "main", "Lean"
        elif claim_id == verification["verification_method"]:
            claim["kind"], claim["verifier"] = "verification_method", "Lean"
        elif claim_id in verification["unverifiable"]:
            claim["kind"], claim["verifier"], claim["unverifiable"] = "axiom", None, verification["unverifiable"][claim_id]
        elif claim["proved_in_spec"]:
            claim["kind"], claim["verifier"] = "definition", "Lean"
        elif claim_id in verification["derived"]:
            claim["kind"], claim["verifier"], claim["derived"] = "", "Lean", verification["derived"][claim_id]
        else:
            claim["kind"], claim["verifier"] = "", "GitHub"
            unknown = [a["name"] for a in claim["arguments"] if a["name"] not in verification["variables"]]
            if unknown:
                raise ValueError(f"{claim_id}: 値の取り方が verification.json に無い: {unknown}")
    return {"instruction": verification["instruction"], "claims": claims,
            "variables": verification["variables"], "axioms": STANDARD_AXIOMS}


def declaration_part(record: dict) -> dict:
    """スキーマから、検証の結果（result、verified）を除いたもの。"""
    return {"instruction": record["instruction"], "axioms": record["axioms"],
            "claims": [{k: v for k, v in claim.items() if k != "result"} for claim in record["claims"]],
            "variables": {name: {k: v for k, v in variable.items() if k != "verified"}
                          for name, variable in record["variables"].items()}}


def query_values(record: dict, repository: str, mode: str) -> tuple[dict, dict[str, str]]:
    """変数を、検証器に問い合わせる。(JSON の値, 取れなかった理由) を返す。"""
    values, errors = {}, {}
    for name, variable in record["variables"].items():
        try:
            values[name] = QUERIES[variable["verifier"]][variable["query"]](repository, mode, name, **variable.get("args", {}))
        except Exception as error:  # 取れなかった値を使う claim だけを、未検証にする
            errors[name] = str(error)
    return values, errors


def write_values(record: dict) -> None:
    """検証済みの値から、Values.lean を書く。RunFacts の項目がすべて揃っていれば、まとめた observed も置く。"""
    lines = ["import Spec", "/-! 検証済みの値。parse_claims.py が生成する。手で編集しない。 -/", "namespace Values"]
    verified = {name: variable for name, variable in record["variables"].items() if "verified" in variable}
    for name, variable in verified.items():
        lines.append(f"def {name} : {variable['type']} := {lean_literal(variable['type'], variable['verified']['value'])}")
    spec = (LEAN / "Spec.lean").read_text(encoding="utf-8")
    fields = re.findall(r"^  (\w+) : ", re.search(r"structure RunFacts where\n(.*?)\n  deriving", spec, re.S).group(1), re.M)
    if all(field in verified for field in fields):
        lines += ["def observed : Spec.RunFacts where"] + [f"  {field} := {field}" for field in fields]
    (LEAN / "Values.lean").write_text("\n".join(lines + ["end Values", ""]), encoding="utf-8")


def _statement(claim: dict) -> str:
    return " ".join([claim["id"]] + [argument["name"] for argument in claim["arguments"]])


def _proof(claim: dict) -> str:
    return f"{claim['id']}_axiom" if claim["kind"] == "axiom" else f"{claim['id']}_holds"


def _method_application(claims: dict[str, dict], method: dict) -> tuple[str, list[str]]:
    """検証方法の定理に、前提の claims の証明を、命題に書かれた順に渡した式と、前提の ID。"""
    quantified, premises = method["proposition"].split(",\n", 1)
    premise_ids = re.findall(r"\bC\d\d\b", premises.rsplit("(", 1)[0])
    holes = " ".join("_" for _ in _binders(quantified))
    return f"{method['id']}_holds {holes} " + " ".join(_proof(claims[i]) for i in premise_ids), premise_ids


def candidates(record: dict, available: set[str]) -> list[str]:
    """各 claim の、真である定理と偽である（否定の）定理。通ったほうが判定になる。値が揃った claim だけを書く。"""
    claims = {claim["id"]: claim for claim in record["claims"]}
    spec = (LEAN / "Spec.lean").read_text(encoding="utf-8")
    lines, later = [], []
    for claim in record["claims"]:
        name, statement = claim["id"], _statement(claim)
        if not {a["name"] for a in claim["arguments"]} <= available | {"observed"} or ("observed" in statement and "observed" not in available):
            continue
        if claim["kind"] in ("definition", "verification_method"):
            lines.append(f"#print axioms Spec.{name}_holds")
        elif claim["kind"] == "axiom":
            # 値を含む公理は、検証された値に対してだけ宣言する
            if not claim["axiom_in_spec"]:
                lines.insert(0, f"axiom {name}_axiom : {statement}")
            lines.append(f"#print axioms {name}_axiom")
        elif claim["kind"] == "main":
            application, _ = _method_application(claims, claims[next(c["id"] for c in record["claims"] if c["kind"] == "verification_method")])
            tactic = f"by rw [{application}]; decide +kernel"
            later += [f"theorem {name}_holds : {statement} := {tactic}", f"theorem {name}_fails : ¬ ({statement}) := {tactic}",
                      f"#print axioms {name}_holds", f"#print axioms {name}_fails"]
        elif "derived" in claim:
            theorem = claim["derived"]["theorem"]
            signature = re.search(rf"theorem {theorem}\b(.*?) :\n", spec, re.S).group(1)
            holes = " ".join("_" for _ in _binders(signature))
            later = [f"theorem {name}_holds : {statement} := {theorem} {holes} "
                     + " ".join(_proof(claims[i]) for i in claim["derived"]["from"]), f"#print axioms {name}_holds"] + later
        else:
            lines += [f"theorem {name}_holds : {statement} := by decide +kernel",
                      f"theorem {name}_fails : ¬ ({statement}) := by decide +kernel",
                      f"#print axioms {name}_holds", f"#print axioms {name}_fails"]
    return lines + later


def read_axioms(lean_output: str) -> dict[str, list[str] | None]:
    """定理ごとの、依存する公理。証明が通らなかった定理は sorryAx に依存する。出力に無い定理は None。"""
    flat = re.sub(r"\s+", " ", lean_output)
    short = lambda name: name.removeprefix("Spec.")
    axioms = {short(name): [] for name in re.findall(r"'([\w.]+)' does not depend on any axioms", flat)}
    axioms |= {short(name): [short(axiom) for axiom in listed.split(", ")]
               for name, listed in re.findall(r"'([\w.]+)' depends on axioms: \[([^\]]*)\]", flat)}
    return axioms


def judge(record: dict, axioms: dict, errors: dict[str, str]) -> dict[str, dict]:
    """claim ごとの結果。真か偽かは、通った定理で決まる。前提が欠けた claim は inconclusive にする。"""
    claims = {claim["id"]: claim for claim in record["claims"]}
    declared = {f"{claim['id']}_axiom" for claim in record["claims"] if claim["kind"] == "axiom"}
    allowed = set(record["axioms"]) | declared
    results = {}

    def passed(name: str) -> list[str] | None:
        used = axioms.get(name)
        return used if used is not None and "sorryAx" not in used and set(used) <= allowed else None

    for claim in record["claims"]:
        name = claim["id"]
        lacking = sorted({a["name"] for a in claim["arguments"]} & set(errors))
        if claim["kind"] == "axiom":
            results[name] = {"status": "unverifiable", "reason": claim["unverifiable"],
                             "axiom": f"{name}_axiom" if axioms.get(f"{name}_axiom") is not None else None}
        elif lacking:
            results[name] = {"status": "unverified", "reason": "値が取れない: " + "、".join(f"{n}（{errors[n]}）" for n in lacking)}
        elif (used := passed(f"{name}_holds")) is not None:
            results[name] = {"status": "verified", "verdict": "真", "axioms": sorted(used)}
        elif (used := passed(f"{name}_fails")) is not None:
            results[name] = {"status": "verified", "verdict": "偽", "axioms": sorted(used)}
        else:
            results[name] = {"status": "inconclusive"}
    # inconclusive の理由: 成り立たなかった前提
    method = next((claim for claim in record["claims"] if claim["kind"] == "verification_method"), None)
    for claim in record["claims"]:
        result = results[claim["id"]]
        if result["status"] != "inconclusive":
            continue
        premises = claim.get("derived", {}).get("from") or (_method_application(claims, method)[1] if claim["kind"] == "main" else [])
        failed = [i for i in premises if not (results[i]["status"] == "unverifiable" and results[i]["axiom"])
                  and results[i].get("verdict") != "真"]
        result["reason"] = ("成り立たなかった前提: " + "、".join(failed)) if failed else "真の定理も偽の定理も通らなかった"
    return results


def write_theorems(record: dict, results: dict, available: set[str]) -> None:
    """判定が付いた命題を、真なら定理、偽なら否定の定理として Theorems.lean に書く。"""
    keep = {f"{name}_{'holds' if result['verdict'] == '真' else 'fails'}" for name, result in results.items() if "verdict" in result}
    lines = HEADER + ["/-! 各命題の判定。parse_claims.py が生成する。手で編集しない。 -/"]
    for line in candidates(record, available):
        theorem = re.match(r"theorem (\w+)", line)
        if line.startswith("axiom ") or (theorem and theorem.group(1) in keep):
            lines.append(line)
    (LEAN / "Theorems.lean").write_text("\n".join(lines) + "\n", encoding="utf-8")
