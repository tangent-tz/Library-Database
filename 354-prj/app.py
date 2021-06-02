from flask import Flask, render_template, flash, redirect, url_for, logging, request, session
from flask_mysqldb import MySQL
from wtforms import Form, StringField, TextAreaField, PasswordField, validators

app = Flask(__name__)


app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'password'
app.config['MYSQL_DB'] = 'project'
app.config['MYSQL_CURSORCLASS'] = 'DictCursor'
mysql = MySQL(app)
print(mysql)


@app.route('/')
def index():
    return render_template("home.html")


@app.route('/about')
def about():
    return render_template('about.html')


@app.route('/books/<string:id>/')
def book(id):
    details = {
        'author': 'authors',
        'genre': 'bookgenre'
    }
    return item('bookISBN', 'Book', 'ISBN13', id, details)


@app.route('/cds/<string:id>/')
def cd(id):
    details = {
        'artist': 'cdartist',
        'genre': 'cdgenre'
    }
    return item('cdISSN', 'CD', 'ISSN', id, details)


@app.route('/dvds/<string:id>/')
def dvd(id):
    details = {
        'actor': 'dvdactors',
        'director': 'dvddirectors',
        'genre': 'dvdgenre'
    }
    return item('dvdISSN', 'DVD', 'ISSN', id, details)


def item(item, table, pk, id, details):
    cur = mysql.connection.cursor()
    query = (
        f"SELECT item_id, {table}.* FROM item"
        f" JOIN {table} ON {item}={pk}"
        f" WHERE item_id={id}"
    )
    cur.execute(query)
    res = cur.fetchone()

    for det in details:
        query = (
            f"SELECT {det} FROM {details[det]}"
            f" WHERE {item} IN ("
            f"SELECT {pk} FROM {table}"
            f" JOIN item ON {item}={pk}"
            f" WHERE item_id={id})"
        )
        cur.execute(query)
        details[det] = cur.fetchall()

    cur.close()
    return render_template(
        'item.html', title=res['title'], item=res, details=details
    )


class RegisterForm(Form):
    name = StringField('First Name', [validators.Length(min=1, max=20)])
    lastname = StringField('Last Name', [validators.Length(min=1, max=20)])
    phone = StringField('Phone', [validators.Length(min=0, max=10)])
    address = StringField('Address', [validators.Length(min=1, max=50)])
    email = StringField('Email', [validators.Length(min=6, max=50)])
    password = PasswordField(
        'Password', [validators.DataRequired(), validators.EqualTo(
            'confirm', message="The entered passwords do not match"
        )]
    )
    confirm = PasswordField('Confirm Password')


# registration page
@app.route('/register', methods=['GET', "POST"])
def register():
    form = RegisterForm(request.form)
    if request.method == 'POST' and form.validate():
        name = form.name.data
        lastname = form.lastname.data
        address = form.address.data
        email = form.email.data
        password = form.password.data

        cur = mysql.connection.cursor()
        query = (
            f"INSERT INTO Member(address, email, password, fName, lName) "
            f"VALUES('{address}','{email}','{password}','{name}','{lastname}')"
        )
        cur.execute(query)
        mysql.connection.commit()
        cur.close()
        flash("You are now registed and can log in", 'Success')
        return redirect(url_for('login'))
    return render_template('register.html', form=form)


# log in page
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == "POST":
        # get form fields
        email = request.form['email']
        password_cadidate = request.form['password']
        cur = mysql.connection.cursor()
        result = cur.execute(f"SELECT * FROM Member WHERE email='{email}'")
        if result > 0:
            data = cur.fetchone()
            password = data['password']
            getname = data['fName']
            lib_card = data['lib_card_num']
            # compares entered password to stored password
            if password_cadidate == password:
                session['loggedin'] = True
                session['email'] = email
                session['name'] = getname
                session['id'] = lib_card
                flash("Logged in successfully", 'success')
                return redirect(url_for('account'))
            else:
                error = 'Email/Password Mismatch'
                return render_template('login.html', error=error)
            cur.close()
        else:
            error = 'User not found'
            return render_template('login.html', error=error)
    return render_template('login.html')


