import json, sys, time, websocket
PAGE_ID, cnt = sys.argv[1], sys.argv[2]
ws = websocket.create_connection(f"ws://127.0.0.1:9222/devtools/page/{PAGE_ID}", timeout=30, suppress_origin=True)
mid=0
def call(method, params=None):
    global mid; mid+=1
    ws.send(json.dumps({"id":mid,"method":method,"params":params or {}}))
    while True:
        m=json.loads(ws.recv())
        if m.get("id")==mid: return m
# set count cookie low
call("Runtime.evaluate",{"expression":f"document.cookie='RECRUIT_VIEW_COUNT={cnt}; path=/; domain=komate.saramin.co.kr'; 'set'","returnByValue":True})
call("Page.reload",{"ignoreCache":True})
time.sleep(6)
r=call("Runtime.evaluate",{"expression":"""(function(){
  const m=[...document.querySelectorAll('div')].filter(e=>{const s=getComputedStyle(e);return (e.className+'').match(/modal/i)&&s.display!=='none'&&e.offsetHeight>50;}).map(e=>(e.innerText||'').replace(/\\s+/g,' ').slice(0,50));
  return {modal:m.slice(0,1), cnt: document.cookie.match(/RECRUIT_VIEW_COUNT=\\d+/)?.[0]};
})()""","returnByValue":True})
print(json.dumps(r["result"]["result"]["value"], ensure_ascii=False))
ws.close()
