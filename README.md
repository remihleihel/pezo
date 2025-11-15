# Pezo 📱💰

A comprehensive Flutter app for tracking your spending with intelligent receipt scanning capabilities. Keep track of your income and expenses, scan receipts automatically, and get insights into your spending patterns.

## ✨ Features

### Core Functionality
- **Income & Expense Tracking**: Add and categorize your financial transactions
- **Receipt Scanning**: Take photos of receipts and automatically extract transaction details
- **Smart OCR**: Uses Google ML Kit to extract text from receipt images
- **AI-Powered Parsing**: Automatically detects amounts, merchants, and categories
- **Local Storage**: All data stored securely on your device using SQLite

### Analytics & Insights
- **Spending Analytics**: Visual charts and graphs of your spending patterns
- **Category Breakdown**: See where your money goes with detailed category analysis
- **Monthly Trends**: Track your spending over time
- **Smart Insights**: Get personalized spending recommendations and alerts

### Budget Management
- **Monthly Budgets**: Set spending limits for different categories
- **Spending Goals**: Create and track financial goals
- **Budget Alerts**: Get notified when approaching budget limits
- **Progress Tracking**: Visual progress indicators for your goals

### Additional Features
- **Data Export**: Export your data in JSON, CSV, or PDF formats
- **Cross-Platform**: Works on both iOS and Android
- **Dark Mode**: Beautiful dark and light themes
- **Privacy-First**: All data stays on your device
- **Receipt History**: Keep track of scanned receipts with images

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / Xcode for mobile development
- Camera permissions for receipt scanning

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd pezo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (if needed)**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Platform Setup

#### Android
- Minimum SDK version: 21
- Camera permissions are automatically requested
- No additional setup required

#### iOS
- Minimum iOS version: 11.0
- Camera and photo library permissions are configured
- No additional setup required

## 📱 Usage

### Adding Transactions
1. **Manual Entry**: Use the "Add Income" or "Add Expense" buttons
2. **Receipt Scanning**: 
   - Tap the camera icon
   - Point camera at receipt
   - App automatically extracts amount, merchant, and category
   - Review and confirm the details

### Viewing Analytics
- Navigate to the Analytics tab
- View spending trends, category breakdowns, and insights
- Filter by different time periods (week, month, year)

### Setting Budgets
- Go to Settings > Budget & Goals
- Set monthly spending limits for categories
- Create spending goals with target amounts and dates
- Track progress with visual indicators

## 🛠️ Technical Details

### Architecture
- **State Management**: Provider pattern for reactive UI updates
- **Database**: SQLite for local data persistence
- **Image Processing**: Google ML Kit for OCR functionality
- **Charts**: FL Chart for beautiful data visualizations

### Key Dependencies
- `provider`: State management
- `sqflite`: Local database
- `camera`: Camera functionality
- `google_mlkit_text_recognition`: OCR processing
- `fl_chart`: Data visualization
- `image_picker`: Image selection
- `intl`: Date formatting

### Data Models
- **Transaction**: Core transaction data with receipt support
- **ReceiptData**: Extracted receipt information
- **Budget**: Monthly budget tracking
- **SpendingGoal**: Financial goal management

## 🔒 Privacy & Security

- **Local Storage**: All data is stored locally on your device
- **No Cloud Sync**: Your financial data never leaves your device
- **Encrypted Storage**: Sensitive data is encrypted at rest
- **Permission-Based**: Only requests necessary camera and storage permissions

## 🎨 UI/UX Features

- **Material Design 3**: Modern, beautiful interface
- **Responsive Design**: Works on phones and tablets
- **Accessibility**: Screen reader support and high contrast
- **Customizable**: Dark/light theme support
- **Intuitive Navigation**: Bottom navigation with clear sections

## 📊 Analytics Features

### Spending Insights
- Top spending categories
- Monthly spending trends
- Budget vs actual spending
- Receipt scanning usage statistics

### Smart Recommendations
- Spending pattern analysis
- Budget optimization suggestions
- Goal achievement tracking
- Expense reduction tips

## 🔮 Surprise Features

1. **Smart Category Detection**: AI automatically suggests categories based on merchant names
2. **Spending Pattern Recognition**: Identifies your spending habits and trends
3. **Goal Achievement Celebrations**: Fun animations when you reach financial goals
4. **Export Capabilities**: Multiple format support for data portability
5. **Budget Alerts**: Proactive notifications for budget management
6. **Receipt Image Storage**: Keep photos of receipts for record-keeping
7. **Cross-Device Sync**: (Future feature) Sync data across multiple devices

## 🤝 Contributing

We welcome contributions! Please feel free to submit issues and pull requests.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Google ML Kit for OCR capabilities
- Flutter team for the amazing framework
- FL Chart for beautiful data visualizations
- The open-source community for inspiration and tools

## 📞 Support

If you encounter any issues or have questions:
- Check the FAQ in the app settings
- Submit an issue on GitHub
- Contact support at support@spendingtracker.app

---

**Happy Spending Tracking! 💰📱**

