import 'dart:io';
import 'package:csv/csv.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/todo.dart';

class CsvService {
  // Convert todos to CSV format
  Future<String> todosToCsv(List<Todo> todos) async {
    List<List<dynamic>> rows = [];

    // Add header row
    rows.add([
      'ID',
      'Title',
      'Description',
      'Time',
      'Weekday',
      'Is Done',
      'Type'
    ]);

    // Add data rows
    for (var todo in todos) {
      rows.add([
        todo.id,
        todo.title,
        todo.description,
        todo.time ?? '',
        todo.weekday ?? '',
        todo.isDone ? 1 : 0,
        todo.type.index,
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);
    return csv;
  }

  // Convert CSV to todos
  List<Todo> csvToTodos(String csvContent) {
    List<Todo> todos = [];
    
    // Convert CSV to lists
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);

    // Skip the header row
    if (rows.isNotEmpty) {
      for (var i = 1; i < rows.length; i++) {
        try {
          var row = rows[i];
          // Check if row has enough columns
          if (row.length >= 7) {
            todos.add(Todo(
              id: row[0] != '' ? row[0] as int : null,
              title: row[1].toString(),
              description: row[2].toString(),
              time: row[3] != '' ? row[3].toString() : null,
              weekday: row[4] != '' ? row[4].toString() : null,
              isDone: row[5] == 1 ? true : false,
              type: TodoType.values[row[6] as int],
            ));
          }
        } catch (e) {
          debugPrint('Error parsing CSV row: $e');
        }
      }
    }
    
    return todos;
  }

  // Check and request all required permissions based on Android version
  Future<bool> _requestPermissions() async {
    // Check Android version
    if (Platform.isAndroid) {
      // Get Android SDK version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;
      
      try {
        if (sdkVersion >= 33) { // Android 13+
          // For Android 13+ (API 33+), request specific permissions
          final documents = await Permission.manageExternalStorage.request();
          if (documents.isGranted) {
            return true;
          }
          
          // Try alternative permissions
          final photos = await Permission.photos.request();
          final storage = await Permission.storage.request();
          if (photos.isGranted || storage.isGranted) {
            return true;
          }
        } else if (sdkVersion >= 30) { // Android 11-12
          // First try normal storage permission
          final storage = await Permission.storage.request();
          if (storage.isGranted) {
            return true;
          }
          
          // On Android 11+, we definitely need manage external storage for direct access
          // to specific external paths like '/storage/emulated/0/'
          final manageStorage = await Permission.manageExternalStorage.request();
          return manageStorage.isGranted;
        } else { // Android 10 and below
          // Legacy storage permission is sufficient
          final storage = await Permission.storage.request();
          return storage.isGranted;
        }
      } catch (e) {
        debugPrint('İzin isteme hatası: $e');
      }
      
      // Always check if we can access app-specific directory as a fallback
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final testFile = File('${appDir.path}/test_permission.txt');
        await testFile.writeAsString('test');
        await testFile.delete();
        return true; // We can at least access app-specific directories
      } catch (e) {
        debugPrint('Yedek izin testi hatası: $e');
      }
      
      return false;
    } else if (Platform.isIOS) {
      // iOS has a different permission model
      return true; // iOS uses document picker which handles permissions
    }
    
    return true; // Default for other platforms
  }

