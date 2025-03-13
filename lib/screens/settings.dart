import 'package:flutter/material.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:camera/camera.dart';
import 'debug.dart';

class PrinterSettings extends StatefulWidget {
  final Function(FlutterUsbPrinter, bool, Map<String, dynamic>?) onPrinterConnected;
  final Function(Map<String, dynamic>?)? onScannerConnected;

  const PrinterSettings({
    Key? key,
    required this.onPrinterConnected,
    this.onScannerConnected,
  }) : super(key: key);

  @override
  State<PrinterSettings> createState() => _PrinterSettingsState();
}

class _PrinterSettingsState extends State<PrinterSettings> {
  final FlutterUsbPrinter _flutterUsbPrinter = FlutterUsbPrinter();

  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _selectedPrinter;
  Map<String, dynamic>? _selectedScanner;
  bool _isPrinterConnected = false;
  bool _isScannerConnected = false;
  String _printerStatus = 'Not connected to any printer';
  String _scannerStatus = 'No QR scanner connected';
  bool _showCameraPreview = false;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraLoading = false;

  @override
  void initState() {
    super.initState();
    _getDevices();
    _initializeCameras();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  Future<void> _initializeCameraController() async {
    if (_cameras.isEmpty) {
      setState(() {
        _showCameraPreview = false;
        _isCameraInitialized = false;
      });
      return;
    }

    setState(() {
      _isCameraLoading = true;
    });

    final CameraDescription camera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _isCameraLoading = false;
      });
    } catch (e) {
      print('Error initializing camera controller: $e');
      setState(() {
        _isCameraInitialized = false;
        _isCameraLoading = false;
      });
    }
  }

  Future<void> _getDevices() async {
    try {
      List<Map<String, dynamic>> devices = await FlutterUsbPrinter.getUSBDeviceList();
      setState(() {
        _devices = devices;
        _printerStatus = 'Found ${devices.length} device(s)';
      });

      _autoSelectDefaultPrinter(devices);
    } catch (e) {
      setState(() {
        _printerStatus = 'Error getting devices: $e';
      });
    }
  }

  void _autoSelectDefaultPrinter(List<Map<String, dynamic>> devices) {
    for (var device in devices) {
      if ((device['manufacturer'] == 'Gprinter' &&
          device['productName'] == 'GP-58') ||
          (device['deviceName'] == '/dev/bus/usb/002/003')) {
        setState(() {
          _selectedPrinter = device;
        });
        _connectPrinter();
        break;
      }
    }
  }

  Future<void> _connectPrinter() async {
    if (_selectedPrinter == null) {
      _showMessage('Please select a printer first');
      return;
    }

    try {
      bool? isConnected = await _flutterUsbPrinter.connect(
        int.parse(_selectedPrinter!['vendorId'].toString()),
        int.parse(_selectedPrinter!['productId'].toString()),
      );

      setState(() {
        _isPrinterConnected = isConnected ?? false;
        _printerStatus = _isPrinterConnected
            ? 'Connected to ${_selectedPrinter!['manufacturer']} ${_selectedPrinter!['productName']}'
            : 'Failed to connect to printer';
      });

      widget.onPrinterConnected(_flutterUsbPrinter, _isPrinterConnected, _selectedPrinter);
    } catch (e) {
      setState(() {
        _printerStatus = 'Error connecting to printer: $e';
        _isPrinterConnected = false;
      });
      widget.onPrinterConnected(_flutterUsbPrinter, false, null);
    }
  }

  Future<void> _connectScanner() async {
    if (_selectedScanner == null) {
      _showMessage('Please select a QR scanner first');
      return;
    }

    try {
      setState(() {
        _isScannerConnected = true;
        _scannerStatus = 'Connected to ${_selectedScanner!['manufacturer']} ${_selectedScanner!['productName']}';

        _showCameraPreview = _isCameraDevice(_selectedScanner!);
      });

      if (_showCameraPreview) {
        await _initializeCameraController();
      }

      if (widget.onScannerConnected != null) {
        widget.onScannerConnected!(_selectedScanner);
      }
    } catch (e) {
      setState(() {
        _scannerStatus = 'Error connecting to scanner: $e';
        _isScannerConnected = false;
        _showCameraPreview = false;
      });

      if (widget.onScannerConnected != null) {
        widget.onScannerConnected!(null);
      }
    }
  }

  bool _isCameraDevice(Map<String, dynamic> device) {
    final String manufacturer = (device['manufacturer'] ?? '').toString().toLowerCase();
    final String productName = (device['productName'] ?? '').toString().toLowerCase();

    return manufacturer.contains('camera') ||
        productName.contains('camera') ||
        manufacturer.contains('webcam') ||
        productName.contains('webcam') ||
        productName.contains('scan');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showDebugScreen() async {
    try {
      List<Map<String, dynamic>> devices = await FlutterUsbPrinter.getUSBDeviceList();

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DebugScreen(
            devices: devices,
            connectedDevice: _selectedPrinter,
          ),
        ),
      );
    } catch (e) {
      _showMessage('Error accessing USB devices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _showDebugScreen,
            tooltip: 'USB Debugging',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Printer Settings', Icons.print),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: _isPrinterConnected ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _isPrinterConnected ? Colors.green.shade300 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  _printerStatus,
                  style: TextStyle(
                    color: _isPrinterConnected ? Colors.green.shade800 : Colors.black87,
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
                  value: _selectedPrinter,
                  items: _devices.map((device) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: device,
                      child: Text('${device['manufacturer'] ?? 'Unknown'} ${device['productName'] ?? 'Printer'}'),
                    );
                  }).toList(),
                  onChanged: (Map<String, dynamic>? value) {
                    setState(() {
                      _selectedPrinter = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _connectPrinter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
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

              _buildSectionHeader('QR Scanner Settings', Icons.qr_code_scanner),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: _isScannerConnected ? Colors.blue.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _isScannerConnected ? Colors.blue.shade300 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  _scannerStatus,
                  style: TextStyle(
                    color: _isScannerConnected ? Colors.blue.shade800 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_devices.isNotEmpty) ...[
                const Text('Select a QR scanner:'),
                const SizedBox(height: 8),
                DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  hint: const Text('Select QR scanner'),
                  value: _selectedScanner,
                  items: _devices.map((device) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: device,
                      child: Text('${device['manufacturer'] ?? 'Unknown'} ${device['productName'] ?? 'Device'}'),
                    );
                  }).toList(),
                  onChanged: (Map<String, dynamic>? value) {
                    setState(() {
                      _selectedScanner = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _connectScanner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Connect to QR Scanner'),
                ),
              ],

              if (_showCameraPreview) ...[
                const SizedBox(height: 24),
                _buildCameraPreview(),
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              if (_isPrinterConnected || _isScannerConnected) ...[
                const Text(
                  'Connected Devices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (_isPrinterConnected) ...[
                  _buildConnectedDeviceInfo(
                    'Printer',
                    '${_selectedPrinter?['manufacturer'] ?? 'Unknown'} ${_selectedPrinter?['productName'] ?? 'Printer'}',
                    Colors.green,
                    Icons.print,
                  ),
                  const SizedBox(height: 8),
                ],

                if (_isScannerConnected) ...[
                  _buildConnectedDeviceInfo(
                    'QR Scanner',
                    '${_selectedScanner?['manufacturer'] ?? 'Unknown'} ${_selectedScanner?['productName'] ?? 'Scanner'}',
                    Colors.blue,
                    Icons.qr_code_scanner,
                  ),
                  const SizedBox(height: 8),
                ],
              ],

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Return to Receipt Screen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedDeviceInfo(String type, String name, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Camera Preview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _isCameraLoading
                ? const Center(child: CircularProgressIndicator())
                : _isCameraInitialized
                ? CameraPreview(_cameraController!)
                : _buildCameraPlaceholder(),
          ),
        ),
        const SizedBox(height: 8),
        if (_isCameraInitialized) ...[
          Text(
            'QR scanning ready',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else ...[
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Text(
                'Camera access required for QR scanning',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCameraPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            color: Colors.white54,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Camera Preview',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'Camera access required',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
