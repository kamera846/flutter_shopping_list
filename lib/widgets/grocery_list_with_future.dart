import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:flutter_shopping_list/models/grocery_item.dart';
import 'package:flutter_shopping_list/widgets/new_item.dart';
import 'package:flutter_shopping_list/data/categories.dart';

class GroceryListWithFuture extends StatefulWidget {
  const GroceryListWithFuture({super.key});

  @override
  State<GroceryListWithFuture> createState() => _GroceryListWithFutureState();
}

class _GroceryListWithFutureState extends State<GroceryListWithFuture> {
  final List<GroceryItem> _groceryItems = [];
  // var isLoading = true;
  late Future<List<GroceryItem>> _loadedItems;
  // String? _error;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'my-testing-project-17d76-default-rtdb.firebaseio.com',
        'shopping-list.json');

    // try {
    final response = await http.get(url);
    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch grocery items. Please try again later.');
      // setState(() {
      //   _error = 'Failed to fetch data. Please try again later.';
      // });
    }

    if (response.body == 'null') {
      // setState(() {
      //   isLoading = false;
      // });
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere((catItem) => catItem.value.name == item.value['category'])
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
    // setState(() {
    //   _groceryItems = loadedItems;
    //   isLoading = false;
    // });
    // } catch (e) {
    //   setState(() {
    //     _error = 'Something when wrong!. Please try again later.';
    //   });
    // }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
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
    String deleteMessage = '${item.name} was deleted.';
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
        'my-testing-project-17d76-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      deleteMessage = 'Failed to delete ${item.name} item.';
      setState(() {
        _groceryItems.insert(index, item);
      });
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(deleteMessage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Widget content = Center(
    //   child: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       Text(
    //         'Uh oh ... nothing here!',
    //         style: Theme.of(context).textTheme.headlineSmall!.copyWith(
    //               color: Theme.of(context).colorScheme.onBackground,
    //             ),
    //       ),
    //       const SizedBox(height: 16),
    //       Text(
    //         'Try add a new item!',
    //         style: Theme.of(context).textTheme.bodyLarge!.copyWith(
    //               color: Theme.of(context).colorScheme.onBackground,
    //             ),
    //       ),
    //     ],
    //   ),
    // );

    // // if (isLoading) {
    // //   content = const Center(
    // //     child: CircularProgressIndicator(),
    // //   );
    // // }

    // if (_groceryItems.isNotEmpty) {
    //   content = ListView.builder(
    //     itemCount: _groceryItems.length,
    //     itemBuilder: (ctx, index) => Dismissible(
    //       onDismissed: (direction) {
    //         _removeItem(_groceryItems[index]);
    //       },
    //       key: ValueKey(_groceryItems[index].id),
    //       child: ListTile(
    //         title: Text(_groceryItems[index].name),
    //         leading: Container(
    //           width: 24,
    //           height: 24,
    //           color: _groceryItems[index].category.color,
    //         ),
    //         trailing: Text(
    //           _groceryItems[index].quantity.toString(),
    //         ),
    //       ),
    //     ),
    //   );
    // }

    // if (_error != null) {
    //   content = Center(
    //     child: Column(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         Text(
    //           'Uh oh ...!',
    //           style: Theme.of(context).textTheme.headlineSmall!.copyWith(
    //                 color: Theme.of(context).colorScheme.onBackground,
    //               ),
    //         ),
    //         const SizedBox(height: 16),
    //         Text(
    //           _error!,
    //           style: Theme.of(context).textTheme.bodyLarge!.copyWith(
    //                 color: Theme.of(context).colorScheme.onBackground,
    //               ),
    //         ),
    //       ],
    //     ),
    //   );
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Uh oh ...!',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Uh oh ... nothing here!',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Try add a new item!',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) => Dismissible(
              onDismissed: (direction) {
                _removeItem(snapshot.data![index]);
              },
              key: ValueKey(snapshot.data![index].id),
              child: ListTile(
                title: Text(snapshot.data![index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: snapshot.data![index].category.color,
                ),
                trailing: Text(
                  snapshot.data![index].quantity.toString(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}