
import 'package:flutter/material.dart';
/*CustomTextField làm được gì?
Hiển thị placeholder (hintText) trước khi nhập.
Khi bấm vào ô, chữ sẽ biến mất.
Nếu nhập dữ liệu, sẽ hiển thị nút xóa (X).
Nếu là ô mật khẩu, sẽ có nút bật/tắt mật khẩu (👁).*/

class CustomTextField extends StatefulWidget{
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,  //không cần viết Key? key và gán super.key
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    required this.controller,
    this.focusNode,
  });
  
  @override
  State<StatefulWidget> createState() => _CustomTextFieldState();
  
}

class _CustomTextFieldState extends State<CustomTextField>{
  bool _isObscure = true;
  bool _isFocused = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: SizedBox(
        width: 355,
        height: 42,
        child: TextField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _isObscure : false,
          decoration: InputDecoration(
            hintText: _isFocused ? "" : widget.hintText, // Ẩn khi bấm vào
            prefixIcon: Icon(widget.icon, color: Colors.black54),
            suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility, 
                    color: Colors.black54), 
                  onPressed: (){
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
                : (widget.controller.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.black54), 
                        onPressed: (){
                          widget.controller.clear();
                          setState(() {});
                        },
                      )
                    : null), 
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0), // Adjust padding to center text
          ),
          onChanged: (text) => setState(() {}), // Cập nhật UI khi nhập
        ),
      ),
    );
        
  }

}