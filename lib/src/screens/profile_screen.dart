import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_controller.dart';
import '../models/request_models.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_tiles.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badges.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _requestLabelController = TextEditingController();
  final _requestReasonController = TextEditingController();

  bool _loadingRequests = true;
  bool _submittingRequest = false;
  String? _requestError;
  String? _requestInfo;
  List<PackageRequestItem> _requests = const [];

  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _requestLabelController.dispose();
    _requestReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final user = controller.user;
    if (user == null) {
      return;
    }

    setState(() {
      _loadingRequests = true;
      _requestError = null;
    });

    try {
      final requests = user.isAdmin
          ? await controller.api.getPendingPackageRequests()
          : await controller.api.getMyPackageRequests();
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = requests;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _requestError = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _requestError = 'Could not load package requests.');
    } finally {
      if (mounted) {
        setState(() => _loadingRequests = false);
      }
    }
  }

  Future<void> _submitRequest() async {
    final requestedLabel = _requestLabelController.text.trim();
    final reason = _requestReasonController.text.trim();

    if (requestedLabel.isEmpty || reason.isEmpty) {
      setState(() => _requestError = 'Enter a label and a short request note.');
      return;
    }

    setState(() {
      _submittingRequest = true;
      _requestError = null;
      _requestInfo = null;
    });

    try {
      await controller.api.createPackageRequest(
        requestedLabel: requestedLabel,
        reason: reason,
      );
      if (!mounted) {
        return;
      }
      _requestLabelController.clear();
      _requestReasonController.clear();
      setState(() => _requestInfo = 'Package request sent to the admin team.');
      await _loadRequests();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _requestError = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _requestError = 'Could not submit the package request.');
    } finally {
      if (mounted) {
        setState(() => _submittingRequest = false);
      }
    }
  }

  Future<void> _approveRequest(PackageRequestItem request) async {
    final lfpController = TextEditingController();
    final supercapController = TextEditingController();
    final commentController = TextEditingController();

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve package request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: lfpController,
                decoration: const InputDecoration(
                  labelText: 'LFP BMS ID',
                  hintText: 'LFP-001',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: supercapController,
                decoration: const InputDecoration(
                  labelText: 'Supercap BMS ID',
                  hintText: 'SC-001',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Admin comment',
                  hintText: 'Optional note for the user',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (approved != true) {
      lfpController.dispose();
      supercapController.dispose();
      commentController.dispose();
      return;
    }

    try {
      await controller.api.approvePackageRequest(
        requestId: request.id,
        lfpBmsId: lfpController.text.trim(),
        supercapBmsId: supercapController.text.trim(),
        adminComment: commentController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _requestInfo = 'Package request approved.');
      await _loadRequests();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _requestError = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _requestError = 'Could not approve this package request.');
    } finally {
      lfpController.dispose();
      supercapController.dispose();
      commentController.dispose();
    }
  }

  Future<void> _rejectRequest(PackageRequestItem request) async {
    final commentController = TextEditingController();

    final rejected = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject package request'),
        content: TextField(
          controller: commentController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Admin comment',
            hintText: 'Optional reason for rejection',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (rejected != true) {
      commentController.dispose();
      return;
    }

    try {
      await controller.api.rejectPackageRequest(
        requestId: request.id,
        adminComment: commentController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _requestInfo = 'Package request rejected.');
      await _loadRequests();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _requestError = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _requestError = 'Could not reject this package request.');
    } finally {
      commentController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = controller.user;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppColors.ocean, AppColors.coral],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(user?.fullName),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Battery Pack User',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Account details',
          child: Column(
            children: [
              MetricRow(label: 'User ID', value: user?.id.toString() ?? '-'),
              MetricRow(label: 'Role', value: user?.role ?? '-'),
              MetricRow(
                label: 'Email verified',
                value: user?.emailVerified == true ? 'Yes' : 'No',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_requestInfo != null) ...[
          _InfoBanner(color: AppColors.success, message: _requestInfo!),
          const SizedBox(height: 16),
        ],
        if (_requestError != null) ...[
          _InfoBanner(color: AppColors.danger, message: _requestError!),
          const SizedBox(height: 16),
        ],
        if (user?.isAdmin == true) ...[
          SectionCard(
            title: 'Pending package requests',
            subtitle: 'Approve or reject requested battery-pack access.',
            action: IconButton(
              onPressed: _loadingRequests ? null : _loadRequests,
              icon: const Icon(Icons.refresh_rounded),
            ),
            child: _loadingRequests
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _requests.isEmpty
                ? const Text('There are no pending package requests right now.')
                : Column(
                    children: _requests
                        .map(
                          (request) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _AdminRequestCard(
                              request: request,
                              onApprove: () => _approveRequest(request),
                              onReject: () => _rejectRequest(request),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          SectionCard(
            title: 'Request a package',
            subtitle: 'Send a new package request for admin approval.',
            child: Column(
              children: [
                TextField(
                  controller: _requestLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Requested package label',
                    hintText: 'Field vehicle package',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _requestReasonController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Explain why you need this package assigned.',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submittingRequest ? null : _submitRequest,
                    icon: _submittingRequest
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _submittingRequest ? 'Sending...' : 'Request package',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Request history',
            subtitle: 'Track the status of your package requests.',
            action: IconButton(
              onPressed: _loadingRequests ? null : _loadRequests,
              icon: const Icon(Icons.refresh_rounded),
            ),
            child: _loadingRequests
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _requests.isEmpty
                ? const Text('You have not submitted any package requests yet.')
                : Column(
                    children: _requests
                        .map(
                          (request) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _RequestHistoryCard(request: request),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 16),
        ],
        FilledButton.icon(
          onPressed: controller.logout,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.ink,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }

  String _initials(String? name) {
    final cleaned = (name ?? '').trim();
    if (cleaned.isEmpty) {
      return 'BP';
    }

    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final letters = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return letters.isEmpty ? 'BP' : letters;
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.color, required this.message});

  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
      ),
    );
  }
}

class _RequestHistoryCard extends StatelessWidget {
  const _RequestHistoryCard({required this.request});

  final PackageRequestItem request;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.displayLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusBadge(
                label: request.status,
                color: _requestStatusColor(request.status),
              ),
            ],
          ),
          if ((request.reason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(request.reason!),
          ],
          const SizedBox(height: 12),
          Text(
            'Requested ${_formatDateTime(request.requestedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if ((request.adminComment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Admin note: ${request.adminComment!}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  const _AdminRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final PackageRequestItem request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final user = request.user;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.displayLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusBadge(
                label: request.status,
                color: _requestStatusColor(request.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user == null
                ? 'Unknown requester'
                : '${user.fullName}  ${user.email}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if ((request.reason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(request.reason!),
          ],
          const SizedBox(height: 12),
          Text(
            'Requested ${_formatDateTime(request.requestedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _requestStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
      return AppColors.success;
    case 'REJECTED':
      return AppColors.danger;
    default:
      return AppColors.warning;
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'recently';
  }

  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day at $hour:$minute';
}
