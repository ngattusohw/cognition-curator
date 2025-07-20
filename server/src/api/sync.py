"""
Data synchronization API endpoints.
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, timezone

from ..database import db
from ..models.user import User
from ..models.analytics import StudySession

sync_bp = Blueprint('sync', __name__)


@sync_bp.route('/study-session', methods=['POST'])
@jwt_required()
def sync_study_session():
    """Sync a completed study session from iOS app."""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Create study session record
        session = StudySession(
            user_id=current_user_id,
            deck_id=data.get('deck_id'),
            session_type=data.get('session_type', 'regular'),
            started_at=datetime.fromisoformat(data['started_at'].replace('Z', '+00:00')),
            ended_at=datetime.fromisoformat(data['ended_at'].replace('Z', '+00:00')) if data.get('ended_at') else None,
            duration_minutes=data.get('duration_minutes', 0),
            cards_reviewed=data.get('cards_reviewed', 0),
            cards_correct=data.get('cards_correct', 0),
            cards_incorrect=data.get('cards_incorrect', 0),
            accuracy_rate=data.get('accuracy_rate', 0.0),
            platform='iOS',
            device_type=data.get('device_type', 'iPhone'),
            app_version=data.get('app_version')
        )
        
        if session.ended_at:
            session.end_session()
        
        db.session.add(session)
        
        # Update user stats
        user = User.query.get(current_user_id)
        if user:
            user.update_study_stats(
                session_duration_minutes=session.duration_minutes,
                cards_reviewed=session.cards_reviewed,
                accuracy_rate=session.accuracy_rate
            )
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'session_id': str(session.id),
            'message': 'Study session synced successfully'
        }), 201
    
    except Exception as e:
        return jsonify({'error': f'Failed to sync study session: {str(e)}'}), 500


@sync_bp.route('/user-stats', methods=['POST'])
@jwt_required()
def sync_user_stats():
    """Sync user statistics from iOS app."""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        user = User.query.get(current_user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Update user statistics
        if 'current_streak_days' in data:
            user.current_streak_days = max(user.current_streak_days, data['current_streak_days'])
        
        if 'total_cards_reviewed' in data:
            user.total_cards_reviewed = max(user.total_cards_reviewed, data['total_cards_reviewed'])
        
        if 'total_study_time_minutes' in data:
            user.total_study_time_minutes = max(user.total_study_time_minutes, data['total_study_time_minutes'])
        
        user.updated_at = datetime.now(timezone.utc)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'user': user.to_dict(),
            'message': 'User stats synced successfully'
        }), 200
    
    except Exception as e:
        return jsonify({'error': f'Failed to sync user stats: {str(e)}'}), 500 