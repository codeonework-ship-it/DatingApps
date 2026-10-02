from pathlib import Path
import os

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


def env_bool(name: str, default: bool = False) -> bool:
    return os.getenv(name, str(default)).strip().lower() in {"1", "true", "yes", "on"}

SECRET_KEY = os.getenv(
    "DJANGO_SECRET_KEY",
    "dev-only-secret-key-change-in-production",
)
DEBUG = env_bool("DJANGO_DEBUG", True)
ALLOWED_HOSTS = [item.strip() for item in os.getenv("DJANGO_ALLOWED_HOSTS", "*").split(",") if item.strip()]

INSTALLED_APPS = [
    # First, so `manage.py runserver` serves ASGI (pages + the live socket).
    "daphne",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "control_panel",
    "channels",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "control_panel.middleware.OperatorSessionMiddleware",
    "control_panel.middleware.OperatorRoleGateMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "control_panel_project.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
                "control_panel.operator_access.operator_nav",
            ],
        },
    },
]

WSGI_APPLICATION = "control_panel_project.wsgi.application"
ASGI_APPLICATION = "control_panel_project.asgi.application"

# Live console updates (control_panel/consumers.py). The in-memory layer
# reaches the sockets of one server process, which is how the console runs;
# several processes would need a shared layer (e.g. channels-redis).
CHANNEL_LAYERS = {"default": {"BACKEND": "channels.layers.InMemoryChannelLayer"}}

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATICFILES_DIRS = [BASE_DIR / "static"]

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

PROJECT_DISPLAY_NAME = os.getenv("CONTROL_PANEL_NAME", "AegisConnect Control Panel")
GO_API_BASE_URL = os.getenv("GO_API_BASE_URL", "http://localhost:8081/v1").rstrip("/")
GO_HEALTH_BASE_URL = os.getenv("GO_HEALTH_BASE_URL", "http://localhost:8081").rstrip("/")
GO_API_TIMEOUT_SEC = int(os.getenv("GO_API_TIMEOUT_SEC", "8"))
KIBANA_BASE_URL = os.getenv("KIBANA_BASE_URL", "http://localhost:5601").rstrip("/")
KIBANA_DISCOVER_INDEX = os.getenv("KIBANA_DISCOVER_INDEX", "dating-app-logs-*")
KIBANA_DASHBOARD_PATH = os.getenv("KIBANA_DASHBOARD_PATH", "/app/dashboards")
# "kibana" (local ELK) or "loki" (Grafana Explore on the VPS; needs GRAFANA_BASE_URL,
# e.g. https://connect.example.com/grafana). See documents/MONITORING_AND_OBSERVABILITY_2026-10-01.md.
LOGS_BACKEND = os.getenv("LOGS_BACKEND", "kibana").strip().lower()
GRAFANA_BASE_URL = os.getenv("GRAFANA_BASE_URL", "").rstrip("/")

SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"
SESSION_COOKIE_AGE = int(os.getenv("OPERATOR_SESSION_MAX_AGE_SEC", "28800"))
CSRF_COOKIE_SAMESITE = "Lax"
SECURE_SSL_REDIRECT = env_bool("DJANGO_SECURE_SSL_REDIRECT")
SESSION_COOKIE_SECURE = env_bool("DJANGO_SESSION_COOKIE_SECURE")
CSRF_COOKIE_SECURE = env_bool("DJANGO_CSRF_COOKIE_SECURE")
SECURE_HSTS_SECONDS = int(os.getenv("DJANGO_SECURE_HSTS_SECONDS", "0"))
SECURE_HSTS_INCLUDE_SUBDOMAINS = env_bool("DJANGO_SECURE_HSTS_INCLUDE_SUBDOMAINS")
SECURE_HSTS_PRELOAD = env_bool("DJANGO_SECURE_HSTS_PRELOAD")
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = "same-origin"
X_FRAME_OPTIONS = "DENY"
if env_bool("DJANGO_TRUST_PROXY_HEADERS"):
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
LOGIN_URL = "/login/"
