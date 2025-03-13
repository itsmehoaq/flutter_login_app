import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'settings.dart';
import 'qr.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({Key? key}) : super(key: key);

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  FlutterUsbPrinter? _flutterUsbPrinter;
  final FlutterUsbPrinter _usbPrinter = FlutterUsbPrinter();

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

  bool _isConnected = false;
  Map<String, dynamic>? _selectedDevice;
  String _printerStatus = 'Not connected to any printer';
  Map<String, dynamic>? _selectedScanner;

  @override
  void initState() {
    super.initState();
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

  void _handlePrinterConnected(FlutterUsbPrinter printer, bool isConnected, Map<String, dynamic>? device) {
    setState(() {
      _flutterUsbPrinter = printer;
      _isConnected = isConnected;
      _selectedDevice = device;
      _printerStatus = _isConnected
          ? 'Connected to ${_selectedDevice?['manufacturer'] ?? 'Unknown'} ${_selectedDevice?['productName'] ?? 'Printer'}'
          : 'Not connected to any printer';
    });
  }

  void _handleScannerConnected(Map<String, dynamic>? device) {
    setState(() {
      _selectedScanner = device;
    });
  }

  Future<void> _navigateToPrinterSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrinterSettings(
          onPrinterConnected: _handlePrinterConnected,
          onScannerConnected: _handleScannerConnected,
        ),
      ),
    );
  }

  String _generateReceiptText() {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final timeStr = '${now.hour}:${now.minute}:${now.second}';

    double subtotal = 50.0;
    double vatRate = 0.08;
    double vatAmount = subtotal * vatRate / (1 + vatRate);
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
    receipt += '         Please Come Again\n\n\n\n';

    return receipt;
  }

  Future<void> _printReceipt() async {
    if (!_isConnected || _flutterUsbPrinter == null) {
      _showMessage('Please connect to a printer first');
      return;
    }

    try {
      String receiptText = _generateReceiptText();
      Uint8List bytes = Uint8List.fromList(receiptText.codeUnits);
      await _flutterUsbPrinter!.write(bytes);

      await _flutterUsbPrinter!.write(Uint8List.fromList('\n\n\n\n\n'.codeUnits));
      Uint8List cutCommand = Uint8List.fromList([0x1D, 0x56, 0x41, 0x00]);
      await _flutterUsbPrinter!.write(cutCommand);

      _showMessage('Receipt printed successfully');
    } catch (e) {
      _showMessage('Error printing: $e');
    }
  }

  Future<void> _navigateToQRPaymentScreen() async {
    if (_customerNameController.text.isEmpty) {
      _showMessage('Please enter customer name');
      return;
    }

    if (_receivedAmountController.text.isEmpty || _receivedAmountError) {
      _showMessage('Please enter a valid received amount (min \$50.00)');
      return;
    }

    final paymentCompleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => QRPaymentScreen(
          customerName: _customerNameController.text,
          amount: 50.0,
          scanner: _selectedScanner,
          onPrintReceipt: _printReceipt,
        ),
      ),
    );

    if (paymentCompleted == true) {
      _showMessage('Payment completed successfully');
      _customerNameController.clear();
      _receivedAmountController.clear();
      _returnAmountController.text = '0.00';
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
        title: const Text('Receipt Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToPrinterSettings,
            tooltip: 'Printer Settings',
          ),
        ],
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
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.print,
                      color: _isConnected ? Colors.green.shade800 : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _printerStatus,
                        style: TextStyle(
                          color: _isConnected ? Colors.green.shade800 : Colors.black87,
                        ),
                      ),
                    ),
                    if (!_isConnected) ...[
                      TextButton(
                        onPressed: _navigateToPrinterSettings,
                        child: const Text('Connect'),
                      ),
                    ],
                  ],
                ),
              ),
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

              TextField(
                controller: _receivedAmountController,
                decoration: InputDecoration(
                  labelText: 'Received Amount',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                  errorText: _receivedAmountError ? _receivedAmountErrorText : null,
                  helperText: 'Maximum amount: \$9,999',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _returnAmountController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Change Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
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
                  const SizedBox(width: 16),
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
              const SizedBox(height: 24),

              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._items.map((item) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['name']),
                          Text('\$${item['price'].toStringAsFixed(2)}'),
                        ],
                      )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Subtotal:'),
                          Text('\$50.00'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _navigateToQRPaymentScreen,
                icon: const Icon(Icons.payment),
                label: const Text('CHECK OUT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
