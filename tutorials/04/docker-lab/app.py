import os
import socket
from html import escape
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        course = escape(os.getenv("COURSE", "Docker lab"))
        container = escape(socket.gethostname())
        body = f"""<!doctype html>
<html><head><meta charset="utf-8"><title>Docker lab</title></head>
<body><h1>Hello from a container</h1>
<p>Course: {course}</p><p>Container hostname: {container}</p></body></html>""".encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
