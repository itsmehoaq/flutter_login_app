import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QRPaymentScreen extends StatefulWidget {
  final String customerName;
  final double amount;
  final Map<String, dynamic>? scanner;
  final Function onPrintReceipt;

  const QRPaymentScreen({
    Key? key,
    required this.customerName,
    required this.amount,
    this.scanner,
    required this.onPrintReceipt,
  }) : super(key: key);

  @override
  State<QRPaymentScreen> createState() => _QRPaymentScreenState();
}

class _QRPaymentScreenState extends State<QRPaymentScreen> {
  bool _isPaymentCompleted = false;
  bool _isProcessing = false;
  bool _isListeningForQR = false;
  String? _scannedQRData;

  final FocusNode _keyboardFocusNode = FocusNode();
  final TextEditingController _qrInputController = TextEditingController();

  PaymentStep _currentStep = PaymentStep.selectMethod;

  @override
  void initState() {
    super.initState();
    _qrInputController.addListener(_onQRInputChanged);
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _qrInputController.removeListener(_onQRInputChanged);
    _qrInputController.dispose();
    super.dispose();
  }

  void _onQRInputChanged() {
    if (_qrInputController.text.isNotEmpty && _isListeningForQR) {
      setState(() {
        _scannedQRData = _qrInputController.text.trim();
        _isListeningForQR = false;
        _isPaymentCompleted = true;
      });

      _qrInputController.clear();
    }
  }

  void _simulateQRScan() {
    setState(() {
      _isProcessing = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isProcessing = false;
        _isPaymentCompleted = true;
      });
    });
  }

  void _selectPaymentMethod(PaymentStep method) {
    setState(() {
      _currentStep = method;

      if (method == PaymentStep.scanQR) {
        _startScannerListener();
      } else {
        _isListeningForQR = false;
      }
    });
  }

  void _startScannerListener() {
    if (widget.scanner != null) {
      setState(() {
        _isListeningForQR = true;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _keyboardFocusNode.requestFocus();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Scanner not connected. Please connect scanner in settings.')),
      );
    }
  }

  void _skipPayment() {
    setState(() {
      _isPaymentCompleted = true;
    });
  }

  void _printReceiptAndReturn() async {
    await widget.onPrintReceipt();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _goBackToMethodSelection() {
    setState(() {
      _currentStep = PaymentStep.selectMethod;
      _isListeningForQR = false;
    });
  }

  void _simulateUserQRScan() {
    setState(() {
      _isProcessing = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isProcessing = false;
        _isPaymentCompleted = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final timeStr = '${now.hour}:${now.minute}:${now.second}';
    final transactionId = 'TRX${now.millisecondsSinceEpoch.toString().substring(5)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Payment'),
        leading: _currentStep != PaymentStep.selectMethod && !_isPaymentCompleted
            ? BackButton(onPressed: _goBackToMethodSelection)
            : null,
      ),
      body: Stack(
        children: [
          Offstage(
            offstage: true,
            child: TextField(
              controller: _qrInputController,
              focusNode: _keyboardFocusNode,
              autofocus: _isListeningForQR,
              showCursor: false,
              readOnly: false,
              enableInteractiveSelection: false,
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              style: const TextStyle(
                color: Colors.transparent,
                fontSize: 1,
              ),
              keyboardType: TextInputType.none,
            ),
          ),

          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Customer', widget.customerName),
                          _buildInfoRow('Amount', '\$${widget.amount.toStringAsFixed(2)}'),
                          _buildInfoRow('Transaction ID', transactionId),
                          _buildInfoRow('Date', dateStr),
                          _buildInfoRow('Time', timeStr),
                          _buildInfoRow('Payment Method', 'QR Code Payment'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isPaymentCompleted) ...[
                    _buildPaymentSuccessWidget(transactionId),
                  ] else if (_currentStep == PaymentStep.selectMethod) ...[
                    _buildPaymentMethodSelection(),
                  ] else if (_currentStep == PaymentStep.showQR) ...[
                    _buildShowQRWidget(),
                  ] else if (_currentStep == PaymentStep.scanQR) ...[
                    _buildScanQRWidget(),
                  ],

                  if (_isPaymentCompleted) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _printReceiptAndReturn,
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Print Receipt & Return'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSuccessWidget(String transactionId) {
    return Card(
      color: Colors.green.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction ID: $transactionId',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            if (_scannedQRData != null) ...[
              const SizedBox(height: 16),
              const Text(
                'QR Data Received:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _scannedQRData!.length > 100
                      ? '${_scannedQRData!.substring(0, 100)}...'
                      : _scannedQRData!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        _buildPaymentOption(
          icon: Icons.qr_code,
          title: 'Show QR Code',
          subtitle: 'Customer scans QR with their payment app',
          onTap: () => _selectPaymentMethod(PaymentStep.showQR),
          color: Colors.blue.shade100,
          iconColor: Colors.blue.shade800,
        ),

        const SizedBox(height: 16),

        _buildPaymentOption(
          icon: Icons.qr_code_scanner,
          title: 'Scan Customer QR',
          subtitle: 'Scan QR code from customer\'s phone',
          onTap: () => _selectPaymentMethod(PaymentStep.scanQR),
          color: Colors.green.shade100,
          iconColor: Colors.green.shade800,
        ),

        const SizedBox(height: 16),

        TextButton(
          onPressed: _skipPayment,
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
          ),
          child: const Text('Skip Payment (For Testing)'),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShowQRWidget() {
    return Column(
      children: [
        const Text(
          'Scan QR Code to Pay',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
            ),
            child: CustomPaint(
              painter: QRCodePainter(),
            ),
          ),
        ),
        const SizedBox(height: 24),

        if (_isProcessing) ...[
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing payment...'),
              ],
            ),
          ),
        ] else ...[
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: _simulateQRScan,
                icon: const Icon(Icons.check_circle),
                label: const Text('Payment Received'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Wait for customer to scan and complete payment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildScanQRWidget() {
    return Column(
      children: [
        const Text(
          'Scan Customer\'s QR Code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Colors.white.withAlpha(179),
                  ),
                  const SizedBox(height: 16),
                  if (widget.scanner != null) ...[
                    Text(
                      'Using ${widget.scanner!['manufacturer']} ${widget.scanner!['productName']}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Present QR code to the scanner',
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_isListeningForQR) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(51),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sensors,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Scanner ready',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    const Text(
                      'No QR scanner connected',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please connect a scanner in settings',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),

              if (_isListeningForQR) ...[
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withAlpha(128),
                          spreadRadius: 2,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (!_isListeningForQR && widget.scanner != null) ...[
          ElevatedButton.icon(
            onPressed: _startScannerListener,
            icon: const Icon(Icons.sensors),
            label: const Text('Start Scanner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ] else if (_isListeningForQR) ...[
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isListeningForQR = false;
              });
            },
            icon: const Icon(Icons.stop_circle),
            label: const Text('Stop Scanner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ] else if (widget.scanner == null) ...[
          ElevatedButton.icon(
            onPressed: _simulateUserQRScan,
            icon: const Icon(Icons.check_circle),
            label: const Text('Simulate Scan (Testing)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ],
    );
  }
}

class QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cellSize = size.width / 10;

    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        if ((i < 3 && j < 3) ||
            (i > 6 && j < 3) ||
            (i < 3 && j > 6) ||
            (i == 5 && j == 5)) {
          canvas.drawRect(
            Rect.fromLTWH(i * cellSize, j * cellSize, cellSize, cellSize),
            paint..style = PaintingStyle.fill,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

enum PaymentStep {
  selectMethod,
  showQR,
  scanQR,
}
