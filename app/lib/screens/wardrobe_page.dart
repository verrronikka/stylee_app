import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final List<Map<String, dynamic>> _folders = [];

  final List<Color> _colorFilters = [
    const Color(0xFFF8B4C8),
    Colors.black,
    const Color(0xFFC4A882),
    const Color(0xFFE8D5C4),
  ];

  void _createFolder() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Создать папку'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Название папки',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty && mounted) {
                  setState(() {
                    _folders.insert(0, {
                      'name': controller.text.trim(),
                      'tags': <String>[],
                      'items': <String>[],
                    });
                  });
                }
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
              ),
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  void _deleteFolder(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить папку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (mounted) {
                setState(() => _folders.removeAt(index));
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
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
            'My Wardrobe',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.black87),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Поиск
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade400),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Цветовые фильтры и категории
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ..._colorFilters.map((color) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: color,
                        ),
                      )),
                  const SizedBox(width: 8),
                  _buildCategoryIcon(Icons.checkroom),
                  const SizedBox(width: 8),
                  _buildCategoryIcon(Icons.checkroom_outlined),
                  const SizedBox(width: 8),
                  _buildCategoryIcon(Icons.style),
                  const SizedBox(width: 8),
                  _buildCategoryIcon(Icons.shopping_bag_outlined),
                  const SizedBox(width: 8),
                  _buildCategoryIcon(Icons.checkroom_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Список папок или пустое состояние
            Expanded(
              child: _folders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _folders.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _folders.length) {
                          return _buildCreateFolderButton();
                        }
                        return _buildFolder(_folders[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 80,
            color: Colors.pink.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'Гардероб пуст',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Создайте папку для ваших образов',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createFolder,
            icon: const Icon(Icons.add),
            label: const Text('Создать папку'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Icon(icon, size: 18, color: Colors.black87),
    );
  }

  Widget _buildFolder(Map<String, dynamic> folder, int index) {
    final items = folder['items'] as List<dynamic>;
    final tags = folder['tags'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                folder['name'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.grey.shade400,
              onPressed: () => _deleteFolder(index),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: tags.map<Widget>((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                )).toList(),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 32,
                  color: Colors.pink.shade300,
                ),
                const SizedBox(height: 8),
                Text(
                  'Пока пусто',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCreateFolderButton() {
    return GestureDetector(
      onTap: _createFolder,
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              'Создать папку',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
