from flask import Flask, jsonify
from flask_cors import CORS
import os
import socket
import time

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend access

@app.route('/')
def home():
    return jsonify({
        'message': 'Hello from Kubernetes!',
        'hostname': socket.gethostname(),
        'version': os.getenv('APP_VERSION', '1.0')
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

@app.route('/cpu-load')
def cpu_load():
    """CPU intensive endpoint for auto-scaling demonstration"""
    start_time = time.time()

    # Perform CPU-intensive calculation
    result = 0
    for i in range(10000000):
        result += i * i

    end_time = time.time()
    duration = end_time - start_time

    return jsonify({
        'message': 'CPU-intensive task completed',
        'hostname': socket.gethostname(),
        'duration_seconds': round(duration, 2),
        'result': result
    })

@app.route('/info')
def info():
    """Get pod information"""
    return jsonify({
        'hostname': socket.gethostname(),
        'version': os.getenv('APP_VERSION', '1.0'),
        'pod_ip': socket.gethostbyname(socket.gethostname())
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)