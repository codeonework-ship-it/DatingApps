package postgresdata

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"reflect"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Client implements the small CRUD surface used by the runtime repositories,
// directly against PostgreSQL. It deliberately mirrors the existing repository
// transport contract so modules can move off PostgREST without rewriting their
// domain mapping code.
type Client struct {
	pool      *pgxpool.Pool
	untrackFn func()
}

type Options struct {
	StatementTimeout       time.Duration
	LockTimeout            time.Duration
	IdleTransactionTimeout time.Duration
	MaxConns               int32
	MinConns               int32
	// PoolName labels the pool's verified_dating_db_pool_* metrics. Empty
	// means "<package dir>/<file>" of the caller.
	PoolName string
}

var identifierPattern = regexp.MustCompile(`^[A-Za-z_][A-Za-z0-9_]*$`)

func Open(ctx context.Context, databaseURL string, options ...Options) (*Client, error) {
	if strings.TrimSpace(databaseURL) == "" {
		return nil, errors.New("database URL is required")
	}
	cfg, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("parse postgres configuration: %w", err)
	}
	settings := Options{
		StatementTimeout:       5 * time.Second,
		LockTimeout:            time.Second,
		IdleTransactionTimeout: 15 * time.Second,
		MaxConns:               16,
		MinConns:               2,
	}
	if len(options) > 0 {
		settings = options[0]
	}
	name := poolName(settings.PoolName, 1)
	if settings.MaxConns <= 0 {
		settings.MaxConns = 16
	}
	if settings.MinConns < 0 {
		settings.MinConns = 0
	}
	if settings.MinConns > settings.MaxConns {
		settings.MinConns = settings.MaxConns
	}
	cfg.MaxConns = settings.MaxConns
	cfg.MinConns = settings.MinConns
	cfg.MaxConnLifetime = 30 * time.Minute
	cfg.MaxConnIdleTime = 5 * time.Minute
	cfg.HealthCheckPeriod = 30 * time.Second
	setRuntimeTimeout(cfg.ConnConfig.RuntimeParams, "statement_timeout", settings.StatementTimeout)
	setRuntimeTimeout(cfg.ConnConfig.RuntimeParams, "lock_timeout", settings.LockTimeout)
	setRuntimeTimeout(cfg.ConnConfig.RuntimeParams, "idle_in_transaction_session_timeout", settings.IdleTransactionTimeout)

	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("open postgres pool: %w", err)
	}
	client := &Client{pool: pool}
	if err := client.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	client.untrackFn = trackPgxPool(name, pool)
	return client, nil
}

func (c *Client) Ping(ctx context.Context) error {
	if c == nil || c.pool == nil {
		return errors.New("postgres client is not configured")
	}
	if err := c.pool.Ping(ctx); err != nil {
		return fmt.Errorf("ping postgres: %w", err)
	}
	return nil
}

func (c *Client) Close() {
	if c != nil && c.untrackFn != nil {
		c.untrackFn()
		c.untrackFn = nil
	}
	if c != nil && c.pool != nil {
		c.pool.Close()
	}
}

func (c *Client) Select(ctx context.Context, schema, table string, params url.Values) ([]map[string]any, error) {
	return c.selectRows(ctx, schema, table, params)
}

func (c *Client) SelectRead(ctx context.Context, schema, table string, params url.Values) ([]map[string]any, error) {
	return c.selectRows(ctx, schema, table, params)
}

func (c *Client) selectRows(ctx context.Context, schema, table string, params url.Values) ([]map[string]any, error) {
	qualified, err := qualifiedTable(schema, table)
	if err != nil {
		return nil, err
	}
	selectSQL, err := buildSelectList(params.Get("select"))
	if err != nil {
		return nil, err
	}
	whereSQL, args, err := buildWhere(params, 1)
	if err != nil {
		return nil, err
	}
	orderSQL, err := buildOrder(params.Get("order"))
	if err != nil {
		return nil, err
	}
	limitSQL, err := buildLimitOffset(params)
	if err != nil {
		return nil, err
	}
	query := "SELECT " + selectSQL + " FROM " + qualified + whereSQL + orderSQL + limitSQL
	return c.queryMaps(ctx, query, args...)
}

