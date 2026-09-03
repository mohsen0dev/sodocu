import json
import subprocess
import os

PYTHON = r"C:\Users\mohse\AppData\Roaming\uv\tools\graphifyy\Scripts\python.exe"
ARGS = [
    "-u", "-m", "graphify.serve",
    "--graph", r"d:\flutter_project\sodocu\graphify-out\graph.json",
    "--transport", "stdio",
]
WORKDIR = r"d:\flutter_project\sodocu\graphify-out"
OUT = os.path.join(WORKDIR, "_mcp_out.bin")
ERR = os.path.join(WORKDIR, "_mcp_err.txt")

init = {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
        "protocolVersion": "2025-06-18",
        "capabilities": {},
        "clientInfo": {"name": "cline-mcp-test", "version": "0.1"},
    },
}
notif = {"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}}
req = {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}

# newline-delimited JSON framing (mcp python sdk stdio)
payload = (
    json.dumps(init, ensure_ascii=False) + "\n"
    + json.dumps(notif, ensure_ascii=False) + "\n"
    + json.dumps(req, ensure_ascii=False) + "\n"
).encode("utf-8")

with open(os.path.join(WORKDIR, "_mcp_in.bin"), "wb") as f:
    f.write(payload)

with open(os.path.join(WORKDIR, "_mcp_in.bin"), "rb") as fin, \
     open(OUT, "wb") as fout, \
     open(ERR, "wb") as ferr:
    proc = subprocess.Popen([PYTHON, *ARGS], stdin=fin, stdout=fout, stderr=ferr)
    try:
        code = proc.wait(timeout=40)
        print("exit code:", code)
    except subprocess.TimeoutExpired:
        proc.kill()
        print("killed after 40s")

print("OUT size:", os.path.getsize(OUT) if os.path.exists(OUT) else 0)
print("ERR size:", os.path.getsize(ERR) if os.path.exists(ERR) else 0)
if os.path.exists(ERR):
    with open(ERR, "r", encoding="utf-8", errors="replace") as f:
        print("=== STDERR ===\n", f.read()[:3000])
if os.path.exists(OUT):
    with open(OUT, "rb") as f:
        print("=== STDOUT ===\n", f.read()[:6000].decode("utf-8", "replace"))