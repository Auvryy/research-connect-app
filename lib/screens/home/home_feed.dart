import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inquira/widgets/custom_choice_chip.dart';

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
        const SizedBox(height: 10), // Space from top

        // Filter section
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: MediaQuery.of(context).size.width, 
            alignment: Alignment.centerLeft,
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

                const SizedBox(width: 8,),

                CustomChoiceChip(
                  label: "Technology",
                  selected: selectedFilter == "Technology",
                  onSelected: () => setState(() => selectedFilter = "Technology"),
                ),

                const SizedBox(width: 8,),

                CustomChoiceChip(
                  label: "Humanities",
                  selected: selectedFilter == "Humanities",
                  onSelected: () => setState(() => selectedFilter = "Humanities"),
                ),

                const SizedBox(width: 10), // Optional right padding
              ],
            ),
          ),
        ),

        const SizedBox(height: 10), // Space between filters and feed list

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
