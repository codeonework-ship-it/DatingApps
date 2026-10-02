package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
)

// Uniform paging, search, date-range and sort contract for the admin list
// endpoints. Every list reads the same query parameters:
//
//	limit   1..spec.MaxLimit; missing, malformed or < 1 means spec.DefaultLimit
//	offset  >= 0, capped at adminListMaxOffset
//	q       trimmed, at most adminListMaxQueryRunes runes, matched with ILIKE
//	        on the endpoint's text columns with % and _ escaped
//	sort    one of spec.Sorts; anything else falls back to spec.DefaultSort
//	order   asc | desc; anything else falls back to spec.DefaultOrder (desc)
//	from    YYYY-MM-DD, inclusive, UTC, on the endpoint's primary timestamp
//	to      YYYY-MM-DD, inclusive, UTC (the SQL bound is < to + 1 day)
//
// and answers with its existing items key plus total (the count under the same
// WHERE), limit and offset.

const (
	adminListMaxOffset     = 100000
	adminListMaxQueryRunes = 200
	adminListDateLayout    = "2006-01-02"
)

// adminListSpec is one endpoint's paging contract.
type adminListSpec struct {
	DefaultLimit int
	MaxLimit     int
	// Sorts maps a public sort key to an SQL expression. "{dir}" inside the
	// expression is replaced by ASC or DESC; an expression without it gets the
	// direction appended. Only keys of this map ever reach SQL.
	Sorts       map[string]string
	DefaultSort string
	// DefaultOrder is "asc" or "desc"; empty means "desc".
	DefaultOrder string
	// TieBreak makes paging stable (e.g. "id {dir}"). Optional.
	TieBreak string
}

// adminListParams is the validated request.
type adminListParams struct {
	Limit  int
	Offset int
	Q      string
	Sort   string
	Order  string
	// From is the inclusive lower bound (start of the day, UTC); To is the
	// exclusive upper bound (start of the day after the requested date).
	From time.Time
	To   time.Time

	spec adminListSpec
}

var errAdminListBadDate = errors.New("from and to must be dates in YYYY-MM-DD form")

func parseAdminListParams(r *http.Request, spec adminListSpec) (adminListParams, error) {
	if spec.DefaultLimit < 1 {
		spec.DefaultLimit = 50
	}
	if spec.MaxLimit < spec.DefaultLimit {
		spec.MaxLimit = spec.DefaultLimit
	}
	values := r.URL.Query()
	p := adminListParams{spec: spec}
	p.Limit = boundedQueryLimit(r, spec.DefaultLimit, spec.MaxLimit)

	if offset, err := strconv.Atoi(strings.TrimSpace(values.Get("offset"))); err == nil {
		p.Offset = max(0, min(offset, adminListMaxOffset))
	}

	p.Q = strings.TrimSpace(truncateRunes(strings.TrimSpace(values.Get("q")), adminListMaxQueryRunes))

	p.Sort = spec.DefaultSort
	if key := strings.ToLower(strings.TrimSpace(values.Get("sort"))); key != "" {
		if _, ok := spec.Sorts[key]; ok {
			p.Sort = key
		}
	}
	if _, ok := spec.Sorts[p.Sort]; !ok {
		p.Sort = ""
	}

	p.Order = strings.ToLower(strings.TrimSpace(spec.DefaultOrder))
	if p.Order != "asc" {
		p.Order = "desc"
	}
	switch strings.ToLower(strings.TrimSpace(values.Get("order"))) {
	case "asc":
		p.Order = "asc"
	case "desc":
		p.Order = "desc"
	}

	var err error
	if p.From, err = parseAdminListDate(values.Get("from")); err != nil {
		return adminListParams{}, err
	}
	if p.To, err = parseAdminListDate(values.Get("to")); err != nil {
		return adminListParams{}, err
	}
	if !p.To.IsZero() {
		p.To = p.To.AddDate(0, 0, 1)
	}
	return p, nil
}

func parseAdminListDate(raw string) (time.Time, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return time.Time{}, nil
	}
	parsed, err := time.ParseInLocation(adminListDateLayout, raw, time.UTC)
	if err != nil {
		return time.Time{}, errAdminListBadDate
	}
	return parsed, nil
}

// escapeILIKE escapes the LIKE metacharacters so user text matches literally.
// Use it with ESCAPE '\' (sqlFilter.Search does).
func escapeILIKE(value string) string {
	return strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(value)
}

