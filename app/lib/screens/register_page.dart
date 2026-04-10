import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stylee_app/components/text_filed.dart';
import 'package:stylee_app/components/button.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({
    super.key,
    required this.onTap,
  }
  );

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final confirmPasswordTextController = TextEditingController();

  // sign user up
  void signUp() async {

    // show loading circle
    showDialog(
      context: context, 
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      )
    );

    // make sure passwords match
    if (passwordTextController.text != confirmPasswordTextController.text){
      // pop loading circle
      Navigator.pop(context);
      // show error to user
      displayMessage("Passwords don't match!");
      return;
    }

    // try creating the user
    try {
      // create the user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextController.text, 
        password: passwordTextController.text
      );

      // after creating the user, create a new document
      FirebaseFirestore.instance
          .collection("Users")
          .doc(userCredential.user!.email)
          .set({
            'username' : emailTextController.text.split("@")[0],
            'bio': 'Empty bio.'
          });

      // pop loading circle
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e){
      // pop loading circle
      Navigator.pop(context);
      // show error to user
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
                  "Let's create an account for you"
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

                // confirm password textfield

                MyTextField(
                  controller: confirmPasswordTextController, 
                  hintText: "Confirm Password", 
                  obsureText: true
                ),

                const SizedBox(height: 10),
                // sign in button
                MyButton(
                  onTap: signUp, 
                  text: 'Sign up'
                ),

                const SizedBox(height: 25),
                // got to register page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?"),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        "Login here", 
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