import 'package:flutter/material.dart';
import 'package:inquira/widgets/custom_choice_chip.dart';
import 'package:inquira/models/survey.dart';
import 'package:inquira/widgets/survey_card.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  String selectedFilter = "All";

  //Mock survey data (replace later with DB or API)
  final List<Survey> surveys = [
    Survey(
      id: "1",
      title: "The Impact of Social Media Usage on Academic Performance of College Students",
      description:
          "This study aims to explore the relationship between mobile phone usage patterns and the academic performance of undergraduate students.",
      creator: "Andy Sarne • MIT",
      tags: ["Technology", "Science", "Psychology"],
      timeToComplete: 15,
      targetAudience: "All Students",
      createdAt: DateTime.now(),
      questions: [],
    ),
    Survey(
      id: "2",
      title: "Social Media Impact on Academic Performance",
      description:
          "A shorter description to show collapsed vs expanded card state.",
      creator: "Cabigan Red • Psychology Undergraduate",
      tags: ["Technology", "Psychology"],
      timeToComplete: 10,
      targetAudience: "Psychology Students",
      createdAt: DateTime.now(),
      questions: [],
    ),
    Survey(
      id: "3",
      title: "How does it feel like being a mcdonald's worker while having a CS degree.",
      description: 
        "Para ito sa students na may CS degree pero hindi nakapasok sa kahit anumang IT industry.",
      creator: "Acog Laren • BSIT Student",
      tags: ["Humanities", "Technology"],
      timeToComplete: 5,
      targetAudience: "CS Students",
      createdAt: DateTime.now(),
      questions: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Filtered list based on selectedFilter
    final filteredSurveys = selectedFilter == "All"
        ? surveys
        : surveys.where((s) => s.tags.contains(selectedFilter)).toList();

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
                onSelected: () => setState(() => selectedFilter = "All"),
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Business",
                selected: selectedFilter == "Business",
                onSelected: () => setState(() => selectedFilter = "Business"),
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Technology",
                selected: selectedFilter == "Technology",
                onSelected: () => setState(() => selectedFilter = "Technology"),
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Humanities",
                selected: selectedFilter == "Humanities",
                onSelected: () => setState(() => selectedFilter = "Humanities"),
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
