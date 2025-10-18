import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';
import '../models/account.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isCreatingAccount = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createLocalAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreatingAccount = true;
    });

    try {
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);
      final account = await accountProvider.createLocalAccount(_nameController.text);
      
      // Switch to the new account
      await accountProvider.switchAccount(account);
      
      _nameController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account "${account.name}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingAccount = false;
        });
      }
    }
  }

  Future<void> _switchAccount(Account account) async {
    try {
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);
      await accountProvider.switchAccount(account);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to "${account.name}"'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"? This action cannot be undone and will permanently delete all data associated with this account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final accountProvider = Provider.of<AccountProvider>(context, listen: false);
        await accountProvider.deleteAccount(account);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account "${account.name}" deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AccountProvider>(
        builder: (context, accountProvider, child) {
          if (accountProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current Account Card
                if (accountProvider.currentAccount != null) ...[
                  Card(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.green.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_circle,
                                color: Theme.of(context).primaryColor,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Account',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      accountProvider.currentAccount!.name,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (accountProvider.currentAccount!.hasGoogleBackup)
                                Icon(
                                  Icons.cloud_done,
                                  color: Colors.green,
                                  size: 24,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Created: ${DateFormat('MMM dd, yyyy').format(accountProvider.currentAccount!.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Last accessed: ${DateFormat('MMM dd, yyyy').format(accountProvider.currentAccount!.lastAccessed)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Create New Account Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Account',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Account Name',
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g., Personal, Business, Family',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter an account name';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Account name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isCreatingAccount ? null : _createLocalAccount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: _isCreatingAccount
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Creating...'),
                                          ],
                                        )
                                      : const Text(
                                          'Create Local Account',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // All Accounts Section
                if (accountProvider.accounts.isNotEmpty) ...[
                  Text(
                    'All Accounts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...accountProvider.accounts.map((account) {
                    final isCurrentAccount = accountProvider.currentAccount?.id == account.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Theme.of(context).cardTheme.color,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrentAccount 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey,
                          child: Icon(
                            Icons.account_circle,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          account.name,
                          style: TextStyle(
                            fontWeight: isCurrentAccount ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (account.email != null) Text(account.email!),
                            Text(
                              'Created: ${DateFormat('MMM dd, yyyy').format(account.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (account.hasGoogleBackup)
                              Icon(
                                Icons.cloud_done,
                                color: Colors.green,
                                size: 20,
                              ),
                            if (!isCurrentAccount) ...[
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'switch':
                                      _switchAccount(account);
                                      break;
                                    case 'delete':
                                      _deleteAccount(account);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'switch',
                                    child: Row(
                                      children: [
                                        Icon(Icons.swap_horiz),
                                        SizedBox(width: 8),
                                        Text('Switch to this account'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete account', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        onTap: !isCurrentAccount ? () => _switchAccount(account) : null,
                      ),
                    );
                  }).toList(),
                ],

                // Info Section
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'About Multiple Accounts',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Each account has completely separate data storage\n'
                          '• Switch between accounts to access different financial data\n'
                          '• Local accounts store data only on this device\n'
                          '• Google accounts can backup data to Google Drive',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