// direction is the SQL keyword for p.Order.
func (p adminListParams) direction() string {
	if p.Order == "asc" {
		return "ASC"
	}
	return "DESC"
}

// OrderBy returns the ORDER BY expression (without the keyword). It is built
// only from the spec's allow-list, never from request text.
func (p adminListParams) OrderBy() string {
	dir := p.direction()
	render := func(expr string) string {
		if strings.Contains(expr, "{dir}") {
			return strings.ReplaceAll(expr, "{dir}", dir)
		}
		return expr + " " + dir
	}
	parts := []string{}
	if expr, ok := p.spec.Sorts[p.Sort]; ok && strings.TrimSpace(expr) != "" {
		parts = append(parts, render(expr))
	}
	if strings.TrimSpace(p.spec.TieBreak) != "" {
		parts = append(parts, render(p.spec.TieBreak))
	}
	return strings.Join(parts, ", ")
}

// LimitOffset is the paging suffix; both values are validated integers.
func (p adminListParams) LimitOffset() string {
	return fmt.Sprintf(" LIMIT %d OFFSET %d", p.Limit, p.Offset)
}

// Page adds total, limit and offset to an existing response.
func (p adminListParams) Page(resp map[string]any, total int) map[string]any {
	if resp == nil {
		resp = map[string]any{}
	}
	resp["total"] = total
	resp["limit"] = p.Limit
	resp["offset"] = p.Offset
	return resp
}

// InRange reports whether t falls inside [From, To) (an unset bound is open).
func (p adminListParams) InRange(t time.Time) bool {
	if !p.From.IsZero() && t.Before(p.From) {
		return false
	}
	if !p.To.IsZero() && !t.Before(p.To) {
		return false
	}
	return true
}

// sqlFilter builds a WHERE clause with numbered ($n) arguments.
type sqlFilter struct {
	clauses []string
	args    []any
}

func newSQLFilter(clauses ...string) *sqlFilter {
	f := &sqlFilter{}
	for _, clause := range clauses {
		if strings.TrimSpace(clause) != "" {
			f.clauses = append(f.clauses, clause)
		}
	}
	return f
}

// Arg binds a value and returns its placeholder.
func (f *sqlFilter) Arg(value any) string {
	f.args = append(f.args, value)
	return "$" + strconv.Itoa(len(f.args))
}

// Where adds a raw clause; bind its values with Arg first.
func (f *sqlFilter) Where(clause string) *sqlFilter {
	if strings.TrimSpace(clause) != "" {
		f.clauses = append(f.clauses, clause)
	}
	return f
}

// Eq adds column = value when value is not blank.
func (f *sqlFilter) Eq(column, value string) *sqlFilter {
	value = strings.TrimSpace(value)
	if value == "" {
		return f
	}
	return f.Where(column + " = " + f.Arg(value))
}

// UUIDEq adds column = value for a uuid column. A blank value adds nothing; a
// malformed one matches no rows (and never reaches a ::uuid cast).
func (f *sqlFilter) UUIDEq(column, value string) *sqlFilter {
	value = strings.TrimSpace(value)
	if value == "" {
		return f
	}
	if !uuidPattern.MatchString(value) {
		return f.Where("FALSE")
	}
	return f.Eq(column, strings.ToLower(value))
}

// Search ORs column ILIKE %q% across the columns when q is not blank.
func (f *sqlFilter) Search(q string, columns ...string) *sqlFilter {
	q = strings.TrimSpace(q)
	if q == "" || len(columns) == 0 {
		return f
	}
	placeholder := f.Arg("%" + escapeILIKE(q) + "%")
	parts := make([]string, 0, len(columns))
	for _, column := range columns {
		parts = append(parts, column+` ILIKE `+placeholder+` ESCAPE '\'`)
	}
	return f.Where("(" + strings.Join(parts, " OR ") + ")")
}

// TimeRange bounds column by the request's from/to dates.
func (f *sqlFilter) TimeRange(column string, p adminListParams) *sqlFilter {
	if !p.From.IsZero() {
		f.Where(column + " >= " + f.Arg(p.From))
	}
	if !p.To.IsZero() {
		f.Where(column + " < " + f.Arg(p.To))
	}
	return f
}

// Conditions is the AND of every clause, or TRUE.
func (f *sqlFilter) Conditions() string {
	if len(f.clauses) == 0 {
		return "TRUE"
	}
	return strings.Join(f.clauses, " AND ")
}

