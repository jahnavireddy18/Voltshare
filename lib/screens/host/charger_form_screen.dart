import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/models/charger_model.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/charger_service.dart';
import 'package:vnest_app/widgets/common/vs_components.dart';

class ChargerFormScreen extends StatefulWidget {
  final String? chargerId;
  const ChargerFormScreen({super.key, this.chargerId});

  @override
  State<ChargerFormScreen> createState() => _ChargerFormScreenState();
}

class _ChargerFormScreenState extends State<ChargerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _powerController = TextEditingController();
  final _priceController = TextEditingController();

  ConnectorType _connectorType = ConnectorType.type2;
  bool _isLoading = false;
  ChargerModel? _existingCharger;

  @override
  void initState() {
    super.initState();
    if (widget.chargerId != null) {
      _loadCharger();
    }
  }

  Future<void> _loadCharger() async {
    setState(() => _isLoading = true);
    final charger = await ChargerService().getCharger(widget.chargerId!);
    if (charger != null) {
      _existingCharger = charger;
      _nameController.text = charger.name;
      _addressController.text = charger.address;
      _latController.text = charger.latitude.toString();
      _lngController.text = charger.longitude.toString();
      _powerController.text = charger.powerOutput.toString();
      _priceController.text = charger.pricePerKwh.toString();
      _connectorType = charger.connectorType;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveCharger() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final hostId = AuthProvider().currentUser!.id;
      final lat = double.parse(_latController.text);
      final lng = double.parse(_lngController.text);
      final power = double.parse(_powerController.text);
      final price = double.parse(_priceController.text);

      if (_existingCharger == null) {
        // Create new
        await ChargerService().createCharger(
          ChargerModel(
            id: '',
            hostId: hostId,
            name: _nameController.text,
            address: _addressController.text,
            latitude: lat,
            longitude: lng,
            connectorType: _connectorType,
            powerOutput: power,
            pricePerKwh: price,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        // Update existing
        await ChargerService().updateCharger(
          _existingCharger!.id,
          {
            'name': _nameController.text,
            'address': _addressController.text,
            'latitude': lat,
            'longitude': lng,
            'connectorType': _connectorType.name,
            'powerOutput': power,
            'pricePerKwh': price,
          }
        );
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Charger saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _powerController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chargerId == null ? 'Add Charger' : 'Edit Charger',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Charger Details', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    VsTextField(
                      controller: _nameController,
                      label: 'Charger Name (e.g. Home Tesla Charger)',
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    VsTextField(
                      controller: _addressController,
                      label: 'Full Address',
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: VsTextField(
                            controller: _latController,
                            label: 'Latitude',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: VsTextField(
                            controller: _lngController,
                            label: 'Longitude',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('Specifications', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ConnectorType>(
                      value: _connectorType,
                      decoration: const InputDecoration(
                        labelText: 'Connector Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ConnectorType.values.map((e) {
                        return DropdownMenuItem(value: e, child: Text(e.label));
                      }).toList(),
                      onChanged: (val) => setState(() => _connectorType = val!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: VsTextField(
                            controller: _powerController,
                            label: 'Power (kW)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: VsTextField(
                            controller: _priceController,
                            label: 'Price per kWh (₹)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    VsButton.fullWidth(
                      label: 'Save Charger',
                      onPressed: _saveCharger,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
