from django.urls import path

from . import views, views_city_pilot, views_blog, views_group_covers, views_photo_themes, views_rooms
from . import views_client_errors
from . import views_support
from . import views_business
from . import views_analytics

urlpatterns = [
    # ── Product analytics (durable snapshots; analyst/admin) ──────────────────
    path("analytics/", views_analytics.analytics_overview, name="analytics_overview"),
    path("analytics/funnel/", views_analytics.analytics_funnel, name="analytics_funnel"),
    path("analytics/retention/", views_analytics.analytics_retention, name="analytics_retention"),
    path("analytics/engagement/", views_analytics.analytics_engagement, name="analytics_engagement"),
    path("analytics/liquidity/", views_analytics.analytics_liquidity, name="analytics_liquidity"),
    path("analytics/safety/", views_analytics.analytics_safety, name="analytics_safety"),
    path("analytics/data/", views_analytics.analytics_data, name="analytics_data"),
    path("analytics/data/rebuild/", views_analytics.analytics_rebuild, name="analytics_rebuild"),
    path("analytics/data/exclusions/", views_analytics.analytics_exclude, name="analytics_exclude"),
    path("analytics/data/exclusions/<uuid:member_id>/remove/", views_analytics.analytics_include, name="analytics_include"),
    path("analytics/export/<slug:report>/", views_analytics.analytics_export, name="analytics_export"),
    # ── Business (commercial) reports ─────────────────────────────────────────
    path("business/", views_business.business_revenue, name="business_revenue"),
    path("business/subscriptions/", views_business.business_subscriptions, name="business_subscriptions"),
    path("business/conversion/", views_business.business_conversion, name="business_conversion"),
    path("business/coins/", views_business.business_coins, name="business_coins"),
    path("business/referrals/", views_business.business_referrals, name="business_referrals"),
    path("business/markets/", views_business.business_markets, name="business_markets"),
    path("business/markets/save/", views_business.business_market_save, name="business_market_save"),
    path("business/investor-pack/", views_business.business_investor_pack, name="business_investor_pack"),
    path("business/spend/", views_business.business_spend, name="business_spend"),
    path("business/spend/save/", views_business.business_spend_save, name="business_spend_save"),
    path("business/spend/<str:spend_id>/delete/", views_business.business_spend_delete, name="business_spend_delete"),
    path("business/csv/<str:report>/", views_business.business_csv, name="business_csv"),
    path("engagement/photo-themes/", views_photo_themes.photo_themes, name="photo_themes"),
    path("engagement/photo-themes/save/", views_photo_themes.photo_theme_save, name="photo_theme_save"),
    path("moderation/rooms/", views_rooms.rooms, name="rooms"),
    path("moderation/rooms/<uuid:room_id>/", views_rooms.room_detail, name="room_detail"),
    path("moderation/rooms/<uuid:room_id>/actions/", views_rooms.room_action, name="room_action"),
    path("moderation/rooms/<uuid:room_id>/roles/", views_rooms.room_role, name="room_role"),
    path("moderation/group-covers/", views_group_covers.group_covers, name="group_covers"),
    path("moderation/group-covers/<uuid:cover_id>/content/", views_group_covers.group_cover_content, name="group_cover_content"),
    path("moderation/group-covers/<uuid:cover_id>/decision/", views_group_covers.group_cover_decision, name="group_cover_decision"),
    path("moderation/blog/", views_blog.blog_reviews, name="blog_reviews"),
    path("moderation/blog/<uuid:case_id>/decision/", views_blog.blog_decision, name="blog_decision"),
    path("moderation/blog/<uuid:case_id>/photos/<uuid:photo_id>/", views_blog.blog_evidence, name="blog_evidence"),
    path("city-pilot/", views_city_pilot.city_pilot, name="city_pilot"),
    path("city-pilot/save/", views_city_pilot.city_pilot_save, name="city_pilot_save"),
    path("city-pilot/<uuid:pilot_id>/stage/", views_city_pilot.city_pilot_stage, name="city_pilot_stage"),
    path("city-pilot/<uuid:pilot_id>/experiences/", views_city_pilot.city_pilot_experience_create, name="city_pilot_experience_create"),
    path("city-pilot/<uuid:pilot_id>/experiences/<uuid:event_id>/cancel/", views_city_pilot.city_pilot_experience_cancel, name="city_pilot_experience_cancel"),
    path("login/", views.operator_login, name="operator_login"),
    path("logout/", views.operator_logout, name="operator_logout"),
    # ── Dashboard ─────────────────────────────────────────────────────────────
    path("", views.dashboard, name="dashboard"),

    # ── Verifications ─────────────────────────────────────────────────────────
    path("verifications/", views.verification_queue, name="verification_queue"),
    path("verifications/<str:user_id>/approve/", views.approve_verification, name="approve_verification"),
    path("verifications/<str:user_id>/reject/", views.reject_verification, name="reject_verification"),

    # ── Activity Feed ─────────────────────────────────────────────────────────
    path("activities/", views.activity_feed, name="activity_feed"),
    path("audit/", views.audit_log, name="audit_log"),
    path("events/", views.domain_events, name="domain_events"),
    path("client-errors/", views_client_errors.client_errors, name="client_errors"),
    path("client-errors/<uuid:issue_id>/", views_client_errors.client_error_detail, name="client_error_detail"),
    path("client-errors/<uuid:issue_id>/status/", views_client_errors.client_error_status, name="client_error_status"),

    # ── Appeals ───────────────────────────────────────────────────────────────
    path("appeals/", views.appeal_queue, name="appeal_queue"),
    path("appeals/<str:appeal_id>/action/", views.action_appeal, name="action_appeal"),

    # ── Support tickets (views_support.py) ───────────────────────────────────
    path("support/", views_support.support_queue, name="support_queue"),
    path("support/export/", views_support.support_export, name="support_export"),
    path("support/bulk/", views_support.support_bulk, name="support_bulk"),
    path("support/dashboard/", views_support.support_dashboard, name="support_dashboard"),
    path("support/canned/", views_support.support_canned_responses, name="support_canned_responses"),
    path("support/canned/save/", views_support.support_canned_save, name="support_canned_save"),
    path("support/canned/<uuid:response_id>/deactivate/", views_support.support_canned_deactivate, name="support_canned_deactivate"),
    path("support/attachments/<uuid:attachment_id>/", views_support.support_attachment, name="support_attachment"),
    path("support/tickets/<uuid:ticket_id>/", views_support.support_ticket_detail, name="support_ticket_detail"),
    path("support/tickets/<uuid:ticket_id>/reply/", views_support.support_ticket_reply, name="support_ticket_reply"),
    path("support/tickets/<uuid:ticket_id>/update/", views_support.support_ticket_update, name="support_ticket_update"),
    path("support/tickets/<uuid:ticket_id>/claim/", views_support.support_ticket_claim, name="support_ticket_claim"),
    path("support/tickets/<uuid:ticket_id>/merge/", views_support.support_ticket_merge, name="support_ticket_merge"),
    path(
        "support/tickets/<uuid:ticket_id>/canned/<uuid:response_id>/preview/",
        views_support.support_canned_preview,
        name="support_canned_preview",
    ),
    # ── Growth governance (P2 launch register) ────────────────────────────────
    path("growth/governance/", views.growth_governance, name="growth_governance"),

    # ── Moderation Reports ────────────────────────────────────────────────────
    path("moderation/reports/", views.moderation_reports, name="moderation_reports"),
    path("moderation/reports/<str:report_id>/action/", views.action_report, name="action_report"),
    path("moderation/media/", views.media_moderation_queue, name="media_moderation_queue"),
    path("moderation/media/<str:photo_id>/content/", views.media_moderation_content, name="media_moderation_content"),
    path("moderation/media/<str:photo_id>/decision/", views.media_moderation_decision, name="media_moderation_decision"),

    # ── Gift Catalog ──────────────────────────────────────────────────────────
    path("catalog/", views.catalog_list, name="catalog_list"),
    path("catalog/new/", views.catalog_new, name="catalog_new"),
    path("catalog/<str:gift_id>/edit/", views.catalog_edit, name="catalog_edit"),
    path("catalog/<str:gift_id>/toggle/", views.catalog_toggle, name="catalog_toggle"),
    path("catalog/<str:gift_id>/delete/", views.catalog_delete, name="catalog_delete"),

    # ── User Management ───────────────────────────────────────────────────────
    path("users/", views.user_list, name="user_list"),
    path("users/new/", views.user_create, name="user_create"),
    path("users/<str:user_id>/", views.user_detail, name="user_detail"),
    path("users/<str:user_id>/edit/", views.user_edit, name="user_edit"),
    path("users/<str:user_id>/delete/", views.user_delete, name="user_delete"),
    path("users/<str:user_id>/suspend/", views.user_suspend, name="user_suspend"),
    path("users/<str:user_id>/unsuspend/", views.user_unsuspend, name="user_unsuspend"),
    path("users/<str:user_id>/ban/", views.user_ban, name="user_ban"),
    path("users/<str:user_id>/unban/", views.user_unban, name="user_unban"),
    path("users/<str:user_id>/verify/", views.user_force_verify, name="user_force_verify"),
    path("users/<str:user_id>/grant-coins/", views.user_grant_coins, name="user_grant_coins"),

    # ── Feature Flags ─────────────────────────────────────────────────────────
    path("config/flags/", views.config_flags, name="config_flags"),
    path("config/flags/<str:key>/toggle/", views.config_flag_toggle, name="config_flag_toggle"),

    # ── Engagement ────────────────────────────────────────────────────────────
    path("engagement/prompts/", views.engagement_prompts, name="engagement_prompts"),
    path("engagement/prompts/new/", views.engagement_prompt_new, name="engagement_prompt_new"),
    path("engagement/prompts/<str:prompt_id>/edit/", views.engagement_prompt_edit, name="engagement_prompt_edit"),
    path("engagement/prompts/<str:prompt_id>/activate/", views.engagement_prompt_activate, name="engagement_prompt_activate"),
    path("engagement/nudges/", views.engagement_nudges, name="engagement_nudges"),

    # ── Level / XP progression ───────────────────────────────────────────────
    path("progression/", views.progression_admin, name="progression_admin"),
    path("progression/policies/<str:source>/", views.progression_policy_update, name="progression_policy_update"),
    path("progression/experiments/<str:key>/", views.progression_experiment_update, name="progression_experiment_update"),
    path("progression/fraud-rules/<str:rule_code>/", views.progression_fraud_rule_update, name="progression_fraud_rule_update"),
    path("progression/fraud/<str:case_id>/", views.progression_fraud_resolve, name="progression_fraud_resolve"),
    path("progression/users/adjust/", views.progression_user_adjust, name="progression_user_adjust"),
    path("progression/users/control/", views.progression_user_control, name="progression_user_control"),

    # ── Billing ───────────────────────────────────────────────────────────────
    path("billing/", views.billing_dashboard, name="billing_dashboard"),
    path("billing/packages/<str:package_id>/toggle/", views.billing_package_toggle, name="billing_package_toggle"),
    path("billing/packages/new/", views.billing_package_new, name="billing_package_new"),
    path("billing/packages/<str:package_id>/edit/", views.billing_package_edit, name="billing_package_edit"),
    path("billing/transactions/", views.billing_transactions, name="billing_transactions"),
    path("billing/grant-coins/", views.billing_grant_coins, name="billing_grant_coins"),
    path("billing/subscriptions/", views.billing_subscriptions, name="billing_subscriptions"),
    path("billing/payments/", views.billing_payments, name="billing_payments"),
    path("billing/revenue/", views.billing_revenue_analytics, name="billing_revenue_analytics"),
    path("billing/webhooks/", views.billing_webhook_events, name="billing_webhook_events"),
    path("billing/reconciliation/", views.billing_reconciliation, name="billing_reconciliation"),
    path("billing/gifts/reverse/", views.billing_gift_reverse, name="billing_gift_reverse"),
    path(
        "billing/wallets/<str:user_id>/review/",
        views.billing_wallet_review,
        name="billing_wallet_review",
    ),
    path("billing/fraud/cases/<str:case_id>/resolve/", views.billing_fraud_case_resolve, name="billing_fraud_case_resolve"),
    path("billing/fraud/rules/<str:rule_code>/", views.billing_fraud_rule_update, name="billing_fraud_rule_update"),

    # ── Safety / SOS ──────────────────────────────────────────────────────────
    path("safety/sos/", views.safety_sos, name="safety_sos"),
    path("safety/sos/<str:alert_id>/resolve/", views.safety_sos_resolve, name="safety_sos_resolve"),

    # ── Account recovery (lost recovery code) ─────────────────────────────────
    path("account-recovery/", views.account_recovery_queue, name="account_recovery_queue"),
    path(
        "account-recovery/<str:request_id>/resolve/",
        views.account_recovery_resolve,
        name="account_recovery_resolve",
    ),
]
