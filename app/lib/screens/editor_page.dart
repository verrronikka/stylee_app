import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() => _selectedImagePath = image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5E6E8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Editor',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_fix_high, color: Colors.black87),
              onPressed: () {},
            ),
          ],
        ),
        body: _selectedImagePath == null ? _buildEmptyState() : _buildEditor(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_outlined,
              size: 80,
              color: Colors.pink.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Редактор образов',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Выберите фото для редактирования',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Выбрать фото'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Фоновые искры
              Positioned.fill(
                child: CustomPaint(painter: _SparklesPainter()),
              ),
              // Панель инструментов слева
              Positioned(
                left: 16,
                top: 20,
                bottom: 20,
                child: _buildToolbar(),
              ),
              // Изображение по центру
              Center(
                child: Container(
                  width: 220,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_selectedImagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Слайдеры
        _buildSliders(),
        // Кнопки действий
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolItem(Icons.crop_free, 'Crop'),
          const SizedBox(height: 8),
          _buildToolItem(Icons.auto_fix_normal, 'Remove\nBG'),
          const SizedBox(height: 8),
          _buildToolItem(Icons.edit, 'Fix'),
          const SizedBox(height: 8),
          _buildToolItem(Icons.filter, 'Filters'),
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Colors.red,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Color',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildToolItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 22, color: Colors.black87),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSliders() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSliderRow('Brightness', 0.5),
          const SizedBox(height: 12),
          _buildSliderRow('Contrast', 0.4),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 16,
              ),
              activeTrackColor: const Color(0xFFE91E63),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFE91E63).withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              onChanged: (v) {},
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.add, size: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton('Save to\nProfile', Icons.person_outline),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton('Send to\nChat', Icons.chat_bubble_outline),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton('Add to\nWardrobe', Icons.checkroom_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final random = [
      Offset(size.width * 0.8, size.height * 0.1),
      Offset(size.width * 0.15, size.height * 0.3),
      Offset(size.width * 0.9, size.height * 0.5),
      Offset(size.width * 0.1, size.height * 0.7),
      Offset(size.width * 0.85, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.15),
      Offset(size.width * 0.3, size.height * 0.9),
    ];

    for (final offset in random) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.drawPath(_createStar(8), paint);
      canvas.restore();
    }
  }

  Path _createStar(double size) {
    final path = Path();
    path.moveTo(0, -size);
    path.lineTo(size * 0.2, -size * 0.2);
    path.lineTo(size, 0);
    path.lineTo(size * 0.2, size * 0.2);
    path.lineTo(0, size);
    path.lineTo(-size * 0.2, size * 0.2);
    path.lineTo(-size, 0);
    path.lineTo(-size * 0.2, -size * 0.2);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
