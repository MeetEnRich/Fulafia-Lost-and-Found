import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/config/constants.dart';
import 'package:lost_and_found/models/item_model.dart';
import 'package:lost_and_found/providers/item_provider.dart';
import 'package:lost_and_found/widgets/item_card.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  ItemType? _typeFilter;
  String? _categoryFilter;
  String? _locationFilter;
  DateTime? _fromDate;
  DateTime? _toDate;
  List<ItemModel>? _results;
  bool _isSearching = false;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _isSearching = true);
    final results = await context.read<ItemProvider>().searchItems(
      keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      type: _typeFilter,
      category: _categoryFilter,
      campusLocation: _locationFilter,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    setState(() { _results = results; _isSearching = false; });
  }

  void _clearFilters() {
    setState(() { _typeFilter = null; _categoryFilter = null; _locationFilter = null; _fromDate = null; _toDate = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Items'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by keyword...', filled: true, fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search), contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: Icon(Icons.tune, color: _showFilters ? AppTheme.primaryGreen : null), onPressed: () => setState(() => _showFilters = !_showFilters)),
                  IconButton(icon: const Icon(Icons.search), onPressed: _search),
                ]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
        ),
      ),
      body: Column(children: [
        // Filter panel
        if (_showFilters)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), color: Colors.white,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Type filter chips
              Row(children: [
                const Text('Type: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                ChoiceChip(label: const Text('All'), selected: _typeFilter == null, onSelected: (_) => setState(() => _typeFilter = null)),
                const SizedBox(width: 6),
                ChoiceChip(label: const Text('Lost'), selected: _typeFilter == ItemType.lost, onSelected: (_) => setState(() => _typeFilter = ItemType.lost)),
                const SizedBox(width: 6),
                ChoiceChip(label: const Text('Found'), selected: _typeFilter == ItemType.found, onSelected: (_) => setState(() => _typeFilter = ItemType.found)),
              ]),
              const SizedBox(height: 8),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _categoryFilter, isExpanded: true, isDense: true,
                decoration: const InputDecoration(labelText: 'Category', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), prefixIcon: Icon(Icons.category_outlined, size: 20)),
                items: [const DropdownMenuItem<String>(value: null, child: Text('All Categories')),
                  ...AppConstants.categoryNames.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))],
                onChanged: (v) => setState(() => _categoryFilter = v),
              ),
              const SizedBox(height: 8),

              // Location
              DropdownButtonFormField<String>(
                initialValue: _locationFilter, isExpanded: true, isDense: true,
                decoration: const InputDecoration(labelText: 'Location', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), prefixIcon: Icon(Icons.location_on_outlined, size: 20)),
                items: [const DropdownMenuItem<String>(value: null, child: Text('All Locations')),
                  ...AppConstants.campusLocations.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13))))],
                onChanged: (v) => setState(() => _locationFilter = v),
              ),
              const SizedBox(height: 8),

              // Date range
              Row(children: [
                Expanded(child: InkWell(
                  onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now()); if (d != null) setState(() => _fromDate = d); },
                  child: InputDecorator(decoration: const InputDecoration(labelText: 'From', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true),
                    child: Text(_fromDate != null ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}' : 'Any', style: const TextStyle(fontSize: 13))),
                )),
                const SizedBox(width: 8),
                Expanded(child: InkWell(
                  onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now()); if (d != null) setState(() => _toDate = d); },
                  child: InputDecorator(decoration: const InputDecoration(labelText: 'To', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true),
                    child: Text(_toDate != null ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}' : 'Any', style: const TextStyle(fontSize: 13))),
                )),
              ]),
              const SizedBox(height: 8),

              Row(children: [
                TextButton(onPressed: _clearFilters, child: const Text('Clear Filters')),
                const Spacer(),
                ElevatedButton(onPressed: _search, child: const Text('Apply')),
              ]),
            ]),
          ),

        // Results
        Expanded(child: _buildResults()),
      ]),
    );
  }

  Widget _buildResults() {
    if (_isSearching) return const Center(child: CircularProgressIndicator());

    if (_results == null) {
      return const EmptyState(icon: Icons.search, title: 'Search for Items', message: 'Enter a keyword or use filters to find lost and found items on campus.');
    }
    if (_results!.isEmpty) {
      return const EmptyState(icon: Icons.search_off, title: 'No Results Found', message: 'Try different keywords or adjust your filters.');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _results!.length,
      itemBuilder: (_, i) => ItemCard(item: _results![i], onTap: () => context.push('/item/${_results![i].id}')),
    );
  }
}
