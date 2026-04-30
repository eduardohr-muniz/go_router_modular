import 'package:flutter/material.dart';

class StatefulFavoritesPage extends StatefulWidget {
  const StatefulFavoritesPage({Key? key}) : super(key: key);

  @override
  State<StatefulFavoritesPage> createState() => _StatefulFavoritesPageState();
}

class _StatefulFavoritesPageState extends State<StatefulFavoritesPage> {
  final List<String> _favorites = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('❤️ StatefulFavoritesPage initState - items: ${_favorites.length}');
  }

  @override
  void dispose() {
    print('❤️ StatefulFavoritesPage dispose - items: ${_favorites.length}');
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('❤️ StatefulFavoritesPage build - items: ${_favorites.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites Tab'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Favorites List - State Persistence Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Add a favorite...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            setState(() {
                              _favorites.add(_controller.text);
                              _controller.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _favorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text('No favorites yet'),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                '💡 Test: Add items to favorites, then switch tabs.',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'When you come back, all items should still be here!',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.red),
                        title: Text(_favorites[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _favorites.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
