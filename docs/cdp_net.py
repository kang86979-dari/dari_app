import json, sys, time, websocket
PAGE_ID = sys.argv[1]
ws = websocket.create_connection(f"ws://127.0.0.1:9222/devtools/page/{PAGE_ID}", timeout=40, suppress_origin=True)
mid = 0
def send(method, params=None):
    global mid; mid += 1
    ws.send(json.dumps({"id":mid,"method":method,"params":params or {}}))
    return mid
send("Network.enable")
send("Page.reload", {"ignoreCache": True})
reqs = {}
t0 = time.time()
ws.settimeout(3)
while time.time() - t0 < 15:
    try:
        m = json.loads(ws.recv())
    except Exception:
        continue
    if m.get("method") == "Network.responseReceived":
        p = m["params"]; u = p["response"]["url"]
        if ("api" in u or "graphql" in u or "recruit" in u) and "google" not in u and "criteo" not in u:
            reqs[p["requestId"]] = u
# 본문 수집
out = []
for rid, u in list(reqs.items())[:15]:
    i = send("Network.getResponseBody", {"requestId": rid})
    try:
        while True:
            m = json.loads(ws.recv())
            if m.get("id") == i:
                body = m.get("result", {}).get("body", "")[:600]
                out.append((u[:110], body))
                break
    except Exception:
        out.append((u[:110], "<no body>"))
for u, b in out:
    print("###", u)
    print(b.replace("\n"," ")[:500], "\n")
