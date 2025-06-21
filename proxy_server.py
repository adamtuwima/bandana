from proxy import Proxy, ProxyHandler
from flask import Flask, request, jsonify
import threading

app = Flask(name)

# Начальные значения
replace_enabled = False
replace_url = "example.com"
replace_html = "<h1>Подменённый контент</h1>"
allowed_ip = None  # None = все разрешены

class ReplaceProxyHandler(ProxyHandler):
    def handle_response(self, response):
        global replace_enabled, replace_url, replace_html, allowed_ip
        # Проверяем IP клиента (если включено)
        client_ip = self.client_address[0]
        if allowed_ip and client_ip != allowed_ip:
            return super().handle_response(response)

        if replace_enabled and replace_url in response.headers.get('Host', ''):
            if 'text/html' in response.headers.get('Content-Type', ''):
                response.content = replace_html.encode('utf-8')
                response.headers['Content-Length'] = str(len(response.content))
        return super().handle_response(response)

proxy = Proxy(HandlerClass=ReplaceProxyHandler)

@app.route('/control', methods=['GET', 'POST'])
def control():
    global replace_enabled, replace_url, replace_html, allowed_ip
    if request.method == 'POST':
        data = request.json
        replace_enabled = data.get('enabled', replace_enabled)
        replace_url = data.get('url', replace_url)
        replace_html = data.get('html', replace_html)
        allowed_ip = data.get('allowed_ip', allowed_ip)
        return jsonify({
            "enabled": replace_enabled,
            "url": replace_url,
            "allowed_ip": allowed_ip
        })
    else:
        return jsonify({
            "enabled": replace_enabled,
            "url": replace_url,
            "allowed_ip": allowed_ip
        })

def run_proxy():
    proxy.run(host='0.0.0.0', port=8080)

def run_api():
    app.run(host='0.0.0.0', port=5000)

if name == "main":
    t1 = threading.Thread(target=run_proxy)
    t2 = threading.Thread(target=run_api)
    t1.start()
    t2.start()
    t1.join()
    t2.join()