import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class EVVehicle {
  final String id;
  final String model;
  final String regNumber;
  final String connectorType;
  final String batteryCapacity;
  final bool isDefault;

  const EVVehicle({
    required this.id,
    required this.model,
    required this.regNumber,
    required this.connectorType,
    required this.batteryCapacity,
    this.isDefault = false,
  });

  EVVehicle copyWith({
    String? id,
    String? model,
    String? regNumber,
    String? connectorType,
    String? batteryCapacity,
    bool? isDefault,
  }) {
    return EVVehicle(
      id: id ?? this.id,
      model: model ?? this.model,
      regNumber: regNumber ?? this.regNumber,
      connectorType: connectorType ?? this.connectorType,
      batteryCapacity: batteryCapacity ?? this.batteryCapacity,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'model': model,
        'regNumber': regNumber,
        'connectorType': connectorType,
        'batteryCapacity': batteryCapacity,
        'isDefault': isDefault,
      };

  factory EVVehicle.fromJson(Map<String, dynamic> json) => EVVehicle(
        id: json['id'] as String? ?? '',
        model: json['model'] as String? ?? 'EV Vehicle',
        regNumber: json['regNumber'] as String? ?? '',
        connectorType: json['connectorType'] as String? ?? 'CCS2',
        batteryCapacity: json['batteryCapacity'] as String? ?? '30 kWh',
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  static const String _prefsKey = 'voltshare_user_vehicles';

  List<EVVehicle> _vehicles = [
    const EVVehicle(
      id: 'v_default_1',
      model: 'Tata Nexon EV',
      regNumber: 'KA 01 AB 1234',
      connectorType: 'CCS2',
      batteryCapacity: '30 kWh',
      isDefault: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedVehicles();
  }

  Future<void> _loadSavedVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_prefsKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(data) as List<dynamic>;
        final loaded = decoded
            .map((item) => EVVehicle.fromJson(item as Map<String, dynamic>))
            .toList();
        if (loaded.isNotEmpty && mounted) {
          setState(() {
            _vehicles = loaded;
          });
        }
      }
    } catch (_) {
      // Fallback to default in-memory list
    }
  }

  Future<void> _persistVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_vehicles.map((v) => v.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (_) {}
  }

  void _setDefaultVehicle(String id) {
    setState(() {
      _vehicles = _vehicles.map((v) {
        return v.copyWith(isDefault: v.id == id);
      }).toList();
    });
    _persistVehicles();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Primary vehicle updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeVehicle(String id) {
    if (_vehicles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one vehicle must remain registered'),
        ),
      );
      return;
    }

    final removed = _vehicles.firstWhere((v) => v.id == id);
    setState(() {
      _vehicles.removeWhere((v) => v.id == id);
      if (removed.isDefault && _vehicles.isNotEmpty) {
        _vehicles[0] = _vehicles[0].copyWith(isDefault: true);
      }
    });
    _persistVehicles();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.model} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _vehicles.add(removed);
            });
            _persistVehicles();
          },
        ),
      ),
    );
  }

  void _showAddVehicleSheet() {
    final modelController = TextEditingController();
    final regController = TextEditingController();
    final batteryController = TextEditingController(text: '40.5 kWh');
    String selectedConnector = 'CCS2';

    final presetEVs = [
      {'model': 'MG ZS EV', 'battery': '50.3 kWh', 'connector': 'CCS2'},
      {'model': 'Tata Punch EV', 'battery': '35 kWh', 'connector': 'CCS2'},
      {'model': 'Mahindra XUV400', 'battery': '39.4 kWh', 'connector': 'CCS2'},
      {'model': 'Hyundai Ioniq 5', 'battery': '72.6 kWh', 'connector': 'CCS2'},
      {'model': 'Tata Tiago EV', 'battery': '24 kWh', 'connector': 'CCS2'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderDark,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.electric_car, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Add New Electric Vehicle',
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quick Presets',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: presetEVs.map((preset) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(
                                preset['model']!,
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
                              onPressed: () {
                                setSheetState(() {
                                  modelController.text = preset['model']!;
                                  batteryController.text = preset['battery']!;
                                  selectedConnector = preset['connector']!;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vehicle Make & Model',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: modelController,
                      style: GoogleFonts.manrope(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. Tata Punch EV, MG ZS EV',
                        hintStyle: GoogleFonts.manrope(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceVariantDark,
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Registration Number',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: regController,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.manrope(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g. KA 05 MN 5678',
                        hintStyle: GoogleFonts.manrope(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceVariantDark,
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connector Type',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariantDark,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderDark),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedConnector,
                                    dropdownColor: AppColors.surfaceVariantDark,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                    style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
                                    items: ['CCS2', 'Type 2', 'GB/T', 'CHAdeMO'].map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setSheetState(() {
                                          selectedConnector = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Battery Capacity',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: batteryController,
                                style: GoogleFonts.manrope(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'e.g. 40.5 kWh',
                                  hintStyle: GoogleFonts.manrope(color: AppColors.textMuted),
                                  filled: true,
                                  fillColor: AppColors.surfaceVariantDark,
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
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final model = modelController.text.trim();
                          final reg = regController.text.trim().toUpperCase();
                          final battery = batteryController.text.trim();

                          if (model.isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(content: Text('Please enter the vehicle model')),
                            );
                            return;
                          }

                          if (reg.isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(content: Text('Please enter the registration number')),
                            );
                            return;
                          }

                          final newVehicle = EVVehicle(
                            id: 'v_${DateTime.now().millisecondsSinceEpoch}',
                            model: model,
                            regNumber: reg,
                            connectorType: selectedConnector,
                            batteryCapacity: battery.isEmpty ? '30 kWh' : battery,
                            isDefault: _vehicles.isEmpty,
                          );

                          setState(() {
                            _vehicles.add(newVehicle);
                          });
                          _persistVehicles();

                          Navigator.pop(sheetContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$model registered successfully!'),
                              backgroundColor: AppColors.surfaceVariantDark,
                            ),
                          );
                        },
                        child: Text(
                          'Add Vehicle',
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          'My Vehicles',
          style: GoogleFonts.sora(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._vehicles.map((vehicle) => _buildVehicleCard(vehicle, cs)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showAddVehicleSheet,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add a Vehicle',
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.surfaceDark,
              side: const BorderSide(color: AppColors.borderDark),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(EVVehicle vehicle, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vehicle.isDefault ? AppColors.primary : AppColors.borderDark,
          width: vehicle.isDefault ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vehicle.model,
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vehicle.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary, width: 0.8),
                        ),
                        child: Text(
                          'Primary',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle.regNumber,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${vehicle.connectorType} • ${vehicle.batteryCapacity}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
            color: AppColors.surfaceVariantDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (action) {
              if (action == 'default') {
                _setDefaultVehicle(vehicle.id);
              } else if (action == 'delete') {
                _removeVehicle(vehicle.id);
              }
            },
            itemBuilder: (context) => [
              if (!vehicle.isDefault)
                PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      const Icon(Icons.star_outline, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Set as Primary', style: GoogleFonts.manrope(color: Colors.white)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('Remove Vehicle', style: GoogleFonts.manrope(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
