package observability

import (
	"regexp"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

// captureRegisterer is a registry that remembers its collectors so tests can
// enumerate every metric name a constructor registers (Gather only returns
// vectors that already have a child).
type captureRegisterer struct {
	*prometheus.Registry
	collectors []prometheus.Collector
}

func newCapture() *captureRegisterer {
	return &captureRegisterer{Registry: prometheus.NewRegistry()}
}

func (c *captureRegisterer) Register(collector prometheus.Collector) error {
	if err := c.Registry.Register(collector); err != nil {
		return err
	}
	c.collectors = append(c.collectors, collector)
	return nil
}

func (c *captureRegisterer) MustRegister(collectors ...prometheus.Collector) {
	for _, collector := range collectors {
		if err := c.Register(collector); err != nil {
			panic(err)
		}
	}
}

var fqNamePattern = regexp.MustCompile(`fqName: "([^"]+)"`)

// describedNames returns every metric family name the registerer's
// collectors describe.
func describedNames(t *testing.T, registerer any) map[string]bool {
	t.Helper()
	capture, ok := registerer.(*captureRegisterer)
	if !ok {
		reg, isRegistry := registerer.(*prometheus.Registry)
		if !isRegistry {
			t.Fatalf("unsupported registerer %T", registerer)
		}
		names := map[string]bool{}
		families, err := reg.Gather()
		if err != nil {
			t.Fatal(err)
		}
		for _, family := range families {
			names[family.GetName()] = true
		}
		return names
	}
	names := map[string]bool{}
	for _, collector := range capture.collectors {
		ch := make(chan *prometheus.Desc, 64)
		go func() {
			collector.Describe(ch)
			close(ch)
		}()
		for desc := range ch {
			if match := fqNamePattern.FindStringSubmatch(desc.String()); match != nil {
				names[match[1]] = true
			}
		}
	}
	return names
}

func timeAfterMillis(ms int) <-chan time.Time {
	return time.After(time.Duration(ms) * time.Millisecond)
}
