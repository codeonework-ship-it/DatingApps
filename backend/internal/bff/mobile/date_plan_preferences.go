package mobile

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"
)

var datePlanAtmospheres = map[string]bool{"quiet": true, "relaxed": true, "lively": true, "outdoors": true, "indoors": true}
var datePlanAccessibility = map[string]bool{"step_free": true, "accessible_toilet": true, "seating": true, "low_noise": true, "nearby_transit": true, "captions": true}
var errDatePlanAvailabilityChanged = errors.New("Shared availability has changed. Refresh the time suggestions or choose a time to propose manually.")

func parsePlanChoices(value any, allowed map[string]bool, maximum int, label string) ([]string, error) {
	out := []string{}
	if value == nil {
		return out, nil
	}
	raw, ok := value.([]any)
	if !ok || len(raw) > maximum {
		return nil, fmt.Errorf("Choose up to %d supported %s preferences", maximum, label)
	}
	seen := map[string]bool{}
	for _, v := range raw {
		choice, ok := v.(string)
		choice = strings.TrimSpace(choice)
		if !ok || !allowed[choice] {
			return nil, fmt.Errorf("Choose a supported %s preference", label)
		}
		if !seen[choice] {
			out = append(out, choice)
			seen[choice] = true
		}
	}
	return out, nil
}

func parsePlanSharedWindow(value any, start, end time.Time) (*datingWindow, error) {
	if value == nil {
		return nil, nil
	}
	raw, ok := value.(map[string]any)
	if !ok {
		return nil, errors.New("shared_window must contain a start and end")
	}
	a, err := parseDatePlanTime(raw["start"])
	if err != nil {
		return nil, err
	}
	b, err := parseDatePlanTime(raw["end"])
	if err != nil {
		return nil, err
	}
	if !b.After(a) || b.Sub(a) > 6*time.Hour || start.Before(a) || end.After(b) {
		return nil, errors.New("The proposed time must fit within the selected shared window")
	}
	return &datingWindow{a, b}, nil
}

// Only a current intersection is evidence of shared availability. A manually
// proposed time never claims consent or discloses either full schedule.
func validatePlanSharedWindow(ctx context.Context, tx *sql.Tx, p datePlanProposal, partner string, now time.Time) error {
	if p.SharedWindow == nil {
		return nil
	}
	a, err := loadDatingPreferences(ctx, tx, p.ProposerID, now)
	if err != nil {
		return err
	}
	b, err := loadDatingPreferences(ctx, tx, partner, now)
	if err != nil {
		return err
	}
	if !a.ShareAvailability || !b.ShareAvailability || !p.WindowStart.After(now) {
		return errDatePlanAvailabilityChanged
	}
	for _, x := range a.Availability {
		for _, y := range b.Availability {
			if !p.WindowStart.Before(x.Start) && !p.WindowStart.Before(y.Start) && !p.WindowEnd.After(x.End) && !p.WindowEnd.After(y.End) {
				return nil
			}
		}
	}
	return errDatePlanAvailabilityChanged
}