# page right after log in
@app.route('/account')
def account():
    query = (
        f"SELECT item_id, book.* FROM item"
        f" JOIN book on bookISBN=ISBN13"
        f" WHERE bookISBN in ("
            f"SELECT bookISBN FROM loaneditem"
            f" JOIN item ON loaneditem.item_id=item.item_id"
            f" WHERE lib_card_num)"
    )
    print(query)
    cur = mysql.connection.cursor()
    res = cur.execute(query)

    books = ''
    if res > 0:
        books = cur.fetchall()
    
    query = (
        f"SELECT item_id, cd.* FROM item"
        f" JOIN cd on cdISSN=ISSN"
        f" WHERE cdISSN in ("
            f"SELECT cdISSN FROM loaneditem"
            f" JOIN item ON loaneditem.item_id=item.item_id"
            f" WHERE lib_card_num)"
    )
    cur = mysql.connection.cursor()
    res = cur.execute(query)

    cds = ''
    if res > 0:
        cds = cur.fetchall()
    
    query = (
        f"SELECT item_id, dvd.* FROM item"
        f" JOIN dvd on dvdISSN=ISSN"
        f" WHERE dvdISSN in ("
            f"SELECT dvdISSN FROM loaneditem"
            f" JOIN item ON loaneditem.item_id=item.item_id"
            f" WHERE lib_card_num)"
    )
    cur = mysql.connection.cursor()
    res = cur.execute(query)

    dvds = ''
    if res > 0:
        dvds = cur.fetchall()
    
    cur.close()
    return render_template('account.html', books=books, cds=cds, dvds=dvds)


# logout instructions
@app.route('/logout')
def logout():
    session.clear()
    flash("logged out", 'success')
    return redirect(url_for('login'))


@app.route('/admin', methods=['GET', 'POST'])
def admin():
    session.clear()
    if request.method == "POST":
        # get form fields
        email = request.form['email']
        password_cadidate = request.form['password']
        # compares entered password to stored password
        if email == 'admin@admin.com' and password_cadidate == 'adminpass':
            flash("Logged in successfully", 'success')
            return redirect(url_for('admin_console'))
        else:
            error = 'Email/Password Mismatch'
            return render_template('home.html', error=error)

    return render_template('admin.html')


@app.route('/admin_console')
def admin_console():
    cur = mysql.connection.cursor()
    query = (
        f"SELECT COUNT(*) FROM item"
    )
    res = cur.execute(query)
    count = 0
    if res > 0:
        count = cur.fetchone()['COUNT(*)']
    print(count)

    query = (
        f"SELECT COUNT(*) FROM member"
    )
    res = cur.execute(query)
    members = 0
    if res > 0:
        print(res)
        members = cur.fetchone()['COUNT(*)']
    print(members)

    cur.close()
    return render_template('admin-console.html', count=count, members=members)


@app.route('/admin_delete', methods=["GET", "POST"])
def admin_delete():
    if request.method == "POST":
        item = request.form['user']
        query = (
            f"DELETE FROM member"
            f" WHERE lib_card_num={item}"
        )
        cur = mysql.connection.cursor()
        cur.execute(query)
        mysql.connection.commit()
        cur.close()
        
        return redirect(url_for('admin_console'));
    return render_template('admin/delete.html')


@app.route('/admin_update', methods=['GET', 'POST'])
def admin_update():
    if request.method == "POST":
        cur = mysql.connection.cursor()
        member = request.form['id']
        query = (
            f"UPDATE Member SET password='{request.form['password']}'"
            f" WHERE lib_card_num={member}"
        )
        res = cur.execute(query)
        cur.execute(query)
        mysql.connection.commit()
        cur.close()
        
        return redirect(url_for('admin_console'));

    return render_template('admin/update.html')


@app.route('/books')
def books():
    return catalog('bookISBN', 'Book', 'ISBN13')


@app.route('/cds')
def cds():
    return catalog('cdISSN', 'CD', 'ISSN')


@app.route('/dvds')
def dvds():
    return catalog('dvdISSN', 'DVD', 'ISSN')


def catalog(item, table, pk):
    query = (
        f"SELECT item_id, {table}.* FROM item"
        f" JOIN {table} ON {item}={pk}"
        f" ORDER BY item_id"
    )

    cur = mysql.connection.cursor()
    cur.execute(query)
    res = cur.fetchall()
    cur.close()
    return render_template('catalog.html', title=f'{table}s', results=res)


app.secret_key = '123412312321'
if __name__ == '__main__':
    app.run(debug=True)
