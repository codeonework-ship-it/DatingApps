import os
import signal
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOG_DIR = ROOT / ".run" / "logs"
PORTS = [8080, 8081, 9091, 9092, 9093, 9094, 10091, 10092, 10093, 10094]


def kill_ports():
    for port in PORTS:
        result = subprocess.run(["lsof", "-ti", f"tcp:{port}"], capture_output=True, text=True)
        for raw_pid in result.stdout.splitlines():
            pid = raw_pid.strip()
            if not pid:
                continue
            try:
                os.kill(int(pid), signal.SIGKILL)
                print(f"killed {pid} on {port}")
            except Exception as error:
                print(f"failed to kill {pid} on {port}: {error}")


def load_env():
    for env_file in [ROOT / "config" / ".env", ROOT / "config" / ".env.local"]:
        if not env_file.exists():
            continue
        for raw in env_file.read_text().splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ[key.strip()] = value.strip()

    os.environ["SUPABASE_USER_SCHEMA"] = "public"
    os.environ["SUPABASE_MATCHING_SCHEMA"] = "public"
    os.environ["SUPABASE_ENGAGEMENT_SCHEMA"] = "public"


def start_services():
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    commands = [
        ("auth-svc", ["go", "run", "./cmd/auth-svc"]),
        ("profile-svc", ["go", "run", "./cmd/profile-svc"]),
        ("matching-svc", ["go", "run", "./cmd/matching-svc"]),
        ("chat-svc", ["go", "run", "./cmd/chat-svc"]),
        ("mobile-bff", ["go", "run", "./cmd/mobile-bff"]),
        ("api-gateway", ["go", "run", "./cmd/api-gateway"]),
    ]

    base_env = os.environ.copy()

    for name, command in commands:
        process_env = base_env.copy()
        log_file = open(LOG_DIR / f"{name}.log", "w")
        process = subprocess.Popen(
            command,
            cwd=str(ROOT),
            stdout=log_file,
            stderr=subprocess.STDOUT,
            start_new_session=True,
            env=process_env,
        )
        print(f"started {name} pid={process.pid}")


def wait_readiness():
    for _ in range(25):
        statuses = []
        for url in ["http://localhost:8080/readyz", "http://localhost:8081/readyz"]:
            try:
                result = subprocess.run(["curl", "-sS", "-o", "/dev/null", "-w", "%{http_code}", url], capture_output=True, text=True)
                statuses.append(result.stdout.strip() == "200")
            except Exception:
                statuses.append(False)
        if all(statuses):
            print("ready=true")
            return
        time.sleep(1)
    print("ready=false")


if __name__ == "__main__":
    kill_ports()
    load_env()
    start_services()
    wait_readiness()
