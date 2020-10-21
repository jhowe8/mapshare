import 'package:flutter/material.dart';
import 'auth.dart';
import 'package:auto_size_text/auto_size_text.dart';

class LoginPage extends StatefulWidget {
  LoginPage({this.auth, this.onSignedIn});
  final BaseAuth auth;
  final VoidCallback onSignedIn;

  @override
  State<StatefulWidget> createState() => new _LoginPageState();
}

enum FormType {
  login,
  register
}

class _LoginPageState extends State<LoginPage> {
  String _email, _password;
  FormType _formType = FormType.login;

  final formKey = new GlobalKey<FormState>();

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      try {
        if (_formType == FormType.login) {
          String userID = await widget.auth.signInWithEmailAndPassword(_email.trim(), _password);
          print('Signed in: $userID');
        } else {
          String userID = await widget.auth.createUserWithEmailAndPassword(_email.trim(), _password);
          print('Registered: $userID');
        }
        // root page can receive message from login page
        widget.onSignedIn();
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  void moveToRegister() async {
    formKey.currentState.reset();
    setState(() {
      _formType = FormType.register;
    });
  }

  void moveToLogin() async {
    formKey.currentState.reset();
    setState(() {
      _formType = FormType.login;
    });
  }

  BoxFit getPhoneRotation() {
    // Phone held horizontal
    if (MediaQuery.of(context).size.width > MediaQuery.of(context).size.height) {
      return BoxFit.fitWidth;
    } else {
      return BoxFit.fitHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new Stack(
        children: <Widget> [
          new Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: new BoxDecoration(
                image: new DecorationImage(
                    colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.25), BlendMode.darken),
                    image: new AssetImage('assets/images/swiss_alps.png'),
                    fit: getPhoneRotation()
                )
            ),
          ),
          new ListView(
            children: <Widget>[
              new Container(
              padding: EdgeInsets.all(16),
                child: new Form(
                  key: formKey,
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: buildLogoText() + buildInputs() + [SizedBox(height: 15)] + buildSubmitButtons(),
                  )
                )
              )
            ]
          )
        ]
      )
    );
  }

  List<Widget> buildLogoText() {
    var titleGroup = AutoSizeGroup();

    return [
      Padding(
        padding: EdgeInsets.only(top: 8.0, left: 8.0, right: 80.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget> [
            AutoSizeText('HoweCrafty', group: titleGroup, style: TextStyle(fontFamily: 'Helvetica',
            fontWeight: FontWeight.bold, fontSize: 60.0, color: Colors.white), maxFontSize: 70.0, maxLines: 1),
            AutoSizeText('Wreaths', group: titleGroup, style: TextStyle(fontFamily: 'Helvetica',
                fontWeight: FontWeight.bold, fontSize: 60.0, color: Colors.purpleAccent[100]), maxFontSize: 70.0, maxLines: 1),
          ]
        )
      ),
      Padding(
        padding: EdgeInsets.only(top: 6.0, left: 8.0, bottom: 12.0),
        child: AutoSizeText.rich(
          TextSpan(
            style: new TextStyle(
                fontSize: 18.0,
                fontFamily: 'Helvetica',
                fontWeight: FontWeight.bold),
            children: <TextSpan>[
              TextSpan(text: 'Manage your ',
                  style: new TextStyle(
                      color: Colors.white)),
              TextSpan(text: 'wreaths',
                  style: new TextStyle(
                      color: Colors.purpleAccent[100])),
              TextSpan(text: ' with ease.',
                  style: new TextStyle(
                      color: Colors.white))
            ],
          ),
          minFontSize: 5,
          maxLines: 1,
        )
      )
    ];
  }

  List<Widget> buildInputs() {
    return [
      new TextFormField(
          decoration: new InputDecoration(labelText: 'Username (email)'),
          validator: (value) => value.isEmpty ? 'Email can\'t be empty' : null,
          onSaved:(value) => _email = value
      ),
      new TextFormField(
          obscureText: true,
          decoration: new InputDecoration(labelText: 'Password'),
          validator: (value) => value.isEmpty ? 'Password can\'t be empty' : null,
          onSaved:(value) => _password = value
      ),
    ];
  }

  List<Widget> buildSubmitButtons() {
    if (_formType == FormType.login) {
      return [
        new Opacity(
          opacity: 0.75,
          child: new RaisedButton(
            child: new Text('Login', style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: validateAndSubmit,
          ),
        ),
        new Opacity(
          opacity: 0.75,
          child:
          new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget> [
                new Text('Don\'t have an account?', style: new TextStyle(fontFamily: 'Helvetica', fontSize: 12.0)),
                new FlatButton(
                  child: new Text('Register', style: new TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 12.0, decoration: TextDecoration.underline)),
                  onPressed: moveToRegister,
                )
              ]
          )
        )
      ];
    } else {
      return [
        new Opacity(
          opacity: 0.75,
          child: new RaisedButton(
            color: Colors.purpleAccent[100],
            child: new Text('Register', style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: validateAndSubmit,
          ),
        ),
        new Opacity(
          opacity: 0.75,
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget> [
              new Text('Already have an account?', style: new TextStyle(fontFamily: 'Helvetica', fontSize: 12.0)),
              new FlatButton(
                child: new Text('Login', style: new TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 12.0, decoration: TextDecoration.underline)),
                onPressed: moveToLogin,
              )
            ]
          )
        )
      ];
    }
  }
}