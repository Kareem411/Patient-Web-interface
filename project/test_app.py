import pytest
from main import create_app, db, Patient
from signup import Signup, Search
from flask import url_for, template_rendered

@pytest.fixture
def app():
    """Create application for the tests."""
    config_overrides = {
        'TESTING': True,
        'SQLALCHEMY_DATABASE_URI': 'sqlite:///:memory:',
        'WTF_CSRF_ENABLED': False,
        'SQLALCHEMY_TRACK_MODIFICATIONS': False
    }
    
    app = create_app(config_overrides)
    
    with app.app_context():
        db.create_all()
        
    yield app
    
    with app.app_context():
        db.drop_all()

@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()

def test_main_page(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b'Patient Management System' in response.data

def test_signup_get(client):
    response = client.get('/signup')
    assert response.status_code == 200
    assert b'Patient Registration' in response.data

def test_signup_post_success(client, app):
    data = {
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'testpass',
        'Re_password': 'testpass',
        'Fname': 'Test',
        'Lname': 'User',
        'NID': '123456789',
        'BD': '2000-01-01',
        'submit': True
    }
    
    with app.app_context():
        response = client.post('/signup', data=data, follow_redirects=True)
        assert response.status_code == 200
        # Check that the success status is present
        assert b'This User is added' in response.data or b'user is testuser' in response.data

def test_signup_post_duplicate_nid(client, app):
    # First registration
    data1 = {
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'testpass',
        'Re_password': 'testpass',
        'Fname': 'Test',
        'Lname': 'User',
        'NID': '123456789',
        'BD': '2000-01-01',
        'submit': True
    }
    
    with app.app_context():
        client.post('/signup', data=data1)
        
        # Try duplicate NID
        data2 = {
            'username': 'anotheruser',
            'email': 'another@example.com',
            'password': 'pass123',
            'Re_password': 'pass123',
            'Fname': 'Another',
            'Lname': 'User',
            'NID': '123456789',
            'BD': '1990-01-01',
            'submit': True
        }
        
        response = client.post('/signup', data=data2)
        assert response.status_code == 200
        assert b'This id is already IN' in response.data

def test_search_found(client, app):
    # First register a user
    data = {
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'testpass',
        'Re_password': 'testpass',
        'Fname': 'Test',
        'Lname': 'User',
        'NID': '123456789',
        'BD': '2000-01-01',
        'submit': True
    }
    
    with app.app_context():
        client.post('/signup', data=data)
        
        # Now search for the user
        response = client.post('/search', data={'NID': '123456789', 'submit': True})
        assert response.status_code == 200
        assert b'testuser' in response.data or b'User is testuser' in response.data

def test_search_not_found(client):
    response = client.post('/search', data={'NID': '000000000', 'submit': True})
    assert response.status_code == 200
    # Check for either the plain message or the HTML alert structure
    assert b'Cant Find a User' in response.data or b'Patient Not Found' in response.data
