import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SarReportPage extends StatefulWidget {
  final String id;
  final String collection; // 'sos_sessions' or 'help_requests'

  const SarReportPage({super.key, required this.id, required this.collection});

  @override
  State<SarReportPage> createState() => _SarReportPageState();
}

class _SarReportPageState extends State<SarReportPage> {
  final _db = FirebaseFirestore.instance;
  bool _loading = true;
  Map<String, dynamic>? _data;

  // For editable SAR notes
  final TextEditingController _notesController = TextEditingController();
  bool _savingNotes = false;
  bool _notesEdited = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final snap = await _db.collection(widget.collection).doc(widget.id).get();
      if (snap.exists) {
        final data = snap.data();
        setState(() {
          _data = data;
          _loading = false;
          // Load existing SAR notes
          _notesController.text = (data?['sarNotes'] as String?) ?? '';
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSarNotes() async {
    if (_data == null) return;

    setState(() {
      _savingNotes = true;
    });

    try {
      await _db.collection(widget.collection).doc(widget.id).update({
        'sarNotes': _notesController.text,
        'notesUpdatedAt': FieldValue.serverTimestamp(),
        'notesUpdatedBy': 'SAR Team', // You can get current user info here
      });

      setState(() {
        _savingNotes = false;
        _notesEdited = false;
        if (_data != null) {
          _data!['sarNotes'] = _notesController.text;
          _data!['notesUpdatedAt'] = Timestamp.now();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SAR notes saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _savingNotes = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _fmtTs(dynamic v) {
    try {
      if (v is Timestamp) {
        return DateFormat.yMd().add_jm().format(v.toDate());
      }
      return v?.toString() ?? 'Unknown time';
    } catch (_) {
      return 'Unknown time';
    }
  }

  String _fmtCoords(Map<String, dynamic>? loc) {
    if (loc == null) return '';
    final lat = loc['latitude'];
    final lon = loc['longitude'];
    final a = (lat is num) ? lat.toStringAsFixed(5) : (lat?.toString() ?? '');
    final b = (lon is num) ? lon.toStringAsFixed(5) : (lon?.toString() ?? '');
    if (a.isEmpty || b.isEmpty) return '';
    return '$a, $b';
  }

  // PDF/Printing functionality removed to reduce app size.

  Future<void> _openInMaps() async {
    if (_data == null) return;
    final data = _data!;
    final loc = (data['location'] ?? {}) as Map<String, dynamic>;
    final lat = loc['latitude'];
    final lon = loc['longitude'];
    double? toD(v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final dlat = toD(lat);
    final dlon = toD(lon);
    if (dlat == null || dlon == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${dlat.toStringAsFixed(6)},${dlon.toStringAsFixed(6)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // Removed PDF helper widgets (_chip, _kv) as they depended on pdf package.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAR Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _openInMaps,
            tooltip: 'Open in Maps',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? const Center(child: Text('No data found'))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final data = _data!;
    final loc = (data['location'] ?? {}) as Map<String, dynamic>;
    final type = (data['type'] ?? data['category'] ?? 'sos').toString();
    final status = (data['status'] ?? 'active').toString();
    final priority = (data['priority'] ?? 'high').toString();
    final createdAt = _fmtTs(data['createdAt']);
    final updatedAt = _fmtTs(data['updatedAt'] ?? data['timestamp']);
    final coords = _fmtCoords(loc);
    final address = (loc['address'] ?? '').toString();
    final message =
        (data['userMessage'] ?? data['details'] ?? data['description'] ?? '')
            .toString();
    final notesUpdatedBy = data['notesUpdatedBy'] as String?;
    final notesUpdatedAt = data['notesUpdatedAt'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(label: Text(type.toUpperCase())),
              const SizedBox(width: 8),
              Chip(label: Text(status.toUpperCase())),
              const SizedBox(width: 8),
              Chip(label: Text(priority.toUpperCase())),
            ],
          ),
          const SizedBox(height: 12),
          _kvRow('ID', widget.id),
          _kvRow('Created', createdAt),
          _kvRow('Last Update', updatedAt),
          if (address.isNotEmpty) _kvRow('Address', address),
          if (coords.isNotEmpty) _kvRow('Coords', coords),
          const SizedBox(height: 12),
          if (message.isNotEmpty)
            const Text(
              'Message',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          if (message.isNotEmpty) const SizedBox(height: 4),
          if (message.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade700),
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message),
            ),
          const SizedBox(height: 24),

          // SAR Notes Section (Editable)
          Row(
            children: [
              const Icon(Icons.edit_note, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'SAR INCIDENT NOTES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
              const Spacer(),
              if (_savingNotes)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                ElevatedButton.icon(
                  onPressed: _notesEdited ? _saveSarNotes : null,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 8,
            onChanged: (_) {
              if (!_notesEdited) {
                setState(() {
                  _notesEdited = true;
                });
              }
            },
            decoration: InputDecoration(
              hintText:
                  'Enter detailed incident notes, observations, actions taken, patient condition, resources deployed, etc...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black,
            ),
          ),
          if (notesUpdatedBy != null && notesUpdatedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Last updated by $notesUpdatedBy at ${_fmtTs(notesUpdatedAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$k: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