func (c *Client) Insert(ctx context.Context, schema, table string, payload any) ([]map[string]any, error) {
	rows, err := payloadRows(payload)
	if err != nil || len(rows) == 0 {
		return nil, err
	}
	query, args, err := buildInsert(schema, table, rows, "")
	if err != nil {
		return nil, err
	}
	return c.queryMaps(ctx, query, args...)
}

func (c *Client) Upsert(ctx context.Context, schema, table string, payload any, onConflict string) ([]map[string]any, error) {
	rows, err := payloadRows(payload)
	if err != nil || len(rows) == 0 {
		return nil, err
	}
	query, args, err := buildInsert(schema, table, rows, onConflict)
	if err != nil {
		return nil, err
	}
	return c.queryMaps(ctx, query, args...)
}

func (c *Client) Update(ctx context.Context, schema, table string, payload any, filters url.Values) ([]map[string]any, error) {
	qualified, err := qualifiedTable(schema, table)
	if err != nil {
		return nil, err
	}
	values, err := payloadMap(payload)
	if err != nil {
		return nil, err
	}
	columns := sortedKeys(values)
	if len(columns) == 0 {
		return nil, errors.New("update payload must not be empty")
	}
	args := make([]any, 0, len(columns))
	sets := make([]string, 0, len(columns))
	for _, column := range columns {
		quoted, err := quoteIdentifier(column)
		if err != nil {
			return nil, err
		}
		args = append(args, values[column])
		sets = append(sets, fmt.Sprintf("%s = $%d", quoted, len(args)))
	}
	whereSQL, whereArgs, err := buildWhere(filters, len(args)+1)
	if err != nil {
		return nil, err
	}
	if whereSQL == "" {
		return nil, errors.New("refusing unfiltered update")
	}
	args = append(args, whereArgs...)
	query := "UPDATE " + qualified + " SET " + strings.Join(sets, ", ") + whereSQL + " RETURNING *"
	return c.queryMaps(ctx, query, args...)
}

func (c *Client) Delete(ctx context.Context, schema, table string, filters url.Values) ([]map[string]any, error) {
	qualified, err := qualifiedTable(schema, table)
	if err != nil {
		return nil, err
	}
	whereSQL, args, err := buildWhere(filters, 1)
	if err != nil {
		return nil, err
	}
	if whereSQL == "" {
		return nil, errors.New("refusing unfiltered delete")
	}
	return c.queryMaps(ctx, "DELETE FROM "+qualified+whereSQL+" RETURNING *", args...)
}

func (c *Client) queryMaps(ctx context.Context, query string, args ...any) ([]map[string]any, error) {
	if c == nil || c.pool == nil {
		return nil, errors.New("postgres client is not configured")
	}
	rows, err := c.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, classifyQueryError(err)
	}
	result, err := pgx.CollectRows(rows, pgx.RowToMap)
	if err != nil {
		return nil, err
	}
	for _, row := range result {
		for key, value := range row {
			row[key] = normalizeValue(value)
		}
	}
	return result, nil
}

func setRuntimeTimeout(params map[string]string, name string, value time.Duration) {
	if value <= 0 {
		return
	}
	params[name] = strconv.FormatInt(value.Milliseconds(), 10)
}

func classifyQueryError(err error) error {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return err
	}
	kind := ""
	switch pgErr.Code {
	case "57014":
		kind = "statement_timeout"
	case "55P03":
		kind = "lock_timeout"
	case "40P01":
		kind = "deadlock"
	}
	if kind == "" {
		return err
	}
	return fmt.Errorf("postgres_query_failure kind=%s sqlstate=%s: %w", kind, pgErr.Code, err)
}

