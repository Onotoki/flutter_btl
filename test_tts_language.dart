import 'package:flutter/material.dart';
import 'lib/services/tts_service.dart';

void main() {
  runApp(TTSLanguageTestApp());
}

class TTSLanguageTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TTS Language Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TTSLanguageTestPage(),
    );
  }
}

class TTSLanguageTestPage extends StatefulWidget {
  @override
  _TTSLanguageTestPageState createState() => _TTSLanguageTestPageState();
}

class _TTSLanguageTestPageState extends State<TTSLanguageTestPage> {
  final TTSService _ttsService = TTSService();
  List<dynamic> _availableLanguages = [];
  String? _selectedLanguage = 'vi-VN';
  bool _isLoading = true;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _testTTSLanguages();
  }

  Future<void> _testTTSLanguages() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Đang kiểm tra TTS...';
    });

    try {
      // Initialize TTS service
      await _ttsService.initialize();
      
      // Get available languages
      final languages = await _ttsService.getLanguages();
      
      setState(() {
        _availableLanguages = languages;
        _isLoading = false;
        _testResult = 'Tìm thấy ${languages.length} ngôn ngữ';
      });
      
      print('🔊 Test: Available languages: $languages');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResult = 'Lỗi: $e';
      });
      print('🔊 Test error: $e');
    }
  }

  Future<void> _testLanguage(String language) async {
    setState(() {
      _testResult = 'Đang test ngôn ngữ $language...';
    });

    try {
      await _ttsService.setLanguage(language);
      await _ttsService.speakText('Xin chào, đây là test ngôn ngữ $language');
      
      setState(() {
        _selectedLanguage = language;
        _testResult = 'Test thành công với ngôn ngữ $language';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Lỗi test ngôn ngữ $language: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TTS Language Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kết quả test:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_testResult),
            ),
            SizedBox(height: 20),
            
            if (_isLoading) ...[
              Center(child: CircularProgressIndicator()),
            ] else ...[
              Text(
                'Ngôn ngữ khả dụng (${_availableLanguages.length}):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              
              if (_availableLanguages.isNotEmpty) ...[
                DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  items: _availableLanguages.map((lang) {
                    final langStr = lang.toString();
                    return DropdownMenuItem<String>(
                      value: langStr,
                      child: Text(langStr),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _testLanguage(value);
                    }
                  },
                ),
                SizedBox(height: 16),
                
                ElevatedButton(
                  onPressed: () => _testLanguage(_selectedLanguage ?? 'vi-VN'),
                  child: Text('Test ngôn ngữ đã chọn'),
                ),
                SizedBox(height: 8),
                
                ElevatedButton(
                  onPressed: _testTTSLanguages,
                  child: Text('Làm mới danh sách ngôn ngữ'),
                ),
              ] else ...[
                Text('Không tìm thấy ngôn ngữ nào'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _testTTSLanguages,
                  child: Text('Thử lại'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
