import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditPropertyPage extends StatefulWidget {
  final Map<String, dynamic> propertyData;
  const EditPropertyPage({Key? key, required this.propertyData})
    : super(key: key);

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _rentController;
  late TextEditingController _securityDepositController;
  late TextEditingController _brokerageController;
  late TextEditingController _currentFlatmatesController;
  late TextEditingController _maxFlatmatesController;
  late TextEditingController _descriptionController;
  DateTime? _availableFrom;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.propertyData['title'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.propertyData['location'] ?? '',
    );
    _rentController = TextEditingController(
      text: widget.propertyData['monthlyRent']?.toString() ?? '',
    );
    _securityDepositController = TextEditingController(
      text: widget.propertyData['securityDeposit']?.toString() ?? '',
    );
    _brokerageController = TextEditingController(
      text: widget.propertyData['brokerage']?.toString() ?? '',
    );
    _currentFlatmatesController = TextEditingController(
      text: widget.propertyData['currentFlatmates']?.toString() ?? '',
    );
    _maxFlatmatesController = TextEditingController(
      text: widget.propertyData['maxFlatmates']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.propertyData['description'] ?? '',
    );
    _availableFrom =
        widget.propertyData['availableFrom'] != null &&
                widget.propertyData['availableFrom'].toString().isNotEmpty
            ? DateTime.tryParse(widget.propertyData['availableFrom'])
            : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _rentController.dispose();
    _securityDepositController.dispose();
    _brokerageController.dispose();
    _currentFlatmatesController.dispose();
    _maxFlatmatesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _pickAvailableFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _availableFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _availableFrom = picked;
      });
    }
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // TODO: Update property in database
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Property updated!')));
      Navigator.pop(context, {
        'title': _titleController.text,
        'location': _locationController.text,
        'monthlyRent': double.tryParse(_rentController.text) ?? 0,
        'securityDeposit':
            double.tryParse(_securityDepositController.text) ?? 0,
        'brokerage': double.tryParse(_brokerageController.text) ?? 0,
        'currentFlatmates': int.tryParse(_currentFlatmatesController.text) ?? 0,
        'maxFlatmates': int.tryParse(_maxFlatmatesController.text) ?? 0,
        'description': _descriptionController.text,
        'availableFrom':
            _availableFrom != null
                ? DateFormat('yyyy-MM-dd').format(_availableFrom!)
                : '',
        // Add other fields as needed
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textPrimary =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Property'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.home_rounded),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter property title'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_rounded),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter location'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickAvailableFrom,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Available From',
                          prefixIcon: Icon(Icons.date_range_rounded),
                        ),
                        controller: TextEditingController(
                          text:
                              _availableFrom != null
                                  ? DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_availableFrom!)
                                  : '',
                        ),
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Select available from date'
                                    : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Rent',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter monthly rent'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _securityDepositController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Security Deposit',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter security deposit'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _brokerageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Brokerage',
                      prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentFlatmatesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Flatmates',
                      prefixIcon: Icon(Icons.people_alt_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _maxFlatmatesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Flatmates',
                      prefixIcon: Icon(Icons.group_add_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_rounded),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}