func buildInsert(schema, table string, rows []map[string]any, onConflict string) (string, []any, error) {
	qualified, err := qualifiedTable(schema, table)
	if err != nil {
		return "", nil, err
	}
	columns := sortedKeys(rows[0])
	if len(columns) == 0 {
		return "", nil, errors.New("insert payload must not be empty")
	}
	quotedColumns := make([]string, len(columns))
	for i, column := range columns {
		quotedColumns[i], err = quoteIdentifier(column)
		if err != nil {
			return "", nil, err
		}
	}
	args := make([]any, 0, len(rows)*len(columns))
	valueGroups := make([]string, 0, len(rows))
	for _, row := range rows {
		if !sameKeys(columns, row) {
			return "", nil, errors.New("all insert rows must contain identical columns")
		}
		placeholders := make([]string, len(columns))
		for i, column := range columns {
			args = append(args, row[column])
			placeholders[i] = fmt.Sprintf("$%d", len(args))
		}
		valueGroups = append(valueGroups, "("+strings.Join(placeholders, ", ")+")")
	}
	query := "INSERT INTO " + qualified + " (" + strings.Join(quotedColumns, ", ") + ") VALUES " + strings.Join(valueGroups, ", ")
	if strings.TrimSpace(onConflict) != "" {
		conflictColumns, err := parseIdentifierList(onConflict)
		if err != nil {
			return "", nil, fmt.Errorf("invalid conflict target: %w", err)
		}
		conflictSet := make(map[string]struct{}, len(conflictColumns))
		quotedConflict := make([]string, len(conflictColumns))
		for i, column := range conflictColumns {
			conflictSet[column] = struct{}{}
			quotedConflict[i], _ = quoteIdentifier(column)
		}
		updates := make([]string, 0, len(columns))
		for _, column := range columns {
			if _, conflict := conflictSet[column]; conflict {
				continue
			}
			quoted, _ := quoteIdentifier(column)
			updates = append(updates, quoted+" = EXCLUDED."+quoted)
		}
		query += " ON CONFLICT (" + strings.Join(quotedConflict, ", ") + ") "
		if len(updates) == 0 {
			query += "DO NOTHING"
		} else {
			query += "DO UPDATE SET " + strings.Join(updates, ", ")
		}
	}
	return query + " RETURNING *", args, nil
}

func buildWhere(params url.Values, placeholderStart int) (string, []any, error) {
	if params == nil {
		return "", nil, nil
	}
	keys := make([]string, 0, len(params))
	for key := range params {
		if isControlParameter(key) {
			continue
		}
		keys = append(keys, key)
	}
	sort.Strings(keys)
	clauses := make([]string, 0, len(keys))
	args := make([]any, 0, len(keys))
	for _, key := range keys {
		value := params.Get(key)
		if key == "or" {
			clause, clauseArgs, err := parseOrFilter(value, placeholderStart+len(args))
			if err != nil {
				return "", nil, err
			}
			clauses = append(clauses, clause)
			args = append(args, clauseArgs...)
			continue
		}
		clause, clauseArgs, err := parseFilter(key, value, placeholderStart+len(args))
		if err != nil {
			return "", nil, err
		}
		clauses = append(clauses, clause)
		args = append(args, clauseArgs...)
	}
	if len(clauses) == 0 {
		return "", args, nil
	}
	return " WHERE " + strings.Join(clauses, " AND "), args, nil
}

