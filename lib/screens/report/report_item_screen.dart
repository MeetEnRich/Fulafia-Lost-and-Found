import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/config/constants.dart';
import 'package:lost_and_found/models/item_model.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/providers/item_provider.dart';
import 'package:lost_and_found/utils/validators.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';
import 'package:lost_and_found/widgets/doodle_app_bar.dart';

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key});
  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _specificLocationController = TextEditingController();
  ItemType _type = ItemType.lost;
  String? _category;
  String? _campusLocation;
  DateTime _dateOccurred = DateTime.now();
  final List<File> _images = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _specificLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= AppConstants.maxImagesPerItem) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Maximum ${AppConstants.maxImagesPerItem} images allowed')));
      return;
    }
    final picked = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    if (picked != null) setState(() => _images.add(File(picked.path)));
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context, initialDate: _dateOccurred, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _dateOccurred = date);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null || _campusLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and location')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final itemProvider = context.read<ItemProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await itemProvider.reportItem(
      title: _titleController.text,
      description: _descriptionController.text,
      type: _type,
      category: _category!,
      campusLocation: _campusLocation!,
      specificLocation: _specificLocationController.text.isEmpty
          ? null
          : _specificLocationController.text,
      dateOccurred: _dateOccurred,
      reporterUid: auth.user!.uid,
      reporterName: auth.user!.fullName,
      reporterDepartment: auth.user!.department,
      images: _images,
    );

    if (success) {
      messenger.showSnackBar(SnackBar(
        content: Text(itemProvider.successMessage ?? 'Item reported!'),
        backgroundColor: AppTheme.success,
      ));
      navigator.pop();
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(itemProvider.error ?? 'Failed to report item'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DoodleAppBar(title: Text('Report Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Type toggle
            Text('What happened?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _TypeCard(label: 'I lost something', icon: Icons.search_off, color: AppTheme.lostColor, selected: _type == ItemType.lost, onTap: () => setState(() => _type = ItemType.lost))),
              const SizedBox(width: 12),
              Expanded(child: _TypeCard(label: 'I found something', icon: Icons.inventory_2, color: AppTheme.foundColor, selected: _type == ItemType.found, onTap: () => setState(() => _type = ItemType.found))),
            ]),
            const SizedBox(height: 20),

            // Title
            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Item Title', hintText: 'e.g., Black Samsung Phone', prefixIcon: Icon(Icons.title)), validator: Validators.itemTitle),
            const SizedBox(height: 14),

            // Description
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description', hintText: 'Describe the item in detail...', prefixIcon: Icon(Icons.description_outlined), alignLabelWithHint: true), maxLines: 4, maxLength: AppConstants.maxDescriptionLength, validator: Validators.itemDescription),
            const SizedBox(height: 14),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _category, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
              items: AppConstants.categoryNames.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => Validators.dropdown(v, 'category'),
            ),
            const SizedBox(height: 14),

            // Campus Location
            DropdownButtonFormField<String>(
              initialValue: _campusLocation, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Campus Location', prefixIcon: Icon(Icons.location_on_outlined)),
              items: AppConstants.campusLocations.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _campusLocation = v),
              validator: (v) => Validators.dropdown(v, 'location'),
            ),
            const SizedBox(height: 14),

            // Specific Location
            TextFormField(controller: _specificLocationController, decoration: const InputDecoration(labelText: 'Specific Location (optional)', hintText: 'e.g., Room 204, Block B', prefixIcon: Icon(Icons.pin_drop_outlined))),
            const SizedBox(height: 14),

            // Date
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date Lost/Found', prefixIcon: Icon(Icons.calendar_today_outlined)),
                child: Text('${_dateOccurred.day}/${_dateOccurred.month}/${_dateOccurred.year}'),
              ),
            ),
            const SizedBox(height: 20),

            // Images
            Text('Photos (optional)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Add up to ${AppConstants.maxImagesPerItem} photos', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ..._images.asMap().entries.map((e) => _ImageTile(file: e.value, onRemove: () => setState(() => _images.removeAt(e.key)))),
              if (_images.length < AppConstants.maxImagesPerItem)
                _AddImageTile(onCamera: () => _pickImage(ImageSource.camera), onGallery: () => _pickImage(ImageSource.gallery)),
            ]),
            const SizedBox(height: 28),

            // Submit
            Consumer<ItemProvider>(builder: (context, provider, _) {
              return PrimaryButton(label: 'Submit Report', onPressed: _handleSubmit, isLoading: provider.isLoading, icon: Icons.send);
            }),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label; final IconData icon; final Color color; final bool selected; final VoidCallback onTap;
  const _TypeCard({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: selected ? color : AppTheme.divider, width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? color : AppTheme.textSecondary, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? color : AppTheme.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final File file; final VoidCallback onRemove;
  const _ImageTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ClipRRect(borderRadius: BorderRadius.circular(AppTheme.radiusMd), child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover)),
      Positioned(top: 2, right: 2, child: GestureDetector(
        onTap: onRemove,
        child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
          child: const Icon(Icons.close, size: 14, color: Colors.white)),
      )),
    ]);
  }
}

class _AddImageTile extends StatelessWidget {
  final VoidCallback onCamera; final VoidCallback onGallery;
  const _AddImageTile({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Take Photo'), onTap: () { Navigator.pop(context); onCamera(); }),
        ListTile(leading: const Icon(Icons.photo_library), title: const Text('Choose from Gallery'), onTap: () { Navigator.pop(context); onGallery(); }),
      ]))),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(AppTheme.radiusMd), border: Border.all(color: AppTheme.divider, style: BorderStyle.solid)),
        child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.textSecondary),
      ),
    );
  }
}
