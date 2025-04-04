import 'package:flutter/material.dart';

class AccTextfield extends StatefulWidget{
    final String hintText;
    final TextEditingController controller;

    const AccTextfield({
        super.key,
        required this.hintText,
        required this.controller,
    });
    
      @override
      // ignore: library_private_types_in_public_api
      _AccTextFieldState createState() => _AccTextFieldState();
}

class _AccTextFieldState extends State<AccTextfield>{
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: Focus(
        onFocusChange: (focus) {
          setState(() {
            _isFocused = focus;
          });
        },
        child: Container(
          width: 344,
          height: 61,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.2),
                blurRadius: 2,
                offset: const Offset(0, 2),
              )
            ],
            border: Border.all(
              color: const Color(0xFF777777),
              width: 0.5 //giảm độ dày viền
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: _isFocused ? '' : widget.hintText,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

    
}