func parseFilter(column, expression string, placeholderStart int) (string, []any, error) {
	quoted, err := quoteIdentifier(column)
	if err != nil {
		return "", nil, err
	}
	operator, raw, found := strings.Cut(expression, ".")
	if !found {
		return "", nil, fmt.Errorf("invalid filter for %s", column)
	}
	switch operator {
	case "eq", "neq", "gt", "gte", "lt", "lte":
		sqlOperator := map[string]string{"eq": "=", "neq": "<>", "gt": ">", "gte": ">=", "lt": "<", "lte": "<="}[operator]
		return fmt.Sprintf("%s %s $%d", quoted, sqlOperator, placeholderStart), []any{raw}, nil
	case "like", "ilike":
		raw = strings.ReplaceAll(raw, "*", "%")
		return fmt.Sprintf("%s %s $%d", quoted, strings.ToUpper(operator), placeholderStart), []any{raw}, nil
	case "is":
		switch raw {
		case "null":
			return quoted + " IS NULL", nil, nil
		case "true", "false":
			return quoted + " IS " + strings.ToUpper(raw), nil, nil
		default:
			return "", nil, fmt.Errorf("unsupported is filter %q", raw)
		}
	case "not":
		if raw == "is.null" {
			return quoted + " IS NOT NULL", nil, nil
		}
		return "", nil, fmt.Errorf("unsupported not filter %q", raw)
	case "in":
		values := splitList(raw)
		if len(values) == 0 {
			return "FALSE", nil, nil
		}
		placeholders := make([]string, len(values))
		args := make([]any, len(values))
		for i, value := range values {
			placeholders[i] = fmt.Sprintf("$%d", placeholderStart+i)
			args[i] = value
		}
		return quoted + " IN (" + strings.Join(placeholders, ", ") + ")", args, nil
	case "cs":
		return fmt.Sprintf("%s @> $%d", quoted, placeholderStart), []any{raw}, nil
	default:
		return "", nil, fmt.Errorf("unsupported filter operator %q", operator)
	}
}

func parseOrFilter(expression string, placeholderStart int) (string, []any, error) {
	parts := splitList(expression)
	if len(parts) == 0 {
		return "", nil, errors.New("or filter must not be empty")
	}
	clauses := make([]string, 0, len(parts))
	args := make([]any, 0, len(parts))
	for _, part := range parts {
		segments := strings.SplitN(part, ".", 2)
		if len(segments) != 2 {
			return "", nil, fmt.Errorf("invalid or filter %q", part)
		}
		clause, clauseArgs, err := parseFilter(segments[0], segments[1], placeholderStart+len(args))
		if err != nil {
			return "", nil, err
		}
		clauses = append(clauses, clause)
		args = append(args, clauseArgs...)
	}
	return "(" + strings.Join(clauses, " OR ") + ")", args, nil
}

func buildSelectList(raw string) (string, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" || raw == "*" {
		return "*", nil
	}
	columns, err := parseIdentifierList(raw)
	if err != nil {
		return "", err
	}
	quoted := make([]string, len(columns))
	for i, column := range columns {
		quoted[i], _ = quoteIdentifier(column)
	}
	return strings.Join(quoted, ", "), nil
}

func buildOrder(raw string) (string, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return "", nil
	}
	parts := strings.Split(raw, ",")
	orders := make([]string, 0, len(parts))
	for _, part := range parts {
		segments := strings.Split(strings.TrimSpace(part), ".")
		quoted, err := quoteIdentifier(segments[0])
		if err != nil {
			return "", err
		}
		direction := "ASC"
		if len(segments) > 1 {
			direction = strings.ToUpper(segments[1])
			if direction != "ASC" && direction != "DESC" {
				return "", fmt.Errorf("invalid order direction %q", direction)
			}
		}
		orders = append(orders, quoted+" "+direction)
	}
	return " ORDER BY " + strings.Join(orders, ", "), nil
}

func buildLimitOffset(params url.Values) (string, error) {
	if params == nil {
		return "", nil
	}
	result := ""
	if raw := strings.TrimSpace(params.Get("limit")); raw != "" {
		value, err := strconv.Atoi(raw)
		if err != nil || value < 0 || value > 10000 {
			return "", fmt.Errorf("invalid limit %q", raw)
		}
		result += fmt.Sprintf(" LIMIT %d", value)
	}
	if raw := strings.TrimSpace(params.Get("offset")); raw != "" {
		value, err := strconv.Atoi(raw)
		if err != nil || value < 0 {
			return "", fmt.Errorf("invalid offset %q", raw)
		}
		result += fmt.Sprintf(" OFFSET %d", value)
	}
	return result, nil
}

func payloadRows(payload any) ([]map[string]any, error) {
	switch typed := payload.(type) {
	case []map[string]any:
		return typed, nil
	case map[string]any:
		return []map[string]any{typed}, nil
	default:
		return nil, fmt.Errorf("unsupported payload type %T", payload)
	}
}

