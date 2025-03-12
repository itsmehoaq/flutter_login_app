import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';

class PrintScreen extends StatefulWidget {
  const PrintScreen({Key? key}) : super(key: key);

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final FlutterUsbPrinter _flutterUsbPrinter = FlutterUsbPrinter();
  final TextEditingController _textController = TextEditingController();

  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _selectedDevice;
  bool _isConnected = false;
  String _status = 'Not connected to any printer';

  @override
  void initState() {
    super.initState();
    _getDevices();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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

  Future<void> _printText() async {
    if (!_isConnected) {
      _showMessage('Please connect to a printer first');
      await _getDevices();
      return;
    }

    if (_textController.text.isEmpty) {
      _showMessage('Please enter text to print');
      return;
    }

    try {
      Uint8List bytes = Uint8List.fromList(_textController.text.codeUnits);
      await _flutterUsbPrinter.write(bytes);

      // Thêm chức năng Auto Cut Printer
      Uint8List cutCommand = Uint8List.fromList([0x1D, 0x56, 0x41, 0x00]); // Lệnh cắt giấy ESC/POS
      await _flutterUsbPrinter.write(cutCommand);

      _showMessage('Text sent to printer with Auto Cut');
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
        title: const Text('Print Text'),
      ),
      body: Padding(
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

            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text to Print',
                border: OutlineInputBorder(),
                hintText: 'Enter text to print',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _printText,
              icon: const Icon(Icons.print),
              label: const Text('Print Text'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}