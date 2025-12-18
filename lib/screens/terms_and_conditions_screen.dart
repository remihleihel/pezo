import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
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
              '1. Acceptance of Terms',
              'By downloading, installing, or using Pezo ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App.',
            ),
            _buildSection(
              context,
              '2. Description of Service',
              'Pezo is a personal finance management application that allows you to:\n\n'
              '• Track income and expenses\n'
              '• Scan and extract data from receipts\n'
              '• Set budgets and financial goals\n'
              '• View spending analytics and insights\n'
              '• Get AI-powered purchase recommendations (optional)\n'
              '• Export your financial data\n\n'
              'The App is provided "as is" for personal use only.',
            ),
            _buildSection(
              context,
              '3. User Responsibilities',
              'You are responsible for:\n\n'
              '• Maintaining the accuracy of your financial data\n'
              '• Keeping your device secure and protected\n'
              '• Backing up your data regularly (using export features)\n'
              '• Using the App in compliance with applicable laws\n'
              '• Not using the App for any illegal or unauthorized purpose\n\n'
              'You acknowledge that you are solely responsible for your financial decisions and that the App provides tools and information, not financial advice.',
            ),
            _buildSection(
              context,
              '4. AI Analysis Disclaimer',
              'The optional AI-powered "Should I Buy It?" feature provides recommendations based on your financial data:\n\n'
              '• AI recommendations are for informational purposes only\n'
              '• They do not constitute financial, investment, or legal advice\n'
              '• We are not responsible for any financial decisions you make based on AI recommendations\n'
              '• AI analysis may not be accurate or suitable for your specific situation\n'
              '• You should consult with qualified financial advisors for important financial decisions\n\n'
              'By using AI features, you acknowledge and accept these limitations.',
            ),
            _buildSection(
              context,
              '5. Data and Privacy',
              '• Your data is stored locally on your device\n'
              '• We do not have access to your financial data\n'
              '• When using AI features, aggregated financial summaries are sent to third-party services (OpenAI via Cloudflare)\n'
              '• Individual transactions are never shared\n'
              '• Please review our Privacy Policy for detailed information about data handling\n\n'
              'You are responsible for maintaining backups of your data. We are not liable for data loss.',
            ),
            _buildSection(
              context,
              '6. Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW:\n\n'
              '• The App is provided "as is" without warranties of any kind\n'
              '• We do not guarantee the accuracy, completeness, or usefulness of any information\n'
              '• We are not liable for any financial losses or damages resulting from use of the App\n'
              '• We are not responsible for any errors, bugs, or interruptions in service\n'
              '• We are not liable for data loss, corruption, or unauthorized access\n\n'
              'Your use of the App is at your own risk.',
            ),
            _buildSection(
              context,
              '7. Intellectual Property',
              '• The App and its original content, features, and functionality are owned by us\n'
              '• You may not copy, modify, distribute, or create derivative works\n'
              '• Third-party services (Google ML Kit, OpenAI) have their own intellectual property rights\n'
              '• Receipt images and transaction data you create belong to you',
            ),
            _buildSection(
              context,
              '8. Prohibited Uses',
              'You agree not to:\n\n'
              '• Use the App for any unlawful purpose\n'
              '• Attempt to reverse engineer or decompile the App\n'
              '• Interfere with or disrupt the App\'s functionality\n'
              '• Use automated systems to access the App\n'
              '• Share your account with others\n'
              '• Use the App to store or transmit malicious code',
            ),
            _buildSection(
              context,
              '9. Service Modifications',
              'We reserve the right to:\n\n'
              '• Modify or discontinue the App at any time\n'
              '• Update features, remove features, or change functionality\n'
              '• Change these Terms and Conditions\n'
              '• Implement rate limits or usage restrictions\n\n'
              'We will attempt to notify users of significant changes, but are not obligated to do so.',
            ),
            _buildSection(
              context,
              '10. Termination',
              'You may stop using the App at any time by uninstalling it. We may terminate or suspend your access to the App at any time, with or without cause, with or without notice.',
            ),
            _buildSection(
              context,
              '11. Governing Law',
              'These Terms shall be governed by and construed in accordance with applicable local laws, without regard to conflict of law provisions.',
            ),
            _buildSection(
              context,
              '12. Changes to Terms',
              'We reserve the right to modify these Terms and Conditions at any time. We will update the "Last Updated" date when changes are made. Your continued use of the App after changes constitutes acceptance of the new terms.',
            ),
            _buildSection(
              context,
              '13. Contact Information',
              'If you have any questions about these Terms and Conditions, please contact us through the app\'s Help & Support section in Settings.',
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

