import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/model.dart';
import 'package:frontend/service.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MediCareApp());
}

Uint8List? globalFileBytes;
String? globalFileName;

class MediCareApp extends StatelessWidget {
  const MediCareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediCare AI',
      theme: _buildTheme(),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: Container(
            constraints: const BoxConstraints(minWidth: 800, minHeight: 600),
            child: child!,
          ),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF1A73E8),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A73E8),
        primary: const Color(0xFF1A73E8),
        secondary: const Color(0xFF66BB6A),
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? gender;
  bool isChild = false;
  bool isPregnant = false;
  bool _isSending = false; // Add loading state for send operation
  bool _isConfirmationSending = false; // Add loading state for confirmation
  final TextEditingController _commentController = TextEditingController();
  final Map<String, bool> serviceStatus = {
    'Server': true,
    'AI': false,
    'Google Calendar': true,
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkAllServices() async {
    try {
      Map<String, bool> answer = await ServiceFunctions.checkAllServiceStatus();

      setState(() {
        serviceStatus['Server'] = answer['server']!;
        serviceStatus['AI'] = answer['ai']!;
        serviceStatus['Google Calendar'] = answer['calendar']!;
      });
    } catch (e) {
    }
  }

  Future<void> _selectFile() async {
    try {
      final result = await ServiceFunctions.pickImageLocally();
      if (result != null) {
        setState(() {
          globalFileName = result.name; // Update global file name
          globalFileBytes = result.bytes; // Update global file bytes
        });
        _showSnackBar(
          'File "${result.name}" selected successfully!',
          Colors.green,
        );
      }
    } catch (e) {
      _showSnackBar('Error selecting file: $e', Colors.red);
    }
  }

  void _handleSend() async {
  final comment = _commentController.text;

  if (globalFileName == null || globalFileBytes == null) {
    _showSnackBar('Please select a file before sending.', Colors.red);
    return;
  }

  // Set loading state
  setState(() {
    _isSending = true;
  });

  // Prepare the payload
  final payload = {
    'comment': comment,
    'gender': gender,
    'isChild': isChild,
    'isPregnant': isPregnant,
  };

  try {
    // Send the payload with file bytes
    final success = await ServiceFunctions.sendPayload(
      payload: payload,
      fileBytes: globalFileBytes,
      filePath: globalFileName,
    );

    setState(() {
      _isSending = false; // Reset loading state
    });

    if (success.isNotEmpty) {
      setState(() {
        _commentController.clear();
        globalFileName = null;
        globalFileBytes = null;
      });
      _showConfirmationDialog(context, success);
    } else {
      _showSnackBar('Failed to send payload.', Colors.red);
    }
  } catch (e) {
    setState(() {
      _isSending = false; // Reset loading state on error
    });
    _showSnackBar('Error: $e', Colors.red);
  }
}

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientInfoCard(),
                  const SizedBox(height: 24),
                  _buildFileUploadCard(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'MediCare AI',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your personal reminder assistant',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          _buildServiceStatus(),
          const SizedBox(height: 16), // Add spacing before the button
          ElevatedButton.icon(
            onPressed: _checkAllServices, // Call the method when pressed
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Check Services'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A73E8),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            serviceStatus.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entry.value ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              icon: Icons.person_outline,
              title: 'Patient Information',
              color: const Color(0xFF1A73E8),
            ),
            const SizedBox(height: 24),
            _buildGenderSelection(),
            const SizedBox(height: 24),
            _buildAgeAndPregnancySelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              icon: Icons.upload_file,
              title: 'Upload Medical Documents',
              color: const Color(0xFF66BB6A),
            ),
            const SizedBox(height: 24),
            _buildFileUploadArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a note or comment...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 16),
         ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1A73E8),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  ),
  onPressed: _isSending ? null : _handleSend, // Disable button while sending
  icon: _isSending 
      ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ) 
      : const Icon(Icons.send),
  label: Text(
    _isSending ? 'Sending...' : 'Send',
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  ),
)
        ],
      ),
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5F6368),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSelectionTile(
              isSelected: gender == 'Male',
              icon: Icons.male,
              label: 'Male',
              onTap: () {
                setState(() {
                  gender = 'Male';
                  if (gender == 'Male') isPregnant = false;
                });
              },
            ),
            const SizedBox(width: 16),
            _buildSelectionTile(
              isSelected: gender == 'Female',
              icon: Icons.female,
              label: 'Female',
              onTap: () {
                setState(() {
                  gender = 'Female';
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeAndPregnancySelection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Age Group',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5F6368),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSelectionTile(
                    isSelected: !isChild,
                    icon: Icons.person,
                    label: 'Adult',
                    onTap: () {
                      setState(() {
                        isChild = false;
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildSelectionTile(
                    isSelected: isChild,
                    icon: Icons.child_care,
                    label: 'Child',
                    onTap: () {
                      setState(() {
                        isChild = true;
                        isPregnant = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        if (gender == 'Female' && !isChild)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pregnancy Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5F6368),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSelectionTile(
                      isSelected: !isPregnant,
                      icon: Icons.do_not_disturb,
                      label: 'No',
                      onTap: () {
                        setState(() {
                          isPregnant = false;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildSelectionTile(
                      isSelected: isPregnant,
                      icon: Icons.pregnant_woman,
                      label: 'Yes',
                      onTap: () {
                        setState(() {
                          isPregnant = true;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFileUploadArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              globalFileName != null
                  ? Icons.insert_drive_file
                  : Icons.cloud_upload,
              size: 32,
              color: const Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 16),
          if (globalFileName != null)
            Column(
              children: [
                Text(
                  'Selected File:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    globalFileName!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      globalFileName = null;
                      globalFileBytes = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Clear Selection'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                const Text(
                  'Drag and Drop here',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text('or', style: TextStyle(color: Color(0xFF5F6368))),
              ],
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _selectFile,
            icon: Icon(
              globalFileName != null ? Icons.refresh : Icons.upload_file,
            ),
            label: Text(
              globalFileName != null ? 'Change File' : 'Select File',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color(0xFF1A73E8).withOpacity(0.1)
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, List<Medicine> medicines) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmation'),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The payload has been sent successfully. Would you like to add these medications to your calendar?',
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = medicines[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.medication, color: Color(0xFF1A73E8)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      medicine.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Date: ${medicine.date.toLocal().toString().split(' ')[0]}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Time: ${medicine.time.format(context)}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await _sendConfirmationPayload(medicines);
            },
            child: const Text('Yes'),
          )
        ],
      );
    },
  );
}
  Future<void> _sendConfirmationPayload(List<Medicine> medicines) async {
  try {
    final payload = {
      'medicines': medicines.map((medicine) {
        return {
          'name': medicine.name,
          'date': medicine.date.toIso8601String(),
          'time': '${medicine.time.hour}:${medicine.time.minute}',
        };
      }).toList(),
      'confirmed': true, // Indicate that the user confirmed the medicines
    };

    final success = await ServiceFunctions.sendConfirmationPayload(payload);

    if (success) {
      _showSnackBar('Confirmation sent successfully!', Colors.green);
    } else {
      _showSnackBar('Failed to send confirmation.', Colors.red);
    }
  } catch (e) {
    _showSnackBar('Error sending confirmation: $e', Colors.red);
  }
}
}
