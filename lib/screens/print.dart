import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';

class PrintScreen extends StatefulWidget {
  const PrintScreen({Key? key}) : super(key: key);

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final FlutterUsbPrinter _flutterUsbPrinter = FlutterUsbPrinter();

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _receivedAmountController = TextEditingController();
  final TextEditingController _returnAmountController = TextEditingController();

  String _paymentMethod = 'Card';

  bool _receivedAmountError = false;
  String _receivedAmountErrorText = '';

  final List<Map<String, dynamic>> _items = [
    {'name': 'Item A', 'price': 5.0},
    {'name': 'Item B', 'price': 10.0},
    {'name': 'Item C', 'price': 15.0},
    {'name': 'Item D', 'price': 20.0},
  ];

  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _selectedDevice;
  bool _isConnected = false;
  String _status = 'Not connected to any printer';

  @override
  void initState() {
    super.initState();
    _getDevices();
    _receivedAmountController.addListener(_validateAndCalculateReturnAmount);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _receivedAmountController.dispose();
    _returnAmountController.dispose();
    super.dispose();
  }

  void _validateAndCalculateReturnAmount() {
    setState(() {
      _receivedAmountError = false;
      _receivedAmountErrorText = '';
    });

    if (_receivedAmountController.text.isEmpty) {
      _returnAmountController.text = '0.00';
      return;
    }

    try {
      double receivedAmount = double.parse(_receivedAmountController.text);
      double subtotal = 50.0;

      if (receivedAmount < subtotal) {
        setState(() {
          _receivedAmountError = true;
          _receivedAmountErrorText = 'Amount must be at least \$50.00';
        });
        _returnAmountController.text = '0.00';
        return;
      }

      double returnAmount = receivedAmount - subtotal;
      _returnAmountController.text = returnAmount.toStringAsFixed(2);
    } catch (e) {
      setState(() {
        _receivedAmountError = true;
        _receivedAmountErrorText = 'Please enter a valid number';
      });
      _returnAmountController.text = '0.00';
    }
  }

  Future<void> _getDevices() async {
    try {
      List<Map<String, dynamic>> devices = await FlutterUsbPrinter.getUSBDeviceList();
      setState(() {
        _devices = devices;
        _status = 'Found ${devices.length} device(s)';
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting devices: $e';
      });
    }
  }

  Future<void> _connectPrinter() async {
    if (_selectedDevice == null) {
      _showMessage('Please select a printer first');
      return;
    }

    try {
      bool? isConnected = await _flutterUsbPrinter.connect(
        int.parse(_selectedDevice!['vendorId']),
        int.parse(_selectedDevice!['productId']),
      );

      setState(() {
        _isConnected = isConnected ?? false;
        _status = _isConnected
            ? 'Connected to ${_selectedDevice!['manufacturer']} ${_selectedDevice!['productName']}'
            : 'Failed to connect to device';
      });
    } catch (e) {
      setState(() {
        _status = 'Error connecting: $e';
        _isConnected = false;
      });
    }
  }

