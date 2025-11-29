import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/survey.dart';
import 'package:inquira/data/api/survey_api.dart';

class EditSurveyPage extends StatefulWidget {
  final Survey survey;

  const EditSurveyPage({super.key, required this.survey});

  @override
  State<EditSurveyPage> createState() => _EditSurveyPageState();
}

class _EditSurveyPageState extends State<EditSurveyPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _captionController;
  late TextEditingController _descriptionController;
  late String _status;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.survey.title);
    _captionController = TextEditingController(text: widget.survey.caption);
    _descriptionController = TextEditingController(text: widget.survey.description);
    _status = widget.survey.status ? 'open' : 'closed';

    // Listen for changes
    _titleController.addListener(_onFieldChanged);
    _captionController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final hasChanges = _titleController.text != widget.survey.title ||
        _captionController.text != widget.survey.caption ||
        _descriptionController.text != widget.survey.description ||
        _status != (widget.survey.status ? 'open' : 'closed');
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveSurvey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await SurveyAPI.updateSurvey(
        surveyId: widget.survey.postId!,
        title: _titleController.text.trim(),
        postContent: _captionController.text.trim(),
        surveyDescription: _descriptionController.text.trim(),
        status: _status,
      );

      if (mounted) {
        if (response['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Survey updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate changes were made
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to update survey'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Edit Survey'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveSurvey,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can edit the title, caption, description, and status of your survey. Questions cannot be modified after creation.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Title Field
                _buildLabel('Survey Title', Icons.title),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter survey title',
                    helperText: 'Min 5, Max 100 characters',
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    if (value.trim().length < 5) {
                      return 'Title must be at least 5 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Caption Field (Post Content)
                _buildLabel('Caption', Icons.short_text),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _captionController,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter a short caption for your survey',
                    helperText: 'Min 5, Max 500 characters',
                  ),
                  maxLines: 3,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Caption is required';
                    }
                    if (value.trim().length < 5) {
                      return 'Caption must be at least 5 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description Field
                _buildLabel('Description', Icons.description),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter detailed description for survey takers',
                    helperText: 'Min 5, Max 500 characters',
                  ),
                  maxLines: 5,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    if (value.trim().length < 5) {
                      return 'Description must be at least 5 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Status Section
                _buildLabel('Survey Status', Icons.toggle_on),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      _buildStatusOption(
                        'open',
                        'Open',
                        'Users can take this survey',
                        Icons.lock_open,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildStatusOption(
                        'closed',
                        'Closed',
                        'Survey is no longer accepting responses',
                        Icons.lock,
                        Colors.red,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || !_hasChanges ? null : _saveSurvey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _hasChanges ? 'Save Changes' : 'No Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _hasChanges ? Colors.white : Colors.grey[600],
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Read-only Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[700], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Read-only Information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildReadOnlyInfo('Survey ID', widget.survey.postId?.toString() ?? 'N/A'),
                      _buildReadOnlyInfo('Creator', widget.survey.creator),
                      _buildReadOnlyInfo('Created', _formatDate(widget.survey.createdAt)),
                      _buildReadOnlyInfo('Tags', widget.survey.tags.join(', ')),
                      _buildReadOnlyInfo('Target Audience', widget.survey.targetAudience),
                      _buildReadOnlyInfo('Time to Complete', '${widget.survey.timeToComplete} min'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hintText,
      helperText: helperText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildStatusOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _status == value;
    return InkWell(
      onTap: () {
        setState(() {
          _status = value;
          _onFieldChanged();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _status,
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _status = v;
                    _onFieldChanged();
                  });
                }
              },
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