  // Export todos to a CSV file with directory selection
  Future<String?> exportToCsvFile(List<Todo> todos, {String defaultFileName = 'todos.csv'}) async {
    try {
      // Get CSV content
      String csvContent = await todosToCsv(todos);
      
      // Request necessary permissions
      bool permissionsGranted = await _requestPermissions();
      
      if (permissionsGranted) {
        // Ask user to select a directory first
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'CSV Dosyası için Klasör Seçin',
        );

        // If user canceled the directory selection
        if (selectedDirectory == null) {
          return null;
        }
        
        // Now ask user for the filename
        String fileName = defaultFileName;
        
        // Full path with selected directory and filename
        String outputFilePath = '$selectedDirectory/$fileName';
        
        // Ensure the path ends with .csv
        if (!outputFilePath.toLowerCase().endsWith('.csv')) {
          outputFilePath = '$outputFilePath.csv';
        }
        
        // Write file to the selected location
        final File file = File(outputFilePath);
        await file.writeAsString(csvContent);
        return outputFilePath;
      } else {
        // No permissions, try app-specific directory as last resort
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$defaultFileName');
        await file.writeAsString(csvContent);
        
        return file.path + '\n⚠️ Not: Dosya uygulama dizininde kaydedildi, depolama izni alınamadı.';
      }
    } catch (e) {
      debugPrint('CSV dışa aktarma hatası: $e');
      
      // Fall back to default method if directory selection fails
      try {
        return _fallbackExportToCsvFile(todos, defaultFileName);
      } catch (fallbackError) {
        debugPrint('Alternatif dışa aktarma yöntemi de başarısız: $fallbackError');
        rethrow;
      }
    }
  }
  
  // Fallback method for platforms where saveFile is not supported
  Future<String?> _fallbackExportToCsvFile(List<Todo> todos, String fileName) async {
    try {
      // Get CSV content
      String csvContent = await todosToCsv(todos);
      
      Directory? directory;
      if (Platform.isAndroid) {
        try {
          // Try to use the safer Download directory first
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          final sdkVersion = androidInfo.version.sdkInt;
          
          if (sdkVersion >= 29) { // Android 10+
            // Use the app's Download directory - safer for Android 10+
            directory = await getExternalStorageDirectory();
            
            // Create a 'Download' subfolder in the app's external storage
            final downloadDir = Directory('${directory?.path}/Download');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            directory = downloadDir;
          } else {
            // On older Android versions, we can still use public directories
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              // Fall back to app-specific directory
              directory = await getExternalStorageDirectory();
            }
          }
          
          // Final fallback to app documents if still null
          if (directory == null) {
            directory = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          debugPrint('Dizin alma hatası: $e');
          // Always have a fallback
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        // iOS and other platforms - use app documents
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory != null) {
        // Create the file
        final File file = File('${directory.path}/$fileName');
        await file.writeAsString(csvContent);
        return file.path;
      }
    } catch (e) {
      debugPrint('Alternatif dışa aktarma hatası: $e');
      // Final fallback: try to save in app documents directory
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final file = File('${appDir.path}/$fileName');
        final String csvContent = await todosToCsv(todos);
        await file.writeAsString(csvContent);
        return file.path + '\n⚠️ Not: Dosya uygulama dizininde kaydedildi.';
      } catch (e2) {
        debugPrint('Son çare dışa aktarma hatası: $e2');
        rethrow;
      }
    }
    return null;
  }

  // Import todos from a CSV file with enhanced file picker
  Future<List<Todo>> importFromCsvFile() async {
    try {
      // Always try to use file picker first
      try {
        // Enhanced file picker configuration
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv'],
          allowMultiple: false,
          dialogTitle: 'CSV Dosyasını Seç',
          lockParentWindow: true,
        );
        
        if (result != null && result.files.isNotEmpty) {
          final filePath = result.files.single.path!;
          
          // Always prefer to use a URI-based approach when possible
          File file;
          if (filePath.startsWith('/storage/emulated/0') || filePath.startsWith('/storage/')) {
            // For paths that might need special permission handling
            try {
              bool hasPermission = await _requestPermissions();
              if (!hasPermission) {
                throw Exception('Bu dosyaya erişmek için gerekli izinler eksik');
              }
            } catch (e) {
              debugPrint('İzin kontrolü hatası: $e');
            }
          }
          
          file = File(filePath);
          
          // Check if file exists and is readable before attempting to read
          if (await file.exists()) {
            try {
              final String csvContent = await file.readAsString();
              return csvToTodos(csvContent);
            } catch (e) {
              debugPrint('Dosya okuma hatası: $e');
              throw Exception('Dosya okunamadı: $e');
            }
          } else {
            throw Exception('Seçilen dosya bulunamadı: $filePath');
          }
        } else {
          // User canceled the picker
          return [];
        }
      } catch (e) {
        debugPrint('FilePicker hatası: $e');
        // If file picker fails, check if this is a specific path we're trying to access
        if (e.toString().contains('/storage/emulated/0/Data.csv')) {
          throw Exception('\'Data.csv\' dosyasına erişilemedi. Lütfen dosyayı Download klasörüne taşıyın veya dosya seçici kullanın.');
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('CSV içe aktarma hatası: $e');
      rethrow;
    }
  }
  
  // Direct import from a specified path - be careful with this
  Future<List<Todo>> importFromPath(String filePath) async {
    try {
      // Request permissions first
      bool permissionsGranted = await _requestPermissions();
      
      if (!permissionsGranted) {
        throw Exception('Depolama izinleri reddedildi. Lütfen uygulama ayarlarından depolama izinlerini verin.');
      }
      
      final File file = File(filePath);
      if (await file.exists()) {
        final String csvContent = await file.readAsString();
        return csvToTodos(csvContent);
      } else {
        throw Exception('Dosya bulunamadı: $filePath');
      }
    } catch (e) {
      debugPrint('Belirli dosyadan içe aktarma hatası: $e');
      rethrow;
    }
  }
}