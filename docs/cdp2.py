import json, sys, websocket
PAGE_ID = sys.argv[1]
ws = websocket.create_connection(f"ws://127.0.0.1:9222/devtools/page/{PAGE_ID}", timeout=25, suppress_origin=True)
def call(i, method, params=None):
    ws.send(json.dumps({"id":i,"method":method,"params":params or {}}))
    while True:
        r = json.loads(ws.recv())
        if r.get("id")==i: return r
print(call(1,"Network.clearBrowserCookies"))
print(call(2,"Runtime.evaluate",{"expression":"localStorage.clear(); sessionStorage.clear(); 'cleared'","returnByValue":True})["result"]["result"].get("value"))
print(call(3,"Page.reload",{"ignoreCache":True}))
ws.close()
