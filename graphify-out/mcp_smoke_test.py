"""Test the EXACT command Cline runs from .mcp.json: graphify-mcp.exe --graph <graph.json> --transport stdio"""
import json
import subprocess
import sys

CMD = r"C:\Users\mohse\.local\bin\graphify-mcp.exe"
ARGS = [
    "--graph", r"d:\flutter_project\sodocu\graphify-out\graph.json",
    "--transport", "stdio",
]

init = {
    "jsonrpc": "2.0", "id": 1, "method": "initialize",
    "params": {
        "protocolVersion": "2025-06-18",
        "capabilities": {},
        "clientInfo": {"name": "cline-config-test", "version": "0.1"},
    },
}
notif = {"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}}
req = {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}
call = {
    "jsonrpc": "2.0", "id": 3, "method": "tools/call",
    "params": {"name": "graph_stats", "arguments": {}},
}

payload = (
    json.dumps(init, ensure_ascii=False) + "\n"
    + json.dumps(notif, ensure_ascii=False) + "\n"
    + json.dumps(req, ensure_ascii=False) + "\n"
    + json.dumps(call, ensure_ascii=False) + "\n"
).encode("utf-8")

proc = subprocess.Popen(
    [CMD, *ARGS],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
)
try:
    out, err = proc.communicate(input=payload, timeout=60)
except subprocess.TimeoutExpired:
    proc.kill()
    out, err = proc.communicate()
    print("TIMED OUT", file=sys.stderr)

print("=== exit code:", proc.returncode)
print("=== STDERR:")
print(err.decode("utf-8", "replace")[:1500])
print("=== STDOUT:")
for line in out.decode("utf-8", "replace").splitlines():
    if not line.strip():
        continue
    try:
        msg = json.loads(line)
    except json.JSONDecodeError:
        print("NON-JSON:", line[:200])
        continue
    tag = "id=" + str(msg.get("id"))
    if "error" in msg:
        print(f"{tag} ERROR: {json.dumps(msg['error'], ensure_ascii=False)[:600]}")
    elif "result" in msg:
        if "serverInfo" in msg["result"]:
            print(f"{tag} serverInfo -> {json.dumps(msg['result']['serverInfo'])}")
        elif "tools" in msg["result"]:
            print(f"{tag} tools -> {[t.get('name') for t in msg['result']['tools']]}")
        elif "content" in msg["result"]:
            text = msg["result"]["content"][0].get("text", "")
            print(f"{tag} graph_stats -> {text[:300].strip()}")
        else:
            print(f"{tag} result: {json.dumps(msg['result'], ensure_ascii=False)[:400]}")
    else:
        print(f"{tag} other: {json.dumps(msg, ensure_ascii=False)[:400]}")