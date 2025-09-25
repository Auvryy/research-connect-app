import 'package:flutter/material.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  String selectedFilter = "All";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter section
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text("All"),
                selected: selectedFilter == "All",
                onSelected: (_) => setState(() => selectedFilter = "All"),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Business"),
                selected: selectedFilter == "Business",
                onSelected: (_) => setState(() => selectedFilter = "Business"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Feed list
        Expanded(
          child: ListView(
            children: const [
              Card(child: ListTile(title: Text("Survey 1"))),
              Card(child: ListTile(title: Text("Survey 2"))),
            ],
          ),
        ),
      ],
    );
  }
}
