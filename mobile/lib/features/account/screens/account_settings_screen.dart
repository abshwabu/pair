import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/auth_state.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/auth/services/auth_service.dart';
import 'package:pair/features/onboarding/services/profile_service.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  bool _isDeleting = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text;
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'All password fields are required.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _error = null;
      _success = null;
    });

    try {
      await ref.read(profileServiceProvider).updatePassword(
            currentPassword: current,
            password: password,
            passwordConfirmation: confirm,
          );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _isChangingPassword = false;
        _success = 'Password updated successfully.';
      });
    } on ApiException catch (e) {
      setState(() {
        _isChangingPassword = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _isChangingPassword = false;
        _error = 'Unable to update password.';
      });
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account, dissolves active pods, '
          'and removes your data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
      _error = null;
      _success = null;
    });

    try {
      await ref.read(profileServiceProvider).deleteAccount();
      await ref.read(authServiceProvider).clearToken();
      if (!mounted) return;
      notifyAuthChanged(ref);
      context.go(AppRoutes.login);
    } on ApiException catch (e) {
      setState(() {
        _isDeleting = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _isDeleting = false;
        _error = 'Unable to delete account.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = _isChangingPassword || _isDeleting;

    return Scaffold(
      appBar: AppBar(title: const Text('Account settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Change password', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                      ),
                      enabled: !isBusy,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                      ),
                      enabled: !isBusy,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                      ),
                      enabled: !isBusy,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Update password',
                      isLoading: _isChangingPassword,
                      onPressed: isBusy ? null : _changePassword,
                    ),
                  ],
                ),
              ),
            ),
            if (_success != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _success!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text('Danger zone', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text(
                  'Delete account',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: const Text('Permanently remove your account and data'),
                enabled: !isBusy,
                onTap: _isDeleting ? null : _confirmDeleteAccount,
                trailing: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
