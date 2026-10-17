import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: CartScreen()));

// ---------------------------------------------------------------------------
// MODEL: one item in the cart.
// name and price never change, so they are final.
// quantity and gotIt change while the app runs, so they are NOT final.
// ---------------------------------------------------------------------------
class CartItem {
  final String name;
  final double price;
  int quantity;
  bool gotIt;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.gotIt = false,
  });
}

// ---------------------------------------------------------------------------
// STATEFUL PARENT: the widget class only creates the State object.
// The State class below owns the data (_items) and calls setState().
// ---------------------------------------------------------------------------
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // The list of items lives here, in the State.
  final List<CartItem> _items = [];

  // Controllers read what the user typed in the two TextFields.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Error messages shown under the fields (null means no error).
  String? _nameError;
  String? _priceError;

  // Runs once when the screen is created: preload 3 sample items.
  @override
  void initState() {
    super.initState();
    _items.addAll([
      CartItem(name: 'Rice', price: 60.00, quantity: 2),
      CartItem(name: 'Eggs', price: 8.00, quantity: 12),
      CartItem(name: 'Milk', price: 95.00, quantity: 1),
    ]);
  }

  // Runs when the screen is removed: free the controllers.
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Plus button: stops at 99.
  void _increase(int i) {
    setState(() {
      if (_items[i].quantity < 99) {
        _items[i].quantity++;
      }
    });
  }

  // Minus button: never goes below 1.
  void _decrease(int i) {
    setState(() {
      if (_items[i].quantity > 1) {
        _items[i].quantity--;
      }
    });
  }

  // Checkbox: flip gotIt between true and false.
  void _toggle(int i) {
    setState(() {
      _items[i].gotIt = !_items[i].gotIt;
    });
  }

  // Add button: validate first, then add the item and clear the fields.
  void _addItem() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    // Show or clear the error messages.
    setState(() {
      _nameError = name.isEmpty ? 'Name is required' : null;
      _priceError =
          (price == null || price <= 0) ? 'Enter a price greater than 0' : null;
    });

    // Stop here if anything is invalid.
    if (name.isEmpty || price == null || price <= 0) return;

    // Valid: add the item and clear both fields.
    setState(() {
      _items.add(CartItem(name: name, price: price, quantity: 1));
      _nameController.clear();
      _priceController.clear();
    });
  }

  // Clear checked button: remove every item marked "got it".
  void _clearChecked() {
    setState(() {
      _items.removeWhere((item) => item.gotIt);
    });
  }

  // Total = sum of price x quantity for all items.
  double get _total {
    double sum = 0;
    for (final item in _items) {
      sum += item.price * item.quantity;
    }
    return sum;
  }

  // How many items are checked.
  int get _gotItCount => _items.where((item) => item.gotIt).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini Shopping Cart')),
      body: SafeArea(
        child: Column(
          children: [
            // Summary bar (updates live because build runs after setState).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.amber.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Items: ${_items.length}'),
                  Text('Got it: $_gotItCount'),
                  Text(
                    'Total: PHP ${_total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // The list. Expanded gives it the leftover height.
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  return CartItemTile(
                    item: _items[i],
                    onIncrease: () => _increase(i),
                    onDecrease: () => _decrease(i),
                    onToggle: () => _toggle(i),
                  );
                },
              ),
            ),

            // Add item form and Clear checked button.
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Item name',
                            errorText: _nameError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price',
                            errorText: _priceError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton(
                          onPressed: _addItem,
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _clearChecked,
                      child: const Text('Clear checked'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATELESS CHILD: only displays data it receives and calls the callbacks.
// It never calls setState. The parent changes the data.
// ---------------------------------------------------------------------------
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onToggle;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: item.gotIt,
        onChanged: (_) => onToggle(),
      ),
      title: Text( 
        item.name,
        style: TextStyle(
          // Line-through when the item is checked.
          decoration: item.gotIt ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text('PHP ${item.price.toStringAsFixed(2)} each'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.remove), onPressed: onDecrease),
          Text('${item.quantity}'),
          IconButton(icon: const Icon(Icons.add), onPressed: onIncrease),
        ],
      ),
    );
  }
}