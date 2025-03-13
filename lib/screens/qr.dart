import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final timeStr = '${now.hour}:${now.minute}:${now.second}';
    final transactionId = 'TRX${now.millisecondsSinceEpoch.toString().substring(5)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Payment'),
      ),
      body: SingleChildScrollView(
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

              if (!_isPaymentCompleted) ...[
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
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _skipPayment,
                        child: const Text('Skip (For Testing)'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Payment Completed Successfully',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Amount: \$${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Transaction ID: $transactionId',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    final cellSize = size.width / 25;

    _drawPositioningSquare(canvas, 0, 0, cellSize * 7, paint);
    _drawPositioningSquare(canvas, size.width - cellSize * 7, 0, cellSize * 7, paint);
    _drawPositioningSquare(canvas, 0, size.height - cellSize * 7, cellSize * 7, paint);

    final random = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 25; i++) {
      for (int j = 0; j < 25; j++) {
        if ((i < 7 && j < 7) ||
            (i < 7 && j > 17) ||
            (i > 17 && j < 7)) {
          continue;
        }

        if (((i * j + random) % 3) == 0) {
          canvas.drawRect(
            Rect.fromLTWH(i * cellSize, j * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  void _drawPositioningSquare(Canvas canvas, double x, double y, double size, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x, y, size, size), paint);

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(x + size/7, y + size/7, size*5/7, size*5/7), whitePaint);

    canvas.drawRect(Rect.fromLTWH(x + size*2/7, y + size*2/7, size*3/7, size*3/7), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
