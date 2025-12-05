import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/api/survey_api.dart';

/// Survey Responses Analytics Page
/// Displays aggregated analytics for a survey's responses
class SurveyResponsesPage extends StatefulWidget {
  final int surveyId;
  final String surveyTitle;

  const SurveyResponsesPage({
    super.key,
    required this.surveyId,
    required this.surveyTitle,
  });

  @override
  State<SurveyResponsesPage> createState() => _SurveyResponsesPageState();
}

class _SurveyResponsesPageState extends State<SurveyResponsesPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _responseData;

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await SurveyAPI.getSurveyResponses(widget.surveyId);

      if (mounted) {
        if (result['ok'] == true) {
          setState(() {
            _responseData = result['data'] as Map<String, dynamic>?;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load responses';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Survey Analytics',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _responseData != null
                  ? _buildResponseContent()
                  : _buildEmptyState(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadResponses,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.poll_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No responses yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your survey to collect responses!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseContent() {
    final totalResponses = _responseData!['_total_peeps_who_answered'] ?? 0;
    final surveyTitle = _responseData!['survey_title'] ?? widget.surveyTitle;
    final choicesData = _responseData!['choices_data'] as Map<String, dynamic>?;
    final ratingsData = _responseData!['rating_data'] as Map<String, dynamic>?;
    final datesData = _responseData!['dates_data'] as Map<String, dynamic>?;
    final textData = _responseData!['text_data'] as Map<String, dynamic>?;

    // Separate number responses from text responses
    Map<String, dynamic>? numberData;
    Map<String, dynamic>? filteredTextData;
    
    if (textData != null && textData.isNotEmpty) {
      numberData = {};
      filteredTextData = {};
      
      for (final entry in textData.entries) {
        final data = entry.value as Map<String, dynamic>?;
        final questionType = data?['type'] as String? ?? '';
        
        if (questionType == 'number') {
          numberData[entry.key] = entry.value;
        } else {
          filteredTextData[entry.key] = entry.value;
        }
      }
      
      // Set to null if empty to match the original null check behavior
      if (numberData.isEmpty) numberData = null;
      if (filteredTextData.isEmpty) filteredTextData = null;
    }

    return RefreshIndicator(
      onRefresh: _loadResponses,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Survey Header Card
            _buildHeaderCard(surveyTitle, totalResponses),
            const SizedBox(height: 20),

            // Choice Questions Section
            if (choicesData != null && choicesData.isNotEmpty) ...[
              _buildSectionHeader('Choice Questions', Icons.radio_button_checked),
              const SizedBox(height: 12),
              ...choicesData.entries.map((entry) => _buildChoiceQuestionCard(entry.key, entry.value)),
              const SizedBox(height: 20),
            ],

            // Rating Questions Section
            if (ratingsData != null && ratingsData.isNotEmpty) ...[
              _buildSectionHeader('Rating Questions', Icons.star),
              const SizedBox(height: 12),
              ...ratingsData.entries.map((entry) => _buildRatingQuestionCard(entry.key, entry.value)),
              const SizedBox(height: 20),
            ],

            // Date Questions Section
            if (datesData != null && datesData.isNotEmpty) ...[
              _buildSectionHeader('Date Questions', Icons.calendar_today),
              const SizedBox(height: 12),
              ...datesData.entries.map((entry) => _buildDateQuestionCard(entry.key, entry.value)),
              const SizedBox(height: 20),
            ],

            // Number Questions Section (NEW - separated from text)
            if (numberData != null && numberData.isNotEmpty) ...[
              _buildSectionHeader('Number Responses', Icons.numbers),
              const SizedBox(height: 12),
              ...numberData.entries.map((entry) => _buildNumberQuestionCard(entry.key, entry.value)),
              const SizedBox(height: 20),
            ],

            // Text Questions Section (now filtered to exclude numbers)
            if (filteredTextData != null && filteredTextData.isNotEmpty) ...[
              _buildSectionHeader('Text Responses', Icons.text_fields),
              const SizedBox(height: 12),
              ...filteredTextData.entries.map((entry) => _buildTextQuestionCard(entry.key, entry.value)),
              const SizedBox(height: 20),
            ],

            // No data message
            if ((choicesData == null || choicesData.isEmpty) &&
                (ratingsData == null || ratingsData.isEmpty) &&
                (datesData == null || datesData.isEmpty) &&
                (numberData == null || numberData.isEmpty) &&
                (filteredTextData == null || filteredTextData.isEmpty))
              _buildNoQuestionsMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String title, int totalResponses) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$totalResponses ${totalResponses == 1 ? 'Response' : 'Responses'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceQuestionCard(String questionId, Map<String, dynamic> data) {
    final questionText = data['question_text'] as String? ?? 'Question';
    final questionType = data['type'] as String? ?? '';
    final answerData = data['answer_data'] as Map<String, dynamic>? ?? {};

    // Calculate total for percentages
    int total = 0;
    answerData.forEach((key, value) {
      total += (value as int? ?? 0);
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatQuestionType(questionType),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (answerData.isEmpty)
              Text(
                'No responses yet',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              )
            else
              ...answerData.entries.map((entry) {
                final count = entry.value as int? ?? 0;
                final percentage = total > 0 ? (count / total * 100) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '$count (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingQuestionCard(String questionId, Map<String, dynamic> data) {
    final questionText = data['question_text'] as String? ?? 'Question';
    final answerData = data['answer_data'] as Map<String, dynamic>? ?? {};
    
    // Get max_rating from backend (now included in rating_data)
    int maxRating = 5; // Default fallback
    final backendMaxRating = data['max_rating'];
    if (backendMaxRating != null) {
      if (backendMaxRating is int) {
        maxRating = backendMaxRating;
      } else if (backendMaxRating is String) {
        maxRating = int.tryParse(backendMaxRating) ?? 5;
      }
    }
    // Ensure maxRating is valid (1-10 range)
    if (maxRating < 1) maxRating = 5;
    if (maxRating > 10) maxRating = 10;

    // Calculate average rating and total
    int total = 0;
    double weightedSum = 0;
    answerData.forEach((key, value) {
      final rating = int.tryParse(key) ?? 0;
      final count = value as int? ?? 0;
      total += count;
      weightedSum += rating * count;
    });
    final averageRating = total > 0 ? (weightedSum / total) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              questionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Text(
                'No responses yet',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              )
            else ...[
              // Average rating display
              Row(
                children: [
                  // Use Wrap for many stars, Row for few
                  if (maxRating <= 5)
                    ...List.generate(maxRating, (index) {
                      return Icon(
                        index < averageRating.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      );
                    })
                  else
                    ...List.generate(maxRating, (index) {
                      return Icon(
                        index < averageRating.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  const SizedBox(width: 12),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    ' / $maxRating',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Based on $total ${total == 1 ? 'response' : 'responses'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),
              // Rating distribution
              ...answerData.entries.map((entry) {
                final count = entry.value as int? ?? 0;
                final percentage = total > 0 ? (count / total * 100) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          entry.key,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateQuestionCard(String questionId, Map<String, dynamic> data) {
    final questionText = data['question_text'] as String? ?? 'Question';
    final answerData = data['answer_data'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (answerData.isEmpty)
              Text(
                'No responses yet',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: answerData.entries.map((entry) {
                  final count = entry.value as int? ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${entry.key} ($count)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextQuestionCard(String questionId, Map<String, dynamic> data) {
    final questionText = data['question_text'] as String? ?? 'Question';
    final answerData = data['answer_data'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${answerData.length} responses',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (answerData.isEmpty)
              Text(
                'No responses yet',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              )
            else
              ...answerData.take(10).map((response) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    response?.toString() ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }),
            if (answerData.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... and ${answerData.length - 10} more responses',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberQuestionCard(String questionId, Map<String, dynamic> data) {
    final questionText = data['question_text'] as String? ?? 'Question';
    final answerData = data['answer_data'] as List<dynamic>? ?? [];

    // Calculate statistics for number responses
    final List<double> numericValues = [];
    for (final answer in answerData) {
      final parsed = double.tryParse(answer?.toString() ?? '');
      if (parsed != null) {
        numericValues.add(parsed);
      }
    }

    double? average;
    double? min;
    double? max;
    double? sum;

    if (numericValues.isNotEmpty) {
      sum = numericValues.reduce((a, b) => a + b);
      average = sum / numericValues.length;
      min = numericValues.reduce((a, b) => a < b ? a : b);
      max = numericValues.reduce((a, b) => a > b ? a : b);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.numbers, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${answerData.length} responses',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (answerData.isEmpty)
              Text(
                'No responses yet',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              )
            else ...[
              // Statistics summary
              if (numericValues.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Average', average!.toStringAsFixed(2)),
                      _buildStatItem('Min', min!.toStringAsFixed(2)),
                      _buildStatItem('Max', max!.toStringAsFixed(2)),
                      _buildStatItem('Sum', sum!.toStringAsFixed(2)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // Individual responses
              ...answerData.take(10).map((response) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tag, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        response?.toString() ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }),
              if (answerData.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... and ${answerData.length - 10} more responses',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.blue[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNoQuestionsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No question data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'radiobutton':
        return 'Single Choice';
      case 'checkbox':
        return 'Multiple Choice';
      case 'dropdown':
        return 'Dropdown';
      default:
        return type;
    }
  }
}
