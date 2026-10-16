import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/models/charger_model.dart';
import 'package:vnest_app/core/enums/app_enums.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/charger_service.dart';
import 'package:vnest_app/core/theme/app_theme.dart';
import 'package:vnest_app/widgets/common/vs_components.dart';

class ChargerFormScreen extends StatefulWidget {
  final String? chargerId;
  const ChargerFormScreen({super.key, this.chargerId});

  @override
  State<ChargerFormScreen> createState() => _ChargerFormScreenState();
}

class _ChargerFormScreenState extends State<ChargerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Home Wallbox 7.4 kW');
  final _addressController =
      TextEditingController(text: 'Prestige Tech Park, Outer Ring Road, Bangalore');
  final _latController = TextEditingController(text: '12.9352');
  final _lngController = TextEditingController(text: '77.6946');
  final _powerController = TextEditingController(text: '7.4');
  final _priceController = TextEditingController(text: '16.0');

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

  void _applyPreset(
    String name,
    String address,
    double power,
    double price,
    ConnectorType type,
  ) {
    setState(() {
      _nameController.text = name;
      _addressController.text = address;
      _powerController.text = power.toString();
      _priceController.text = price.toString();
      _connectorType = type;
    });
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
      final hostId = AuthProvider().currentUser?.id ?? 'demo_host_1';
      final lat = double.tryParse(_latController.text.trim()) ?? 12.9352;
      final lng = double.tryParse(_lngController.text.trim()) ?? 77.6946;
      final power = double.tryParse(_powerController.text.trim()) ?? 7.4;
      final price = double.tryParse(_priceController.text.trim()) ?? 16.0;

      if (_existingCharger == null) {
        // Create new
        await ChargerService().createCharger(
          ChargerModel(
            id: '',
            hostId: hostId,
            hostName: AuthProvider().currentUser?.name ?? 'Priya Sharma',
            name: _nameController.text.trim().isEmpty
                ? 'My EV Charger'
                : _nameController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? 'Bangalore, Karnataka'
                : _addressController.text.trim(),
            latitude: lat,
            longitude: lng,
            connectorType: _connectorType,
            powerOutput: power,
            pricePerKwh: price,
            status: ChargerListingStatus.active,
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
          },
        );
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Charger saved successfully!'),
            backgroundColor: AppColors.surfaceVariantDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving charger: $e')),
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
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          widget.chargerId == null ? 'Add Charger' : 'Edit Charger',
          style: GoogleFonts.sora(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Presets (1-Tap Fill)',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            label: Text(
                              '🏠 Home Wallbox (7.4 kW)',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.surfaceVariantDark,
                            side: const BorderSide(color: AppColors.borderDark),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () => _applyPreset(
                              'Home Wallbox 7.4 kW',
                              'Tower B, Parking Slot 4, Prestige Tech Park',
                              7.4,
                              16.0,
                              ConnectorType.type2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            label: Text(
                              '🏢 Society AC (11 kW)',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.surfaceVariantDark,
                            side: const BorderSide(color: AppColors.borderDark),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () => _applyPreset(
                              'Society Hub - Tower A',
                              'Visitor Parking, Tower A Basement, Bangalore',
                              11.0,
                              18.0,
                              ConnectorType.type2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            label: Text(
                              '⚡ DC Fast (25 kW CCS2)',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.surfaceVariantDark,
                            side: const BorderSide(color: AppColors.borderDark),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () => _applyPreset(
                              'Commercial Fast Hub',
                              'Ground Floor EV Bay, Gate 2, Bangalore',
                              25.0,
                              22.0,
                              ConnectorType.ccs2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Charger Details',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    VsTextField(
                      controller: _nameController,
                      label: 'Charger Name',
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    VsTextField(
                      controller: _addressController,
                      label: 'Full Address',
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: VsTextField(
                            controller: _latController,
                            label: 'Latitude',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: VsTextField(
                            controller: _lngController,
                            label: 'Longitude',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Power & Pricing Specifications',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ConnectorType>(
                      value: _connectorType,
                      dropdownColor: AppColors.surfaceVariantDark,
                      style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Connector Type',
                        labelStyle: GoogleFonts.manrope(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderDark),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderDark),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      items: ConnectorType.values.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text(e.label, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _connectorType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: VsTextField(
                            controller: _powerController,
                            label: 'Power (kW)',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: VsTextField(
                            controller: _priceController,
                            label: 'Tariff (₹/kWh)',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    VsButton.fullWidth(
                      label: widget.chargerId == null ? 'Save Charger' : 'Update Charger',
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
