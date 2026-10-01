package observability

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"testing"

	"go.yaml.in/yaml/v4"
)

const (
	rulesDir       = "../../../observability/prometheus/rules"
	dashboardsDir  = "../../../observability/grafana/dashboards"
	provisioning   = "../../../observability/grafana/provisioning"
	runbookDoc     = "../../../../documents/MONITORING_RUNBOOKS_2026-10-01.md"
	diskUsageProm  = "../../../../deploy/monitoring/scripts/connect-disk-usage.sh"
	prometheusConf = "../../../../deploy/monitoring/prometheus/prometheus.yml"
)

type ruleFile struct {
	Groups []struct {
		Name     string `yaml:"name"`
		Interval string `yaml:"interval"`
		Rules    []struct {
			Alert       string            `yaml:"alert"`
			Record      string            `yaml:"record"`
			Expr        string            `yaml:"expr"`
			For         string            `yaml:"for"`
			Labels      map[string]string `yaml:"labels"`
			Annotations map[string]string `yaml:"annotations"`
		} `yaml:"rules"`
	} `yaml:"groups"`
}

var (
	metricRefPattern = regexp.MustCompile(`\bverified_dating[a-zA-Z0-9_:]*`)
	// Strip string literals so label values (routes, regexes) are not read as metric names.
	stringLiteralPattern = regexp.MustCompile(`"(?:[^"\\]|\\.)*"`)
	allowedSeverities    = map[string]bool{"page": true, "ticket": true, "none": true}
	allowedOwners        = map[string]bool{"backend-oncall": true, "platform-oncall": true, "progression-oncall": true, "trust-safety-oncall": true}
)

// knownMetricNames is every verified_dating_* family registered by Go code,
// plus the node_exporter textfile series written by the deploy kit.
func knownMetricNames(t *testing.T) map[string]bool {
	t.Helper()
	names := map[string]bool{}
	merge := func(more map[string]bool) {
		for name := range more {
			names[name] = true
		}
	}
	bff := newCapture()
	NewBFFMetrics(bff)
	merge(describedNames(t, bff))
	gateway := newCapture()
	NewGatewayMetrics(gateway)
	merge(describedNames(t, gateway))
	grpc := newCapture()
	NewGRPCMetrics(grpc)
	merge(describedNames(t, grpc))
	process := newCapture()
	RegisterProcessMetrics(process, "test")
	merge(describedNames(t, process))

	script, err := os.ReadFile(diskUsageProm)
	if err != nil {
		t.Fatalf("disk usage textfile script: %v", err)
	}
	for _, name := range metricRefPattern.FindAllString(string(script), -1) {
		names[name] = true
	}
	return names
}

func metricExists(name string, known, recorded map[string]bool) bool {
	if strings.Contains(name, ":") {
		return recorded[name]
	}
	if known[name] {
		return true
	}
	for _, suffix := range []string{"_bucket", "_count", "_sum"} {
		if strings.HasSuffix(name, suffix) && known[strings.TrimSuffix(name, suffix)] {
			return true
		}
	}
	return false
}

func loadRuleFiles(t *testing.T) map[string]ruleFile {
	t.Helper()
	paths, err := filepath.Glob(filepath.Join(rulesDir, "*.yml"))
	if err != nil || len(paths) < 6 {
		t.Fatalf("expected the six rule files, found %v (%v)", paths, err)
	}
	files := map[string]ruleFile{}
	for _, path := range paths {
		raw, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		var parsed ruleFile
		if err := yaml.Unmarshal(raw, &parsed); err != nil {
			t.Fatalf("%s is not valid YAML: %v", path, err)
		}
		if len(parsed.Groups) == 0 {
			t.Fatalf("%s has no rule groups", path)
		}
		files[filepath.Base(path)] = parsed
	}
	return files
}

