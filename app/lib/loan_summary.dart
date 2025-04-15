import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Pie Chart Package
import 'package:cloud_firestore/cloud_firestore.dart';

class LoanSummaryPage extends StatefulWidget {
  final List<String> loanIds;
  const LoanSummaryPage({super.key, required this.loanIds});

  @override
  State<LoanSummaryPage> createState() => _LoanSummaryPageState();
}

class _LoanSummaryPageState extends State<LoanSummaryPage> {
  List<Map<String, dynamic>> loanDetails = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLoanDetails();
  }

  Future<void> fetchLoanDetails() async {
    List<Map<String, dynamic>> fetchedLoans = [];
    DateTime today = DateTime.now();

    for (String loanId in widget.loanIds) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('loan_details')
          .doc(loanId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> loanData = doc.data() as Map<String, dynamic>;

        // Extract Loan Start Date and Tenure
        String? startDateStr = loanData['StartDate']; // Updated field name
        int tenureMonths = (loanData['LoanTerm'] ?? 0).toInt();

        if (startDateStr != null && tenureMonths > 0) {
          DateTime startDate = DateTime.parse(startDateStr);
          DateTime loanEndDate =
              startDate.add(Duration(days: tenureMonths * 30));

          // Check if the loan is still ongoing
          if (loanEndDate.isAfter(today)) {
            fetchedLoans.add(loanData);
          }
        }
      }
    }

    setState(() {
      loanDetails = fetchedLoans;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Summary"),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loanDetails.isEmpty
              ? const Center(child: Text("No loans found."))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: loanDetails
                          .map((loan) => _buildLoanCard(loan))
                          .toList(),
                    ),
                  ),
                ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    double totalLoan = (loan['LoanAmount'] ?? 0).toDouble();
    double interestRate = (loan['InterestRate'] ?? 0).toDouble();
    int tenureMonths = (loan['LoanTerm'] ?? 0).toInt();
    String loanType = loan['LoanPurpose'] ?? "Unknown";
    String lender = loan['BankName'] ?? "Unknown";
    double monthlyEMI = totalLoan / tenureMonths;
    double interestPaid = totalLoan * (interestRate / 100);
    double remainingBalance = totalLoan * 0.4; // Adjust based on repayment data
    double principalPaid = totalLoan - remainingBalance;

    bool isPaidOff = remainingBalance == 0; // Check if loan is fully paid

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: isPaidOff ? Colors.green[100] : Colors.red[100], // Color Coding
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLoanDetailsCard(
                lender, loanType, interestRate, tenureMonths, isPaidOff),
            const SizedBox(height: 20),
            _buildFinancialSummaryCard(
                totalLoan, remainingBalance, monthlyEMI, isPaidOff),
            const SizedBox(height: 20),
            _buildPieChart(principalPaid, remainingBalance),
            const SizedBox(height: 20),
            _buildBreakdownSection(principalPaid, interestPaid),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetailsCard(String lender, String loanType,
      double interestRate, int tenureMonths, bool isPaidOff) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Loan Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildSummaryRow(Icons.business, "Lender", lender),
            _buildSummaryRow(Icons.credit_card, "Loan Type", loanType),
            _buildSummaryRow(Icons.percent, "Interest Rate",
                "${interestRate.toStringAsFixed(2)}%"),
            _buildSummaryRow(
                Icons.schedule, "Loan Tenure", "$tenureMonths months"),
            _buildSummaryRow(
              isPaidOff ? Icons.check_circle : Icons.warning,
              "Status",
              isPaidOff ? "Paid in Full" : "Ongoing",
              isPaidOff ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard(double totalLoan, double remainingBalance,
      double monthlyEMI, bool isPaidOff) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: isPaidOff ? Colors.green[100] : Colors.red[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Financial Summary",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildSummaryRow(Icons.monetization_on, "Total Loan",
                "₹${totalLoan.toStringAsFixed(0)}"),
            _buildSummaryRow(Icons.account_balance_wallet, "Remaining Balance",
                "₹${remainingBalance.toStringAsFixed(0)}"),
            _buildSummaryRow(Icons.payments, "Monthly EMI",
                "₹${monthlyEMI.toStringAsFixed(0)}"),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String value,
      [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.deepPurple),
          const SizedBox(width: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.deepPurple)),
        ],
      ),
    );
  }

  Widget _buildPieChart(double principalPaid, double remainingBalance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Repayment Progress",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: principalPaid,
                  color: Colors.green,
                  radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                PieChartSectionData(
                  value: remainingBalance,
                  color: Colors.red,
                  radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegend(Colors.green, "Paid"),
            const SizedBox(width: 20),
            _buildLegend(Colors.red, "Remaining"),
          ],
        ),
      ],
    );
  }

// Helper function to build legend items
  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildBreakdownSection(double principalPaid, double interestPaid) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Breakdown",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildSummaryRow(Icons.account_balance, "Principal Paid",
                "₹${principalPaid.toStringAsFixed(0)}"),
            _buildSummaryRow(Icons.attach_money, "Interest Paid",
                "₹${interestPaid.toStringAsFixed(0)}"),
          ],
        ),
      ),
    );
  }
}
