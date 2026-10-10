import json, sys, websocket
ws = websocket.create_connection(f"ws://127.0.0.1:9222/devtools/page/{sys.argv[1]}", timeout=20, suppress_origin=True)
ws.send(json.dumps({"id":1,"method":"Network.getAllCookies"}))
while True:
    m=json.loads(ws.recv())
    if m.get("id")==1: break
for c in m["result"]["cookies"]:
    if c["name"] in ("CUST_NO","UID","AUID","saramin_last_login_provider","FOREIGN_MEMBER_TYPE","RECRUIT_VIEW_COUNT"):
        print(f"{c['name']:30} domain={c['domain']:24} value={c['value'][:30]}")
ws.close()
