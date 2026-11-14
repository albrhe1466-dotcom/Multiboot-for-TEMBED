import http.server
import socketserver
import os
import sys
import webbrowser
import threading
import time
import shutil

DIRECTORY = os.path.dirname(os.path.abspath(__file__))

def sync_flipper_bin():
    src_bin = r"C:\Users\Abdullah\Desktop\qias\flipper_src\build\furi_esp32.bin"
    dst_bin = os.path.join(DIRECTORY, "bin", "flipper.bin")
    if os.path.exists(src_bin):
        try:
            shutil.copy2(src_bin, dst_bin)
            print(f"[INFO] Auto-synced freshly compiled furi_esp32.bin -> {dst_bin}")
        except Exception as e:
            print(f"[WARN] Could not copy furi_esp32.bin: {e}")

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        clean_path = self.path.split('?')[0].split('#')[0]
        if clean_path.endswith("blank_4k.bin"):
            data = b"\xff" * 4096
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        if "flipper.bin" in clean_path:
            sync_flipper_bin()
        super().do_GET()

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, HEAD')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200, "OK")
        self.end_headers()

    def guess_type(self, path):
        clean_path = str(path).split('?')[0].split('#')[0]
        if clean_path.endswith('.json'):
            return 'application/json'
        if clean_path.endswith('.bin'):
            return 'application/octet-stream'
        return super().guess_type(path)

    def log_message(self, format, *args):
        # Clean timestamped output
        sys.stdout.write("[%s] %s\n" % (self.log_date_time_string(), format % args))
        sys.stdout.flush()

def find_available_port(start_ports=[8000, 8080, 8088, 8888, 5000]):
    for port in start_ports:
        try:
            with socketserver.TCPServer(("", port), None) as s:
                return port
        except OSError:
            continue
    # If all defaults busy, let OS choose
    with socketserver.TCPServer(("", 0), None) as s:
        return s.server_address[1]

def open_browser(url):
    time.sleep(1.2)
    try:
        webbrowser.open(url)
    except Exception as e:
        print("[WARN] Could not automatically launch browser: %s" % e)

def run():
    os.chdir(DIRECTORY)
    sync_flipper_bin()
    port = find_available_port()
    handler = CORSHTTPRequestHandler

    class ReusableTCPServer(socketserver.ThreadingTCPServer):
        allow_reuse_address = True
        daemon_threads = True
        request_queue_size = 128

    with ReusableTCPServer(("", port), handler) as httpd:
        timestamp = int(time.time())
        url = f"http://localhost:{port}/index.html?t={timestamp}"
        print("=" * 72)
        print("  LILYGO T-EMBED MULTIBOOT WEB FLASHER (CORS & CACHE-FREE)")
        print("=" * 72)
        print(f"  Serving directory : {DIRECTORY}")
        print(f"  Web Flasher URL   : {url}")
        print("  Access-Control    : Allow-Origin * (Full CORS enabled)")
        print("  Browser Cache     : Disabled (fresh version guaranteed)")
        print("  Status            : SERVER READY & LISTENING")
        print("=" * 72)
        print("  [IMPORTANT] Keep this command window OPEN while flashing!\n")

        t = threading.Thread(target=open_browser, args=(url,))
        t.daemon = True
        t.start()

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer shutting down gracefully...")
            httpd.server_close()

if __name__ == "__main__":
    run()
