"""Runs a report: validates parameters, reads Go, types values, groups rows
with subtotals and a grand total, and prepares charts.

The result (``RunResult``) is what every renderer uses: the HTML viewer, and
the Excel, CSV and PDF exports, so they always show the same numbers.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from decimal import Decimal, InvalidOperation
from typing import Any
from urllib.parse import urlencode

from django.http import QueryDict
from django.urls import reverse

from ..services.go_client import GoBFFClient
from .model import AVG, BOOL, DATE, INT, MAX, MIN, MONEY, NUMBER, PCT, SUM, TEXT, Dataset, Field, Report

_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
MAX_ROWS = 5_000  # per dataset on screen and in exports
SUPPRESSED = "<5"


# ── Parameters ────────────────────────────────────────────────────────────

def read_params(report: Report, query: QueryDict | dict) -> dict[str, str]:
    """Allowed, valid parameter values (defaults filled in)."""
    out: dict[str, str] = {}
    for p in report.params:
        raw = str(query.get(p.name, "") or "").strip()
        if p.kind == "date":
            value = raw if _DATE.match(raw) else ""
        elif p.kind == "int":
            value = raw if raw.isdigit() and (p.min is None or int(raw) >= p.min) and (p.max is None or int(raw) <= p.max) else ""
        elif p.kind == "text":
            value = raw[:100]
        else:
            value = raw if raw in {v for v, _ in p.choices} else ""
        value = value or p.default
        if value:
            out[p.name] = value
    return out


# ── Values ────────────────────────────────────────────────────────────────

def _number(value: Any) -> float | int | None:
    if isinstance(value, bool) or value is None:
        return None
    if isinstance(value, (int, float)):
        return value
    try:
        return float(Decimal(str(value).replace(",", "").strip()))
    except (InvalidOperation, ValueError):
        return None


def typed(f: Field, row: dict) -> Any:
    """The value as a number, date string, bool or text (None if missing)."""
    if f.key in set(row.get("suppressed") or []):
        return SUPPRESSED
    raw = f.get(row) if f.get else row.get(f.key)
    if f.type == MONEY:
        minor = row.get(f.minor) if f.minor else None
        if isinstance(minor, (int, float)) and not isinstance(minor, bool):
            return round(minor / 100, 2)
        return _number(raw)
    if f.type in (INT, NUMBER, PCT):
        n = _number(raw)
        if f.type == INT and isinstance(n, float) and n.is_integer():
            return int(n)
        return n
    if f.type == BOOL:
        return None if raw is None else bool(raw)
    if raw is None or raw == "":
        return None
    return str(raw) if not isinstance(raw, (list, dict)) else raw


def display(f: Field, value: Any, currency: str = "") -> str:
    if value is None:
        return "—"
    if value == SUPPRESSED:
        return SUPPRESSED
    if f.type == PCT:
        return f"{value * 100:.1f}%"
    if f.type == MONEY:
        text = f"{value:,.2f}"
        return f"{text} {currency}".strip()
    if f.type == INT:
        return f"{int(value):,}"
    if f.type == NUMBER:
        return f"{value:,.2f}" if abs(value) >= 1 else f"{value:.3g}"
    if f.type == BOOL:
        return "Yes" if value else "No"
    if isinstance(value, list):
        return ", ".join(str(v) for v in value)
    if isinstance(value, dict):
        return ", ".join(f"{k}: {v}" for k, v in value.items())
    return str(value)


def aggregate(f: Field, values: list[Any]) -> Any:
    nums = [v for v in values if isinstance(v, (int, float)) and not isinstance(v, bool)]
    if not f.agg or not nums:
        return None
    if f.agg == SUM:
        total = sum(nums)
        return round(total, 2) if isinstance(total, float) else total
    if f.agg == AVG:
        return sum(nums) / len(nums)
    if f.agg == MIN:
        return min(nums)
    if f.agg == MAX:
        return max(nums)
    return None


# ── Result ────────────────────────────────────────────────────────────────

@dataclass
class Cell:
    value: Any
    text: str
    numeric: bool
    href: str = ""


@dataclass
class Row:
    kind: str  # data | subtotal | total
    cells: list[Cell]
    level: int = 0  # grouping depth of a subtotal
    group: str = ""  # group label for subtotal rows / data row's group key


@dataclass
class Group:
    label: str
    key: str
    rows: list[Row]
    subtotal: Row | None
    count: int


@dataclass
class DatasetResult:
    spec: Dataset
    fields: tuple[Field, ...]
    group_by: tuple[str, ...]
    rows: list[Row]  # flat: data rows interleaved with subtotals, then total
    groups: list[Group]
    total: Row | None
    raw_rows: list[dict]
    truncated: bool = False
    error: str = ""
    chart: dict | None = None
    mixed_currency: bool = False

    @property
    def has_aggregates(self) -> bool:
        return any(f.agg for f in self.fields)


@dataclass
class RunResult:
    report: Report
    params: dict[str, str]
    datasets: list[DatasetResult]
    errors: list[str] = field(default_factory=list)
    denied: bool = False


def _rows_at(data: Any, path: tuple[str, ...]) -> list[dict]:
    node = data
    for key in path:
        node = node.get(key) if isinstance(node, dict) else None
    return [r for r in node if isinstance(r, dict)] if isinstance(node, list) else []


def _auto_datasets(data: dict) -> list[Dataset]:
    """Analytics reports carry their own column metadata."""
    out = []
    for name, table in (data.get("tables") or {}).items():
        if not isinstance(table, dict):
            continue
        fields = []
        for c in table.get("columns") or []:
            if not isinstance(c, dict) or not c.get("key"):
                continue
            kind, unit = c.get("kind"), c.get("unit")
            if kind == "dimension":
                ftype, agg = TEXT, ""
            elif unit == "%":
                ftype, agg = NUMBER, ""  # already ×100; rates are not totalled
            elif kind == "count":
                ftype, agg = INT, SUM
            else:
                ftype, agg = NUMBER, ""
            label = c.get("label") or c["key"]
            if unit == "%":
                label = f"{label} (%)"
            fields.append(Field(c["key"], label, ftype, agg))
        if fields:
            out.append(Dataset(name, str(table.get("title") or name.replace("_", " ").capitalize()),
                               ("tables", name, "rows"), tuple(fields)))
    return out


def _drill_href(f: Field, row: dict, report_params: dict[str, str]) -> str:
    if not f.drill:
        return ""
    target, mapping = f.drill
    params = {k: v for k, v in report_params.items() if k in ("since", "until", "from", "to")}
    for param, key in mapping.items():
        value = row.get(key)
        if value in (None, "") or str(value).lower() in ("unknown", "other", "pooled"):
            return ""
        params[param] = value
    return reverse("report_view", args=[target]) + ("?" + urlencode(params) if params else "")


def _build_rows(spec: Dataset, fields: tuple[Field, ...], raw: list[dict], group_by: tuple[str, ...],
                params: dict[str, str]) -> tuple[list[Row], list[Group], Row | None]:
    by_key = {f.key: f for f in fields}

    def data_row(r: dict) -> Row:
        currency = str(r.get("currency") or "")
        cells = []
        for f in fields:
            v = typed(f, r)
            cells.append(Cell(v, display(f, v, currency), f.type in (INT, NUMBER, MONEY, PCT), _drill_href(f, r, params)))
        return Row("data", cells)

    def summary(kind: str, members: list[dict], label: str, level: int = 0) -> Row:
        currencies = {str(m.get("currency") or "") for m in members}
        currency = currencies.pop() if len(currencies) == 1 else ""
        cells = []
        for i, f in enumerate(fields):
            if i == 0:
                cells.append(Cell(label, label, False))
                continue
            if f.type == MONEY and len({str(m.get("currency") or "") for m in members}) > 1:
                cells.append(Cell(None, "mixed currencies", True))  # never add rupees to euros
                continue
            v = aggregate(f, [typed(f, m) for m in members])
            cells.append(Cell(v, display(f, v, currency) if v is not None else "", f.type in (INT, NUMBER, MONEY, PCT)))
        return Row(kind, cells, level=level, group=label)

    keys = [k for k in group_by if k in by_key]
    groups: list[Group] = []
    rows: list[Row] = []
    if keys:
        buckets: dict[tuple, list[dict]] = {}
        for r in raw:
            buckets.setdefault(tuple(str(r.get(k) if r.get(k) is not None else "—") for k in keys), []).append(r)
        for gkey, members in buckets.items():
            label = " · ".join(gkey)
            members_rows = [data_row(m) for m in members]
            sub = summary("subtotal", members, f"{label} subtotal", level=1) if any(f.agg for f in fields) else None
            groups.append(Group(label, "|".join(gkey), members_rows, sub, len(members)))
            rows.extend(members_rows)
            if sub:
                rows.append(sub)
    else:
        rows = [data_row(r) for r in raw]
    total = summary("total", raw, "Total") if spec.total and raw and any(f.agg for f in fields) else None
    if total:
        rows.append(total)
    return rows, groups, total


def _chart(spec: Dataset, fields: tuple[Field, ...], raw: list[dict]) -> dict | None:
    c = spec.chart
    if not c or not raw:
        return None
    by_key = {f.key: f for f in fields}
    labels: list[str] = []
    for r in raw:
        x = str(r.get(c.x) or "")
        if x not in labels:
            labels.append(x)
    datasets = []
    series_values = sorted({str(r.get(c.series) or "") for r in raw}) if c.series else [""]
    for y in c.y:
        f = by_key.get(y)
        if not f:
            continue
        for s in series_values:
            points = {str(r.get(c.x) or ""): typed(f, r) for r in raw if not c.series or str(r.get(c.series) or "") == s}
            data = [points.get(x) if isinstance(points.get(x), (int, float)) else None for x in labels]
            if f.type == PCT:
                data = [round(v * 100, 2) if v is not None else None for v in data]
            datasets.append({"label": f"{f.label}{' · ' + s if s else ''}", "data": data})
    return {"kind": c.kind, "labels": labels, "datasets": datasets, "title": c.title}


def run(report: Report, params: dict[str, str], *, group_overrides: dict[str, tuple[str, ...]] | None = None,
        client: GoBFFClient | None = None) -> RunResult:
    client = client or GoBFFClient()
    group_overrides = group_overrides or {}
    responses: dict[tuple[str, str], Any] = {}
    errors: list[str] = []
    denied = False

    def fetch(source: tuple[str, str]) -> dict:
        nonlocal denied
        if source not in responses:
            kind, name = source
            query = dict(params)
            result = client.business_report(name, query) if kind == "business" else client.analytics_report(name, query)
            if not result.ok:
                if result.status_code == 403:
                    denied = True
                errors.append(result.error or "The report source is unavailable.")
            responses[source] = result.data if result.ok and isinstance(result.data, dict) else {}
        return responses[source]

    main = fetch(report.source)
    specs = list(report.datasets) + (_auto_datasets(main) if report.auto_tables else [])
    out: list[DatasetResult] = []
    for spec in specs:
        data = fetch(spec.source) if spec.source else main
        raw = _rows_at(data, spec.path)
        truncated = len(raw) > MAX_ROWS
        raw = raw[:MAX_ROWS]
        fields = spec.fields
        allowed = set(spec.groupable) | set(spec.group_by)
        group_by = tuple(k for k in group_overrides.get(spec.key, spec.group_by) if k in allowed)
        rows, groups, total = _build_rows(spec, fields, raw, group_by, params)
        mixed = len({str(r.get("currency") or "") for r in raw} - {""}) > 1
        out.append(DatasetResult(spec, fields, group_by, rows, groups, total, raw, truncated,
                                 chart=_chart(spec, fields, raw), mixed_currency=mixed))
    return RunResult(report, params, out, errors=list(dict.fromkeys(errors)), denied=denied)
