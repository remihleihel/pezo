import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Introduction',
              'Pezo ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
            ),
            _buildSection(
              context,
              '2. Information We Collect',
              'Pezo is designed with privacy in mind. We collect and store the following information:\n\n'
              '• Financial Transactions: Income and expense records you manually enter or scan from receipts\n'
              '• Receipt Images: Photos of receipts you choose to scan (stored locally on your device)\n'
              '• Budgets and Goals: Financial goals and budget limits you set\n'
              '• Account Information: Multiple account profiles you create (if using multi-account feature)\n\n'
              'All data is stored locally on your device using SQLite database. We do not collect personal identification information such as your name, email address, or phone number unless you explicitly provide it.',
            ),
            _buildSection(
              context,
              '3. How We Use Your Information',
              'Your data is used solely to provide the app\'s functionality:\n\n'
              '• Track and categorize your income and expenses\n'
              '• Generate spending analytics and insights\n'
              '• Manage budgets and financial goals\n'
              '• Provide receipt scanning and OCR capabilities\n'
              '• Enable data export features\n\n'
              'We do not sell, rent, or share your financial data with third parties for marketing or advertising purposes.',
            ),
            _buildSection(
              context,
              '4. AI-Powered Analysis (Optional)',
              'Pezo offers an optional AI-powered "Should I Buy It?" feature that provides purchase recommendations:\n\n'
              '• When you choose to use AI analysis, aggregated financial data (balance, income, spending patterns, category totals) is sent to OpenAI via our secure Cloudflare Worker\n'
              '• Individual transactions are NEVER sent - only summarized financial snapshots\n'
              '• OpenAI does not store your data per their privacy policy\n'
              '• AI analysis is rate-limited to 3 requests per day per user\n'
              '• You can choose to use offline calculations only and never use AI features\n'
              '• AI responses are cached locally for 7 days to reduce API calls\n\n'
              'You have full control over AI usage through the analysis mode selection in the app.',
            ),
            _buildSection(
              context,
              '5. Data Storage and Security',
              '• All data is stored locally on your device using SQLite database\n'
              '• Receipt images are stored in your device\'s local storage\n'
              '• Data is encrypted at rest using platform security features\n'
              '• We do not use cloud storage or cloud synchronization\n'
              '• Your data never leaves your device unless you explicitly export it\n\n'
              'We implement industry-standard security measures to protect your data, but no method of transmission or storage is 100% secure.',
            ),
            _buildSection(
              context,
              '6. Third-Party Services',
              'Pezo uses the following third-party services:\n\n'
              '• Google ML Kit: For receipt text recognition (OCR). Text recognition happens on-device.\n'
              '• OpenAI (via Cloudflare Worker): For optional AI purchase analysis. Only used when you explicitly choose AI analysis mode.\n'
              '• Cloudflare Workers: Secure proxy service for AI requests. Does not store your data.\n\n'
              'These services have their own privacy policies. We recommend reviewing them:\n'
              '• Google ML Kit: https://developers.google.com/ml-kit/terms\n'
              '• OpenAI: https://openai.com/policies/privacy-policy',
            ),
            _buildSection(
              context,
              '7. Your Rights and Choices',
              'You have complete control over your data:\n\n'
              '• Access: View all your transactions, budgets, and goals within the app\n'
              '• Export: Export your data in JSON, CSV, or PDF formats\n'
              '• Delete: Delete individual transactions or clear all data from Settings\n'
              '• AI Control: Choose to never use AI features, use them automatically for borderline cases, or always use them\n'
              '• Account Management: Create, switch, or delete multiple accounts\n\n'
              'You can manage your privacy preferences in the app Settings.',
            ),
            _buildSection(
              context,
              '8. Data Retention',
              '• Your data is stored on your device until you delete it\n'
              '• When you delete transactions or clear data, it is permanently removed from your device\n'
              '• We do not retain copies of deleted data\n'
              '• AI analysis cache expires after 7 days automatically\n\n'
              'If you uninstall the app, all local data is removed with the app.',
            ),
            _buildSection(
              context,
              '9. Children\'s Privacy',
              'Pezo is not intended for children under 13 years of age. We do not knowingly collect personal information from children. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
            ),
            _buildSection(
              context,
              '10. Changes to This Privacy Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last Updated" date at the top of this policy. You are advised to review this Privacy Policy periodically for any changes.',
            ),
            _buildSection(
              context,
              '11. Contact Us',
              'If you have any questions about this Privacy Policy or our data practices, please contact us through the app\'s Help & Support section in Settings.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : null,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[200] : null,
                ),
          ),
        ],
      ),
    );
  }
}

