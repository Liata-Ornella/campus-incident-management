import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services.dart';

// ==================== STUDENT DASHBOARD ====================

class StudentDashboard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const StudentDashboard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile['fullName']?.toString() ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusCare'),
        actions: [
          IconButton(
            onPressed: () => AuthService.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: IncidentService.myIncidents(),
        builder: (context, snapshot) {
          final reports = snapshot.data?.docs ?? [];
          final total = reports.length;
          final resolved = reports
              .where((doc) => doc.data()['status'] == 'resolved')
              .length;
          final active = total - resolved;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Hello, $name!',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Your campus safety starts with speaking up.'),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'My Reports',
                      value: '$total',
                      icon: Icons.description_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Resolved',
                      value: '$resolved',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Active',
                      value: '$active',
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _PrimaryAction(
                icon: Icons.add_circle_outline,
                title: 'Report an Incident',
                subtitle: 'Tell us what happened on campus.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateIncidentScreen(reporterName: name),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _PrimaryAction(
                icon: Icons.history,
                title: 'My Incident History',
                subtitle: 'View and track your previous reports.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncidentListScreen(isStaff: false),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Reports',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (snapshot.hasError)
                const Text('Unable to load your reports.')
              else if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (reports.isEmpty)
                const _EmptyState(
                  message: 'You have not submitted any reports yet.',
                )
              else
                ..._sortDocuments(reports)
                    .take(3)
                    .map(
                      (doc) =>
                          IncidentCard(incident: doc.data(), isStaff: false),
                    ),
            ],
          );
        },
      ),
    );
  }
}

// ==================== STAFF DASHBOARD ====================

class StaffDashboard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const StaffDashboard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile['fullName']?.toString() ?? 'Staff member';

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusCare Staff'),
        actions: [
          IconButton(
            onPressed: () => AuthService.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: IncidentService.allIncidents(),
        builder: (context, snapshot) {
          final reports = snapshot.data?.docs ?? [];

          int countStatus(String status) {
            return reports
                .where((doc) => doc.data()['status'] == status)
                .length;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Welcome, $name!',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Monitor and manage campus incident reports.'),
              const SizedBox(height: 22),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    title: 'Total Reports',
                    value: '${reports.length}',
                    icon: Icons.assignment_outlined,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Submitted',
                    value: '${countStatus('submitted')}',
                    icon: Icons.fiber_new,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Under Review',
                    value: '${countStatus('under review')}',
                    icon: Icons.visibility_outlined,
                    color: Colors.purple,
                  ),
                  _StatCard(
                    title: 'In Progress',
                    value: '${countStatus('in progress')}',
                    icon: Icons.pending_actions,
                    color: Colors.indigo,
                  ),
                  _StatCard(
                    title: 'Resolved',
                    value: '${countStatus('resolved')}',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _PrimaryAction(
                icon: Icons.manage_search,
                title: 'Manage Incidents',
                subtitle: 'Search, filter and update reports.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncidentListScreen(isStaff: true),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Latest Reports',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (snapshot.hasError)
                const Text('Unable to load incidents.')
              else if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (reports.isEmpty)
                const _EmptyState(
                  message: 'No incidents have been reported yet.',
                )
              else
                ..._sortDocuments(reports)
                    .take(4)
                    .map(
                      (doc) =>
                          IncidentCard(incident: doc.data(), isStaff: true),
                    ),
            ],
          );
        },
      ),
    );
  }
}

// ==================== CREATE INCIDENT ====================

class CreateIncidentScreen extends StatefulWidget {
  final String reporterName;

  const CreateIncidentScreen({super.key, required this.reporterName});

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = IncidentService.categories.first;
  XFile? _selectedImage;
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() => _selectedImage = image);
      }
    } catch (error) {
      _message(
        'Could not ${source == ImageSource.camera ? 'take' : 'select'} image: $error',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await IncidentService.uploadImage(_selectedImage!.path);
      }

      await IncidentService.createIncident(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        reporterName: widget.reporterName,
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      _message('Submission failed: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report an Incident')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Incident Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Incident title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an incident title';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: IncidentService.categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 7,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Describe what happened',
                hintText: 'Include where and when it happened...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Enter at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _chooseImageSource,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Take Photo or Choose from Gallery'),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_selectedImage!.path),
                  height: 190,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _selectedImage = null),
                child: const Text('Remove Photograph'),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Submit Incident'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== INCIDENT LIST AND FILTERS ====================

class IncidentListScreen extends StatefulWidget {
  final bool isStaff;

  const IncidentListScreen({super.key, required this.isStaff});

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  final _searchController = TextEditingController();

