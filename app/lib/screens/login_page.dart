import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stylee_app/components/text_filed.dart';
import 'package:stylee_app/components/button.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage( {
    super.key, 
    required this.onTap,
    }
  );

  @override
  State<LoginPage> createState() =>  _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text editing controllers
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  void signIn() async {
    // show loader circle
    showDialog(
      context: context, 
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      )
    );

    // try sign in
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailTextController.text, 
      password: passwordTextController.text,
      );
      
      // pop loading circle
      if (context.mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e){
      // pop loading circle
      Navigator.pop(context);
      // display error message
      displayMessage(e.code);
    }
  }

  // display a dialog message
  void displayMessage(String message) {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade100,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // logo
                Icon(
                  Icons.lock,
                  size: 100,
                ),

                const SizedBox(height: 50),
                // welcome back message
                Text(
                  "Welcome back, you've been missed!"
                ),

                const SizedBox(height: 25),
                // email textfield
                MyTextField(
                  controller: emailTextController, 
                  hintText: "Email", 
                  obsureText: false
                ),

                const SizedBox(height: 10),

                // password textfield

                MyTextField(
                  controller: passwordTextController, 
                  hintText: "Password", 
                  obsureText: true
                ),

                const SizedBox(height: 10),
                // sign in button
                MyButton(
                  onTap: signIn, 
                  text: 'Sign up'
                ),

                const SizedBox(height: 25),
                // got to register page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Not a member? "),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text("Register now", 
                        style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.black,
                        fontSize: 16
                      )
                     )
                    )
                  ],
                )

              ],
            ),
          ),
        )
      )
    );
  }
}