// SQL is " WHERE <conditions>", or "" without clauses.
func (f *sqlFilter) SQL() string {
	if len(f.clauses) == 0 {
		return ""
	}
	return " WHERE " + f.Conditions()
}

func (f *sqlFilter) Args() []any { return append([]any(nil), f.args...) }

type adminPageQueryer interface {
	QueryContext(context.Context, string, ...any) (*sql.Rows, error)
	QueryRowContext(context.Context, string, ...any) *sql.Row
}

// queryAdminPage counts `fromSQL + WHERE` and then runs
// `SELECT selectSQL fromSQL WHERE ... ORDER BY ... LIMIT ... OFFSET ...`,
// handing each row to scan. fromSQL starts with " FROM".
func queryAdminPage(
	ctx context.Context,
	db adminPageQueryer,
	selectSQL, fromSQL string,
	filter *sqlFilter,
	p adminListParams,
	scan func(*sql.Rows) error,
) (int, error) {
	where := filter.SQL()
	args := filter.Args()
	var total int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*)`+fromSQL+where, args...).Scan(&total); err != nil {
		return 0, err
	}
	if total == 0 || p.Offset >= total {
		return total, nil
	}
	query := `SELECT ` + selectSQL + fromSQL + where
	if order := p.OrderBy(); order != "" {
		query += ` ORDER BY ` + order
	}
	rows, err := db.QueryContext(ctx, query+p.LimitOffset(), args...)
	if err != nil {
		return 0, err
	}
	defer rows.Close()
	for rows.Next() {
		if err := scan(rows); err != nil {
			return 0, err
		}
	}
	return total, rows.Err()
}

// queryAdminMapPage is queryAdminPage for list endpoints that return plain
// column maps. Values are normalised the way the local data-access client
// normalises them (UTC RFC 3339 timestamps, JSON numbers, decoded JSON), so a
// response keeps its shape whichever path produced it.
func queryAdminMapPage(
	ctx context.Context,
	db adminPageQueryer,
	selectSQL, fromSQL string,
	filter *sqlFilter,
	p adminListParams,
) ([]map[string]any, int, error) {
	items := make([]map[string]any, 0)
	var columns []*sql.ColumnType
	total, err := queryAdminPage(ctx, db, selectSQL, fromSQL, filter, p, func(rows *sql.Rows) error {
		if columns == nil {
			var err error
			if columns, err = rows.ColumnTypes(); err != nil {
				return err
			}
		}
		item, err := scanAdminRowMap(rows, columns)
		if err != nil {
			return err
		}
		items = append(items, item)
		return nil
	})
	if err != nil {
		return nil, 0, err
	}
	return items, total, nil
}

func scanAdminRowMap(rows *sql.Rows, columns []*sql.ColumnType) (map[string]any, error) {
	values := make([]any, len(columns))
	targets := make([]any, len(columns))
	for i := range values {
		targets[i] = &values[i]
	}
	if err := rows.Scan(targets...); err != nil {
		return nil, err
	}
	item := make(map[string]any, len(columns))
	for i, column := range columns {
		item[column.Name()] = normalizeAdminSQLValue(values[i], column.DatabaseTypeName())
	}
	return item, nil
}

func normalizeAdminSQLValue(value any, dbType string) any {
	switch typed := value.(type) {
	case nil:
		return nil
	case time.Time:
		return typed.UTC().Format(time.RFC3339Nano)
	case int64:
		return float64(typed)
	case int32:
		return float64(typed)
	case []byte:
		switch strings.ToUpper(dbType) {
		case "JSON", "JSONB":
			var decoded any
			if err := json.Unmarshal(typed, &decoded); err == nil {
				return decoded
			}
		}
		return string(typed)
	case string:
		if strings.EqualFold(dbType, "NUMERIC") {
			if parsed, err := strconv.ParseFloat(typed, 64); err == nil {
				return parsed
			}
		}
		return typed
	}
	return value
}

// adminUUIDParam returns a lower-cased UUID query parameter, "" when absent,
// or an error when present but malformed (so a typo never matches nothing
// silently and never reaches a ::uuid cast).
func adminUUIDParam(r *http.Request, key string) (string, error) {
	value := strings.TrimSpace(r.URL.Query().Get(key))
	if value == "" {
		return "", nil
	}
	if !uuidPattern.MatchString(value) {
		return "", fmt.Errorf("%s must be a UUID", key)
	}
	return strings.ToLower(value), nil
}