func TestAlertRulesAreCompleteAndReferenceRealMetrics(t *testing.T) {
	files := loadRuleFiles(t)
	known := knownMetricNames(t)

	recorded := map[string]bool{}
	for _, file := range files {
		for _, group := range file.Groups {
			for _, rule := range group.Rules {
				if rule.Record != "" {
					recorded[rule.Record] = true
				}
			}
		}
	}

	runbook, err := os.ReadFile(runbookDoc)
	if err != nil {
		t.Fatalf("runbook document missing: %v", err)
	}
	headings := map[string]bool{}
	for _, line := range strings.Split(string(runbook), "\n") {
		if strings.HasPrefix(line, "### ") {
			headings[strings.ToLower(strings.TrimSpace(strings.TrimPrefix(line, "### ")))] = true
		}
	}

	alerts := map[string]string{}
	for fileName, file := range files {
		groupNames := map[string]bool{}
		for _, group := range file.Groups {
			if groupNames[group.Name] {
				t.Fatalf("%s: duplicate group %s", fileName, group.Name)
			}
			groupNames[group.Name] = true
			for _, rule := range group.Rules {
				if strings.TrimSpace(rule.Expr) == "" {
					t.Fatalf("%s: rule %s%s has no expression", fileName, rule.Alert, rule.Record)
				}
				if strings.Count(rule.Expr, "(") != strings.Count(rule.Expr, ")") ||
					strings.Count(rule.Expr, "{") != strings.Count(rule.Expr, "}") {
					t.Fatalf("%s: unbalanced expression in %s%s", fileName, rule.Alert, rule.Record)
				}
				for _, ref := range metricRefPattern.FindAllString(stringLiteralPattern.ReplaceAllString(rule.Expr, `""`), -1) {
					if !metricExists(ref, known, recorded) {
						t.Fatalf("%s: %s%s references %s, which no collector, recording rule or textfile script defines", fileName, rule.Alert, rule.Record, ref)
					}
				}
				if rule.Alert == "" {
					continue
				}
				if previous, ok := alerts[rule.Alert]; ok {
					t.Fatalf("alert %s defined in both %s and %s", rule.Alert, previous, fileName)
				}
				alerts[rule.Alert] = fileName
				if !allowedSeverities[rule.Labels["severity"]] {
					t.Fatalf("%s: %s has severity %q", fileName, rule.Alert, rule.Labels["severity"])
				}
				if !allowedOwners[rule.Labels["owner"]] {
					t.Fatalf("%s: %s has owner %q", fileName, rule.Alert, rule.Labels["owner"])
				}
				for _, annotation := range []string{"summary", "description", "runbook_url"} {
					if strings.TrimSpace(rule.Annotations[annotation]) == "" {
						t.Fatalf("%s: %s is missing annotation %s", fileName, rule.Alert, annotation)
					}
				}
				wantRunbook := "/documents/MONITORING_RUNBOOKS_2026-10-01.md#" + strings.ToLower(rule.Alert)
				if rule.Annotations["runbook_url"] != wantRunbook {
					t.Fatalf("%s: %s runbook_url = %q, want %q", fileName, rule.Alert, rule.Annotations["runbook_url"], wantRunbook)
				}
				if !headings[strings.ToLower(rule.Alert)] {
					t.Fatalf("runbook has no '### %s' section", rule.Alert)
				}
			}
		}
	}
	if len(alerts) < 50 {
		t.Fatalf("expected the full alert catalogue, found %d alerts", len(alerts))
	}
	// Every runbook alert section belongs to a real alert (no stale docs).
	for heading := range headings {
		if strings.HasPrefix(heading, "verifieddating") {
			found := false
			for alert := range alerts {
				if strings.ToLower(alert) == heading {
					found = true
				}
			}
			if !found {
				t.Fatalf("runbook section %q has no matching alert", heading)
			}
		}
	}
}

func TestPrometheusConfigLoadsEveryRuleFileAndScrapesEveryJob(t *testing.T) {
	raw, err := os.ReadFile(prometheusConf)
	if err != nil {
		t.Fatal(err)
	}
	var cfg struct {
		Global        map[string]any `yaml:"global"`
		RuleFiles     []string       `yaml:"rule_files"`
		ScrapeConfigs []struct {
			JobName       string `yaml:"job_name"`
			StaticConfigs []struct {
				Targets []string `yaml:"targets"`
			} `yaml:"static_configs"`
		} `yaml:"scrape_configs"`
	}
	if err := yaml.Unmarshal(raw, &cfg); err != nil {
		t.Fatalf("prometheus.yml is not valid YAML: %v", err)
	}
	if len(cfg.RuleFiles) == 0 {
		t.Fatal("prometheus.yml loads no rule files")
	}
	jobs := map[string]bool{}
	for _, scrape := range cfg.ScrapeConfigs {
		jobs[scrape.JobName] = true
		for _, static := range scrape.StaticConfigs {
			for _, target := range static.Targets {
				if strings.HasPrefix(scrape.JobName, "connect-blackbox") {
					continue
				}
				if !strings.HasPrefix(target, "127.0.0.1:") {
					t.Fatalf("job %s scrapes %s; every exporter must be bound to loopback", scrape.JobName, target)
				}
			}
		}
	}
	// Jobs the alert rules select on must exist.
	files := loadRuleFiles(t)
	jobRef := regexp.MustCompile(`job=~?"([^"]+)"`)
	for name, file := range files {
		for _, group := range file.Groups {
			for _, rule := range group.Rules {
				for _, match := range jobRef.FindAllStringSubmatch(rule.Expr, -1) {
					pattern := regexp.MustCompile("^(?:" + match[1] + ")$")
					found := false
					for job := range jobs {
						if pattern.MatchString(job) {
							found = true
						}
					}
					if !found {
						t.Fatalf("%s: %s%s selects job %q, which prometheus.yml never scrapes", name, rule.Alert, rule.Record, match[1])
					}
				}
			}
		}
	}
}

