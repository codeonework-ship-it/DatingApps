package mobile

import (
	"context"
	"net/url"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type preferenceMasterData struct {
	Countries              []string            `json:"countries"`
	StatesByCountry        map[string][]string `json:"states_by_country"`
	CitiesByState          map[string][]string `json:"cities_by_state"`
	Religions              []string            `json:"religions"`
	MotherTongues          []string            `json:"mother_tongues"`
	Languages              []string            `json:"languages"`
	DietPreferences        []string            `json:"diet_preferences"`
	WorkoutFrequencies     []string            `json:"workout_frequencies"`
	DietTypes              []string            `json:"diet_types"`
	SleepSchedules         []string            `json:"sleep_schedules"`
	TravelStyles           []string            `json:"travel_styles"`
	PoliticalComfortRanges []string            `json:"political_comfort_ranges"`
}

type masterDataRepository struct {
	cfg        config.Config
	db         *supabase.Client
	cacheTTL   time.Duration
	mu         sync.RWMutex
	cached     preferenceMasterData
	cachedAt   time.Time
	refreshing bool
}

func newMasterDataRepository(cfg config.Config) *masterDataRepository {
	apiKey := strings.TrimSpace(cfg.SupabaseServiceRole)
	if apiKey == "" {
		apiKey = strings.TrimSpace(cfg.SupabaseAnonKey)
	}
	if strings.TrimSpace(cfg.SupabaseURL) == "" || apiKey == "" {
		return &masterDataRepository{cfg: cfg}
	}
	client := supabase.NewClient(
		cfg.SupabaseURL,
		cfg.SupabaseAnonKey,
		cfg.SupabaseServiceRole,
		cfg.SupabaseHTTPTimeout(),
	)
	client.SetReadBaseURL(cfg.SupabaseReadReplicaURL)
	return &masterDataRepository{cfg: cfg, db: client, cacheTTL: cfg.MasterDataCacheTTL()}
}

func (r *masterDataRepository) getPreferenceMasterData(ctx context.Context) preferenceMasterData {
	if cached, ok := r.getCached(); ok {
		if r.cacheStale() {
			go r.refreshCache(context.Background())
		}
		return cached
	}

	fresh := r.fetchPreferenceMasterData(ctx)
	r.setCached(fresh)
	return fresh
}

func (r *masterDataRepository) fetchPreferenceMasterData(ctx context.Context) preferenceMasterData {
	if r.db == nil {
		return fallbackMasterData()
	}

	countries, countryCodeToName, err := r.loadCountries(ctx)
	if err != nil {
		return fallbackMasterData()
	}

	statesByCountry, stateCodeToName, err := r.loadStates(ctx, countryCodeToName)
	if err != nil {
		return fallbackMasterData()
	}

	citiesByState, err := r.loadCities(ctx, stateCodeToName)
	if err != nil {
		return fallbackMasterData()
	}

	religions, err := r.loadNamedList(ctx, "master_religions")
	if err != nil {
		religions = fallbackMasterData().Religions
	}
	motherTongues, err := r.loadNamedList(ctx, "master_mother_tongues")
	if err != nil {
		motherTongues = fallbackMasterData().MotherTongues
	}
	languages, err := r.loadNamedList(ctx, "master_languages")
	if err != nil {
		languages = fallbackMasterData().Languages
	}
	dietPreferences, err := r.loadNamedList(ctx, "master_diet_preferences")
	if err != nil {
		dietPreferences = fallbackMasterData().DietPreferences
	}
	workoutFrequencies, err := r.loadNamedList(ctx, "master_workout_frequencies")
	if err != nil {
		workoutFrequencies = fallbackMasterData().WorkoutFrequencies
	}
	dietTypes, err := r.loadNamedList(ctx, "master_diet_types")
	if err != nil {
		dietTypes = fallbackMasterData().DietTypes
	}
	sleepSchedules, err := r.loadNamedList(ctx, "master_sleep_schedules")
	if err != nil {
		sleepSchedules = fallbackMasterData().SleepSchedules
	}
	travelStyles, err := r.loadNamedList(ctx, "master_travel_styles")
	if err != nil {
		travelStyles = fallbackMasterData().TravelStyles
	}
	politicalRanges, err := r.loadNamedList(ctx, "master_political_comfort_ranges")
	if err != nil {
		politicalRanges = fallbackMasterData().PoliticalComfortRanges
	}

	return preferenceMasterData{
		Countries:              countries,
		StatesByCountry:        statesByCountry,
		CitiesByState:          citiesByState,
		Religions:              religions,
		MotherTongues:          motherTongues,
		Languages:              languages,
		DietPreferences:        dietPreferences,
		WorkoutFrequencies:     workoutFrequencies,
		DietTypes:              dietTypes,
		SleepSchedules:         sleepSchedules,
		TravelStyles:           travelStyles,
		PoliticalComfortRanges: politicalRanges,
	}
}

func (r *masterDataRepository) getCached() (preferenceMasterData, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if r.cachedAt.IsZero() {
		return preferenceMasterData{}, false
	}
	return r.cached, true
}

func (r *masterDataRepository) cacheStale() bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if r.cacheTTL <= 0 || r.cachedAt.IsZero() {
		return false
	}
	return time.Since(r.cachedAt) >= r.cacheTTL
}

