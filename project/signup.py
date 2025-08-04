from flask_wtf import FlaskForm
from wtforms import (DateField, EmailField, PasswordField, StringField,
                     SubmitField)
from wtforms.validators import DataRequired, Email, EqualTo, Length


class Signup(FlaskForm):
    username = StringField("username", validators=[DataRequired(), Length(max=20)])
    email = EmailField("Email", validators=[DataRequired(), Email()])
    password = PasswordField(
        "password", validators=[DataRequired(), Length(max=20, min=3)]
    )
    Re_password = PasswordField(
        "confirm_password",
        validators=[
            DataRequired(),
            EqualTo("password", message="password didnt match"),
        ],
    )
    Fname = StringField("First name", validators=[DataRequired(), Length(max=10)])
    Lname = StringField("Last name", validators=[DataRequired(), Length(max=10)])
    NID = StringField("National ID", validators=[DataRequired()])
    BD = DateField("BirthDate", format="%Y-%m-%d")
    submit = SubmitField("submit")


class Search(FlaskForm):
    NID = StringField("National ID", validators=[DataRequired()])
    submit = SubmitField("submit")
