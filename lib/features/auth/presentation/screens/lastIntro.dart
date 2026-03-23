import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/widgets/gasp_button.dart';


class Lastintro extends ConsumerStatefulWidget {
  const Lastintro({super.key});

  @override
  ConsumerState<Lastintro> createState() => _LastintroState();
}

class _LastintroState extends ConsumerState<Lastintro> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
        margin: const EdgeInsets.all(16.0),
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/party-popper 1.png',
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 24),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'your account in complete, please enjoy the best service from us.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              GaspButton(label: 'Get Started', 
              buttonColor: AppColors.primaryMid,
              textColor: Colors.white,
              onPressed: (){
                context.go('/login');

              },
              height: 60,
              borderRadius: 30,
              

              )
            ],
          ),
        ),
      ),
    );
  }
}