func (r *masterDataRepository) setCached(data preferenceMasterData) {
	r.mu.Lock()
	r.cached = data
	r.cachedAt = time.Now().UTC()
	r.mu.Unlock()
}

func (r *masterDataRepository) refreshCache(ctx context.Context) {
	r.mu.Lock()
	if r.refreshing {
		r.mu.Unlock()
		return
	}
	r.refreshing = true
	r.mu.Unlock()

	defer func() {
		r.mu.Lock()
		r.refreshing = false
		r.mu.Unlock()
	}()

	timeoutCtx := ctx
	if _, ok := ctx.Deadline(); !ok {
		var cancel context.CancelFunc
		timeoutCtx, cancel = context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
	}

	fresh := r.fetchPreferenceMasterData(timeoutCtx)
	r.setCached(fresh)
}

func (r *masterDataRepository) loadCountries(ctx context.Context) ([]string, map[string]string, error) {
	params := url.Values{}
	params.Set("select", "code,name")
	params.Set("order", "name.asc")
	rows, err := r.selectWithSchemaFallback(ctx, "master_countries", params)
	if err != nil {
		return nil, nil, err
	}

	countries := make([]string, 0, len(rows))
	codeToName := make(map[string]string, len(rows))
	for _, row := range rows {
		code := strings.TrimSpace(toString(row["code"]))
		name := strings.TrimSpace(toString(row["name"]))
		if code == "" || name == "" {
			continue
		}
		codeToName[code] = name
		countries = append(countries, name)
	}
	countries = uniqueSorted(countries)
	return countries, codeToName, nil
}

func (r *masterDataRepository) loadStates(
	ctx context.Context,
	countryCodeToName map[string]string,
) (map[string][]string, map[string]string, error) {
	params := url.Values{}
	params.Set("select", "country_code,code,name")
	params.Set("order", "name.asc")
	rows, err := r.selectWithSchemaFallback(ctx, "master_states", params)
	if err != nil {
		return nil, nil, err
	}

	statesByCountry := map[string][]string{}
	stateCodeToName := map[string]string{}
	for _, row := range rows {
		countryCode := strings.TrimSpace(toString(row["country_code"]))
		stateCode := strings.TrimSpace(toString(row["code"]))
		stateName := strings.TrimSpace(toString(row["name"]))
		countryName := strings.TrimSpace(countryCodeToName[countryCode])
		if countryName == "" || stateCode == "" || stateName == "" {
			continue
		}
		stateCodeToName[stateCode] = stateName
		statesByCountry[countryName] = append(statesByCountry[countryName], stateName)
	}
	for key, values := range statesByCountry {
		statesByCountry[key] = uniqueSorted(values)
	}
	return statesByCountry, stateCodeToName, nil
}

func (r *masterDataRepository) loadCities(
	ctx context.Context,
	stateCodeToName map[string]string,
) (map[string][]string, error) {
	params := url.Values{}
	params.Set("select", "state_code,name")
	params.Set("order", "name.asc")
	rows, err := r.selectWithSchemaFallback(ctx, "master_cities", params)
	if err != nil {
		return nil, err
	}

	citiesByState := map[string][]string{}
	for _, row := range rows {
		stateCode := strings.TrimSpace(toString(row["state_code"]))
		cityName := strings.TrimSpace(toString(row["name"]))
		stateName := strings.TrimSpace(stateCodeToName[stateCode])
		if stateName == "" || cityName == "" {
			continue
		}
		citiesByState[stateName] = append(citiesByState[stateName], cityName)
	}
	for key, values := range citiesByState {
		citiesByState[key] = uniqueSorted(values)
	}
	return citiesByState, nil
}

