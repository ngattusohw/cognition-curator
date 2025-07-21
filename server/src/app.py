"""
Main Flask application for Cognition Curator Server.
"""

import os
import sys
from pathlib import Path

# Add the src directory to the Python path for absolute imports
src_dir = Path(__file__).parent
sys.path.insert(0, str(src_dir.parent))

from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager

from src.config.config import Config, DevelopmentConfig, ProductionConfig, TestingConfig
from src.database import init_db


def create_app(config_name=None):
    """Create and configure the Flask application."""
    app = Flask(__name__)

    # Configure the app based on environment
    if config_name is None:
        config_name = os.environ.get("FLASK_ENV", "development")

    if config_name == "production":
        app.config.from_object(ProductionConfig)
    elif config_name == "testing":
        app.config.from_object(TestingConfig)
    else:
        app.config.from_object(DevelopmentConfig)

    # Initialize extensions
    init_db(app)

    # Initialize CORS
    CORS(app, origins=app.config["CORS_ORIGINS"])

    # Initialize JWT
    jwt = JWTManager(app)

    # Register blueprints
    from src.api.ai import ai_bp
    from src.api.analytics import analytics_bp
    from src.api.auth import auth_bp
    from src.api.decks import decks_bp
    from src.api.flashcards import flashcards_bp
    from src.api.sync import sync_bp
    from src.api.users import users_bp

    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(users_bp, url_prefix="/api/users")
    app.register_blueprint(decks_bp, url_prefix="/api/decks")
    app.register_blueprint(flashcards_bp, url_prefix="/api/flashcards")
    app.register_blueprint(analytics_bp, url_prefix="/api/analytics")
    app.register_blueprint(sync_bp, url_prefix="/api/sync")
    app.register_blueprint(ai_bp, url_prefix="/api/ai")

    # Health check endpoint
    @app.route("/health")
    def health_check():
        return {"status": "healthy", "service": "cognition-curator-api"}

    # JWT error handlers
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return {"error": "Token has expired", "code": "token_expired"}, 401

    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        return {"error": "Invalid token", "code": "invalid_token"}, 401

    @jwt.unauthorized_loader
    def missing_token_callback(error):
        return {
            "error": "Authorization token required",
            "code": "authorization_required",
        }, 401

    return app


# Create the app instance for development
app = create_app()

if __name__ == "__main__":
    # Run the development server
    app.run(host="0.0.0.0", port=5001, debug=True)
