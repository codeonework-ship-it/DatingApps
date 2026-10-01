BEGIN;

CREATE OR REPLACE VIEW matching.notification_queue_metrics AS
WITH queue AS (
  SELECT
    COUNT(*) FILTER (WHERE status IN ('pending','retry')) AS queue_depth,
    COUNT(*) FILTER (WHERE status = 'processing') AS processing,
    COUNT(*) FILTER (WHERE status = 'dead_letter') AS dead_letter,
    COUNT(*) FILTER (WHERE status = 'delivered') AS delivered,
    COALESCE(EXTRACT(EPOCH FROM (NOW() - MIN(created_at)
      FILTER (WHERE status IN ('pending','retry')))), 0)::BIGINT
      AS oldest_pending_age_seconds
  FROM matching.notification_outbox
), recent_push AS (
  SELECT
    COUNT(*) AS attempts,
    COUNT(*) FILTER (WHERE d.status = 'delivered') AS delivered,
    COUNT(*) FILTER (WHERE d.status = 'dead_letter') AS dead_letter,
    COALESCE(
      PERCENTILE_CONT(0.95) WITHIN GROUP (
        ORDER BY EXTRACT(EPOCH FROM (d.delivered_at - o.created_at)) * 1000
      ) FILTER (WHERE d.status = 'delivered' AND d.delivered_at IS NOT NULL),
      0
    )::DOUBLE PRECISION AS p95_latency_ms
  FROM matching.notification_deliveries d
  JOIN matching.notification_outbox o ON o.id = d.outbox_id
  WHERE d.channel = 'push' AND d.updated_at >= NOW() - INTERVAL '15 minutes'
)
SELECT
  q.queue_depth,
  q.processing,
  q.dead_letter,
  q.delivered,
  q.oldest_pending_age_seconds,
  p.attempts AS push_attempts_15m,
  p.delivered AS push_delivered_15m,
  p.dead_letter AS push_dead_letter_15m,
  CASE WHEN p.attempts = 0 THEN 100.0
       ELSE ROUND((p.delivered::NUMERIC * 100.0) / p.attempts, 3)
  END::DOUBLE PRECISION AS push_success_percent_15m,
  p.p95_latency_ms AS push_p95_latency_ms_15m
FROM queue q CROSS JOIN recent_push p;

COMMIT;
