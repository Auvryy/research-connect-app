import 'package:flutter/material.dart';
import 'package:inquira/widgets/custom_choice_chip.dart';
import 'package:inquira/widgets/survey_card.dart';
import 'package:inquira/data/api/survey_api.dart';
import 'package:inquira/models/survey.dart';
import 'package:inquira/constants/colors.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  String selectedFilter = "All";
  List<Survey> _allSurveys = [];
  List<Survey> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;
  
  // Pagination state
  int _currentPage = 1;
  static const int _perPage = 5;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Delay slightly to ensure network/auth is ready after login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSurveys();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Listen to scroll events for infinite scrolling
  void _onScroll() {
    // Safety check: ensure scroll position is available and widget is mounted
    if (!mounted || !_scrollController.hasClients) return;
    
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Near bottom, load more if not already loading and has more data
      if (!_isLoadingMore && _hasMoreData && !_showSearchResults) {
        _loadMoreSurveys();
      }
    }
  }

  /// Handle filter selection and auto-load more surveys if needed
  Future<void> _onFilterChanged(String newFilter) async {
    setState(() => selectedFilter = newFilter);
    
    // If filter is not "All", check if we have matching surveys
    if (newFilter != "All") {
      final matchingSurveys = _allSurveys.where((s) => s.tags.contains(newFilter)).toList();
      
      // If no matching surveys but more data available, keep loading until we find some
      if (matchingSurveys.isEmpty && _hasMoreData && !_isLoadingMore) {
        // Try to load more surveys (up to 3 times)
        int attempts = 0;
        while (attempts < 3 && matchingSurveys.isEmpty && _hasMoreData && !_isLoadingMore) {
          await _loadMoreSurveys();
          attempts++;
          // Check again after loading
          final newMatches = _allSurveys.where((s) => s.tags.contains(newFilter)).toList();
          if (newMatches.isNotEmpty) break;
        }
      }
    }
  }

  /// Load more surveys (next page)
  Future<void> _loadMoreSurveys() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final nextPage = _currentPage + 1;
      print('HomeFeed: Loading more surveys, page $nextPage...');
      final backendData = await SurveyAPI.getAllSurveys(page: nextPage, perPage: _perPage);
      
      final newSurveys = backendData
          .map((json) => _parseSurveyFromBackend(json))
          .where((survey) => !survey.archived)
          .toList();
      
      if (mounted) {
        setState(() {
          _allSurveys.addAll(newSurveys);
          _currentPage = nextPage;
          _isLoadingMore = false;
          // If we got fewer than perPage, there's no more data
          _hasMoreData = newSurveys.length >= _perPage;
        });
        print('HomeFeed: Loaded ${newSurveys.length} more surveys. Total: ${_allSurveys.length}');
      }
    } catch (e) {
      print('HomeFeed: Error loading more surveys: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _searchSurveys(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await SurveyAPI.searchSurveys(query: query);
      
      if (response['ok'] == true) {
        final surveys = (response['surveys'] as List)
            .map((json) => _parseSurveyFromBackend(json))
            .toList();
        
        if (mounted) {
          setState(() {
            _searchResults = surveys;
            _showSearchResults = true;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _showSearchResults = true;
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      print('HomeFeed: Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _showSearchResults = true;
          _isSearching = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showSearchResults = false;
      _searchResults = [];
    });
  }

  Future<void> _loadSurveys({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        // Reset pagination when doing fresh load
        _currentPage = 1;
        _hasMoreData = true;
        _allSurveys = [];
      });
    }
    
    try {
      // Fetch surveys from backend with pagination
      print('HomeFeed: Fetching surveys from backend (page 1)...');
      final backendData = await SurveyAPI.getAllSurveys(page: 1, perPage: _perPage);
      
      final surveys = backendData
          .map((json) => _parseSurveyFromBackend(json))
          // Filter out archived surveys (safety measure - backend should already filter)
          .where((survey) => !survey.archived)
          .toList();
      print('HomeFeed: Loaded ${surveys.length} surveys from backend');
      
      if (mounted) {
        setState(() {
          _allSurveys = surveys;
          _isLoading = false;
          _hasLoadedOnce = true;
          _currentPage = 1;
          // If we got fewer than perPage, there's no more data
          _hasMoreData = surveys.length >= _perPage;
        });
      }
    } catch (e) {
      print('HomeFeed: Error fetching surveys: $e');
      
      // If first load fails, retry once after a short delay
      if (!_hasLoadedOnce) {
        print('HomeFeed: First load failed, retrying in 500ms...');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          try {
            final retryData = await SurveyAPI.getAllSurveys(page: 1, perPage: _perPage);
            final surveys = retryData
                .map((json) => _parseSurveyFromBackend(json))
                // Filter out archived surveys (safety measure)
                .where((survey) => !survey.archived)
                .toList();
            if (mounted) {
              setState(() {
                _allSurveys = surveys;
                _isLoading = false;
                _hasLoadedOnce = true;
                _currentPage = 1;
                _hasMoreData = surveys.length >= _perPage;
              });
            }
            return;
          } catch (retryError) {
            print('HomeFeed: Retry also failed: $retryError');
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _allSurveys = [];
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  /// Parse survey from backend JSON format to Survey model
  /// Backend returns: pk_survey_id, survey_title, survey_content, survey_category,
  /// survey_target_audience, survey_date_created, user_username, user_profile, approx_time,
  /// num_of_responses, num_of_likes, is_liked
  /// Note: survey_content from get_post() is actually Posts.content (the caption)
  Survey _parseSurveyFromBackend(Map<String, dynamic> json) {
    // Handle target_audience which can be a list or string
    String targetAudience = '';
    if (json['survey_target_audience'] is List) {
      targetAudience = (json['survey_target_audience'] as List).join(', ');
    } else if (json['survey_target_audience'] is String) {
      targetAudience = json['survey_target_audience'] as String;
    }

    // Handle category/tags
    List<String> tags = [];
    if (json['survey_category'] != null) {
      if (json['survey_category'] is List) {
        tags = List<String>.from(json['survey_category']);
      } else if (json['survey_category'] is String) {
        tags = [json['survey_category'] as String];
      }
    }

    // Backend: survey_content from get_post() is actually Posts.content (caption)
    final caption = json['survey_content'] as String? ?? '';
    
    // Parse status from backend if available (defaults to 'open')
    // Backend stores status as 'open' or 'closed' string
    // Note: Backend get_post() doesn't include status field currently,
    // so we check both 'status' and 'survey_status' fields
    bool isOpen = true;
    if (json['status'] != null) {
      isOpen = json['status'].toString().toLowerCase() == 'open';
    } else if (json['survey_status'] != null) {
      isOpen = json['survey_status'].toString().toLowerCase() == 'open';
    }

    // Parse response count, likes count, and liked status
    final numOfResponses = json['num_of_responses'] as int? ?? 0;
    final numOfLikes = json['num_of_likes'] as int? ?? 0;
    final isLiked = json['is_liked'] as bool? ?? false;

    // Parse approved and archived flags
    // Backend has a typo: uses 'approved`' (with backtick) instead of 'approved'
    final approved = (json['approved`'] as bool?) ?? (json['approved'] as bool?) ?? false;
    final archived = json['archived'] as bool? ?? false;
    
    // Parse creator profile URL
    final creatorProfileUrl = json['user_profile'] as String?;

    return Survey(
      id: json['pk_survey_id']?.toString() ?? '',
      postId: json['pk_survey_id'] as int?,
      title: json['survey_title'] ?? 'Untitled Survey',
      caption: caption, // Caption is the post content
      description: '', // Description only available from questionnaire endpoint
      timeToComplete: _parseTimeToComplete(json['approx_time']),
      tags: tags,
      targetAudience: targetAudience,
      creator: json['user_username'] ?? 'Unknown',
      creatorProfileUrl: creatorProfileUrl,
      createdAt: _parseDateTime(json['survey_date_created']),
      status: isOpen,
      approved: approved,
      archived: archived,
      responses: numOfResponses,
      numOfLikes: numOfLikes,
      isLiked: isLiked,
      questions: [], // Questions are loaded separately when taking the survey
    );
  }

  DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is String) {
      return DateTime.tryParse(dateValue) ?? DateTime.now();
    }
    return DateTime.now();
  }

  int _parseTimeToComplete(String? approxTime) {
    if (approxTime == null) return 5;
    // Parse strings like "10-15 min" to get the first number
    final match = RegExp(r'(\d+)').firstMatch(approxTime);
    return match != null ? int.tryParse(match.group(1)!) ?? 5 : 5;
  }

  @override
  Widget build(BuildContext context) {
    // Determine which surveys to display
    List<Survey> displaySurveys;
    if (_showSearchResults) {
      displaySurveys = _searchResults;
    } else {
      displaySurveys = selectedFilter == "All"
          ? _allSurveys 
          : _allSurveys.where((s) => s.tags.contains(selectedFilter)).toList();
    }

    return Column(
      children: [
        const SizedBox(height: 10),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search surveys...',
              prefixIcon: const Icon(Icons.search, color: AppColors.shadedPrimary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.shadedPrimary),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              // Debounce search - wait 500ms after user stops typing
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == value && value.isNotEmpty) {
                  _searchSurveys(value);
                }
              });
              if (value.isEmpty) {
                _clearSearch();
              }
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _searchSurveys(value);
              }
            },
          ),
        ),

        const SizedBox(height: 10),

        // Filter section (hide when showing search results)
        if (!_showSearchResults)
          SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 10),
              CustomChoiceChip(
                label: "All",
                selected: selectedFilter == "All",
                onSelected: (selected) {
                  if (selected) _onFilterChanged("All");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Academic",
                selected: selectedFilter == "Academic",
                onSelected: (selected) {
                  if (selected) _onFilterChanged("Academic");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Health",
                selected: selectedFilter == "Health",
                onSelected: (selected) {
                  if (selected) _onFilterChanged("Health");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Technology",
                selected: selectedFilter == "Technology",
                onSelected: (selected) {
                  if (selected) _onFilterChanged("Technology");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Entertainment",
                selected: selectedFilter == "Entertainment",
                onSelected: (selected) {
                  if (selected) _onFilterChanged("Entertainment");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Lifestyle",
                selected: selectedFilter == "Lifestyle",
                onSelected: (selected) {
                  if (selected) _onFilterChanged("Lifestyle");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Business",
                selected: selectedFilter == "Business",
                onSelected: (selected) {
                  if (selected) _onFilterChanged("Business");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Research",
                selected: selectedFilter == "Research",
                onSelected: (selected) {
                  if (selected) _onFilterChanged("Research");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Marketing",
                selected: selectedFilter == "Marketing",
                onSelected: (selected) {
                  if (selected) _onFilterChanged("Marketing");
                },
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Feed list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load surveys',
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _loadSurveys,
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
                        )
                      : displaySurveys.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _showSearchResults ? Icons.search_off : Icons.poll_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _showSearchResults ? 'No results found' : 'No surveys yet',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _showSearchResults 
                                        ? 'Try a different search term'
                                        : 'Create your first survey!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (!_showSearchResults)
                                    ElevatedButton.icon(
                                      onPressed: _loadSurveys,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Refresh'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  if (_showSearchResults)
                                    ElevatedButton.icon(
                                      onPressed: _clearSearch,
                                      icon: const Icon(Icons.clear),
                                      label: const Text('Clear Search'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _showSearchResults 
                                  ? () => _searchSurveys(_searchController.text)
                                  : _loadSurveys,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_showSearchResults)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${displaySurveys.length} result${displaySurveys.length == 1 ? '' : 's'} found',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: _clearSearch,
                                            child: const Text('Clear'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      itemCount: displaySurveys.length + (_hasMoreData && !_showSearchResults ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        // Show loading indicator at the bottom
                                        if (index == displaySurveys.length) {
                                          return Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Center(
                                              child: _isLoadingMore
                                                  ? const CircularProgressIndicator()
                                                  : const SizedBox.shrink(),
                                            ),
                                          );
                                        }
                                        final survey = displaySurveys[index];
                                        return SurveyCard(survey: survey);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
        ),
      ],
    );
  }
}
