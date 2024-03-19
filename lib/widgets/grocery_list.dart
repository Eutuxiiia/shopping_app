import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/models/grocery_item.dart';
import 'package:shopping_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({
    super.key,
  });

  @override
  State<GroceryList> createState() {
    return _GroceryListState();
  }
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  void _loadItem() async {
    final url = Uri.https(
        'https://shopping-app-a476c-default-rtdb.firebaseio.com',
        'shopping-list.json');

    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        _error = 'Failed to fetch data. Try again later.';
      }

      if (response.body == 'null') {
        setState(() {
          isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              (categoryItem) =>
                  categoryItem.value.name == item.value['category'],
            )
            .value;
        loadItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadItems;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    } else {
      setState(() {
        _groceryItems.add(newItem);
      });
    }
    _loadItem();
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https('flutter-prep-46c41-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(_error!);
    } else {
      if (isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      } else {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Groceries'),
            actions: [
              IconButton(
                onPressed: () {
                  _addItem();
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: _groceryItems.isEmpty
              ? const Center(
                  child: Text(
                    'No items added yet!',
                  ),
                )
              : ListView.builder(
                  itemCount: _groceryItems.length,
                  itemBuilder: (ctx, index) => Dismissible(
                    background: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(5),
                        ),
                        color: _groceryItems[index].category.color,
                      ),
                    ),
                    key: ValueKey(_groceryItems[index].id),
                    child: ListTile(
                      leading: Container(
                        height: 30,
                        width: 30,
                        color: _groceryItems[index].category.color,
                      ),
                      title: Text(_groceryItems[index].name),
                      trailing: Text(
                        _groceryItems[index].quantity.toString(),
                      ),
                    ),
                    onDismissed: (direction) {
                      _removeItem(_groceryItems[index]);
                    },
                  ),
                ),
        );
      }
    }
  }
}
