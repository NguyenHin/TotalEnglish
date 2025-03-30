
import 'package:flutter/material.dart';

class LanguageSwitcher extends StatefulWidget{
  final Function(String) onLanguageChanged;

  const LanguageSwitcher({
    super.key,
    required this.onLanguageChanged
  });

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher>{
  String _selectedLanguage = 'English';
  final Map<String, String> _languageFlags = {
    'English': '🇺🇸',
    'Tiếng việt': '🇻🇳'
  };

  @override
  Widget build(BuildContext context){
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedLanguage,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
        items: _languageFlags.keys.map((String language) {
          return DropdownMenuItem<String>(
            value: language,
            child: Row(
              children: [
                Text(_languageFlags[language] ?? ''),
                const SizedBox(width: 8),
                Text(language),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue){
          if(newValue != null){
            setState(() {
              _selectedLanguage = newValue;
            });
            widget.onLanguageChanged(newValue);
          }
        },
      ),
    );
  }
}