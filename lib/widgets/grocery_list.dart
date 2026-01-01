import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/models/groceries_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'dart:convert';
import 'package:shopping_list/data/categories.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final Uri url = Uri.https(
      'flutter-prep-ed671-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    final response = await http.get(url);
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to fetch data. Please try again later.';
      });
      return [];
    }
    if (response.body == 'null') {
      return [];
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.title == item.value['category'],
          )
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.push<GroceryItem>(
      context,
      MaterialPageRoute(builder: (context) => const NewItem()),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.removeWhere((grocery) => grocery.id == item.id);
    });
    final Uri url = Uri.https(
      'flutter-prep-ed671-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to delete item. Please try again later.';
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Text(
        'No items added yet.',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall!.copyWith(color: Colors.white),
      ),
    );

    content = ListView.builder(
      itemCount: _groceryItems.length,
      itemBuilder: (context, index) {
        final item = _groceryItems[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red.withOpacity(0.8),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            _removeItem(item);
          },
          child: ListTile(
            title: Text(item.name),
            leading: Container(
              width: 24,
              height: 24,
              color: item.category.color,
            ),
            trailing: Text(item.quantity.toString()),
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _addItem)],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            _groceryItems = snapshot.data!;
            if (_groceryItems.isEmpty) {
              return Center(
                child: Text(
                  'No items added yet.',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall!.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              return ListView.builder(
                itemCount: _groceryItems.length,
                itemBuilder: (context, index) {
                  final item = _groceryItems[index];
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red.withOpacity(0.8),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      _removeItem(item);
                    },
                    child: ListTile(
                      title: Text(item.name),
                      leading: Container(
                        width: 24,
                        height: 24,
                        color: item.category.color,
                      ),
                      trailing: Text(item.quantity.toString()),
                    ),
                  );
                },
              );
            }
          } else {
            return content;
          }
        },
      ),
    );
  }
}
