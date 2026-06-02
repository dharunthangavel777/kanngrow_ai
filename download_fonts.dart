import 'dart:io';

void main() async {
  final fontsDir = Directory('assets/fonts');
  if (!await fontsDir.exists()) {
    await fontsDir.create(recursive: true);
  }

  final fonts = {
    'Outfit-Regular.ttf': 'https://raw.githubusercontent.com/googlefonts/Outfit/main/fonts/ttf/Outfit-Regular.ttf',
    'Outfit-Medium.ttf': 'https://raw.githubusercontent.com/googlefonts/Outfit/main/fonts/ttf/Outfit-Medium.ttf',
    'Outfit-SemiBold.ttf': 'https://raw.githubusercontent.com/googlefonts/Outfit/main/fonts/ttf/Outfit-SemiBold.ttf',
    'Outfit-Bold.ttf': 'https://raw.githubusercontent.com/googlefonts/Outfit/main/fonts/ttf/Outfit-Bold.ttf',
  };

  final client = HttpClient();
  
  for (final entry in fonts.entries) {
    final fileName = entry.key;
    final url = entry.value;
    final file = File('${fontsDir.path}/$fileName');
    
    print('Downloading $fileName...');
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      await response.pipe(file.openWrite());
      print('Downloaded $fileName');
    } catch (e) {
      print('Failed to download $fileName: $e');
    }
  }
  
  client.close();
}
