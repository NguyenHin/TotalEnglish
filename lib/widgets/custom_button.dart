
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget{
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFF89B3D4),
    this.textColor = const Color(0xFFFFFFFF)
  });


  @override
  Widget build (BuildContext context){
    return SizedBox(
      width: 355,
      height: 42,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5, //drop shadow
          shadowColor: Colors.black,
        ),
        onPressed: onPressed, 
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500), //medium
        ),
      ),
    );
  }
}