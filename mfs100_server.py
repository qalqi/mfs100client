import os
import sys
import ctypes
import struct
import base64
import json
import time
from http.server import HTTPServer, BaseHTTPRequestHandler

DLL_DIR = r"C:\Users\X2\Downloads\lib\lib\win\x64"
os.add_dll_directory(DLL_DIR)
dll_path = os.path.join(DLL_DIR, "MFS100Dll.dll")

try:
    dll = ctypes.CDLL(dll_path)
    print(f"[+] Loaded MFS100Dll.dll from {dll_path}")
except Exception as e:
    print(f"[-] Failed to load MFS100Dll.dll: {e}")
    sys.exit(1)

# Configure DLL Function Signatures
dll.MFS100DeviceConnected.restype = ctypes.c_int
dll.MFS100Init.argtypes = [ctypes.c_char_p]
dll.MFS100Init.restype = ctypes.c_int
dll.MFS100Uninit.restype = ctypes.c_int
dll.MFS100GetWidth.restype = ctypes.c_int
dll.MFS100GetHeight.restype = ctypes.c_int
dll.MFS100StartXcan.restype = ctypes.c_int
dll.MFS100StopXcan.restype = ctypes.c_int
dll.MFS100GetFrame.argtypes = [ctypes.c_char_p]
dll.MFS100GetFrame.restype = ctypes.c_int

dll.MFS100GetQuality.argtypes = [
    ctypes.c_char_p,
    ctypes.POINTER(ctypes.c_int),
    ctypes.POINTER(ctypes.c_int),
    ctypes.POINTER(ctypes.c_int)
]
dll.MFS100GetQuality.restype = ctypes.c_int

dll.MFS100ExtractISOTemplate.argtypes = [
    ctypes.c_char_p,
    ctypes.c_char_p,
    ctypes.POINTER(ctypes.c_int)
]
dll.MFS100ExtractISOTemplate.restype = ctypes.c_int

# Helper: Convert raw 8-bit grayscale bytes to valid BMP
def raw_to_bmp(raw_bytes, width, height):
    row_size = (width + 3) & ~3
    image_size = row_size * height
    file_size = 54 + 1024 + image_size

    # BMP Header (14 bytes)
    bmp_header = struct.pack('<2sIHHI', b'BM', file_size, 0, 0, 54 + 1024)
    # DIB Header (40 bytes)
    dib_header = struct.pack('<IIIHHIIIIII', 40, width, height, 1, 8, 0, image_size, 19685, 19685, 256, 0)
    # Color Table (256 grayscale entries)
    palette = bytearray()
    for i in range(256):
        palette.extend([i, i, i, 0])

    # BMP rows are stored bottom-up
    padded_rows = bytearray()
    padding = b'\x00' * (row_size - width)
    for y in range(height - 1, -1, -1):
        start = y * width
        padded_rows.extend(raw_bytes[start:start + width])
        padded_rows.extend(padding)

    return bytes(bmp_header + dib_header + palette + padded_rows)

class MFS100Handler(BaseHTTPRequestHandler):
    def _send_cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Origin, Accept, Key')
        self.send_header('Access-Control-Allow-Private-Network', 'true')

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors()
        self.end_headers()

    def do_GET(self):
        if self.path.startswith('/mfs100/info'):
            serial_buf = ctypes.create_string_buffer(64)
            ret = dll.MFS100Init(serial_buf)
            serial_no = serial_buf.value.decode('latin1', errors='ignore').strip() or "MFS100"
            w = dll.MFS100GetWidth() or 316
            h = dll.MFS100GetHeight() or 354
            dll.MFS100Uninit()

            print(f"[+] /mfs100/info -> Scanner Ready (Serial: {serial_no}, {w}x{h})")
            resp = {
                "ErrorCode": "0",
                "ErrorDescription": "Success",
                "DeviceInfo": {
                    "Make": "Mantra",
                    "Model": "MFS100",
                    "SerialNo": serial_no,
                    "Width": str(w),
                    "Height": str(h),
                    "Certificate": ""
                }
            }
            self.send_response(200)
            self._send_cors()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(resp).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path.startswith('/mfs100/capture'):
            print("\n[+] /mfs100/capture received from Chrome!")
            serial_buf = ctypes.create_string_buffer(64)
            ret_init = dll.MFS100Init(serial_buf)
            if ret_init != 0:
                print(f"[-] MFS100Init failed with code: {ret_init}")
                resp = {"ErrorCode": str(ret_init), "ErrorDescription": f"Init failed: {ret_init}"}
                self.send_response(200)
                self._send_cors()
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(resp).encode('utf-8'))
                return

            w = dll.MFS100GetWidth() or 316
            h = dll.MFS100GetHeight() or 354
            raw_len = w * h

            print("[*] Sensor starting... Place your finger on the MFS 100 scanner now...")
            dll.MFS100StartXcan()

            raw_buf = ctypes.create_string_buffer(raw_len)
            quality = ctypes.c_int(0)
            contrast = ctypes.c_int(0)
            nfiq = ctypes.c_int(0)

            start_time = time.time()
            captured = False
            while time.time() - start_time < 15:
                ret = dll.MFS100GetFrame(raw_buf)
                if ret == 0:
                    dll.MFS100GetQuality(raw_buf, ctypes.byref(quality), ctypes.byref(contrast), ctypes.byref(nfiq))
                    if quality.value >= 35:
                        captured = True
                        print(f"[✓] Finger captured! Quality: {quality.value}, Contrast: {contrast.value}, NFIQ: {nfiq.value}")
                        break
                time.sleep(0.1)

            dll.MFS100StopXcan()

            if captured:
                iso_buf = ctypes.create_string_buffer(2048)
                iso_len = ctypes.c_int(2048)
                dll.MFS100ExtractISOTemplate(raw_buf, iso_buf, ctypes.byref(iso_len))
                iso_bytes = iso_buf.raw[:iso_len.value]

                bmp_bytes = raw_to_bmp(raw_buf.raw, w, h)
                bmp_base64 = base64.b64encode(bmp_bytes).decode('ascii')
                iso_base64 = base64.b64encode(iso_bytes).decode('ascii')

                print(f"[✓] Successfully generated BMP ({len(bmp_bytes)} bytes) and ISO template ({iso_len.value} bytes)")

                resp = {
                    "ErrorCode": "0",
                    "ErrorDescription": "Success",
                    "BitmapData": bmp_base64,
                    "IsoTemplate": iso_base64,
                    "AnsiTemplate": "",
                    "RawData": "",
                    "Quality": quality.value,
                    "Nfiq": nfiq.value,
                    "WsqImage": ""
                }
            else:
                print("[-] Capture timeout: No finger placed with sufficient quality within 15 seconds")
                resp = {
                    "ErrorCode": "-1",
                    "ErrorDescription": "Capture timeout / Finger not placed"
                }

            dll.MFS100Uninit()

            self.send_response(200)
            self._send_cors()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(resp).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    PORT = 8004
    server = HTTPServer(('127.0.0.1', PORT), MFS100Handler)
    print(f"[✓] MFS 100 Live Hardware Bridge running on http://127.0.0.1:{PORT}")
    print("[✓] Ready for Chrome! You can now click capture in the browser.")
    server.serve_forever()
