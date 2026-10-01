# Connect — Document Source Register

Inventory date: 2026-09-26. Local checkout only; no external document system was queried.

Inventoried 103 first-party Markdown, contract and migration-order documents. Generated consolidation files, vendor dependencies, screenshots, machine logs, seed data and test-result artifacts are not counted as source specifications. No standalone file named FRD was found; five BRDs and the profile-details BA are the detailed requirement sources.

## Review method

The five BRDs and profile-details BA received detailed requirement review, along with the current architecture and key completion/acceptance reports. Historical plans/runbooks/QA were reviewed for scope, status, relevant sections and supersession; the inventory is not a claim that every historical code block or every generated test artifact was revalidated. OpenAPI received route/contract section review, not an exhaustive schema audit. Review depth is recorded below. All original files remain unchanged.

## Source aliases used by the FRD and traceability

| Alias | Source | Treatment |
|---|---|---|
| SIGNUP | [SIGNUP_WORKFLOW_LOCAL_POSTGRES_ARCHITECTURE.md](SIGNUP_WORKFLOW_LOCAL_POSTGRES_ARCHITECTURE.md) | Current-topic decision or scoped local evidence; production residuals retained |
| AUTH | [AUTH_SECURITY_FOUNDATION_LOCAL_POSTGRES.md](AUTH_SECURITY_FOUNDATION_LOCAL_POSTGRES.md) | Current-topic decision or scoped local evidence; production residuals retained |
| PROFILE | [BRD_PROFILE_SETUP_FLOW_SCREENS_4_TO_8_2026-04-11.md](BRD_PROFILE_SETUP_FLOW_SCREENS_4_TO_8_2026-04-11.md) | Retain detailed intent; supersede conflicting runtime/policy assumptions explicitly |
| RUNTIME | [NATIVE_POSTGRES_RUNTIME_CONVERSION.md](NATIVE_POSTGRES_RUNTIME_CONVERSION.md) | Current-topic decision or scoped local evidence; production residuals retained |
| CORE | [CORE_DATING_NATIVE_POSTGRES_REALTIME.md](CORE_DATING_NATIVE_POSTGRES_REALTIME.md) | Current-topic decision or scoped local evidence; production residuals retained |
| SAFETY | [SAFETY_MODERATION_ENFORCEMENT_LOCAL_POSTGRES.md](SAFETY_MODERATION_ENFORCEMENT_LOCAL_POSTGRES.md) | Current-topic decision or scoped local evidence; production residuals retained |
| MEDIA | [PROFILE_MEDIA_LIFECYCLE_REPORT_2026-08-09.md](codex/completed/PROFILE_MEDIA_LIFECYCLE_REPORT_2026-08-09.md) | Current-topic decision or scoped local evidence; production residuals retained |
| MODERATION | [MEDIA_MODERATION_PRODUCTION_INTEGRATION_REPORT_2026-08-09.md](codex/completed/MEDIA_MODERATION_PRODUCTION_INTEGRATION_REPORT_2026-08-09.md) | Current-topic decision or scoped local evidence; production residuals retained |
| ADMIN-BRD | [BRD_ADMIN_CONTROL_PANEL_2026-04-11.md](codex/BRD_ADMIN_CONTROL_PANEL_2026-04-11.md) | Retain detailed intent; supersede conflicting runtime/policy assumptions explicitly |
| USER-ADMIN | [BRD_USER_MANAGEMENT_ADMIN_CONSOLE_2026-04-18.md](codex/BRD_USER_MANAGEMENT_ADMIN_CONSOLE_2026-04-18.md) | Retain detailed intent; supersede conflicting runtime/policy assumptions explicitly |
| BILLING | [BRD_BILLING_PLANS_ADMIN_CONSOLE_2026-04-18.md](codex/BRD_BILLING_PLANS_ADMIN_CONSOLE_2026-04-18.md) | Retain detailed intent; supersede conflicting runtime/policy assumptions explicitly |
| ADMIN | [ADMIN_CONTROL_PLANE_REPORT_2026-08-09.md](codex/completed/ADMIN_CONTROL_PLANE_REPORT_2026-08-09.md) | Current-topic decision or scoped local evidence; production residuals retained |
| PUSH | [NOTIFICATION_PRODUCTION_INTEGRATION_REPORT_2026-08-09.md](codex/completed/NOTIFICATION_PRODUCTION_INTEGRATION_REPORT_2026-08-09.md) | Current-topic decision or scoped local evidence; production residuals retained |
| NOTIFICATIONS | [NOTIFICATION_ASYNC_DELIVERY_REPORT_2026-08-09.md](codex/completed/NOTIFICATION_ASYNC_DELIVERY_REPORT_2026-08-09.md) | Current-topic decision or scoped local evidence; production residuals retained |
| PUSH-ACCEPTANCE | [NOTIFICATION_PRODUCTION_DEVICE_ACCEPTANCE_2026-08-09.md](codex/NOTIFICATION_PRODUCTION_DEVICE_ACCEPTANCE_2026-08-09.md) | Current-topic decision or scoped local evidence; production residuals retained |
| RELIABILITY | [RELIABILITY_SCALE_GUARDRAILS_LOCAL_POSTGRES.md](RELIABILITY_SCALE_GUARDRAILS_LOCAL_POSTGRES.md) | Current-topic decision or scoped local evidence; production residuals retained |
| LEVELS | [LEVEL_XP_PROGRESSION_LOCAL_POSTGRES.md](LEVEL_XP_PROGRESSION_LOCAL_POSTGRES.md) | Current-topic decision or scoped local evidence; production residuals retained |
| LEVEL-BRAINSTORM | [08_LEVEL_SYSTEM_ENGAGEMENT_BRAINSTORM.md](08_LEVEL_SYSTEM_ENGAGEMENT_BRAINSTORM.md) | Proposal/target origin; use later decisions for current rules |
| LEVEL-EVIDENCE | [LEVEL_XP_PROGRESSION_REPORT_2026-08-09.md](codex/completed/LEVEL_XP_PROGRESSION_REPORT_2026-08-09.md) | Current-topic decision or scoped local evidence; production residuals retained |
| AUDIT | [PENDING_ENGINE_PRIORITY_AUDIT_2026-08-03.md](PENDING_ENGINE_PRIORITY_AUDIT_2026-08-03.md) | Current-topic decision or scoped local evidence; production residuals retained |
| DETAILS | [BA_VIEW_MORE_PROFILE_DETAILS_2026-04-11.md](codex/BA_VIEW_MORE_PROFILE_DETAILS_2026-04-11.md) | Retain detailed intent; supersede conflicting runtime/policy assumptions explicitly |
| UNLOCK | [ACTIVITY_BASED_MATCHING_AND_CHAT_UNLOCK_PLAN.md](codex/ACTIVITY_BASED_MATCHING_AND_CHAT_UNLOCK_PLAN.md) | Current-topic decision or scoped local evidence; production residuals retained |
| ALIGNMENT | [JIRA_IMPORT_READY_ACTIVITY_UNLOCK_ALIGNMENT_BACKLOG_20260302.md](codex/JIRA_IMPORT_READY_ACTIVITY_UNLOCK_ALIGNMENT_BACKLOG_20260302.md) | Historical delivery/backlog mapping; not production approval |
| TRACKER | [JIRA_STORY_PROGRESS_TRACKER.md](codex/JIRA_STORY_PROGRESS_TRACKER.md) | Historical delivery/backlog mapping; not production approval |
| ACTIVITY | [EPIC4_STORY_4_1_ACTIVITY_SESSION_LIFECYCLE_REPORT.md](codex/completed/EPIC4_STORY_4_1_ACTIVITY_SESSION_LIFECYCLE_REPORT.md) | Current-topic decision or scoped local evidence; production residuals retained |
| ROSES | [ROSE_GIFTS_AGILE_PRODUCT_AND_SPRINT_PLAN_2026-03-19.md](codex/ROSE_GIFTS_AGILE_PRODUCT_AND_SPRINT_PLAN_2026-03-19.md) | Proposal/target origin; use later decisions for current rules |
| GIFTS | [BRD_GIFT_CATALOG_EXPANSION_2026-04-11.md](codex/BRD_GIFT_CATALOG_EXPANSION_2026-04-11.md) | Retain detailed intent; supersede conflicting runtime/policy assumptions explicitly |
| ROSE-CLOSEOUT | [ROSE_GIFTS_QA_SIGNOFF_PACKET_2026-03-19.md](codex/completed/ROSE_GIFTS_QA_SIGNOFF_PACKET_2026-03-19.md) | Current-topic decision or scoped local evidence; production residuals retained |
| ENGAGEMENT | [04_ENGAGEMENT_RETENTION_BRAINSTORM.md](04_ENGAGEMENT_RETENTION_BRAINSTORM.md) | Proposal/target origin; use later decisions for current rules |
| ACTIVITY-BLUEPRINT | [07_USER_ENGAGEMENT_ACTIVITY_BLUEPRINT.md](07_USER_ENGAGEMENT_ACTIVITY_BLUEPRINT.md) | Proposal/target origin; use later decisions for current rules |
| QA | [QA_TEST_CASE_CATALOG_2026-05-10.md](qa/QA_TEST_CASE_CATALOG_2026-05-10.md) | Current-topic decision or scoped local evidence; production residuals retained |
| ENGAGEMENT-EVIDENCE | [ENGAGEMENT_PERSISTENCE_UI_BREADTH_REPORT_2026-08-09.md](codex/completed/ENGAGEMENT_PERSISTENCE_UI_BREADTH_REPORT_2026-08-09.md) | Current-topic decision or scoped local evidence; production residuals retained |
| JOURNEYS | [BACKEND_ONLY_USER_JOURNEYS_REPORT_2026-08-09.md](codex/completed/BACKEND_ONLY_USER_JOURNEYS_REPORT_2026-08-09.md) | Current-topic decision or scoped local evidence; production residuals retained |
| APPEALS | [ALN_3_4_5_APPEALS_AND_KPI_SIGNOFF_2026-03-03.md](codex/ALN_3_4_5_APPEALS_AND_KPI_SIGNOFF_2026-03-03.md) | Current-topic decision or scoped local evidence; production residuals retained |
| API | [openapi.yaml](../backend/internal/platform/docs/openapi.yaml) | Current API reference; exact contract lives here |
| API-SNAPSHOT | [openapi-mobile-bff-v2026-03-02.yaml](../backend/internal/platform/docs/contracts/openapi-mobile-bff-v2026-03-02.yaml) | Historical contract; current API file takes precedence |
| SCALE | [05_SCALE_CONCURRENCY_RELIABILITY_PLAN.md](05_SCALE_CONCURRENCY_RELIABILITY_PLAN.md) | Proposal/target origin; use later decisions for current rules |
| SCALE-BLUEPRINT | [06_10M_CONCURRENT_REQUESTS_BLUEPRINT.md](06_10M_CONCURRENT_REQUESTS_BLUEPRINT.md) | Proposal/target origin; use later decisions for current rules |
| QA-RELEASE | [QA_RELEASE_REGRESSION_REPORT_2026-08-09.md](codex/completed/QA_RELEASE_REGRESSION_REPORT_2026-08-09.md) | Current-topic decision or scoped local evidence; production residuals retained |
| LAUNCH | [ALN_4_2_OWNER_SIGNOFF_PACKET_2026-03-03.md](codex/ALN_4_2_OWNER_SIGNOFF_PACKET_2026-03-03.md) | Launch governance; pending fields remain pending |
| LAUNCH-GATE | [ALN_4_2_PHASE_A_RELEASE_GATE_CHECKLIST_2026-03-03.md](codex/ALN_4_2_PHASE_A_RELEASE_GATE_CHECKLIST_2026-03-03.md) | Launch governance; pending fields remain pending |
| LIVE-ADMIN | [README.md](../control-panel/README.md) | Current-topic decision or scoped local evidence; production residuals retained |

