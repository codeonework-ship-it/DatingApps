package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"sync/atomic"
	"time"
)

// Creative-contribution rewards (migration 113).
//
// An award is queued in the caller's transaction as a ready progression
// repair intent, so it commits atomically with the like, approval, tier or
// publish that earned it, and the progression worker grants it within a
// second. Awards are idempotent per (member, key) in both the queue and the
// XP ledger, so a retried action can never pay twice. Source policies (base
// XP and daily caps) live in progression.xp_source_policies.

// xpRewardsDisabled mirrors the release contract: where level progression is
// excluded, no rewards are queued.
var xpRewardsDisabled atomic.Bool

// rewardAvailableAfter delays when queued rewards become claimable. Zero in
// production; tests raise it so a progression worker sharing the database
// cannot grant real XP for test members.
var rewardAvailableAfter time.Duration

func queueReward(ctx context.Context, tx *sql.Tx, userID, source, eventKey string) error {
	if xpRewardsDisabled.Load() || userID == "" {
		return nil
	}
	key := source + ":" + eventKey
	if len(key) > 255 {
		key = key[:255]
	}
	payload, err := json.Marshal(xpAwardRepairPayload{
		UserID: userID, Source: source, SourceEventID: eventKey, IdempotencyKey: key,
		ActorType: "system", Metadata: map[string]any{"origin": "creative_rewards"},
	})
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO progression.xp_award_repair_queue
 (user_id,source,source_event_id,idempotency_key,input,status,available_at,last_error)
 SELECT $1::uuid,$2,$3,$4,$5::jsonb,'pending',NOW()+make_interval(secs=>$6),'creative reward'
 WHERE EXISTS(SELECT 1 FROM progression.xp_source_policies WHERE source=$2 AND enabled)
 ON CONFLICT (user_id,idempotency_key) DO NOTHING`, userID, source, eventKey, key, string(payload), rewardAvailableAfter.Seconds())
	return err
}
