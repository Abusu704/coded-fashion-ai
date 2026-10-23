import 'dart:convert';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(const CampaignApp());
}

class CampaignApp extends StatelessWidget {
  const CampaignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fashion Campaign Studio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315C35)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F2),
      ),
      home: const CampaignFormScreen(),
    );
  }
}

class CampaignFormScreen extends StatefulWidget {
  const CampaignFormScreen({super.key});

  @override
  State<CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends State<CampaignFormScreen> {
  final _brandController = TextEditingController();
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _promptController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _productImage;
  Uint8List? _previewBytes;
  bool _isGenerating = false;
  Map<String, dynamic>? _campaign;
  String? _errorMessage;
  Uint8List? _posterBytes;

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        setState(() {
          _productImage = image;
          _previewBytes = bytes;
          _campaign = null;
          _posterBytes = null;
          _errorMessage = null;
        });
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select the image.')),
      );
    }
  }

  Future<void> _generateCampaign() async {
    if (_productImage == null ||
        _previewBytes == null ||
        _brandController.text.trim().isEmpty ||
        _productController.text.trim().isEmpty ||
        _promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a photo, brand, product and campaign prompt.'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _campaign = null;
      _posterBytes = null;
      _errorMessage = null;
    });

    try {
     const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

final apiUrl = apiBaseUrl.isNotEmpty
    ? '$apiBaseUrl/api/campaign'
    : 'http://${Platform.isAndroid ? '172.31.245.137' : 'localhost'}:5001/api/campaign';

final request = http.MultipartRequest(
  'POST',
  Uri.parse(apiUrl),
);

      request.fields.addAll({
        'brandName': _brandController.text.trim(),
        'productName': _productController.text.trim(),
        'price': _priceController.text.trim(),
        'prompt': _promptController.text.trim(),
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'productImage',
          _previewBytes!,
          filename: _productImage!.name.isNotEmpty
              ? _productImage!.name
              : 'upload.png',
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );

      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Campaign generation failed.');
      }

      final posterBytes = base64Decode(data['posterBase64'] as String);

      if (!mounted) return;

      setState(() {
        _campaign = Map<String, dynamic>.from(data['campaign'] as Map);
        _posterBytes = posterBytes;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Could not generate your campaign. Check that the backend is running on port 5001.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _downloadPoster() {
    if (_posterBytes == null) return;

    if (kIsWeb) {
      try {
        final blob = html.Blob([_posterBytes!], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'fashion_campaign.png')
          ..click();
        html.Url.revokeObjectUrl(url);
      } catch (_) {
        _showSnack('Could not download the poster.');
      }
    } else {
      _showSnack('Poster download currently configured for web browser.');
    }
  }

  Future<void> _copyText(String text) async {
    if (text.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    _showSnack('Copied to clipboard!');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _brandController.dispose();
    _productController.dispose();
    _priceController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fashion Campaign Studio'),
        backgroundColor: const Color(0xFFF7F7F2),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          final formSection = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create your next campaign',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Turn your product details into an Instagram-ready promotion.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _isGenerating ? null : _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8DDCF)),
                  ),
                  child: _previewBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: Color(0xFF315C35),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Upload product photo',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text('Tap to choose an image'),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _previewBytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              ),
              if (_previewBytes != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _isGenerating ? null : _pickImage,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Choose another photo'),
                ),
              ],
              const SizedBox(height: 12),
              _field(
                controller: _brandController,
                label: 'Brand name',
                hint: 'e.g. Akos Fashion',
              ),
              _field(
                controller: _productController,
                label: 'Product name',
                hint: 'e.g. Elegant Ankara Dress',
              ),
              _field(
                controller: _priceController,
                label: 'Price (optional)',
                hint: 'e.g. GH₵250',
              ),
              _field(
                controller: _promptController,
                label: 'Campaign prompt',
                hint: 'Describe the audience, mood or promotion...',
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isGenerating ? null : _generateCampaign,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isGenerating
                        ? 'Generating campaign...'
                        : 'Generate Campaign',
                  ),
                ),
              ),
              if (_isGenerating) ...[
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Creating your campaign. This may take a moment...',
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ],
            ],
          );

          final resultsSection = _campaign != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Your promotional poster',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_posterBytes != null) ...[
                      Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        child: Image.memory(
                          _posterBytes!,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _downloadPoster,
                          icon: const Icon(Icons.download),
                          label: const Text('Download Poster PNG'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _copyText(
                        'Campaign: ${_campaign?['campaignTitle'] ?? ''}\n\n${_campaign?['caption'] ?? ''}',
                      ),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy campaign text'),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your campaign',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _resultCard(
                      title: 'Campaign title',
                      content: _campaign!['campaignTitle']?.toString() ?? '',
                    ),
                    _resultCard(
                      title: 'Instagram caption',
                      content: _campaign!['caption']?.toString() ?? '',
                    ),
                    _resultCard(
                      title: 'Call to action',
                      content: _campaign!['callToAction']?.toString() ?? '',
                    ),
                    _resultCard(
                      title: 'Promotional image direction',
                      content: _campaign!['visualDirection']?.toString() ?? '',
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _copyText(_campaign!['caption']?.toString() ?? ''),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Instagram caption'),
                    ),
                  ],
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 48,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8DDCF)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.auto_awesome_mosaic_outlined,
                        size: 52,
                        color: Color(0xFF315C35),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your results will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete the form to see your promotional poster and campaign content.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 20,
                  vertical: 24,
                ),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: formSection),
                          const SizedBox(width: 32),
                          Expanded(flex: 6, child: resultsSection),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          formSection,
                          if (_campaign != null) ...[
                            const SizedBox(height: 36),
                            resultsSection,
                          ],
                          const SizedBox(height: 30),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _resultCard({required String title, required String content}) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SelectableText(content),
          ],
        ),
      ),
    );
  }
}