  String _generateReceiptText() {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final timeStr = '${now.hour}:${now.minute}:${now.second}';

    double subtotal = 50.0;
    double vatRate = 0.08;
    double vatAmount = subtotal * vatRate / (1 + vatRate); // VAT included calculation
    double netAmount = subtotal - vatAmount;

    String receipt = '';

    receipt += '      KOSON STORE RECEIPT\n';
    receipt += '================================\n';
    receipt += 'Date: $dateStr\n';
    receipt += 'Time: $timeStr\n';
    receipt += 'Customer: ${_customerNameController.text}\n';
    receipt += 'Payment Method: $_paymentMethod\n';
    receipt += '================================\n\n';

    receipt += 'ITEMS:\n';
    receipt += 'Item          Price\n';
    receipt += '--------------------------------\n';

    for (var item in _items) {
      String name = item['name'];
      double price = item['price'];
      receipt += '${name.padRight(14)}  \$${price.toStringAsFixed(2)}\n';
    }

    receipt += '--------------------------------\n\n';

    receipt += 'Net Amount:      \$${netAmount.toStringAsFixed(2)}\n';
    receipt += 'VAT (8%):        \$${vatAmount.toStringAsFixed(2)}\n';
    receipt += 'SUBTOTAL:        \$${subtotal.toStringAsFixed(2)}\n\n';

    if (_receivedAmountController.text.isNotEmpty) {
      double receivedAmount = double.tryParse(_receivedAmountController.text) ?? 0.0;
      double returnAmount = double.tryParse(_returnAmountController.text) ?? 0.0;

      receipt += 'Received:        \$${receivedAmount.toStringAsFixed(2)}\n';
      receipt += 'Change:          \$${returnAmount.toStringAsFixed(2)}\n';
    }

    receipt += '================================\n';
    receipt += '      Thank You For Shopping\n';
    receipt += '          Please Come Again\n\n\n\n';

    return receipt;
  }

  Future<void> _printReceipt() async {
    if (!_isConnected) {
      _showMessage('Please connect to a printer first');
      await _getDevices();
      return;
    }

    if (_customerNameController.text.isEmpty) {
      _showMessage('Please enter customer name');
      return;
    }

    if (_receivedAmountController.text.isEmpty || _receivedAmountError) {
      _showMessage('Please enter a valid received amount (min \$50.00)');
      return;
    }

    try {
      String receiptText = _generateReceiptText();
      Uint8List bytes = Uint8List.fromList(receiptText.codeUnits);
      await _flutterUsbPrinter.write(bytes);

      await _flutterUsbPrinter.write(Uint8List.fromList('\n\n\n\n\n'.codeUnits));
      Uint8List cutCommand = Uint8List.fromList([0x1D, 0x56, 0x41, 0x00]);
      await _flutterUsbPrinter.write(cutCommand);

      _showMessage('Receipt sent to printer');
    } catch (e) {
      _showMessage('Error printing: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Printer'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _isConnected ? Colors.green.shade800 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_devices.isNotEmpty) ...[
                const Text('Select a printer:'),
                const SizedBox(height: 8),
                DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  hint: const Text('Select printer'),
                  value: _selectedDevice,
                  items: _devices.map((device) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: device,
                      child: Text('${device['manufacturer'] ?? 'Unknown'} ${device['productName'] ?? 'Printer'}'),
                    );
                  }).toList(),
                  onChanged: (Map<String, dynamic>? value) {
                    setState(() {
                      _selectedDevice = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _connectPrinter,
                  child: const Text('Connect to Printer'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _getDevices,
                  child: const Text('Refresh Devices'),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              const Text(
                'Receipt Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Payment Method:'),
              Row(
                children: [
                  Radio<String>(
                    value: 'Card',
                    groupValue: _paymentMethod,
                    onChanged: (String? value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                  const Text('Card'),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: 'Cash',
                    groupValue: _paymentMethod,
                    onChanged: (String? value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                  const Text('Cash'),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Items (Fixed):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_items[index]['name']),
                    trailing: Text('\$${_items[index]['price'].toStringAsFixed(2)}'),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                title: const Text('Subtotal (8% VAT included)', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Text('\$50.00', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _receivedAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Received Amount (\$)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                  errorText: _receivedAmountError ? _receivedAmountErrorText : null,
                  hintText: 'Min \$50.00',
                ),
              ),
              const SizedBox(height: 16),

              // Return Amount (calculated)
              TextField(
                controller: _returnAmountController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Change Amount (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money_off),
                  filled: true,
                  fillColor: Color(0xFFEEEEEE),
                ),
              ),
              const SizedBox(height: 24),

              // Print Button
              ElevatedButton.icon(
                onPressed: _printReceipt,
                icon: const Icon(Icons.print),
                label: const Text('Print Receipt'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
