import 'package:flutter/material.dart';

class DebugScreen extends StatelessWidget {
  final List<Map<String, dynamic>> devices;
  final Map<String, dynamic>? connectedDevice;

  const DebugScreen({
    Key? key,
    required this.devices,
    this.connectedDevice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USB Device Debug'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Refresh Device List',
          ),
        ],
      ),
      backgroundColor: Colors.grey[850],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: devices.isEmpty
                    ? _buildEmptyState()
                    : _buildDeviceList(),
              ),
              const SizedBox(height: 16),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.usb,
              color: Colors.blue,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'USB Device Inspector',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withAlpha(128)),
              ),
              child: Text(
                '${devices.length} device${devices.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(color: Colors.white24),
        if (connectedDevice != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connected to: ${connectedDevice!['manufacturer'] ?? 'Unknown'} ${connectedDevice!['productName'] ?? 'Printer'}',
                  style: const TextStyle(color: Colors.green, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.usb_off,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          const Text(
            'No USB devices detected',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect a USB device or printer to see it here',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final isConnected = connectedDevice != null &&
            device['deviceId'] == connectedDevice!['deviceId'] &&
            device['vendorId'] == connectedDevice!['vendorId'] &&
            device['productId'] == connectedDevice!['productId'];

        return DeviceCard(
          device: device,
          isConnected: isConnected,
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white24),
        const SizedBox(height: 8),
        const Text(
          'Debug Information',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Access this screen from the Printer Settings page',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Return to Previous Screen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }
}

class DeviceCard extends StatefulWidget {
  final Map<String, dynamic> device;
  final bool isConnected;

  const DeviceCard({
    Key? key,
    required this.device,
    required this.isConnected,
  }) : super(key: key);

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: widget.isConnected ? Colors.green[800] : Colors.grey[800],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.isConnected ? Colors.green[600]! : Colors.transparent,
          width: widget.isConnected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isConnected ? Icons.print : Icons.usb,
                    color: widget.isConnected ? Colors.green[300] : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.device['manufacturer'] ?? 'Unknown Manufacturer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.device['productName'] ?? 'Unknown Product',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isConnected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'CONNECTED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white70,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const Divider(color: Colors.white24, height: 24),
                _buildDetailSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Device ID', '${widget.device['deviceId'] ?? 'N/A'}'),
        _buildDetailRow('Vendor ID', _formatId(widget.device['vendorId'])),
        _buildDetailRow('Product ID', _formatId(widget.device['productId'])),
        _buildDetailRow('Device Name', widget.device['deviceName'] ?? 'N/A'),
        if (widget.device.containsKey('interface'))
          _buildDetailRow('Interface', '${widget.device['interface']}'),
        if (widget.device.containsKey('endpoint'))
          _buildDetailRow('Endpoint', '${widget.device['endpoint']}'),

        const SizedBox(height: 12),
        const Text(
          'Technical Details',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(77),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.device.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatId(dynamic id) {
    if (id == null) return 'N/A';

    try {
      if (id is String) {
        final parsedId = int.tryParse(id);
        if (parsedId != null) {
          return '0x${parsedId.toRadixString(16).padLeft(4, '0').toUpperCase()}';
        }
        return id;
      }

      if (id is int) {
        return '0x${id.toRadixString(16).padLeft(4, '0').toUpperCase()}';
      }

      return '$id';
    } catch (e) {
      return '$id';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