## Complete inventory

| Source | Type / authority treatment | Review depth | SHA-256 prefix |
|---|---|---|---|
| [app/DEVELOPER_GUIDE.md](../app/DEVELOPER_GUIDE.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `5727dced75d2` |
| [backend/internal/platform/docs/contracts/README.md](../backend/internal/platform/docs/contracts/README.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `9a41bd32d0a6` |
| [backend/internal/platform/docs/contracts/openapi-mobile-bff-v2026-03-02.yaml](../backend/internal/platform/docs/contracts/openapi-mobile-bff-v2026-03-02.yaml) | Historical versioned API snapshot | Scope/index review | `829b7c1e1c6c` |
| [backend/internal/platform/docs/openapi.yaml](../backend/internal/platform/docs/openapi.yaml) | Current API contract | Route/selected contract sections | `2fbb40ef2b6c` |
| [backend/observability/elk/README.md](../backend/observability/elk/README.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `55c0344f052e` |
| [backend/observability/elk/kibana/quickstart.md](../backend/observability/elk/kibana/quickstart.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `36c2721f9941` |
| [backend/scripts_run_order.txt](../backend/scripts_run_order.txt) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `056403568baf` |
| [control-panel/README.md](../control-panel/README.md) | Topic decision / evidence / governance (see alias table) | Detailed | `cbb54dfacbff` |
| [documents/04_ENGAGEMENT_RETENTION_BRAINSTORM.md](04_ENGAGEMENT_RETENTION_BRAINSTORM.md) | Product/scale proposals; later decisions override | Detailed | `ec45488c7804` |
| [documents/05_SCALE_CONCURRENCY_RELIABILITY_PLAN.md](05_SCALE_CONCURRENCY_RELIABILITY_PLAN.md) | Topic decision / evidence / governance (see alias table) | Detailed | `b48c84235374` |
| [documents/06_10M_CONCURRENT_REQUESTS_BLUEPRINT.md](06_10M_CONCURRENT_REQUESTS_BLUEPRINT.md) | Product/scale proposals; later decisions override | Detailed | `4d14b96dda97` |
| [documents/06_10M_SLO_DASHBOARDS_AND_PLAYBOOKS.md](06_10M_SLO_DASHBOARDS_AND_PLAYBOOKS.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `31343fb88fc9` |
| [documents/07_USER_ENGAGEMENT_ACTIVITY_BLUEPRINT.md](07_USER_ENGAGEMENT_ACTIVITY_BLUEPRINT.md) | Product/scale proposals; later decisions override | Detailed | `878f42112fd7` |
| [documents/08_LEVEL_SYSTEM_ENGAGEMENT_BRAINSTORM.md](08_LEVEL_SYSTEM_ENGAGEMENT_BRAINSTORM.md) | Product/scale proposals; later decisions override | Detailed | `81db7c7b4d76` |
| [documents/AUTH_SECURITY_FOUNDATION_LOCAL_POSTGRES.md](AUTH_SECURITY_FOUNDATION_LOCAL_POSTGRES.md) | Topic decision / evidence / governance (see alias table) | Detailed | `734f8f1d1508` |
| [documents/BRD_PROFILE_SETUP_FLOW_SCREENS_4_TO_8_2026-04-11.md](BRD_PROFILE_SETUP_FLOW_SCREENS_4_TO_8_2026-04-11.md) | Detailed business/functional requirements; mixed current and superseded assumptions | Detailed requirements | `b35ed0122179` |
| [documents/CORE_DATING_NATIVE_POSTGRES_REALTIME.md](CORE_DATING_NATIVE_POSTGRES_REALTIME.md) | Topic decision / evidence / governance (see alias table) | Detailed | `33c71aa7594b` |
| [documents/FLUTTER_LOCAL_TERMINAL_AND_AVD_RUN_GUIDE.md](FLUTTER_LOCAL_TERMINAL_AND_AVD_RUN_GUIDE.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `1dfea64dcc11` |
| [documents/LEVEL_XP_PROGRESSION_LOCAL_POSTGRES.md](LEVEL_XP_PROGRESSION_LOCAL_POSTGRES.md) | Topic decision / evidence / governance (see alias table) | Detailed | `9460e19631b9` |
| [documents/NATIVE_POSTGRES_RUNTIME_CONVERSION.md](NATIVE_POSTGRES_RUNTIME_CONVERSION.md) | Topic decision / evidence / governance (see alias table) | Detailed | `674c8d8cd799` |
| [documents/PENDING_ENGINE_PRIORITY_AUDIT_2026-08-03.md](PENDING_ENGINE_PRIORITY_AUDIT_2026-08-03.md) | Topic decision / evidence / governance (see alias table) | Detailed | `d6d28f5ba374` |
| [documents/RELIABILITY_SCALE_GUARDRAILS_LOCAL_POSTGRES.md](RELIABILITY_SCALE_GUARDRAILS_LOCAL_POSTGRES.md) | Topic decision / evidence / governance (see alias table) | Detailed | `ce9d20953b08` |
| [documents/SAFETY_MODERATION_ENFORCEMENT_LOCAL_POSTGRES.md](SAFETY_MODERATION_ENFORCEMENT_LOCAL_POSTGRES.md) | Topic decision / evidence / governance (see alias table) | Detailed | `7b2e7b937e28` |
| [documents/SIGNUP_WORKFLOW_LOCAL_POSTGRES_ARCHITECTURE.md](SIGNUP_WORKFLOW_LOCAL_POSTGRES_ARCHITECTURE.md) | Topic decision / evidence / governance (see alias table) | Detailed | `9c04e45e096a` |
| [documents/VPS_FIRST_TIME_BRINGUP_CHECKLIST.md](VPS_FIRST_TIME_BRINGUP_CHECKLIST.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `aee257f5eaf2` |
| [documents/VPS_NGINX_AND_FLUTTER_PRODUCTION_RUNBOOK.md](VPS_NGINX_AND_FLUTTER_PRODUCTION_RUNBOOK.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `be20ddb50144` |
| [documents/codex/ACTIVITY_BASED_MATCHING_AND_CHAT_UNLOCK_PLAN.md](codex/ACTIVITY_BASED_MATCHING_AND_CHAT_UNLOCK_PLAN.md) | Topic decision / evidence / governance (see alias table) | Detailed | `e9448a5a6824` |
| [documents/codex/ALN_2_1_DURABLE_STORE_INVENTORY_20260302.md](codex/ALN_2_1_DURABLE_STORE_INVENTORY_20260302.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `9e010fc0fa9d` |
| [documents/codex/ALN_3_4_5_APPEALS_AND_KPI_SIGNOFF_2026-03-03.md](codex/ALN_3_4_5_APPEALS_AND_KPI_SIGNOFF_2026-03-03.md) | Topic decision / evidence / governance (see alias table) | Detailed | `469b5fb67a74` |
| [documents/codex/ALN_4_2_ESCALATION_PATH_TEMPLATE_2026-03-03.md](codex/ALN_4_2_ESCALATION_PATH_TEMPLATE_2026-03-03.md) | Launch runbook/template; unsigned items remain open | Scope/status/governance sections | `9677af753581` |
| [documents/codex/ALN_4_2_MODERATION_STAFFING_ROSTER_TEMPLATE_2026-03-03.md](codex/ALN_4_2_MODERATION_STAFFING_ROSTER_TEMPLATE_2026-03-03.md) | Launch runbook/template; unsigned items remain open | Scope/status/governance sections | `92151075be43` |
| [documents/codex/ALN_4_2_OWNER_SIGNOFF_PACKET_2026-03-03.md](codex/ALN_4_2_OWNER_SIGNOFF_PACKET_2026-03-03.md) | Topic decision / evidence / governance (see alias table) | Detailed | `2da7f2ae952c` |
| [documents/codex/ALN_4_2_PHASE_A_GO_NO_GO_RUNBOOK_2026-03-03.md](codex/ALN_4_2_PHASE_A_GO_NO_GO_RUNBOOK_2026-03-03.md) | Launch runbook/template; unsigned items remain open | Scope/status/governance sections | `66a1fc9d1372` |
| [documents/codex/ALN_4_2_PHASE_A_RELEASE_GATE_CHECKLIST_2026-03-03.md](codex/ALN_4_2_PHASE_A_RELEASE_GATE_CHECKLIST_2026-03-03.md) | Topic decision / evidence / governance (see alias table) | Detailed | `0eaa95ab329e` |
| [documents/codex/ALN_4_2_ROLLBACK_COMMUNICATION_TEMPLATE_2026-03-03.md](codex/ALN_4_2_ROLLBACK_COMMUNICATION_TEMPLATE_2026-03-03.md) | Launch runbook/template; unsigned items remain open | Scope/status/governance sections | `513eb806b880` |
| [documents/codex/ALN_4_2_STAGING_DRY_RUN_EVIDENCE_2026-03-03.md](codex/ALN_4_2_STAGING_DRY_RUN_EVIDENCE_2026-03-03.md) | Launch runbook/template; unsigned items remain open | Scope/status/governance sections | `5b9769321fb5` |
| [documents/codex/BA_VIEW_MORE_PROFILE_DETAILS_2026-04-11.md](codex/BA_VIEW_MORE_PROFILE_DETAILS_2026-04-11.md) | Detailed business/functional requirements; mixed current and superseded assumptions | Detailed requirements | `da4cdc815f93` |
| [documents/codex/BRD_ADMIN_CONTROL_PANEL_2026-04-11.md](codex/BRD_ADMIN_CONTROL_PANEL_2026-04-11.md) | Detailed business/functional requirements; mixed current and superseded assumptions | Detailed requirements | `3f3ef982f078` |
| [documents/codex/BRD_BILLING_PLANS_ADMIN_CONSOLE_2026-04-18.md](codex/BRD_BILLING_PLANS_ADMIN_CONSOLE_2026-04-18.md) | Detailed business/functional requirements; mixed current and superseded assumptions | Detailed requirements | `318f5d9d2f84` |
| [documents/codex/BRD_GIFT_CATALOG_EXPANSION_2026-04-11.md](codex/BRD_GIFT_CATALOG_EXPANSION_2026-04-11.md) | Detailed business/functional requirements; mixed current and superseded assumptions | Detailed requirements | `111c7c8015ca` |
| [documents/codex/BRD_USER_MANAGEMENT_ADMIN_CONSOLE_2026-04-18.md](codex/BRD_USER_MANAGEMENT_ADMIN_CONSOLE_2026-04-18.md) | Detailed business/functional requirements; mixed current and superseded assumptions | Detailed requirements | `cac32aebba8c` |
| [documents/codex/JIRA_IMPORT_READY_10M_CONCURRENCY_BACKLOG.md](codex/JIRA_IMPORT_READY_10M_CONCURRENCY_BACKLOG.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `b96ea6f3115a` |
| [documents/codex/JIRA_IMPORT_READY_ACTIVITY_UNLOCK_ALIGNMENT_BACKLOG_20260302.md](codex/JIRA_IMPORT_READY_ACTIVITY_UNLOCK_ALIGNMENT_BACKLOG_20260302.md) | Topic decision / evidence / governance (see alias table) | Detailed | `2c2b3a220cbc` |
| [documents/codex/JIRA_IMPORT_READY_ACTIVITY_UNLOCK_BACKLOG.md](codex/JIRA_IMPORT_READY_ACTIVITY_UNLOCK_BACKLOG.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `24d6c0a467fb` |
| [documents/codex/JIRA_STORY_PROGRESS_TRACKER.md](codex/JIRA_STORY_PROGRESS_TRACKER.md) | Topic decision / evidence / governance (see alias table) | Relevant sections | `15f53b7457d4` |
| [documents/codex/NOTIFICATION_PRODUCTION_DEVICE_ACCEPTANCE_2026-08-09.md](codex/NOTIFICATION_PRODUCTION_DEVICE_ACCEPTANCE_2026-08-09.md) | Topic decision / evidence / governance (see alias table) | Detailed | `58e1031f9de8` |
| [documents/codex/PERSISTENCE_TABLE_BACKLOG_2026-03-21.md](codex/PERSISTENCE_TABLE_BACKLOG_2026-03-21.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `da5268a03028` |
| [documents/codex/PHASE2_RESPONSIVE_AUDIT_CHECKLIST.md](codex/PHASE2_RESPONSIVE_AUDIT_CHECKLIST.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `ae6720c29846` |
| [documents/codex/PHASED_IMPLEMENTATION_PLAN_ACTIVITY_UNLOCK.md](codex/PHASED_IMPLEMENTATION_PLAN_ACTIVITY_UNLOCK.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `f0346691f65d` |
| [documents/codex/ROSE_GIFTS_AGILE_PRODUCT_AND_SPRINT_PLAN_2026-03-19.md](codex/ROSE_GIFTS_AGILE_PRODUCT_AND_SPRINT_PLAN_2026-03-19.md) | Topic decision / evidence / governance (see alias table) | Detailed | `da8eb9a853ae` |
| [documents/codex/ROSE_GIFTS_DELTA_EXECUTION_PLAN_2026-03-19.md](codex/ROSE_GIFTS_DELTA_EXECUTION_PLAN_2026-03-19.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `5148b9f7ae91` |
| [documents/codex/ROSE_GIFTS_KICKOFF_BOARD_SETUP_2026-03-19.md](codex/ROSE_GIFTS_KICKOFF_BOARD_SETUP_2026-03-19.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `f8528f113f40` |
| [documents/codex/ROSE_GIFTS_QA_SIGNOFF_PACKET_2026-03-19.md](codex/ROSE_GIFTS_QA_SIGNOFF_PACKET_2026-03-19.md) | Supporting plan, backlog, or operational reference | Scope/status/relevant sections | `838d9c775388` |
| [documents/codex/UI_SMOKE_CHECKLIST_20260228T204220Z.md](codex/UI_SMOKE_CHECKLIST_20260228T204220Z.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `309eb355b2c2` |
| [documents/codex/UI_SMOKE_CHECKLIST_20260228T204309Z.md](codex/UI_SMOKE_CHECKLIST_20260228T204309Z.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `b98d8480271f` |
| [documents/codex/UI_SMOKE_CHECKLIST_20260228T204641Z.md](codex/UI_SMOKE_CHECKLIST_20260228T204641Z.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `9f676832b3bc` |
| [documents/codex/UI_SMOKE_CHECKLIST_20260228T204751Z.md](codex/UI_SMOKE_CHECKLIST_20260228T204751Z.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `ac782b83596a` |
| [documents/codex/UI_SMOKE_CHECKLIST_20260301T053640Z.md](codex/UI_SMOKE_CHECKLIST_20260301T053640Z.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `a073c6e0bf04` |
| [documents/codex/UI_SMOKE_CHECKLIST_20260301T055237Z.md](codex/UI_SMOKE_CHECKLIST_20260301T055237Z.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `74912cd0b978` |
| [documents/codex/UI_SMOKE_CHECKLIST_20260301T060139Z.md](codex/UI_SMOKE_CHECKLIST_20260301T060139Z.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `1acb5440df03` |
| [documents/codex/UI_SMOKE_CHECKLIST_20260301T060354Z.md](codex/UI_SMOKE_CHECKLIST_20260301T060354Z.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `5bbf11a86613` |
| [documents/codex/completed/ADMIN_CONTROL_PLANE_REPORT_2026-08-09.md](codex/completed/ADMIN_CONTROL_PLANE_REPORT_2026-08-09.md) | Topic decision / evidence / governance (see alias table) | Detailed | `6f16571976ca` |
| [documents/codex/completed/BACKEND_ONLY_USER_JOURNEYS_REPORT_2026-08-09.md](codex/completed/BACKEND_ONLY_USER_JOURNEYS_REPORT_2026-08-09.md) | Topic decision / evidence / governance (see alias table) | Detailed | `acd588caeb46` |
| [documents/codex/completed/ENGAGEMENT_PERSISTENCE_UI_BREADTH_REPORT_2026-08-09.md](codex/completed/ENGAGEMENT_PERSISTENCE_UI_BREADTH_REPORT_2026-08-09.md) | Topic decision / evidence / governance (see alias table) | Detailed | `d8079ab27f54` |
| [documents/codex/completed/EPIC4_STORY_4_1_ACTIVITY_SESSION_LIFECYCLE_REPORT.md](codex/completed/EPIC4_STORY_4_1_ACTIVITY_SESSION_LIFECYCLE_REPORT.md) | Topic decision / evidence / governance (see alias table) | Detailed | `c2a17625a731` |
| [documents/codex/completed/EPIC4_STORY_4_2_ACTIVITY_UI_FLOW_REPORT.md](codex/completed/EPIC4_STORY_4_2_ACTIVITY_UI_FLOW_REPORT.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `a5341de00d9d` |
| [documents/codex/completed/EPIC5_STORY_5_1_TRUST_BADGES_REPORT.md](codex/completed/EPIC5_STORY_5_1_TRUST_BADGES_REPORT.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `6b79cc782f3d` |
| [documents/codex/completed/EPIC5_STORY_5_2_TRUST_FILTERS_REPORT.md](codex/completed/EPIC5_STORY_5_2_TRUST_FILTERS_REPORT.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `b89f1e4d790c` |
| [documents/codex/completed/EPIC6_STORY_6_1_ROOM_ENDPOINTS_REPORT.md](codex/completed/EPIC6_STORY_6_1_ROOM_ENDPOINTS_REPORT.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `eb838b4a49b7` |
| [documents/codex/completed/EPIC6_STORY_6_2_ROOM_MODERATION_REPORT.md](codex/completed/EPIC6_STORY_6_2_ROOM_MODERATION_REPORT.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `db4206585fe0` |
| [documents/codex/completed/EPIC7_STORY_7_1_TEST_COVERAGE_REPORT.md](codex/completed/EPIC7_STORY_7_1_TEST_COVERAGE_REPORT.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `667e8bc79733` |
| [documents/codex/completed/EPIC7_STORY_7_2_FEATURE_FLAGS_METRICS_REPORT.md](codex/completed/EPIC7_STORY_7_2_FEATURE_FLAGS_METRICS_REPORT.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `0b1ea077f403` |
| [documents/codex/completed/LEVEL_XP_PROGRESSION_REPORT_2026-08-09.md](codex/completed/LEVEL_XP_PROGRESSION_REPORT_2026-08-09.md) | Topic decision / evidence / governance (see alias table) | Relevant sections | `e0117661069f` |
| [documents/codex/completed/MEDIA_MODERATION_PRODUCTION_INTEGRATION_REPORT_2026-08-09.md](codex/completed/MEDIA_MODERATION_PRODUCTION_INTEGRATION_REPORT_2026-08-09.md) | Topic decision / evidence / governance (see alias table) | Detailed | `b22f958fccd4` |
| [documents/codex/completed/NOTIFICATION_ASYNC_DELIVERY_REPORT_2026-08-09.md](codex/completed/NOTIFICATION_ASYNC_DELIVERY_REPORT_2026-08-09.md) | Topic decision / evidence / governance (see alias table) | Detailed | `c6cbd084ccf6` |
| [documents/codex/completed/NOTIFICATION_PRODUCTION_INTEGRATION_REPORT_2026-08-09.md](codex/completed/NOTIFICATION_PRODUCTION_INTEGRATION_REPORT_2026-08-09.md) | Topic decision / evidence / governance (see alias table) | Detailed | `3d0a2ffc3705` |
| [documents/codex/completed/PHASE_1_STORY_1_1_ANDROID_EMULATOR_RUNBOOK.md](codex/completed/PHASE_1_STORY_1_1_ANDROID_EMULATOR_RUNBOOK.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `c0e4a76e5f90` |
| [documents/codex/completed/PHASE_1_STORY_1_2_BASELINE_REGRESSION_REPORT.md](codex/completed/PHASE_1_STORY_1_2_BASELINE_REGRESSION_REPORT.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `a949afe2bdde` |
| [documents/codex/completed/PROFILE_MEDIA_LIFECYCLE_REPORT_2026-08-09.md](codex/completed/PROFILE_MEDIA_LIFECYCLE_REPORT_2026-08-09.md) | Topic decision / evidence / governance (see alias table) | Detailed | `a553b2ab467e` |
| [documents/codex/completed/QA_RELEASE_REGRESSION_REPORT_2026-08-09.md](codex/completed/QA_RELEASE_REGRESSION_REPORT_2026-08-09.md) | Topic decision / evidence / governance (see alias table) | Detailed | `92aae1667451` |
| [documents/codex/completed/RELIABILITY_LOCAL_HARDENING_REPORT_2026-08-09.md](codex/completed/RELIABILITY_LOCAL_HARDENING_REPORT_2026-08-09.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `047668d31b00` |
| [documents/codex/completed/RELIABILITY_SCALE_GATE_REPORT_2026-08-09.md](codex/completed/RELIABILITY_SCALE_GATE_REPORT_2026-08-09.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `6fbbdc4581a1` |
| [documents/codex/completed/ROSE_GIFTS_KICKOFF_BOARD_SETUP_2026-03-19.md](codex/completed/ROSE_GIFTS_KICKOFF_BOARD_SETUP_2026-03-19.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `f8528f113f40` |
| [documents/codex/completed/ROSE_GIFTS_QA_SIGNOFF_PACKET_2026-03-19.md](codex/completed/ROSE_GIFTS_QA_SIGNOFF_PACKET_2026-03-19.md) | Topic decision / evidence / governance (see alias table) | Detailed | `cd7c4da301ae` |
| [documents/codex/completed/ROSE_GIFTS_SPRINT_01_EXECUTION_PLAN_2026-03-19.md](codex/completed/ROSE_GIFTS_SPRINT_01_EXECUTION_PLAN_2026-03-19.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `cf97d8d65306` |
| [documents/codex/completed/ROSE_GIFTS_TASK_STATUS_2026-03-19.md](codex/completed/ROSE_GIFTS_TASK_STATUS_2026-03-19.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `acef03167c8d` |
| [documents/qa/QA_AUTOMATION_EXECUTION_PLAN_2026-05-10.md](qa/QA_AUTOMATION_EXECUTION_PLAN_2026-05-10.md) | QA plan/coverage; validate mixed legacy assumptions | Scope/status/acceptance sections | `0beb53c6907a` |
| [documents/qa/QA_EXECUTION_REPORT_2026-05-10.md](qa/QA_EXECUTION_REPORT_2026-05-10.md) | Historical scoped evidence; not a current test pass | Scope/status/acceptance sections | `11bf2cb16ede` |
| [documents/qa/QA_TEST_CASE_CATALOG_2026-05-10.md](qa/QA_TEST_CASE_CATALOG_2026-05-10.md) | Topic decision / evidence / governance (see alias table) | Detailed | `c1b6d20f904e` |
| [documents/qa/UI_FEATURE_AUTOMATION_BACKLOG_2026-05-10.md](qa/UI_FEATURE_AUTOMATION_BACKLOG_2026-05-10.md) | QA plan/coverage; validate mixed legacy assumptions | Scope/status/acceptance sections | `a8449a2fd1c8` |
| [qa/appium/AUTOMATION_PLAN.md](../qa/appium/AUTOMATION_PLAN.md) | QA plan/coverage; validate mixed legacy assumptions | Scope/status/acceptance sections | `95ec3c005cb5` |
| [qa/appium/FULL_WORKFLOW_IMPLEMENTATION_PLAN_2026-05-03.md](../qa/appium/FULL_WORKFLOW_IMPLEMENTATION_PLAN_2026-05-03.md) | QA plan/coverage; validate mixed legacy assumptions | Scope/status/acceptance sections | `49ba8756a238` |
| [qa/appium/README.md](../qa/appium/README.md) | QA plan/coverage; validate mixed legacy assumptions | Scope/status/acceptance sections | `d999682783f9` |
| [scripts/COMPLETION_SUMMARY.md](../scripts/COMPLETION_SUMMARY.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `94c1d22ead72` |
| [scripts/DART_MODELS_REFERENCE.md](../scripts/DART_MODELS_REFERENCE.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `8e61c07c36f9` |
| [scripts/DEPLOYMENT_SUMMARY.md](../scripts/DEPLOYMENT_SUMMARY.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `2abdf5318e9f` |
| [scripts/DEVELOPMENT_ROADMAP.md](../scripts/DEVELOPMENT_ROADMAP.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `d8539284f568` |
| [scripts/FILES_INDEX.md](../scripts/FILES_INDEX.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `b7c0648b4892` |
| [scripts/MIGRATION_CHECKLIST.md](../scripts/MIGRATION_CHECKLIST.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `823c4d7fd191` |
| [scripts/QUICK_START_GUIDE.md](../scripts/QUICK_START_GUIDE.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `bd9fd18a9da3` |
| [scripts/STATUS_BOARD.md](../scripts/STATUS_BOARD.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `f0f5b7cde2ca` |
| [scripts/SUPABASE_MIGRATION_GUIDE.md](../scripts/SUPABASE_MIGRATION_GUIDE.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `6d8908f4b1de` |
| [scripts/SUPABASE_SETUP_GUIDE.md](../scripts/SUPABASE_SETUP_GUIDE.md) | Legacy/mixed operational guidance; not current local authority | Relevant status/architecture sections | `c54574f109ad` |

## Missing referenced sources

These paths are referenced by existing plans but were not found in this checkout. Their full requirements cannot be represented as reviewed or fully preserved. Recover them or record explicit retirement; do not invent their contents.

| Missing path | Reference establishing the gap |
|---|---|
| `documents/Verified_Dating_App_Full_PRD.md` | Activity-Based Matching & Chat Unlock Plan, product-docs baseline; scripts/DEVELOPMENT_ROADMAP.md |
| `documents/Verified_Dating_App_API_Spec.md` | Activity-Based Matching & Chat Unlock Plan, product-docs baseline |
| `documents/02_NEW_FEATURES_FUNCTIONALITY.md` | Activity-Based Matching & Chat Unlock Plan, enhancement ideas baseline |
| Root `ARCHITECTURE.md` | app/DEVELOPER_GUIDE.md links to ../ARCHITECTURE.md |

## Supersession navigation

| Older assumption | Current reference |
|---|---|
| OTP / repeated basic-info / Supabase local setup | [SIGNUP](SIGNUP_WORKFLOW_LOCAL_POSTGRES_ARCHITECTURE.md), [AUTH](AUTH_SECURITY_FOUNDATION_LOCAL_POSTGRES.md), [RUNTIME](NATIVE_POSTGRES_RUNTIME_CONVERSION.md) |
| Header-only admin authority and sample credentials | [ADMIN](codex/completed/ADMIN_CONTROL_PLANE_REPORT_2026-08-09.md), [LIVE-ADMIN](../control-panel/README.md) |
| In-memory business persistence gaps | [RUNTIME](NATIVE_POSTGRES_RUNTIME_CONVERSION.md); current domain-specific completion reports |
| Process-local command replay | [RELIABILITY](RELIABILITY_SCALE_GUARDRAILS_LOCAL_POSTGRES.md) (shared PostgreSQL replay; domain dedupe still required) |
| Local-only storage policy used as production policy | [MEDIA](codex/completed/PROFILE_MEDIA_LIFECYCLE_REPORT_2026-08-09.md), [MODERATION](codex/completed/MEDIA_MODERATION_PRODUCTION_INTEGRATION_REPORT_2026-08-09.md) |
| Generic push token disablement / no-traffic success | [PUSH](codex/completed/NOTIFICATION_PRODUCTION_INTEGRATION_REPORT_2026-08-09.md), [PUSH-ACCEPTANCE](codex/NOTIFICATION_PRODUCTION_DEVICE_ACCEPTANCE_2026-08-09.md) |
| XP ladder/paid acceleration brainstorm | [LEVELS](LEVEL_XP_PROGRESSION_LOCAL_POSTGRES.md); acceleration remains deferred |
| Old “done” and capacity claims | [AUDIT](PENDING_ENGINE_PRIORITY_AUDIT_2026-08-03.md), [RELIABILITY](RELIABILITY_SCALE_GUARDRAILS_LOCAL_POSTGRES.md), [LAUNCH](codex/ALN_4_2_OWNER_SIGNOFF_PACKET_2026-03-03.md) |