func TestDashboardsAreValidAndProvisionedPerFolder(t *testing.T) {
	known := knownMetricNames(t)
	recorded := map[string]bool{}
	for _, file := range loadRuleFiles(t) {
		for _, group := range file.Groups {
			for _, rule := range group.Rules {
				if rule.Record != "" {
					recorded[rule.Record] = true
				}
			}
		}
	}
	provisioningText, err := os.ReadFile(filepath.Join(provisioning, "dashboards", "connect.yml"))
	if err != nil {
		t.Fatal(err)
	}
	var providers struct {
		Providers []struct {
			Folder  string `yaml:"folder"`
			Options struct {
				Path string `yaml:"path"`
			} `yaml:"options"`
		} `yaml:"providers"`
	}
	if err := yaml.Unmarshal(provisioningText, &providers); err != nil {
		t.Fatalf("dashboard provisioning is not valid YAML: %v", err)
	}
	provisioned := map[string]bool{}
	for _, provider := range providers.Providers {
		if !strings.HasPrefix(provider.Options.Path, "${GRAFANA_DASHBOARDS_DIR}/") {
			t.Fatalf("provider %s must load an installed directory, got %s", provider.Folder, provider.Options.Path)
		}
		provisioned[strings.TrimPrefix(provider.Options.Path, "${GRAFANA_DASHBOARDS_DIR}/")] = true
	}

	entries, err := os.ReadDir(dashboardsDir)
	if err != nil {
		t.Fatal(err)
	}
	uids := map[string]string{}
	var dirs []string
	for _, entry := range entries {
		if !entry.IsDir() {
			if strings.HasSuffix(entry.Name(), ".json") {
				t.Fatalf("dashboard %s must live in a folder directory", entry.Name())
			}
			continue
		}
		dirs = append(dirs, entry.Name())
		if !provisioned[entry.Name()] {
			t.Fatalf("dashboard folder %s has no Grafana provider", entry.Name())
		}
		files, _ := filepath.Glob(filepath.Join(dashboardsDir, entry.Name(), "*.json"))
		if len(files) == 0 {
			t.Fatalf("dashboard folder %s is empty", entry.Name())
		}
		for _, path := range files {
			raw, err := os.ReadFile(path)
			if err != nil {
				t.Fatal(err)
			}
			var dashboard struct {
				UID    string `json:"uid"`
				Title  string `json:"title"`
				Panels []struct {
					ID      int    `json:"id"`
					Type    string `json:"type"`
					Title   string `json:"title"`
					Targets []struct {
						Expr       string `json:"expr"`
						Datasource *struct {
							UID string `json:"uid"`
						} `json:"datasource"`
					} `json:"targets"`
				} `json:"panels"`
			}
			if err := json.Unmarshal(raw, &dashboard); err != nil {
				t.Fatalf("%s is not valid JSON: %v", path, err)
			}
			if dashboard.UID == "" || dashboard.Title == "" || len(dashboard.Panels) == 0 {
				t.Fatalf("%s needs a uid, title and panels", path)
			}
			if previous, ok := uids[dashboard.UID]; ok {
				t.Fatalf("dashboard uid %s used by %s and %s", dashboard.UID, previous, path)
			}
			uids[dashboard.UID] = path
			ids := map[int]bool{}
			for _, panel := range dashboard.Panels {
				if ids[panel.ID] {
					t.Fatalf("%s: duplicate panel id %d", path, panel.ID)
				}
				ids[panel.ID] = true
				for _, target := range panel.Targets {
					if target.Datasource != nil && target.Datasource.UID != "" &&
						target.Datasource.UID != "verified-dating-prometheus" && target.Datasource.UID != "verified-dating-loki" {
						t.Fatalf("%s: panel %q uses unknown datasource %s", path, panel.Title, target.Datasource.UID)
					}
					for _, ref := range metricRefPattern.FindAllString(stringLiteralPattern.ReplaceAllString(target.Expr, `""`), -1) {
						if !metricExists(ref, known, recorded) {
							t.Fatalf("%s: panel %q references unknown metric %s", path, panel.Title, ref)
						}
					}
				}
			}
		}
	}
	sort.Strings(dirs)
	for _, want := range []string{"api", "database", "host", "product", "realtime", "workers"} {
		if !provisioned[want] || sort.SearchStrings(dirs, want) == len(dirs) {
			t.Fatalf("missing dashboard folder %s (have %v)", want, dirs)
		}
	}
}
