from flask import Flask, request, render_template
from signup import Signup, Search
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', '123456')  # add secret key CSR
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get('DATABASE_URL', 'sqlite:///patient.db')
db = SQLAlchemy(app)


class Patient(db.Model):
    __tablename__ = "Patient"
    NID = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String)
    password = db.Column(db.String, nullable=False)
    mail = db.Column(db.String)
    Fname = db.Column(db.String)
    Lname = db.Column(db.String)
    BD = db.Column(db.TEXT)


@app.route('/', methods=["GET"])
def mainpage():
    return render_template('main.html', main='Main Page')


@app.route('/signup', methods=["POST", "GET"])
def signup():
    form = Signup()
    if request.method == 'GET':
        return render_template('signup.html', form=form)
    elif request.method == 'POST' and form.validate_on_submit():
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
            return render_template(
                'out.html',
                output=value,
                Statues="This User is added"
            )
        else:
            return render_template(
                'signup.html',
                form=form,
                value="This id is aready IN"
            )


@app.route('/search', methods=["POST", "GET"])
def search():
    form = Search()
    if request.method == 'GET':
        return render_template('search.html', form=form)
    elif request.method == 'POST':
        patient = Patient.query.filter_by(NID=form.NID.data).first()
        if patient is None:
            return render_template('out.html', output="Cant Find a User")
        value = (f'User is {patient.username} <br> UID is {patient.NID} <br> '
                 f'Mail is {patient.mail}')
        return render_template('out.html', output=value)


if __name__ == "__main__":
    import time
    import sys
    
    # Ensure instance directory exists and is writable
    instance_dir = os.path.join(os.path.dirname(__file__), 'instance')
    os.makedirs(instance_dir, exist_ok=True)
    
    # Try to create database with retries
    max_retries = 5
    for attempt in range(max_retries):
        try:
            with app.app_context():
                db.create_all()
            print(f"Database initialized successfully on attempt {attempt + 1}")
            break
        except Exception as e:
            print(f"Database initialization attempt {attempt + 1} failed: {e}")
            if attempt == max_retries - 1:
                print("Failed to initialize database after all retries")
                sys.exit(1)
            time.sleep(2)  # Wait 2 seconds before retry
    
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
