
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '/widgets/custom_textfield.dart';
import '/widgets/primary_button.dart';
import 'package:inquira/widgets/secondary_button.dart';
import 'package:inquira/constants/colors.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Inquira",
                style: TextStyle(
                  fontSize: 36,
                  fontFamily: 'Giaza',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5,),
              const Text(
                "Create and share surveys, or discover insights by answering others-only on Inquira.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height:20),

              //first name + last name
              Row(
                children: const [
                  Expanded(child: CustomTextfield(label: "First name")),
                  SizedBox(width: 10),
                  Expanded(child: CustomTextfield(label: "Last name")),
                ],
              ),
              const SizedBox(height: 20),

              //email
              const CustomTextfield(label: "Email"),
              const SizedBox(height: 20),

              //password1
              const CustomTextfield(label: "Create password", obsercure: true),
              const SizedBox(height: 20),

              //confirm pass
              const CustomTextfield(label: "Confirm password", obsercure: true),
              const SizedBox(height: 0),

              
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (bool? value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                        children: [
                          const TextSpan(text: "I agree to the "),
                          TextSpan(
                            text: "Terms & Services",
                            style: const TextStyle(
                              color: AppColors.accent1,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                //function
                                print("Terms & Services clicked");
                              },
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: const TextStyle(
                              color: AppColors.accent1,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                //function tap
                                print("Privacy policy clicked");
                              }

                          )
                        ]
                      ),
                    ),
                    
                  ),
                ],
              ),
              const SizedBox(height: 0),

              // Create Account button (disabled if unchecked)
              PrimaryButton(
                text: "Create Account",
                onPressed: _agreedToTerms
                    ? () {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    : null, // disable button if not checked
              ),

              const SizedBox(height: 5,),

              Row(
                children: const[
                  Expanded(child: Divider(thickness: 2.0, color: AppColors.primary),),
                  SizedBox(width: 10,),
                  Text(
                    "or",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 10,),
                  Expanded(child: Divider(thickness: 2.0, color: AppColors.primary))
                ],
              ),

              const SizedBox(height: 5),

              SecondaryButton(
                text: "Continue with Google",
                iconPath: "assets/images/google-icon.png",
                onPressed: () {
                  print("Google clicked");
                },
              ),

              const SizedBox(height: 5),

              

              


            ],
          ),
        ),
      ),
    );
  }
}
