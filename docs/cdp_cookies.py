import json, sys, websocket
ws = websocket.create_connection(f"ws://127.0.0.1:9222/devtools/page/{sys.argv[1]}", timeout=20, suppress_origin=True)
ws.send(json.dumps({"id":1,"method":"Network.getAllCookies"}))
while True:
    m=json.loads(ws.recv())
    if m.get("id")==1: break
for c in m["result"]["cookies"]:
    if "saramin" in c["domain"]:
        print(f"{c['domain']:28} {c['name']:28} httpOnly={c['httpOnly']} session={c.get('session')} exp={c.get('expires')}")
ws.close()
