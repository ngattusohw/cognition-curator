"""
Flashcard management API endpoints.
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, timezone

from ..database import db
from ..models.flashcard import Flashcard, DifficultyLevel
from ..models.deck import Deck

flashcards_bp = Blueprint('flashcards', __name__)


@flashcards_bp.route('/', methods=['POST'])
@jwt_required()
def create_flashcard():
    """Create a new flashcard."""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()

        if not data:
            return jsonify({'error': 'No data provided'}), 400

        # Validate required fields
        required_fields = ['deck_id', 'front', 'back']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400

        # Verify deck belongs to user
        deck = Deck.query.filter_by(id=data['deck_id'], user_id=current_user_id).first()
        if not deck:
            return jsonify({'error': 'Deck not found or access denied'}), 404

        # Create flashcard
        flashcard = Flashcard(
            front=data['front'],
            back=data['back'],
            deck_id=data['deck_id'],
            hint=data.get('hint'),
            explanation=data.get('explanation'),
            tags=data.get('tags', []),
            ai_generated=data.get('ai_generated', False),
            ai_generation_prompt=data.get('ai_generation_prompt'),
            source_reference=data.get('source_reference')
        )

        db.session.add(flashcard)
        db.session.commit()

        return jsonify({'flashcard': flashcard.to_dict(include_analytics=True)}), 201

    except Exception as e:
        return jsonify({'error': f'Failed to create flashcard: {str(e)}'}), 500


@flashcards_bp.route('/deck/<deck_id>', methods=['GET'])
@jwt_required()
def get_deck_flashcards(deck_id):
    """Get all flashcards for a specific deck."""
    try:
        current_user_id = get_jwt_identity()

        # Verify deck belongs to user
        deck = Deck.query.filter_by(id=deck_id, user_id=current_user_id).first()
        if not deck:
            return jsonify({'error': 'Deck not found or access denied'}), 404

        # Get query parameters
        include_inactive = request.args.get('include_inactive', 'false').lower() == 'true'
        status_filter = request.args.get('status')

        # Build query
        query = Flashcard.query.filter_by(deck_id=deck_id)

        if not include_inactive:
            query = query.filter_by(is_active=True)

        if status_filter:
            query = query.filter_by(status=status_filter)

        flashcards = query.order_by(Flashcard.created_at.desc()).all()

        return jsonify({
            'flashcards': [card.to_dict(include_analytics=True) for card in flashcards],
            'total_count': len(flashcards)
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to get flashcards: {str(e)}'}), 500


@flashcards_bp.route('/<flashcard_id>', methods=['GET'])
@jwt_required()
def get_flashcard(flashcard_id):
    """Get a specific flashcard."""
    try:
        current_user_id = get_jwt_identity()

        # Get flashcard and verify user owns the deck
        flashcard = db.session.query(Flashcard).join(Deck).filter(
            Flashcard.id == flashcard_id,
            Deck.user_id == current_user_id
        ).first()

        if not flashcard:
            return jsonify({'error': 'Flashcard not found or access denied'}), 404

        return jsonify({'flashcard': flashcard.to_dict(include_analytics=True)}), 200

    except Exception as e:
        return jsonify({'error': f'Failed to get flashcard: {str(e)}'}), 500


@flashcards_bp.route('/<flashcard_id>', methods=['PUT'])
@jwt_required()
def update_flashcard(flashcard_id):
    """Update a flashcard."""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()

        if not data:
            return jsonify({'error': 'No data provided'}), 400

        # Get flashcard and verify user owns the deck
        flashcard = db.session.query(Flashcard).join(Deck).filter(
            Flashcard.id == flashcard_id,
            Deck.user_id == current_user_id
        ).first()

        if not flashcard:
            return jsonify({'error': 'Flashcard not found or access denied'}), 404

        # Update allowed fields
        updatable_fields = [
            'front', 'back', 'hint', 'explanation', 'tags',
            'is_active', 'source_reference'
        ]

        for field in updatable_fields:
            if field in data:
                setattr(flashcard, field, data[field])

        flashcard.updated_at = datetime.now(timezone.utc)
        db.session.commit()

        return jsonify({'flashcard': flashcard.to_dict(include_analytics=True)}), 200

    except Exception as e:
        return jsonify({'error': f'Failed to update flashcard: {str(e)}'}), 500


@flashcards_bp.route('/<flashcard_id>', methods=['DELETE'])
@jwt_required()
def delete_flashcard(flashcard_id):
    """Delete a flashcard."""
    try:
        current_user_id = get_jwt_identity()

        # Get flashcard and verify user owns the deck
        flashcard = db.session.query(Flashcard).join(Deck).filter(
            Flashcard.id == flashcard_id,
            Deck.user_id == current_user_id
        ).first()

        if not flashcard:
            return jsonify({'error': 'Flashcard not found or access denied'}), 404

        db.session.delete(flashcard)
        db.session.commit()

        return jsonify({'message': 'Flashcard deleted successfully'}), 200

    except Exception as e:
        return jsonify({'error': f'Failed to delete flashcard: {str(e)}'}), 500


@flashcards_bp.route('/due', methods=['GET'])
@jwt_required()
def get_due_cards():
    """Get cards due for review."""
    try:
        current_user_id = get_jwt_identity()

        # Get query parameters
        deck_id = request.args.get('deck_id')
        limit = min(int(request.args.get('limit', 50)), 100)  # Max 100 cards

        # Build base query for cards due for review
        query = db.session.query(Flashcard).join(Deck).filter(
            Deck.user_id == current_user_id,
            Flashcard.is_active == True,
            Flashcard.next_review_date <= datetime.now(timezone.utc)
        )

        if deck_id:
            query = query.filter(Flashcard.deck_id == deck_id)

        # Order by priority: new cards first, then by due date
        flashcards = query.order_by(
            Flashcard.status.desc(),  # NEW status first
            Flashcard.next_review_date.asc()
        ).limit(limit).all()

        return jsonify({
            'cards': [card.to_dict(include_analytics=True) for card in flashcards],
            'total_due': len(flashcards)
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to get due cards: {str(e)}'}), 500


@flashcards_bp.route('/<flashcard_id>/review', methods=['POST'])
@jwt_required()
def review_flashcard(flashcard_id):
    """Record a flashcard review."""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()

        if not data or 'difficulty' not in data:
            return jsonify({'error': 'Difficulty level required'}), 400

        # Get flashcard and verify user owns the deck
        flashcard = db.session.query(Flashcard).join(Deck).filter(
            Flashcard.id == flashcard_id,
            Deck.user_id == current_user_id
        ).first()

        if not flashcard:
            return jsonify({'error': 'Flashcard not found or access denied'}), 404

        # Parse difficulty level
        try:
            difficulty = DifficultyLevel(int(data['difficulty']))
        except (ValueError, TypeError):
            return jsonify({'error': 'Invalid difficulty level. Use 1-4'}), 400

        # Process the review
        response_time = data.get('response_time_seconds')
        review_result = flashcard.review_card(difficulty, response_time)

        db.session.commit()

        return jsonify({
            'review_result': review_result,
            'flashcard': flashcard.to_dict(include_analytics=True)
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to record review: {str(e)}'}), 500


@flashcards_bp.route('/stats', methods=['GET'])
@jwt_required()
def get_flashcard_stats():
    """Get flashcard statistics for the user."""
    try:
        current_user_id = get_jwt_identity()

        # Get basic counts
        total_cards = db.session.query(Flashcard).join(Deck).filter(
            Deck.user_id == current_user_id,
            Flashcard.is_active == True
        ).count()

        due_cards = db.session.query(Flashcard).join(Deck).filter(
            Deck.user_id == current_user_id,
            Flashcard.is_active == True,
            Flashcard.next_review_date <= datetime.now(timezone.utc)
        ).count()

        new_cards = db.session.query(Flashcard).join(Deck).filter(
            Deck.user_id == current_user_id,
            Flashcard.is_active == True,
            Flashcard.status == 'new'
        ).count()

        learning_cards = db.session.query(Flashcard).join(Deck).filter(
            Deck.user_id == current_user_id,
            Flashcard.is_active == True,
            Flashcard.status == 'learning'
        ).count()

        mastered_cards = db.session.query(Flashcard).join(Deck).filter(
            Deck.user_id == current_user_id,
            Flashcard.is_active == True,
            Flashcard.status == 'mastered'
        ).count()

        return jsonify({
            'total_cards': total_cards,
            'due_cards': due_cards,
            'new_cards': new_cards,
            'learning_cards': learning_cards,
            'mastered_cards': mastered_cards,
            'review_cards': total_cards - new_cards - learning_cards - mastered_cards
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to get stats: {str(e)}'}), 500