"""
Deck management API endpoints.
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..database import db
from ..models.deck import Deck

decks_bp = Blueprint('decks', __name__)


@decks_bp.route('/', methods=['GET'])
@jwt_required()
def get_decks():
    """Get all user decks."""
    try:
        current_user_id = get_jwt_identity()
        decks = Deck.query.filter_by(user_id=current_user_id, is_active=True).all()
        
        return jsonify({
            'decks': [deck.to_dict() for deck in decks]
        }), 200
    
    except Exception as e:
        return jsonify({'error': f'Failed to get decks: {str(e)}'}), 500


@decks_bp.route('/', methods=['POST'])
@jwt_required()
def create_deck():
    """Create a new deck."""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or 'name' not in data:
            return jsonify({'error': 'Deck name required'}), 400
        
        deck = Deck(
            name=data['name'],
            user_id=current_user_id,
            description=data.get('description'),
            category=data.get('category'),
            color=data.get('color', '#007AFF'),
            icon=data.get('icon')
        )
        
        db.session.add(deck)
        db.session.commit()
        
        return jsonify({'deck': deck.to_dict()}), 201
    
    except Exception as e:
        return jsonify({'error': f'Failed to create deck: {str(e)}'}), 500 