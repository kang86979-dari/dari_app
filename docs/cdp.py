import json, sys, websocket
PAGE_ID = sys.argv[1]
expr = sys.stdin.read()
ws = websocket.create_connection(f"ws://127.0.0.1:9222/devtools/page/{PAGE_ID}", timeout=20, suppress_origin=True)
ws.send(json.dumps({"id":1,"method":"Runtime.evaluate","params":{"expression":expr,"returnByValue":True,"awaitPromise":True}}))
while True:
    r = json.loads(ws.recv())
    if r.get("id")==1:
        res = r.get("result",{}).get("result",{})
        print(json.dumps(res.get("value", res), ensure_ascii=False)[:4000])
        break
ws.close()