func (r *masterDataRepository) loadNamedList(ctx context.Context, table string) ([]string, error) {
	params := url.Values{}
	params.Set("select", "name")
	params.Set("order", "sort_order.asc,name.asc")
	rows, err := r.selectWithSchemaFallback(ctx, table, params)
	if err != nil {
		return nil, err
	}
	values := make([]string, 0, len(rows))
	for _, row := range rows {
		name := strings.TrimSpace(toString(row["name"]))
		if name == "" {
			continue
		}
		values = append(values, name)
	}
	return uniqueSortedPreservingOrder(values), nil
}

func (r *masterDataRepository) selectWithSchemaFallback(
	ctx context.Context,
	table string,
	params url.Values,
) ([]map[string]any, error) {
	schema := strings.TrimSpace(r.cfg.MatchingSchema)
	if schema == "" {
		schema = "matching"
	}
	rows, err := r.db.SelectRead(ctx, schema, table, params)
	if err == nil {
		return rows, nil
	}
	if schema == "matching" {
		return nil, err
	}
	return r.db.SelectRead(ctx, "matching", table, params)
}

func uniqueSorted(values []string) []string {
	set := map[string]struct{}{}
	out := make([]string, 0, len(values))
	for _, value := range values {
		normalized := strings.TrimSpace(value)
		if normalized == "" {
			continue
		}
		if _, ok := set[normalized]; ok {
			continue
		}
		set[normalized] = struct{}{}
		out = append(out, normalized)
	}
	sort.Strings(out)
	return out
}

func uniqueSortedPreservingOrder(values []string) []string {
	set := map[string]struct{}{}
	out := make([]string, 0, len(values))
	for _, value := range values {
		normalized := strings.TrimSpace(value)
		if normalized == "" {
			continue
		}
		if _, ok := set[normalized]; ok {
			continue
		}
		set[normalized] = struct{}{}
		out = append(out, normalized)
	}
	return out
}

func fallbackMasterData() preferenceMasterData {
	countries := []string{"India"}
	states := []string{"Karnataka", "Maharashtra", "Delhi", "Tamil Nadu", "Telangana"}
	statesByCountry := map[string][]string{"India": states}
	citiesByState := map[string][]string{
		"Karnataka":   {"Bengaluru", "Mysuru", "Mangaluru"},
		"Maharashtra": {"Mumbai", "Pune", "Nagpur"},
		"Delhi":       {"New Delhi", "Delhi"},
		"Tamil Nadu":  {"Chennai", "Coimbatore", "Madurai"},
		"Telangana":   {"Hyderabad", "Warangal", "Nizamabad"},
	}

	return preferenceMasterData{
		Countries:              countries,
		StatesByCountry:        statesByCountry,
		CitiesByState:          citiesByState,
		Religions:              []string{"Hindu", "Muslim", "Christian", "Sikh", "Buddhist", "Jain", "Spiritual", "Other", "Prefer not to say"},
		MotherTongues:          []string{"Hindi", "English", "Tamil", "Telugu", "Kannada", "Malayalam", "Marathi", "Gujarati", "Punjabi", "Bengali", "Urdu"},
		Languages:              []string{"English", "Hindi", "Tamil", "Telugu", "Kannada", "Malayalam", "Marathi", "Gujarati", "Punjabi", "Bengali", "Urdu"},
		DietPreferences:        []string{"No preference", "Vegetarian", "Eggetarian", "Non-vegetarian", "Vegan", "Jain"},
		WorkoutFrequencies:     []string{"Never", "1-2 times a week", "3-4 times a week", "5+ times a week", "Daily"},
		DietTypes:              []string{"Balanced", "High Protein", "Low Carb", "Keto", "Mediterranean", "Intermittent Fasting"},
		SleepSchedules:         []string{"Early bird", "Night owl", "Flexible", "Shift based"},
		TravelStyles:           []string{"Homebody", "Occasional traveler", "Frequent traveler", "Adventure seeker", "Luxury traveler", "Backpacker"},
		PoliticalComfortRanges: []string{"Similar views only", "Open to differences", "Prefer not to discuss", "No strong preference"},
	}
}
