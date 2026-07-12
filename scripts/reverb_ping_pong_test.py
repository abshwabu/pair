#!/usr/bin/env python3
"""Test Laravel Reverb WebSocket ping/pong and live chat broadcast delivery."""

import json
import sys
import time
import urllib.parse
import urllib.request
from typing import Any

try:
    import websocket
except ImportError:
    print("FAIL: websocket-client not installed (pip install websocket-client)")
    sys.exit(1)

API_BASE = "http://localhost:8000/api/v1"
APP_BASE = "http://localhost:8000"
REVERB_KEY = "pair-app-key"
REVERB_HOST = "localhost"
REVERB_PORT = 8080
POD_ID = "a23a66c5-dfc5-4e01-afc7-cce11d81cfd1"
USERS = [
    ("test@example.com", "password"),
    ("new@example.com", "password"),
]


def api_request(method: str, path: str, token: str | None = None, data: dict | None = None) -> dict:
    url = f"{API_BASE}{path}"
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode())


def login(email: str, password: str) -> tuple[str, str]:
    payload = api_request("POST", "/auth/login", data={"email": email, "password": password})
    token = payload["data"]["token"]
    user = payload["data"]["user"]
    user_id = user["id"]
    return token, user_id


def broadcast_auth(token: str, socket_id: str, channel: str) -> str:
    form = urllib.parse.urlencode({"socket_id": socket_id, "channel_name": channel}).encode()
    req = urllib.request.Request(
        f"{APP_BASE}/broadcasting/auth",
        data=form,
        headers={
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": f"Bearer {token}",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        payload = json.loads(resp.read().decode())
    return payload["auth"]


class ReverbClient:
    def __init__(self, label: str):
        self.label = label
        self.ws: websocket.WebSocket | None = None
        self.socket_id: str | None = None
        self.events: list[dict[str, Any]] = []

    def connect(self) -> None:
        url = (
            f"ws://{REVERB_HOST}:{REVERB_PORT}/app/{REVERB_KEY}"
            "?protocol=7&client=ping-pong-test&version=8.4.0"
        )
        self.ws = websocket.create_connection(url, timeout=10)
        raw = self.ws.recv()
        msg = json.loads(raw)
        if msg.get("event") != "pusher:connection_established":
            raise RuntimeError(f"{self.label}: expected connection_established, got {raw}")
        data = json.loads(msg["data"])
        self.socket_id = data["socket_id"]
        print(f"OK  {self.label}: connected (socket_id={self.socket_id})")

    def ping(self) -> bool:
        assert self.ws is not None
        self.ws.send(json.dumps({"event": "pusher:ping", "data": {}}))
        raw = self.ws.recv()
        msg = json.loads(raw)
        ok = msg.get("event") == "pusher:pong"
        print(f"{'OK' if ok else 'FAIL'}  {self.label}: ping/pong -> {msg.get('event')}")
        return ok

    def subscribe_private(self, token: str, channel: str) -> None:
        assert self.ws is not None and self.socket_id
        auth = broadcast_auth(token, self.socket_id, channel)
        self.ws.send(
            json.dumps(
                {
                    "event": "pusher:subscribe",
                    "data": {"auth": auth, "channel": channel},
                }
            )
        )
        deadline = time.time() + 10
        while time.time() < deadline:
            raw = self.ws.recv()
            msg = json.loads(raw)
            event = msg.get("event")
            if event == "pusher_internal:subscription_succeeded":
                print(f"OK  {self.label}: subscribed to {channel}")
                return
            if event == "pusher:subscription_error":
                raise RuntimeError(f"{self.label}: subscription error: {raw}")
        raise RuntimeError(f"{self.label}: subscription timed out for {channel}")

    def wait_for_event(self, event_name: str, timeout: float = 10) -> dict | None:
        assert self.ws is not None
        deadline = time.time() + timeout
        while time.time() < deadline:
            self.ws.settimeout(max(0.1, deadline - time.time()))
            try:
                raw = self.ws.recv()
            except websocket.WebSocketTimeoutException:
                continue
            msg = json.loads(raw)
            self.events.append(msg)
            if msg.get("event") == event_name:
                data = msg.get("data")
                if isinstance(data, str):
                    data = json.loads(data)
                return {"raw": msg, "data": data}
        return None

    def close(self) -> None:
        if self.ws:
            self.ws.close()


def main() -> int:
    print("=== Reverb ping/pong + live chat test ===\n")

    # 1. Basic connectivity
    client = ReverbClient("reverb")
    try:
        client.connect()
        if not client.ping():
            return 1
    except Exception as exc:
        print(f"FAIL  reverb connectivity: {exc}")
        return 1
    finally:
        client.close()

    print()

    # 2. Auth + subscribe + message delivery
    try:
        token_a, user_a = login(*USERS[0])
        token_b, user_b = login(*USERS[1])
        print(f"OK  logged in users: {USERS[0][0]} ({user_a}), {USERS[1][0]} ({user_b})")
    except Exception as exc:
        print(f"FAIL  login: {exc}")
        return 1

    channel = f"private-pod.{POD_ID}"
    listener = ReverbClient("listener")
    try:
        listener.connect()
        if not listener.ping():
            return 1
        listener.subscribe_private(token_b, channel)

        test_body = f"ping-pong live test {int(time.time())}"
        sent = api_request(
            "POST",
            f"/pods/{POD_ID}/messages",
            token=token_a,
            data={"body": test_body},
        )
        print(f"OK  sender posted message id={sent['data']['id']}")

        received = listener.wait_for_event("MessageSent", timeout=10)
        if not received:
            print("FAIL  listener did not receive MessageSent within 10s")
            print(f"      events seen: {[e.get('event') for e in listener.events]}")
            return 1

        body = received["data"].get("body") if received["data"] else None
        if body != test_body:
            print(f"FAIL  payload mismatch: expected {test_body!r}, got {body!r}")
            return 1

        print(f"OK  listener received MessageSent with body={body!r}")
    except Exception as exc:
        print(f"FAIL  live chat broadcast: {exc}")
        return 1
    finally:
        listener.close()

    print("\n=== ALL TESTS PASSED ===")
    return 0


if __name__ == "__main__":
    sys.exit(main())
