"""Declarative report definitions (the console's report server).

A ``Report`` names a Go source (an /admin/business/... or /admin/analytics/...
report), the parameters an operator may set, and the datasets to show. Each
``Dataset`` points at a list of rows in the Go response and declares typed
``Field``s, so one definition drives the HTML report, its groups and
subtotals, its chart, and the Excel, CSV and PDF exports.

Go defines and computes every number; the report server only selects,
groups, totals, formats and exports what Go returned.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Callable

# Field types: how a value is typed in Excel and shown on screen.
TEXT, INT, NUMBER, MONEY, PCT, DATE, BOOL = "text", "int", "number", "money", "pct", "date", "bool"
# Aggregates for subtotal and total rows.
SUM, AVG, MIN, MAX, NONE = "sum", "avg", "min", "max", ""


@dataclass(frozen=True)
class Param:
    name: str
    label: str
    kind: str = "choice"  # choice | date | int
    choices: tuple[tuple[str, str], ...] = ()
    default: str = ""
    help: str = ""
    min: int | None = None
    max: int | None = None


@dataclass(frozen=True)
class Field:
    key: str
    label: str
    type: str = TEXT
    agg: str = NONE
    # Money: Go sends display strings and/or integer minor units.
    minor: str = ""
    # Read the value some other way (nested values, lists).
    get: Callable[[dict], Any] | None = None
    # Drill-through: (report id, {param: field key}) or a console URL name.
    drill: tuple[str, dict[str, str]] | None = None
    width: int = 14


@dataclass(frozen=True)
class Chart:
    kind: str  # line | bar
    x: str  # field key on the x axis
    y: tuple[str, ...]  # field keys plotted
    series: str = ""  # optional field splitting lines (e.g. currency)
    title: str = ""


@dataclass(frozen=True)
class Dataset:
    key: str
    title: str
    path: tuple[str, ...]  # where the rows list sits in Go's response
    fields: tuple[Field, ...]
    group_by: tuple[str, ...] = ()  # default grouping (operator can change)
    groupable: tuple[str, ...] = ()  # fields offered in "Group by"
    total: bool = True  # grand total row when any field aggregates
    note: str = ""
    chart: Chart | None = None
    # A dataset read from a different Go report than its report's source.
    source: tuple[str, str] | None = None


@dataclass(frozen=True)
class Report:
    id: str
    title: str
    category: str
    description: str
    source: tuple[str, str]  # ("business", "revenue") | ("analytics", "retention")
    params: tuple[Param, ...] = ()
    datasets: tuple[Dataset, ...] = ()
    # Analytics reports describe their own tables; take them all.
    auto_tables: bool = False
    definitions_url: str = ""
    keywords: tuple[str, ...] = field(default_factory=tuple)

    @property
    def admin_path(self) -> str:
        """Go route relative to /v1/admin/, for role checks."""
        kind, name = self.source
        return f"{kind}/{name}"