func payloadMap(payload any) (map[string]any, error) {
	if values, ok := payload.(map[string]any); ok {
		return values, nil
	}
	return nil, fmt.Errorf("unsupported update payload type %T", payload)
}

func qualifiedTable(schema, table string) (string, error) {
	if strings.TrimSpace(schema) == "" {
		schema = "public"
	}
	quotedSchema, err := quoteIdentifier(schema)
	if err != nil {
		return "", err
	}
	quotedTable, err := quoteIdentifier(table)
	if err != nil {
		return "", err
	}
	return quotedSchema + "." + quotedTable, nil
}

func quoteIdentifier(value string) (string, error) {
	value = strings.TrimSpace(value)
	if !identifierPattern.MatchString(value) {
		return "", fmt.Errorf("invalid SQL identifier %q", value)
	}
	return `"` + value + `"`, nil
}

func parseIdentifierList(raw string) ([]string, error) {
	parts := strings.Split(raw, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if _, err := quoteIdentifier(part); err != nil {
			return nil, err
		}
		result = append(result, part)
	}
	if len(result) == 0 {
		return nil, errors.New("identifier list must not be empty")
	}
	return result, nil
}

func splitList(raw string) []string {
	raw = strings.TrimSpace(raw)
	if len(raw) >= 2 && raw[0] == '(' && raw[len(raw)-1] == ')' {
		raw = raw[1 : len(raw)-1]
	}
	if len(raw) >= 2 && raw[0] == '{' && raw[len(raw)-1] == '}' {
		raw = raw[1 : len(raw)-1]
	}
	if strings.TrimSpace(raw) == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.Trim(strings.TrimSpace(part), `"`)
		if part != "" {
			result = append(result, part)
		}
	}
	return result
}

func sortedKeys(values map[string]any) []string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func sameKeys(expected []string, values map[string]any) bool {
	if len(expected) != len(values) {
		return false
	}
	for _, key := range expected {
		if _, ok := values[key]; !ok {
			return false
		}
	}
	return true
}

func isControlParameter(key string) bool {
	switch key {
	case "select", "order", "limit", "offset":
		return true
	default:
		return false
	}
}

func normalizeValue(value any) any {
	if normalizedUUID, ok := normalizeUUID(value); ok {
		return normalizedUUID
	}
	switch typed := value.(type) {
	case nil, string, bool, float64:
		return typed
	case time.Time:
		return typed.UTC().Format(time.RFC3339Nano)
	case uuid.UUID:
		return typed.String()
	case []byte:
		return string(typed)
	case int:
		return float64(typed)
	case int8:
		return float64(typed)
	case int16:
		return float64(typed)
	case int32:
		return float64(typed)
	case int64:
		return float64(typed)
	case uint:
		return float64(typed)
	case uint8:
		return float64(typed)
	case uint16:
		return float64(typed)
	case uint32:
		return float64(typed)
	case uint64:
		return float64(typed)
	case map[string]any:
		for key, nested := range typed {
			typed[key] = normalizeValue(nested)
		}
		return typed
	case []any:
		for i, nested := range typed {
			typed[i] = normalizeValue(nested)
		}
		return typed
	}
	rv := reflect.ValueOf(value)
	if rv.IsValid() && (rv.Kind() == reflect.Slice || rv.Kind() == reflect.Array) {
		result := make([]any, rv.Len())
		for i := 0; i < rv.Len(); i++ {
			result[i] = normalizeValue(rv.Index(i).Interface())
		}
		return result
	}
	return fmt.Sprint(value)
}

func normalizeUUID(value any) (string, bool) {
	rv := reflect.ValueOf(value)
	if !rv.IsValid() || rv.Kind() != reflect.Array || rv.Len() != 16 || rv.Type().Elem().Kind() != reflect.Uint8 {
		return "", false
	}
	bytes := make([]byte, 16)
	for i := 0; i < rv.Len(); i++ {
		bytes[i] = byte(rv.Index(i).Uint())
	}
	parsed, err := uuid.FromBytes(bytes)
	if err != nil {
		return "", false
	}
	return parsed.String(), true
}
