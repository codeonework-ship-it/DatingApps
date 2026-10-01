package observability

import (
	"errors"
	"runtime"
	"runtime/debug"
	"sort"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

// Version and Commit are stamped at build time:
//
//	go build -ldflags "-X github.com/verified-dating/backend/internal/platform/observability.Version=1.4.2 \
//	  -X github.com/verified-dating/backend/internal/platform/observability.Commit=$(git rev-parse --short=12 HEAD)"
//
// When Commit is empty the VCS revision embedded by the Go toolchain is used.
var (
	Version = "dev"
	Commit  = ""
)

// RegisterProcessMetrics registers the per-process collectors every Connect
// binary exposes: verified_dating_build_info and the database pool collector.
// Registering twice on the same registry is a no-op.
func RegisterProcessMetrics(reg prometheus.Registerer, service string) {
	version, commit := BuildVersion()
	buildInfo := prometheus.NewGauge(prometheus.GaugeOpts{
		Namespace: "verified_dating", Name: "build_info",
		Help: "Always 1; labels identify the running build.",
		ConstLabels: prometheus.Labels{
			"service": service, "version": version, "commit": commit, "go_version": runtime.Version(),
		},
	})
	buildInfo.Set(1)
	registerOnce(reg, buildInfo)
	registerOnce(reg, defaultDBPools)
}

func registerOnce(reg prometheus.Registerer, c prometheus.Collector) {
	if err := reg.Register(c); err != nil {
		var already prometheus.AlreadyRegisteredError
		if !errors.As(err, &already) {
			panic(err)
		}
	}
}

// BuildVersion returns the stamped version and commit, falling back to the
// toolchain's embedded VCS revision.
func BuildVersion() (version, commit string) {
	version, commit = Version, Commit
	if commit != "" {
		return version, commit
	}
	commit = "unknown"
	if info, ok := debug.ReadBuildInfo(); ok {
		modified := false
		for _, setting := range info.Settings {
			switch setting.Key {
			case "vcs.revision":
				commit = setting.Value
				if len(commit) > 12 {
					commit = commit[:12]
				}
			case "vcs.modified":
				modified = setting.Value == "true"
			}
		}
		if modified && commit != "unknown" {
			commit += "-dirty"
		}
	}
	return version, commit
}

// DBPoolStats is a driver-neutral snapshot of one connection pool.
type DBPoolStats struct {
	MaxConnections   int
	OpenConnections  int
	InUseConnections int
	IdleConnections  int
	// WaitCount counts acquisitions that had to wait for a free connection;
	// WaitDuration is the total time spent waiting.
	WaitCount    int64
	WaitDuration time.Duration
}

// DBPoolStatsFunc returns the current stats, or ok=false once the pool is gone
// (the collector then forgets it).
type DBPoolStatsFunc func() (stats DBPoolStats, ok bool)

// TrackDBPool publishes a pool as verified_dating_db_pool_* series labelled
// pool=<name>. Pools sharing a name are summed. name must be code-defined.
// The returned function stops tracking.
func TrackDBPool(name string, stats DBPoolStatsFunc) (untrack func()) {
	return defaultDBPools.track(name, stats)
}

var defaultDBPools = newDBPoolCollector()

type dbPoolEntry struct {
	name  string
	stats DBPoolStatsFunc
}

type dbPoolCollector struct {
	mu      sync.Mutex
	nextID  uint64
	entries map[uint64]dbPoolEntry

	max, open, inUse, idle, waits, waitSeconds, pools *prometheus.Desc
}

func newDBPoolCollector() *dbPoolCollector {
	desc := func(name, help string) *prometheus.Desc {
		return prometheus.NewDesc("verified_dating_db_pool_"+name, help, []string{"pool"}, nil)
	}
	return &dbPoolCollector{
		entries:     map[uint64]dbPoolEntry{},
		max:         desc("max_connections", "Configured maximum connections of an application database pool."),
		open:        desc("open_connections", "Open connections (in use + idle) of an application database pool."),
		inUse:       desc("in_use_connections", "Connections currently checked out of an application database pool."),
		idle:        desc("idle_connections", "Idle connections of an application database pool."),
		waits:       desc("wait_total", "Acquisitions that waited because the pool had no free connection."),
		waitSeconds: desc("wait_seconds_total", "Total time spent waiting for a pool connection."),
		pools:       desc("instances", "Pool instances aggregated under this pool name."),
	}
}

func (c *dbPoolCollector) track(name string, stats DBPoolStatsFunc) func() {
	if name == "" || stats == nil {
		return func() {}
	}
	c.mu.Lock()
	c.nextID++
	id := c.nextID
	c.entries[id] = dbPoolEntry{name: name, stats: stats}
	c.mu.Unlock()
	return func() {
		c.mu.Lock()
		delete(c.entries, id)
		c.mu.Unlock()
	}
}

func (c *dbPoolCollector) Describe(ch chan<- *prometheus.Desc) {
	for _, d := range []*prometheus.Desc{c.max, c.open, c.inUse, c.idle, c.waits, c.waitSeconds, c.pools} {
		ch <- d
	}
}

func (c *dbPoolCollector) Collect(ch chan<- prometheus.Metric) {
	type sum struct {
		stats DBPoolStats
		count int
	}
	c.mu.Lock()
	entries := make(map[uint64]dbPoolEntry, len(c.entries))
	for id, entry := range c.entries {
		entries[id] = entry
	}
	c.mu.Unlock()

	sums := map[string]*sum{}
	var gone []uint64
	for id, entry := range entries {
		s, ok := entry.stats()
		if !ok {
			gone = append(gone, id)
			continue
		}
		agg := sums[entry.name]
		if agg == nil {
			agg = &sum{}
			sums[entry.name] = agg
		}
		agg.count++
		agg.stats.MaxConnections += s.MaxConnections
		agg.stats.OpenConnections += s.OpenConnections
		agg.stats.InUseConnections += s.InUseConnections
		agg.stats.IdleConnections += s.IdleConnections
		agg.stats.WaitCount += s.WaitCount
		agg.stats.WaitDuration += s.WaitDuration
	}
	if len(gone) > 0 {
		c.mu.Lock()
		for _, id := range gone {
			delete(c.entries, id)
		}
		c.mu.Unlock()
	}
	names := make([]string, 0, len(sums))
	for name := range sums {
		names = append(names, name)
	}
	sort.Strings(names)
	for _, name := range names {
		s := sums[name]
		ch <- prometheus.MustNewConstMetric(c.max, prometheus.GaugeValue, float64(s.stats.MaxConnections), name)
		ch <- prometheus.MustNewConstMetric(c.open, prometheus.GaugeValue, float64(s.stats.OpenConnections), name)
		ch <- prometheus.MustNewConstMetric(c.inUse, prometheus.GaugeValue, float64(s.stats.InUseConnections), name)
		ch <- prometheus.MustNewConstMetric(c.idle, prometheus.GaugeValue, float64(s.stats.IdleConnections), name)
		ch <- prometheus.MustNewConstMetric(c.waits, prometheus.CounterValue, float64(s.stats.WaitCount), name)
		ch <- prometheus.MustNewConstMetric(c.waitSeconds, prometheus.CounterValue, s.stats.WaitDuration.Seconds(), name)
		ch <- prometheus.MustNewConstMetric(c.pools, prometheus.GaugeValue, float64(s.count), name)
	}
}
