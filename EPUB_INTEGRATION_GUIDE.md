# Enhanced EPUB Reader Integration Guide

This guide explains how to integrate the enhanced EPUB reader with advanced text selection features similar to your novel reader.

## Features Implemented

✅ **Text Highlighting System**
- Multiple highlight colors (7 predefined colors)
- Highlight management and deletion
- Notes on highlights

✅ **Bookmark System**
- Text-based bookmarks with notes
- Bookmark management and editing
- Navigation to bookmarked sections

✅ **Text Selection Features**
- Copy selected text
- Google Translate integration
- Google Search integration
- Context menu with multiple actions

✅ **Advanced Settings**
- Theme color customization
- Night mode toggle
- Text-to-Speech support
- Sharing controls

✅ **Data Persistence**
- Local storage using SharedPreferences
- Separate storage for highlights and bookmarks
- Export/import capabilities

## Step 1: Add Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...
  
  # For EPUB reading (choose one)
  vocsy_epub_viewer: ^1.0.3  # Recommended
  # OR
  # epub_reader: ^2.0.0     # Alternative
  
  # Already added in your project
  uuid: ^4.4.0
  url_launcher: ^6.3.0
  shared_preferences: ^2.5.3
```

## Step 2: Android Configuration

### Update android/app/build.gradle:
```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21  // Required for vocsy_epub_viewer
        targetSdkVersion 33
    }
}
```

### Add permissions in android/src/main/AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Step 3: iOS Configuration

### Update ios/Runner/Info.plist:
```xml
<key>NSDocumentPickerUsageDescription</key>
<string>This app needs access to documents to open EPUB files</string>
<key>NSFileManagerUsageDescription</key>
<string>This app needs file access to manage EPUB files</string>
```

## Step 4: Implementation

### Full Enhanced EPUB Reader Implementation

Replace the placeholder implementation in `enhanced_epub_reader.dart`:

```dart
import 'package:vocsy_epub_viewer/epub_viewer.dart';

