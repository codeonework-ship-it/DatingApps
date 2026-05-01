from django.urls import path

from . import views

urlpatterns = [
    # ── Dashboard ─────────────────────────────────────────────────────────────
    path("", views.dashboard, name="dashboard"),

    # ── Verifications ─────────────────────────────────────────────────────────
    path("verifications/", views.verification_queue, name="verification_queue"),
    path("verifications/<str:user_id>/approve/", views.approve_verification, name="approve_verification"),
    path("verifications/<str:user_id>/reject/", views.reject_verification, name="reject_verification"),

    # ── Activity Feed ─────────────────────────────────────────────────────────
    path("activities/", views.activity_feed, name="activity_feed"),

    # ── Appeals ───────────────────────────────────────────────────────────────
    path("appeals/", views.appeal_queue, name="appeal_queue"),
    path("appeals/<str:appeal_id>/action/", views.action_appeal, name="action_appeal"),

    # ── Moderation Reports ────────────────────────────────────────────────────
    path("moderation/reports/", views.moderation_reports, name="moderation_reports"),
    path("moderation/reports/<str:report_id>/action/", views.action_report, name="action_report"),

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

    # ── Safety / SOS ──────────────────────────────────────────────────────────
    path("safety/sos/", views.safety_sos, name="safety_sos"),
    path("safety/sos/<str:alert_id>/resolve/", views.safety_sos_resolve, name="safety_sos_resolve"),
]

