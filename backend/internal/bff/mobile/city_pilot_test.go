package mobile

import (
	"context"
	"encoding/json"
	"github.com/google/uuid"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"
)

func pilotFixture(t *testing.T) (friendSocialFixture, *Server, *cityPilot) {
	t.Helper()
	f := newFriendSocialFixture(t)
	var original bool
	if err := f.db.QueryRow(`SELECT value_bool FROM matching.platform_feature_flags WHERE key='city_pilot_enabled'`).Scan(&original); err != nil {
		t.Fatal(err)
	}
	pilotExec(t, f, `UPDATE matching.platform_feature_flags SET value_bool=TRUE WHERE key='city_pilot_enabled'`)
	t.Cleanup(func() {
		_, _ = f.db.Exec(`UPDATE matching.platform_feature_flags SET value_bool=$1 WHERE key='city_pilot_enabled'`, original)
	})
	for _, id := range []string{f.alice, f.bob, f.carol, f.stranger} {
		pilotExec(t, f, `UPDATE user_management.users SET city='Pilot QA City',country='QA Country',terms_accepted=TRUE WHERE id=$1`, id)
	}
	id := uuid.NewString()
	pilotExec(t, f, `INSERT INTO growth.city_pilots(id,city,country,owner,safety_owner,status,starts_at,closes_at,capacity,minimum_pairs,conversation_target,plan_target,date_target) VALUES($1,'Pilot QA City','QA Country','QA owner','QA safety','completed',NOW()-INTERVAL '60 days',NOW()-INTERVAL '40 days',20,20,30,10,5)`, id)
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM growth.events WHERE id IN(SELECT event_id FROM growth.city_pilot_experiences WHERE pilot_id=$1)`, id)
		_, _ = f.db.Exec(`DELETE FROM growth.city_pilots WHERE id=$1`, id)
	})
	p, err := readCityPilot(context.Background(), f.db, id, false)
	if err != nil {
		t.Fatal(err)
	}
	return f, &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}, p
}
func pilotExec(t *testing.T, f friendSocialFixture, q string, args ...any) {
	t.Helper()
	if _, err := f.db.Exec(q, args...); err != nil {
		t.Fatal(err)
	}
}
func pilotRequest(method, user, param, value string, payload any) *http.Request {
	b, _ := json.Marshal(payload)
	return socialRequest(method, "/v1/city-pilot", user, param, value, string(b))
}
func pilotAdminRequest(user, param, value string, payload any) *http.Request {
	r := pilotRequest("POST", user, param, value, payload)
	return r.WithContext(context.WithValue(r.Context(), securityPrincipalContextKey{}, securityPrincipal{UserID: user, Roles: map[string]bool{"ops_admin": true}}))
}
func pilotCall(t *testing.T, handler http.HandlerFunc, r *http.Request, status int) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	handler(rec, r)
	if rec.Code != status {
		t.Fatalf("expected %d got %d: %s", status, rec.Code, rec.Body.String())
	}
	return rec
}
func pilotSeedMember(t *testing.T, f friendSocialFixture, p *cityPilot, id string) {
	pilotExec(t, f, `INSERT INTO growth.city_pilot_members(pilot_id,member_id,joined_at) VALUES($1,$2,$3)`, p.ID, id, p.StartsAt)
}
func TestCityPilotGateAndPrivacy(t *testing.T) {
	now := time.Now()
	p := &cityPilot{ClosesAt: now.Add(-29 * 24 * time.Hour), MinimumPairs: 20, ConversationTarget: 50, PlanTarget: 25, DateTarget: 10}
	c := pilotCounts{Pairs: 20, ConversationDenominator: 20, Conversations: 10, DateDenominator: 20, Plans: 5, Dates: 2}
	if !pilotGate(p, c, now) {
		t.Fatal("valid review blocked")
	}
	c.OpenReports = 1
	if pilotGate(p, c, now) {
		t.Fatal("safety report ignored")
	}
	c.OpenReports = 0
	c.DateDenominator = 19
	if pilotGate(p, c, now) {
		t.Fatal("sample ignored")
	}
	c.DateDenominator = 20
	c.Dates = 1
	if pilotGate(p, c, now) {
		t.Fatal("date target ignored")
	}
	c.Dates = 2
	p.ClosesAt = now.Add(-27 * 24 * time.Hour)
	if pilotGate(p, c, now) {
		t.Fatal("immature follow-up passed")
	}
	if pilotCountLabel(1) != "<5" || pilotCountLabel(4) != "<5" || pilotCountLabel(0) != "0" || pilotCountLabel(5) != "5" {
		t.Fatal("small cell suppression failed")
	}
}
func TestCityPilotPermissions(t *testing.T) {
	for _, role := range []string{"user", "analyst", "trust_safety", "ops_admin"} {
		p := securityPrincipal{Roles: map[string]bool{role: true}}
		for _, method := range []string{"GET", "POST"} {
			got := principalCanAccessAdminRoute(p, "/v1", method, "/v1/admin/growth/city-pilot")
			want := role == "ops_admin" || method == "GET" && (role == "analyst" || role == "trust_safety")
			if got != want {
				t.Fatalf("%s %s got %v", role, method, got)
			}
		}
	}
	if introducerRouteAllowed("/v1", "GET", "/v1/city-pilot", securityPrincipal{AccountKind: "introducer", TermsAccepted: true}) {
		t.Fatal("introducer entered dating pilot")
	}
}
func TestCityPilotConsentEligibilityWithdrawalPostgres(t *testing.T) {
	f, s, p := pilotFixture(t)
	pilotExec(t, f, `UPDATE growth.city_pilots SET status='recruiting',starts_at=NOW()-INTERVAL '1 day',closes_at=NOW()+INTERVAL '7 days' WHERE id=$1`, p.ID)
	input := map[string]any{"pilot_id": p.ID}
	pilotCall(t, s.cityPilotMembership, pilotRequest("POST", f.alice, "", "", input), 400)
	input["consent_version"] = "city-pilot-v1"
	pilotCall(t, s.cityPilotMembership, pilotRequest("POST", f.introducer, "", "", input), 403)
	for i := 0; i < 2; i++ {
		pilotCall(t, s.cityPilotMembership, pilotRequest("POST", f.alice, "", "", input), 200)
	}
	var count int
	_ = f.db.QueryRow(`SELECT COUNT(*) FROM growth.city_pilot_members WHERE pilot_id=$1`, p.ID).Scan(&count)
	if count != 1 {
		t.Fatal("duplicate membership")
	}
	pilotExec(t, f, `UPDATE matching.platform_feature_flags SET value_bool=FALSE WHERE key='city_pilot_enabled'`)
	pilotCall(t, s.cityPilotMembership, pilotRequest("POST", f.bob, "", "", input), 409)
	pilotCall(t, s.cityPilotMembership, pilotRequest("DELETE", f.alice, "", "", input), 200)
	pilotCall(t, s.cityPilotMembership, pilotRequest("POST", f.alice, "", "", input), 409)
}
func TestCityPilotMetricsWindowsAndConsentPostgres(t *testing.T) {
	f, _, p := pilotFixture(t)
	ctx := context.Background()
	for _, id := range []string{f.alice, f.bob, f.carol} {
		pilotSeedMember(t, f, p, id)
	}
	seedPair := func(a, b string, at time.Time) string {
		id := uuid.NewString()
		pilotExec(t, f, `INSERT INTO matching.matches(id,user_id_1,user_id_2,created_at) VALUES($1,LEAST($2::uuid,$3::uuid),GREATEST($2::uuid,$3::uuid),$4)`, id, a, b, at)
		return id
	}
	at := p.StartsAt.Add(24 * time.Hour)
	match := seedPair(f.alice, f.bob, at)
	seedPair(f.alice, f.stranger, at)
	seedPair(f.bob, f.carol, p.StartsAt.Add(-time.Hour))
	for _, id := range []string{f.alice, f.bob} {
		for i := 0; i < 3; i++ {
			pilotExec(t, f, `INSERT INTO matching.messages(match_id,sender_id,text,created_at) VALUES($1,$2,'private message body',$3)`, match, id, at.Add(time.Hour))
		}
	}
	c, err := cityPilotCounts(ctx, f.db, p, at.Add(6*24*time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if c.Pairs != 1 || c.ConversationDenominator != 0 || c.Conversations != 0 {
		t.Fatalf("immature/consent counts %+v", c)
	}
	c, err = cityPilotCounts(ctx, f.db, p, time.Now())
	if err != nil || c.Pairs != 1 || c.Conversations != 1 || c.DateDenominator != 1 || c.Dates != 0 {
		t.Fatalf("counts %+v %v", c, err)
	}
	plan := uuid.NewString()
	pilotExec(t, f, `INSERT INTO matching.match_date_plans(id,match_id,proposer_user_id,invitee_user_id,status,window_start,window_end,venue_category,checkin_due_at,created_at) VALUES($1,$2,$3,$4,'accepted',NOW()+INTERVAL '1 hour',NOW()+INTERVAL '2 hours','coffee',NOW()+INTERVAL '3 hours',$5)`, plan, match, f.alice, f.bob, at.Add(2*time.Hour))
	pilotExec(t, f, `UPDATE matching.match_date_plans SET window_start=$2::timestamptz,window_end=$2::timestamptz+INTERVAL '1 hour' WHERE id=$1`, plan, at.Add(3*time.Hour))
	pilotExec(t, f, `INSERT INTO matching.match_date_plan_events(plan_id,event_type,to_status,created_at) VALUES($1,'accepted','accepted',$2)`, plan, at.Add(2*time.Hour))
	for _, id := range []string{f.alice, f.bob} {
		pilotExec(t, f, `INSERT INTO matching.match_date_plan_debriefs(plan_id,user_id,happened,would_meet_again,note,created_at) VALUES($1,$2,TRUE,FALSE,'private note must not reach pilot',$3)`, plan, id, at.Add(5*time.Hour))
	}
	c, err = cityPilotCounts(ctx, f.db, p, time.Now())
	if err != nil || c.Plans != 1 || c.Dates != 1 || c.AnsweredPairs != 1 {
		t.Fatalf("date metrics %+v %v", c, err)
	}
	pilotExec(t, f, `UPDATE matching.match_date_plans SET status='cancelled' WHERE id=$1`, plan)
	c, err = cityPilotCounts(ctx, f.db, p, time.Now())
	if err != nil || c.Plans != 1 {
		t.Fatal("cancelled accepted plan disappeared", c, err)
	}
	pilotExec(t, f, `UPDATE growth.city_pilot_members SET withdrawn_at=NOW() WHERE pilot_id=$1 AND member_id=$2`, p.ID, f.bob)
	c, err = cityPilotCounts(ctx, f.db, p, time.Now())
	if err != nil || c.Pairs != 0 || c.Conversations != 0 || c.Dates != 0 {
		t.Fatal("withdrawal leaked metrics", c, err)
	}
}
func pilotSeedExperience(t *testing.T, f friendSocialFixture, p *cityPilot) string {
	event := uuid.NewString()
	pilotExec(t, f, `UPDATE growth.city_pilots SET status='experiences',safety_ready=TRUE WHERE id=$1`, p.ID)
	pilotExec(t, f, `INSERT INTO growth.events(id,title,summary,city,venue_name,starts_at,registration_closes_at,capacity,safety_contact,status) VALUES($1,'QA coffee walk','A friendly public coffee walk','Pilot QA City','Public cafe',NOW()+INTERVAL '2 days',NOW()+INTERVAL '1 day',2,'QA safety contact','published')`, event)
	pilotExec(t, f, `INSERT INTO growth.city_pilot_experiences(event_id,pilot_id,ends_at,host_name,accessibility_note) VALUES($1,$2,NOW()+INTERVAL '2 days 1 hour','QA host','Step-free access checked')`, event, p.ID)
	return event
}
func TestCityPilotBookingCapacityAndLegacyBypassPostgres(t *testing.T) {
	f, s, p := pilotFixture(t)
	event := pilotSeedExperience(t, f, p)
	for _, id := range []string{f.alice, f.bob, f.carol} {
		pilotSeedMember(t, f, p, id)
	}
	pilotCall(t, s.registerGrowthEvent, pilotRequest("POST", f.stranger, "eventID", event, map[string]any{"safety_terms_accepted": true}), 404)
	codes := make(chan int, 3)
	var wg sync.WaitGroup
	for _, id := range []string{f.alice, f.bob, f.carol} {
		wg.Add(1)
		go func(id string) {
			defer wg.Done()
			r := httptest.NewRecorder()
			s.cityPilotRegistration(r, pilotRequest("POST", id, "eventID", event, map[string]any{"safety_terms_accepted": true}))
			codes <- r.Code
		}(id)
	}
	wg.Wait()
	close(codes)
	success, full := 0, 0
	for code := range codes {
		if code == 200 {
			success++
		} else if code == 409 {
			full++
		} else {
			t.Fatalf("unexpected capacity response %d", code)
		}
	}
	if success != 2 || full != 1 {
		t.Fatal(success, full)
	}
	var booked string
	if err := f.db.QueryRow(`SELECT member_id::text FROM growth.event_registrations WHERE event_id=$1 LIMIT 1`, event).Scan(&booked); err != nil {
		t.Fatal(err)
	}
	pilotCall(t, s.cityPilotRegistration, pilotRequest("POST", booked, "eventID", event, map[string]any{"safety_terms_accepted": true}), 200)
	pilotExec(t, f, `UPDATE matching.platform_feature_flags SET value_bool=FALSE WHERE key='city_pilot_enabled'`)
	pilotCall(t, s.cityPilotRegistration, pilotRequest("DELETE", booked, "eventID", event, nil), 200)
}
func TestCityPilotHostedGateAndSafetyStopPostgres(t *testing.T) {
	f, s, p := pilotFixture(t)
	pilotExec(t, f, `UPDATE growth.city_pilots SET status='measuring' WHERE id=$1`, p.ID)
	pilotCall(t, s.adminTransitionCityPilot, pilotAdminRequest(f.alice, "pilotID", p.ID, map[string]any{"status": "experiences", "version": 1, "safety_ready": true, "note": "Reviewed the pilot evidence"}), 409)
	event := pilotSeedExperience(t, f, p)
	pilotSeedMember(t, f, p, f.bob)
	pilotExec(t, f, `INSERT INTO growth.event_registrations(event_id,member_id,safety_terms_accepted_at) VALUES($1,$2,NOW())`, event, f.bob)
	r := pilotAdminRequest(f.alice, "pilotID", p.ID, map[string]any{"status": "paused", "version": 1, "note": "Paused for a safety review"})
	r = r.WithContext(context.WithValue(r.Context(), securityPrincipalContextKey{}, securityPrincipal{UserID: f.alice, Roles: map[string]bool{"trust_safety": true}}))
	pilotCall(t, s.adminTransitionCityPilot, r, 200)
	var status string
	_ = f.db.QueryRow(`SELECT status FROM growth.events WHERE id=$1`, event).Scan(&status)
	if status != "cancelled" {
		t.Fatal("stop left event published")
	}
	pilotCall(t, s.cityPilotMembership, pilotRequest("DELETE", f.bob, "", "", map[string]any{"pilot_id": p.ID}), 200)
}
func TestCityPilotPrivateFeedbackAndWithdrawalPostgres(t *testing.T) {
	f, s, p := pilotFixture(t)
	event := pilotSeedExperience(t, f, p)
	pilotSeedMember(t, f, p, f.alice)
	pilotSeedMember(t, f, p, f.bob)
	pilotExec(t, f, `UPDATE growth.events SET starts_at=NOW()-INTERVAL '2 hours',registration_closes_at=NOW()-INTERVAL '1 day' WHERE id=$1`, event)
	pilotExec(t, f, `UPDATE growth.city_pilot_experiences SET ends_at=NOW()-INTERVAL '1 hour' WHERE event_id=$1`, event)
	pilotExec(t, f, `INSERT INTO growth.event_registrations(event_id,member_id,safety_terms_accepted_at) VALUES($1,$2,NOW())`, event, f.alice)
	body := map[string]any{"attended": true, "worthwhile": true}
	pilotCall(t, s.cityPilotFeedback, pilotRequest("POST", f.bob, "eventID", event, body), 409)
	pilotCall(t, s.cityPilotFeedback, pilotRequest("POST", f.alice, "eventID", event, body), 200)
	pilotCall(t, s.cityPilotFeedback, pilotRequest("POST", f.alice, "eventID", event, body), 409)
	items, err := listPilotExperiences(context.Background(), f.db, p.ID, "", true, false)
	if err != nil {
		t.Fatal(err)
	}
	if len(items) != 1 || items[0]["feedback"] != nil {
		t.Fatal("admin saw individual feedback", items)
	}
	pilotCall(t, s.cityPilotMembership, pilotRequest("DELETE", f.alice, "", "", map[string]any{"pilot_id": p.ID}), 200)
	var count int
	_ = f.db.QueryRow(`SELECT COUNT(*) FROM growth.city_pilot_feedback WHERE event_id=$1`, event).Scan(&count)
	if count != 0 {
		t.Fatal("withdrawal retained feedback")
	}
	var captured int
	if err = f.db.QueryRow(`SELECT COUNT(*) FROM platform.domain_event_outbox WHERE aggregate_type='growth.city_pilot_feedback'`).Scan(&captured); err != nil {
		t.Fatal(err)
	}
	if captured == 0 {
		t.Fatal("missing events")
	}
}
func TestCityPilotDraftValidationAndVersionPostgres(t *testing.T) {
	f, s, p := pilotFixture(t)
	pilotExec(t, f, `UPDATE growth.city_pilots SET status='draft' WHERE id=$1`, p.ID)
	p.StartsAt = time.Now().Add(time.Hour)
	p.ClosesAt = p.StartsAt.Add(7 * 24 * time.Hour)
	p.Version = 99
	pilotCall(t, s.adminSaveCityPilot, pilotAdminRequest(f.alice, "", "", p), 409)
	p.Version = 1
	pilotCall(t, s.adminSaveCityPilot, pilotAdminRequest(f.alice, "", "", p), 200)
	pilotExec(t, f, `UPDATE growth.city_pilots SET status='recruiting' WHERE id=$1`, p.ID)
	p.Version = 2
	pilotCall(t, s.adminSaveCityPilot, pilotAdminRequest(f.alice, "", "", p), 409)
}
