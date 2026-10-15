from flask import Flask, jsonify
from flask_cors import CORS
import os

app = Flask(__name__)

# Allow your Flutter Web frontend to communicate with the API.
# For initial development only.
CORS(app)

# Directories for uploaded and generated images.
os.makedirs("uploads", exist_ok=True)
os.makedirs("generated", exist_ok=True)


@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "message": "Virtual Try-On Backend is running!",
        "status": "success"
    })


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "service": "virtual-try-on-api"
    })


@app.route("/api/try-on", methods=["POST"])
def try_on():
    return jsonify({
        "status": "not_implemented",
        "message": (
            "The backend is reachable, but the AI "
            "virtual try-on processor has not been integrated yet."
        )
    }), 501


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 5000)),
        debug=False
    )