import 'package:flutter/material.dart';
import 'package:inquira/widgets/custom_choice_chip.dart';
import 'package:inquira/widgets/survey_card.dart';
import 'package:inquira/data/mock_survey.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  String selectedFilter = "All";

  //Mock survey data (replace later with DB or API)

  @override
  Widget build(BuildContext context) {
    // Filtered list based on selectedFilter
    final filteredSurveys = selectedFilter == "All"
        ? mockSurveys 
        : mockSurveys.where((s) => s.tags.contains(selectedFilter)).toList();

    return Column(
      children: [
        const SizedBox(height: 10),

        // Filter section
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 10),
              CustomChoiceChip(
                label: "All",
                selected: selectedFilter == "All",
                onSelected: (selected) {
                  if (selected) setState(() => selectedFilter = "All");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Business",
                selected: selectedFilter == "Business",
                onSelected: (selected) {
                  if (selected) setState(() => selectedFilter = "Business");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Technology",
                selected: selectedFilter == "Technology",
                onSelected: (selected) {
                  if (selected) setState(() => selectedFilter = "Technology");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Humanities",
                selected: selectedFilter == "Humanities",
                onSelected: (selected) {
                  if (selected) setState(() => selectedFilter = "Humanities");
                },
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Feed list
        Expanded(
          child: ListView.builder(
            itemCount: filteredSurveys.length,
            itemBuilder: (context, index) {
              final survey = filteredSurveys[index];
              return SurveyCard(survey: survey);
            },
          ),
        ),
      ],
    );
  }
}
