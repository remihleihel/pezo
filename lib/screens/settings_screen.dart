import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/database_provider.dart';
// import '../services/notification_service.dart';
import 'budget_screen.dart';
import 'export_screen.dart';
import 'account_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _budgetAlertsEnabled = true;
  bool _goalRemindersEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            'Account Management',
            [
              _buildSettingsTile(
                'Multiple Accounts',
                'Create and manage multiple accounts with separate data',
                Icons.people,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountManagementScreen()),
                ),
              ),
            ],
          ),
          _buildSection(
            'Data Management',
            [
              _buildSettingsTile(
                'Budget & Goals',
                'Set monthly budgets and spending goals',
                Icons.account_balance_wallet,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BudgetScreen()),
                ),
              ),
              _buildSettingsTile(
                'Export Data',
                'Export your transactions to various formats',
                Icons.download,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExportScreen()),
                ),
              ),
            ],
          ),
          _buildSection(
            'Notifications',
            [
              _buildSwitchTile(
                'Budget Alerts',
                'Get notified when approaching budget limits',
                Icons.notifications,
                _budgetAlertsEnabled,
                (value) => _updateBudgetAlerts(context, value),
              ),
              _buildSwitchTile(
                'Goal Reminders',
                'Reminders for spending goals',
                Icons.flag,
                _goalRemindersEnabled,
                (value) => _updateGoalReminders(context, value),
              ),
            ],
          ),
          _buildSection(
            'Privacy & Security',
            [
              _buildSettingsTile(
                'Data Privacy',
                'Manage your data privacy settings',
                Icons.privacy_tip,
                () => _showPrivacyDialog(context),
              ),
            ],
          ),
          _buildSection(
            'About',
            [
              _buildSettingsTile(
                'App Version',
                'Version 1.0.0',
                Icons.info,
                null,
              ),
              _buildSettingsTile(
                'Help & Support',
                'Get help and contact support',
                Icons.help,
                () => _showHelpDialog(context),
              ),
              _buildSettingsTile(
                'Rate App',
                'Rate us on the app store',
                Icons.star,
                () => _showRateDialog(context),
              ),
            ],
          ),
          _buildSection(
            'Danger Zone',
            [
              _buildSettingsTile(
                'Clear All Data',
                'Delete all transactions and settings',
                Icons.delete_forever,
                () => _showClearDataDialog(context),
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  void _updateBudgetAlerts(BuildContext context, bool value) async {
    setState(() {
      _budgetAlertsEnabled = value;
    });
    
    // TODO: Implement notifications when plugin is fixed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Budget alerts enabled!' : 'Budget alerts disabled.'),
        backgroundColor: value ? Colors.green : Colors.orange,
      ),
    );
  }

  void _updateGoalReminders(BuildContext context, bool value) async {
    setState(() {
      _goalRemindersEnabled = value;
    });
    
    // TODO: Implement notifications when plugin is fixed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Goal reminders enabled!' : 'Goal reminders disabled.'),
        backgroundColor: value ? Colors.green : Colors.orange,
      ),
    );
  }


  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Privacy'),
        content: const Text(
          'Your financial data is stored locally on your device and is never shared with third parties.\n\n'
          '• All data is encrypted\n'
          '• No cloud sync without your permission\n'
          '• Receipt images are stored locally only\n'
          '• You can export and delete your data anytime',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Need help? We\'re here for you!\n\n'
          '• FAQ and tutorials\n'
          '• Contact support team\n'
          '• Feature requests\n'
          '• Bug reports\n\n'
          'Email: support@spendingtracker.app',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening support email...')),
              );
            },
            child: const Text('Contact'),
          ),
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Our App'),
        content: const Text(
          'Enjoying Spending Tracker? We\'d love to hear from you!\n\n'
          'Your feedback helps us improve the app and reach more users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your support!')),
              );
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your transactions, budgets, and settings. This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );
  }

  void _clearAllData(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Clearing all data...'),
            ],
          ),
        ),
      );

      // Clear all data from database
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      await databaseProvider.clearAllData();

      // Refresh transaction provider
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.loadTransactions();

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data has been cleared successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

