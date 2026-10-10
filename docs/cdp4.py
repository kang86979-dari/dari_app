import json, sys, time, websocket
ws = websocket.create_connection(f"ws://127.0.0.1:{9222}/devtools/page/{sys.argv[1]}", timeout=30, suppress_origin=True)
mid=0
def call(method, params=None):
    global mid; mid+=1
    ws.send(json.dumps({"id":mid,"method":method,"params":params or {}}))
    while True:
        m=json.loads(ws.recv())
        if m.get("id")==mid: return m
# delete both RECRUIT_VIEW_COUNT (dot and host) + route + nudge
for dom in [".komate.saramin.co.kr","komate.saramin.co.kr"]:
    call("Network.deleteCookies",{"name":"RECRUIT_VIEW_COUNT","domain":dom,"path":"/"})
call("Network.deleteCookies",{"name":"route","domain":"komate.saramin.co.kr","path":"/"})
# nudge + modal shown 선세팅(프로모 억제)
call("Runtime.evaluate",{"expression":"document.cookie='mobile_modal_recruit_shown=true; path=/; domain=komate.saramin.co.kr'; document.cookie='nudge_modal_shown=true; path=/; domain=komate.saramin.co.kr'; 'ok'","returnByValue":True})
call("Page.reload",{"ignoreCache":True})
time.sleep(6)
r=call("Runtime.evaluate",{"expression":"""(function(){
  const m=[...document.querySelectorAll('div')].filter(e=>{const s=getComputedStyle(e);return (e.className+'').match(/modal/i)&&s.display!=='none'&&e.offsetHeight>50;}).map(e=>(e.innerText||'').replace(/\\s+/g,' ').slice(0,45));
  return {modal:m.slice(0,1), hasDetail: document.body.innerText.includes('중국어')||document.body.innerText.includes('이지차이나')};
})()""","returnByValue":True})
print(json.dumps(r["result"]["result"]["value"], ensure_ascii=False))
ws.close()
