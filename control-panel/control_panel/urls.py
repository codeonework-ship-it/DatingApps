from django.urls import path

from . import views

urlpatterns = [
    path("", views.dashboard, name="dashboard"),
    path("verifications/", views.verification_queue, name="verification_queue"),
    path(
        "verifications/<str:user_id>/approve/",
        views.approve_verification,
        name="approve_verification",
    ),
    path(
        "verifications/<str:user_id>/reject/",
        views.reject_verification,
        name="reject_verification",
    ),
    path("activities/", views.activity_feed, name="activity_feed"),
    path("appeals/", views.appeal_queue, name="appeal_queue"),
    path("appeals/<str:appeal_id>/action/", views.action_appeal, name="action_appeal"),
]