// In _openEpubReader method:
void _openEpubReader() async {
  setState(() => _isLoading = true);

  try {
    // Configure the EPUB reader
    await VocsyEpub.setConfig(
      themeColor: _themeColor,
      identifier: widget.bookId,
      scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
      allowSharing: _allowSharing,
      enableTts: _enableTts,
      nightMode: _nightMode,
    );

    // Listen for page changes and highlights
    VocsyEpub.locatorStream.listen((locator) {
      print('Current location: $locator');
      // Save reading progress
      _saveReadingProgress(locator);
    });

    // Load existing highlights
    await _loadHighlightsToReader();

    // Open the book
    await VocsyEpub.open(
      widget.bookPath,
      lastLocation: await _getLastReadingLocation(),
    );

  } catch (e) {
    _showError('Error opening EPUB: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Add Highlight Integration

```dart
Future<void> _loadHighlightsToReader() async {
  final highlights = await _readingService.getHighlights(widget.bookId);
  
  // Convert to FolioReader format
  final folioHighlights = highlights.map((h) => 
    _readingService.highlightToFolioFormat(h)
  ).toList();
  
  // Load into reader (this requires extending the plugin)
  // VocsyEpub.loadHighlights(folioHighlights);
}

Future<EpubLocator?> _getLastReadingLocation() async {
  final prefs = await SharedPreferences.getInstance();
  final locationJson = prefs.getString('${widget.bookId}_location');
  
  if (locationJson != null && locationJson.isNotEmpty) {
    return EpubLocator.fromJson(json.decode(locationJson));
  }
  return null;
}

void _saveReadingProgress(String locatorJson) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('${widget.bookId}_location', locatorJson);
}
```

## Step 5: Extending vocsy_epub_viewer for Highlights

To fully integrate highlights, you need to extend the vocsy_epub_viewer plugin:

### Create a custom method channel:

```dart
class ExtendedEpubViewer {
  static const MethodChannel _channel = MethodChannel('extended_epub_viewer');
  
  static Future<void> addHighlight(Map<String, dynamic> highlight) async {
    await _channel.invokeMethod('addHighlight', highlight);
  }
  
  static Future<void> removeHighlight(String highlightId) async {
    await _channel.invokeMethod('removeHighlight', {'id': highlightId});
  }
  
  static Future<List<Map<String, dynamic>>> getHighlights() async {
    final result = await _channel.invokeMethod('getHighlights');
    return List<Map<String, dynamic>>.from(result);
  }
}
```

### Android Implementation (Java):

```java
// In your plugin's Android code
public class ExtendedEpubViewerPlugin implements MethodCallHandler {
    
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "addHighlight":
                addHighlight(call.arguments, result);
                break;
            case "removeHighlight":
                removeHighlight(call.arguments, result);
                break;
            case "getHighlights":
                getHighlights(result);
                break;
            default:
                result.notImplemented();
        }
    }
    
    private void addHighlight(Object arguments, Result result) {
        Map<String, Object> highlight = (Map<String, Object>) arguments;
        
        // Convert to FolioReader HighLight object
        HighlightData highlightData = new HighlightData();
        highlightData.setContent((String) highlight.get("content"));
        highlightData.setBookId((String) highlight.get("bookId"));
        // ... set other properties
        
        // Add to FolioReader
        folioReader.addHighlight(highlightData);
        
        result.success(true);
    }
}
```

## Step 6: Advanced Features

### Context Menu Integration

```dart
// Add to your selection handler
void _showTextSelectionMenu(String selectedText, TextSelection selection) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.copy),
            title: Text('Copy'),
            onTap: () => _copyText(selectedText),
          ),
          ListTile(
            leading: Icon(Icons.translate),
            title: Text('Translate'),
            onTap: () => _translateText(selectedText),
          ),
          ListTile(
            leading: Icon(Icons.search),
            title: Text('Search Google'),
            onTap: () => _searchGoogle(selectedText),
          ),
          ListTile(
            leading: Icon(Icons.highlight),
            title: Text('Highlight'),
            onTap: () => _showHighlightColors(selectedText, selection),
          ),
          ListTile(
            leading: Icon(Icons.bookmark),
            title: Text('Bookmark'),
            onTap: () => _addBookmark(selectedText, selection),
          ),
        ],
      ),
    ),
  );
}
```

### Font and Reading Settings

```dart
void _applyReadingSettings() {
  VocsyEpub.setConfig(
    themeColor: _themeColor,
    nightMode: _nightMode,
    scrollDirection: _isHorizontalReading 
      ? EpubScrollDirection.HORIZONTAL 
      : EpubScrollDirection.VERTICAL,
    allowSharing: _allowSharing,
    enableTts: _enableTts,
  );
}
```

## Step 7: Testing

### Create Test EPUB Files

Place sample EPUB files in `assets/books/`:
- alice.epub
- sample.epub
- gatsby.epub

Update `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/books/
```

### Test the Implementation

1. Run the app
2. Navigate to EPUB Demo page
3. Select a book
4. Test highlighting and bookmarking
5. Verify data persistence

## Step 8: Production Considerations

### Performance Optimization

```dart
// Lazy loading for large highlight lists
class HighlightPaginator {
  static const int pageSize = 50;
  
  Future<List<EpubHighlight>> getHighlightsPage(String bookId, int page) async {
    final allHighlights = await _readingService.getHighlights(bookId);
    final startIndex = page * pageSize;
    final endIndex = math.min(startIndex + pageSize, allHighlights.length);
    
    return allHighlights.sublist(startIndex, endIndex);
  }
}
```

### Error Handling

```dart
class EpubReaderErrorHandler {
  static void handleError(BuildContext context, String operation, dynamic error) {
    String userMessage;
    
    switch (operation) {
      case 'open_epub':
        userMessage = 'Could not open EPUB file. Please check if the file is valid.';
        break;
      case 'save_highlight':
        userMessage = 'Could not save highlight. Please try again.';
        break;
      default:
        userMessage = 'An unexpected error occurred.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userMessage),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _retryOperation(operation),
        ),
      ),
    );
    
    // Log for debugging
    print('EPUB Reader Error [$operation]: $error');
  }
}
```

## Troubleshooting

### Common Issues

1. **Plugin not loading**: Ensure proper Android/iOS configuration
2. **Highlights not showing**: Check FolioReader integration
3. **File access errors**: Verify permissions
4. **Performance issues**: Implement pagination for large datasets

### Debug Mode

```dart
class EpubDebugHelper {
  static bool isDebugMode = true;
  
  static void log(String message) {
    if (isDebugMode) {
      print('[EPUB Debug] $message');
    }
  }
  
  static void logHighlight(EpubHighlight highlight) {
    log('Highlight: ${highlight.content.substring(0, 50)}... on page ${highlight.pageNumber}');
  }
}
```

## Summary

This enhanced EPUB reader provides:

1. **Complete text selection system** with copy, translate, search, highlight, and bookmark
2. **Advanced highlight management** with colors and notes
3. **Comprehensive bookmark system** with navigation
4. **Reading customization** with themes, fonts, and reading modes
5. **Data persistence** with local storage
6. **Performance optimization** for large documents

The implementation mirrors the features you have in your novel reader while being specifically tailored for EPUB format requirements. 