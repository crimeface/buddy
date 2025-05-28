import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class PropertyListingFormPage extends StatefulWidget {
  const PropertyListingFormPage({Key? key}) : super(key: key);

  @override
  State<PropertyListingFormPage> createState() => _PropertyListingFormPageState();
}

class _PropertyListingFormPageState extends State<PropertyListingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _propertyTitleController = TextEditingController();
  final _addressController = TextEditingController();
  final _totalRentController = TextEditingController();
  final _brokerageController = TextEditingController();
  final _depositController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form state variables
  String _propertyType = 'Apartment';
  String _bhkType = '1 BHK';
  int _totalOccupancy = 1;
  int _currentOccupancy = 0;
  String _furnishingType = 'Furnished';
  String _genderPreference = 'Any';
  String _tenantType = 'Any';
  bool _parkingAvailable = false;
  bool _wifiIncluded = false;
  bool _electricityIncluded = false;
  bool _waterIncluded = false;
  bool _cleaningIncluded = false;
  List<String> _selectedAmenities = [];

  final List<String> _propertyTypes = ['Apartment', 'Villa', 'PG', 'Hostel', 'Studio'];
  final List<String> _bhkTypes = ['1 Room','1 RK', '1 BHK', '2 BHK', '3 BHK'];
  final List<String> _furnishingTypes = ['Furnished', 'Semi-Furnished', 'Unfurnished'];
  final List<String> _genderPreferences = ['Any', 'Male Only', 'Female Only'];
  final List<String> _tenantTypes = ['Any', 'Student', 'Professional', 'Family'];
  final List<String> _amenities = [
    'Gym', 'Swimming Pool', 'Security', 'Elevator', 'Power Backup',
    'Garden', 'Balcony', 'Air Conditioning', 'Washing Machine', 'Refrigerator'
  ];

  @override
  void dispose() {
    _propertyTitleController.dispose();
    _addressController.dispose();
    _totalRentController.dispose();
    _brokerageController.dispose();
    _depositController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final inputFillColor = isDark ? Colors.grey[850] : Colors.grey[100];
    final labelColor = isDark ? Colors.white70 : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('List Your Property'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onBackground,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(BuddyTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildPropertyTitleField(inputFillColor!, labelColor, hintColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildAddressField(inputFillColor, labelColor, hintColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildPropertyTypeDropdown(cardColor!, labelColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildBHKTypeDropdown(cardColor, labelColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('Occupancy Details', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildOccupancySection(cardColor, labelColor, dividerColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('Rental Information', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildRentField(inputFillColor, labelColor, hintColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildBrokerageField(inputFillColor, labelColor, hintColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildDepositField(inputFillColor, labelColor, hintColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('Property Features', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildFurnishingDropdown(cardColor, labelColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildInclusionsSection(cardColor, labelColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('Tenant Preferences', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildGenderPreferenceDropdown(cardColor, labelColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildTenantTypeDropdown(cardColor, labelColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('Amenities', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildAmenitiesSection(cardColor, labelColor),

              const SizedBox(height: BuddyTheme.spacingLg),
              _buildSectionTitle('Additional Information', labelColor),
              const SizedBox(height: BuddyTheme.spacingSm),
              _buildDescriptionField(inputFillColor, labelColor, hintColor),
              const SizedBox(height: BuddyTheme.spacingMd),
              _buildParkingCheckbox(cardColor, labelColor),

              const SizedBox(height: BuddyTheme.spacingXl),
              _buildSubmitButton(),
              const SizedBox(height: BuddyTheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color labelColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: BuddyTheme.fontSizeLg,
        fontWeight: FontWeight.w600,
        color: labelColor,
      ),
    );
  }

  Widget _buildPropertyTitleField(Color fillColor, Color labelColor, Color hintColor) {
    return TextFormField(
      controller: _propertyTitleController,
      decoration: InputDecoration(
        labelText: 'Property Title',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'e.g., Spacious 2BHK near Metro Station',
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter property title';
        }
        return null;
      },
    );
  }

  Widget _buildAddressField(Color fillColor, Color labelColor, Color hintColor) {
    return TextFormField(
      controller: _addressController,
      decoration: InputDecoration(
        labelText: 'Complete Address',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'Enter full address with landmark',
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter complete address';
        }
        return null;
      },
    );
  }

  Widget _buildPropertyTypeDropdown(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Type',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          DropdownButton<String>(
            value: _propertyType,
            isExpanded: true,
            underline: Container(),
            items: _propertyTypes.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(color: labelColor)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _propertyType = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBHKTypeDropdown(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BHK Type',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          DropdownButton<String>(
            value: _bhkType,
            isExpanded: true,
            underline: Container(),
            items: _bhkTypes.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(color: labelColor)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _bhkType = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancySection(Color cardColor, Color labelColor, Color dividerColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Occupancy Details',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Occupancy', style: TextStyle(fontSize: BuddyTheme.fontSizeXs, color: labelColor)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_totalOccupancy > 1) {
                              setState(() {
                                _totalOccupancy--;
                                if (_currentOccupancy >= _totalOccupancy) {
                                  _currentOccupancy = _totalOccupancy - 1;
                                }
                              });
                            }
                          },
                          icon: Icon(Icons.remove_circle_outline, color: labelColor),
                        ),
                        Text('$_totalOccupancy', style: TextStyle(fontSize: BuddyTheme.fontSizeMd, color: labelColor)),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _totalOccupancy++;
                            });
                          },
                          icon: Icon(Icons.add_circle_outline, color: labelColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: dividerColor,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Occupancy', style: TextStyle(fontSize: BuddyTheme.fontSizeXs, color: labelColor)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_currentOccupancy > 0) {
                              setState(() {
                                _currentOccupancy--;
                              });
                            }
                          },
                          icon: Icon(Icons.remove_circle_outline, color: labelColor),
                        ),
                        Text('$_currentOccupancy', style: TextStyle(fontSize: BuddyTheme.fontSizeMd, color: labelColor)),
                        IconButton(
                          onPressed: () {
                            if (_currentOccupancy < _totalOccupancy) {
                              setState(() {
                                _currentOccupancy++;
                              });
                            }
                          },
                          icon: Icon(Icons.add_circle_outline, color: labelColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentField(Color fillColor, Color labelColor, Color hintColor) {
    return TextFormField(
      controller: _totalRentController,
      decoration: InputDecoration(
        labelText: 'Total Monthly Rent (₹)',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'Enter total rent amount',
        hintStyle: TextStyle(color: hintColor),
        prefixText: '₹ ',
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter rent amount';
        }
        return null;
      },
    );
  }

  Widget _buildBrokerageField(Color fillColor, Color labelColor, Color hintColor) {
    return TextFormField(
      controller: _brokerageController,
      decoration: InputDecoration(
        labelText: 'Brokerage per Person (₹)',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'Enter brokerage amount',
        hintStyle: TextStyle(color: hintColor),
        prefixText: '₹ ',
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildDepositField(Color fillColor, Color labelColor, Color hintColor) {
    return TextFormField(
      controller: _depositController,
      decoration: InputDecoration(
        labelText: 'Security Deposit (₹)',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'Enter deposit amount',
        hintStyle: TextStyle(color: hintColor),
        prefixText: '₹ ',
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter deposit amount';
        }
        return null;
      },
    );
  }

  Widget _buildFurnishingDropdown(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Furnishing Type',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          DropdownButton<String>(
            value: _furnishingType,
            isExpanded: true,
            underline: Container(),
            items: _furnishingTypes.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(color: labelColor)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _furnishingType = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionsSection(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inclusions',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          CheckboxListTile(
            title: Text('WiFi', style: TextStyle(color: labelColor)),
            value: _wifiIncluded,
            onChanged: (bool? value) {
              setState(() {
                _wifiIncluded = value!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          CheckboxListTile(
            title: Text('Electricity', style: TextStyle(color: labelColor)),
            value: _electricityIncluded,
            onChanged: (bool? value) {
              setState(() {
                _electricityIncluded = value!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          CheckboxListTile(
            title: Text('Water', style: TextStyle(color: labelColor)),
            value: _waterIncluded,
            onChanged: (bool? value) {
              setState(() {
                _waterIncluded = value!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          CheckboxListTile(
            title: Text('Cleaning Service', style: TextStyle(color: labelColor)),
            value: _cleaningIncluded,
            onChanged: (bool? value) {
              setState(() {
                _cleaningIncluded = value!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPreferenceDropdown(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender Preference',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          DropdownButton<String>(
            value: _genderPreference,
            isExpanded: true,
            underline: Container(),
            items: _genderPreferences.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(color: labelColor)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _genderPreference = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTenantTypeDropdown(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tenant Type Preference',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingXs),
          DropdownButton<String>(
            value: _tenantType,
            isExpanded: true,
            underline: Container(),
            items: _tenantTypes.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(color: labelColor)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _tenantType = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      padding: const EdgeInsets.all(BuddyTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Amenities',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: BuddyTheme.spacingMd),
          Wrap(
            spacing: BuddyTheme.spacingXs,
            runSpacing: BuddyTheme.spacingXs,
            children: _amenities.map((amenity) {
              final isSelected = _selectedAmenities.contains(amenity);
              return FilterChip(
                label: Text(amenity, style: TextStyle(color: labelColor)),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenities.add(amenity);
                    } else {
                      _selectedAmenities.remove(amenity);
                    }
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                backgroundColor: cardColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(Color fillColor, Color labelColor, Color hintColor) {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Property Description',
        labelStyle: TextStyle(color: labelColor),
        hintText: 'Describe your property, nearby facilities, rules, etc.',
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      maxLines: 4,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter property description';
        }
        return null;
      },
    );
  }

  Widget _buildParkingCheckbox(Color cardColor, Color labelColor) {
    return Container(
      decoration: BuddyTheme.cardDecoration.copyWith(color: cardColor),
      child: CheckboxListTile(
        title: Text('Parking Available', style: TextStyle(color: labelColor)),
        subtitle: Text('Check if parking space is available', style: TextStyle(color: labelColor.withOpacity(0.7))),
        value: _parkingAvailable,
        onChanged: (bool? value) {
          setState(() {
            _parkingAvailable = value!;
          });
        },
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: BuddyTheme.postAdButtonStyle,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: BuddyTheme.spacingMd),
          child: Text(
            'List Property',
            style: TextStyle(
              fontSize: BuddyTheme.fontSizeMd,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Handle form submission
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success!'),
          content: const Text('Your property has been listed successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}