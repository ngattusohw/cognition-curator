#!/usr/bin/env python3
"""
Database migration script for Railway deployment.
Runs migrations programmatically without relying on Flask CLI.
"""

import os
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from flask_migrate import upgrade

from src.app import create_app


def run_migrations():
    """Run database migrations."""
    print("🔄 Starting database migrations...")

    try:
        # Create the Flask app
        app = create_app("production")

        # Run migrations within app context
        with app.app_context():
            upgrade()
            print("✅ Database migrations completed successfully!")

    except Exception as e:
        print(f"❌ Migration failed: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    run_migrations()
