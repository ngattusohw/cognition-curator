"""
Flashcard management API endpoints.
"""

from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required

flashcards_bp = Blueprint('flashcards', __name__)


@flashcards_bp.route('/due', methods=['GET'])
@jwt_required()
def get_due_cards():
    """Get cards due for review."""
    return jsonify({'cards': []}), 200 