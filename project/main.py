from flask import Flask, request, render_template
from signup import Signup, Search
from flask_sqlalchemy import SQLAlchemy
import os

# Create the Flask app and database instances
app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', '123456')  # add secret key CSR

# Initialize SQLAlchemy without binding to app yet
db = SQLAlchemy()

class Patient(db.Model):
    __tablename__ = "Patient"
    NID = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String)
    password = db.Column(db.String, nullable=False)
    mail = db.Column(db.String)
    Fname = db.Column(db.String)
    Lname = db.Column(db.String)
    BD = db.Column(db.TEXT)

def create_app(config_overrides=None):
    """Application factory function for better testing"""
    app = Flask(__name__)
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', '123456')
    
    # Set default database URI
    app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get('DATABASE_URL', 'sqlite:///instance/patient.db')
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    
    # Apply any config overrides (useful for testing)
    if config_overrides:
        app.config.update(config_overrides)
    
    # Initialize extensions
    db.init_app(app)
    
    # Register routes
    register_routes(app)
    
    return app

def register_routes(app):
    """Register all routes with the given app"""
    @app.route('/', methods=["GET"])
    def mainpage():
        return render_template('main.html', main='Main Page')

    @app.route('/health', methods=["GET"])
    def health_check():
        """Health check endpoint for Kubernetes"""
        try:
            # Try a simple database operation
            with app.app_context():
                db.engine.execute('SELECT 1')
            return {'status': 'healthy', 'database': 'connected'}, 200
        except Exception as e:
            return {'status': 'healthy', 'database': 'disconnected', 'error': str(e)}, 200

    @app.route('/signup', methods=["POST", "GET"])
    def signup():
        form = Signup()
        if request.method == 'GET':
            return render_template('signup.html', form=form)
        elif request.method == 'POST' and form.validate_on_submit():
            try:
                NID = form.NID.data
                patient = Patient.query.filter_by(NID=form.NID.data).first()
                password = form.password.data
                if (patient is None) and (password == form.Re_password.data):
                    username = form.username.data
                    email = form.email.data
                    Fname = form.Fname.data
                    Lname = form.Lname.data
                    BD = form.BD.data
                    patient = Patient(
                        NID=NID,
                        username=username,
                        password=password,
                        mail=email,
                        Fname=Fname,
                        Lname=Lname,
                        BD=BD
                    )
                    db.session.add(patient)
                    db.session.commit()
                    value = (f'user is {username} <br> UID is {NID} <br> '
                             f'mail is {email} <br> Fname is {Fname} <br> '
                             f'Lname is {Lname} <br> Birthday is {BD}')
                    return render_template('out.html', output=value, Statues="This User is added")
                else:
                    return render_template('signup.html', form=form, value="This id is already IN")
            except Exception as e:
                print(f"Database error in signup: {e}")
                return render_template('signup.html', form=form, error='Database error occurred. Please try again later.')
        else:
            return render_template('signup.html', form=form)

    @app.route('/search', methods=["POST", "GET"])
    def search():
        form = Search()
        if request.method == 'GET':
            return render_template('search.html', form=form)
        elif request.method == 'POST':
            try:
                patient = Patient.query.filter_by(NID=form.NID.data).first()
                if patient is None:
                    return render_template('out.html', output="Cant Find a User")
                value = (f'User is {patient.username} <br> UID is {patient.NID} <br> '
                         f'Mail is {patient.mail}')
                return render_template('out.html', output=value)
            except Exception as e:
                print(f"Database error in search: {e}")
                return render_template('search.html', form=form, error='Database error occurred. Please try again later.')

# Configure the default app for non-test usage
if not app.config.get('TESTING', False):
    app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get('DATABASE_URL', 'sqlite:///instance/patient.db')
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    db.init_app(app)
    register_routes(app)


if __name__ == "__main__":
    import time
    import sys
    
    # Only modify database path if not already configured for testing
    if not app.config.get('TESTING', False):
        # Ensure instance directory exists and is writable
        instance_dir = os.path.join(os.path.dirname(__file__), 'instance')
        os.makedirs(instance_dir, exist_ok=True)
        
        # Get the database URL and convert relative path to absolute if needed
        database_url = os.environ.get('DATABASE_URL', 'sqlite:///instance/patient.db')
        if database_url.startswith('sqlite:///instance/'):
            # Convert to absolute path
            db_path = os.path.join(instance_dir, 'patient.db')
            database_url = f'sqlite:///{db_path}'
            app.config["SQLALCHEMY_DATABASE_URI"] = database_url
            print(f"Using database path: {db_path}")
        elif database_url.startswith('sqlite:////'):
            # Already absolute path, use as is
            print(f"Using absolute database path: {database_url}")
        else:
            print(f"Using database URL: {database_url}")
    
    # Try to create database with retries, but don't exit if it fails
    max_retries = 3  # Reduced retries
    database_initialized = False
    
    for attempt in range(max_retries):
        try:
            with app.app_context():
                db.create_all()
            print(f"Database initialized successfully on attempt {attempt + 1}")
            database_initialized = True
            break
        except Exception as e:
            print(f"Database initialization attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(1)  # Shorter wait
    
    if not database_initialized:
        print("⚠️ Database initialization failed, but starting web server anyway...")
        print("⚠️ Database operations may fail until database is properly initialized")
    
    # Start the web server regardless of database status
    port = int(os.environ.get('PORT', 5000))
    print(f"🚀 Starting Flask application on port {port}")
    app.run(host='0.0.0.0', port=port, debug=True)