  String _categoryFilter = 'All';
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.isStaff
        ? IncidentService.allIncidents()
        : IncidentService.myIncidents();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isStaff ? 'Manage Incidents' : 'My Reports'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _EmptyState(
              message:
                  'Unable to load incidents. Check connection and permissions.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = _sortDocuments(snapshot.data?.docs ?? []);

          final filtered = documents.where((doc) {
            final data = doc.data();
            final query = _searchController.text.trim().toLowerCase();

            final title = data['title']?.toString().toLowerCase() ?? '';
            final reporter =
                data['reporterName']?.toString().toLowerCase() ?? '';

            final matchesSearch =
                title.contains(query) || reporter.contains(query);

            final matchesCategory =
                _categoryFilter == 'All' || data['category'] == _categoryFilter;

            final matchesStatus =
                _statusFilter == 'All' || data['status'] == _statusFilter;

            return matchesSearch && matchesCategory && matchesStatus;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search title or reporter...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _categoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: ['All', ...IncidentService.categories].map((
                          value,
                        ) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _categoryFilter = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: ['All', ...IncidentService.statuses].map((
                          value,
                        ) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _statusFilter = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${filtered.length} incident(s) found'),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyState(
                        message: 'No incidents match your filters.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return IncidentCard(
                            incident: filtered[index].data(),
                            isStaff: widget.isStaff,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==================== INCIDENT CARD ====================

class IncidentCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  final bool isStaff;

  const IncidentCard({
    super.key,
    required this.incident,
    required this.isStaff,
  });

  @override
  Widget build(BuildContext context) {
    final title = incident['title']?.toString() ?? 'Untitled';
    final category = incident['category']?.toString() ?? 'Other';
    final status = incident['status']?.toString() ?? 'submitted';
    final reporter = incident['reporterName']?.toString() ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: const Icon(Icons.report_outlined, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category),
              if (isStaff) Text('Reporter: $reporter'),
              const SizedBox(height: 5),
              _StatusChip(status: status),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  IncidentDetailsScreen(incident: incident, isStaff: isStaff),
            ),
          );
        },
      ),
    );
  }
}

// ==================== INCIDENT DETAILS ====================

class IncidentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> incident;
  final bool isStaff;

  const IncidentDetailsScreen({
    super.key,
    required this.incident,
    required this.isStaff,
  });

  Future<void> _changeStatus(BuildContext context, String status) async {
    try {
      await IncidentService.updateStatus(
        incidentId: incident['id'].toString(),
        status: status,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident status updated.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = incident['imageUrl'] as String?;
    final timestamp = incident['createdAt'] as Timestamp?;
    final date =
        timestamp?.toDate().toLocal().toString().split('.').first ??
        'Date unavailable';

    return Scaffold(
      appBar: AppBar(title: const Text('Incident Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            incident['title']?.toString() ?? 'Untitled incident',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _StatusChip(status: incident['status']?.toString() ?? 'submitted'),
          const SizedBox(height: 20),
          _DetailRow(
            label: 'Category',
            value: incident['category']?.toString() ?? 'Other',
          ),
          _DetailRow(
            label: 'Reported by',
            value: incident['reporterName']?.toString() ?? 'Unknown',
          ),
          _DetailRow(label: 'Date submitted', value: date),
          const SizedBox(height: 20),
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            incident['description']?.toString() ?? 'No description',
            style: const TextStyle(fontSize: 16),
          ),
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'Attached Photograph',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 230,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Unable to load photograph.');
                },
              ),
            ),
          ],
          if (isStaff) ...[
            const SizedBox(height: 28),
            const Text(
              'Manage Incident Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: incident['status']?.toString() ?? 'submitted',
              onChanged: (value) {
                if (value != null) {
                  _changeStatus(context, value);
                }
              },
              child: Column(
                children: IncidentService.statuses
                    .map(
                      (status) => RadioListTile<String>(
                        title: Text(_capitalize(status)),
                        value: status,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== REUSABLE WIDGETS ====================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status) {
      case 'resolved':
        color = Colors.green;
        break;
      case 'in progress':
        color = Colors.indigo;
        break;
      case 'under review':
        color = Colors.purple;
        break;
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(
        _capitalize(status),
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ==================== HELPERS ====================

List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortDocuments(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  final sorted = documents.toList();

  sorted.sort((a, b) {
    final aDate = a.data()['createdAt'] as Timestamp?;
    final bDate = b.data()['createdAt'] as Timestamp?;

    return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
      aDate?.millisecondsSinceEpoch ?? 0,
    );
  });

  return sorted;
}

String _capitalize(String value) {
  if (value.isEmpty) return value;

  return '${value[0].toUpperCase()}${value.substring(1)}';
}
