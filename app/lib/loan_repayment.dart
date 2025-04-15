import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class LoanRepaymentPage extends StatefulWidget {
  final String loanId; // Loan ID to fetch data

  const LoanRepaymentPage({super.key, required this.loanId});

  @override
  _LoanRepaymentPageState createState() => _LoanRepaymentPageState();
}

class _LoanRepaymentPageState extends State<LoanRepaymentPage> {
  double totalLoan = 0;
  double remainingBalance = 0;
  double paidAmount = 0;
  double monthlyEMI = 0;
  DateTime loanStartDate = DateTime.now();
  DateTime loanEndDate = DateTime.now();
  DateTime nextEmiDate = DateTime.now();

  bool isLoading = true;
  double progress = 0.0;
  List<DateTime> upcomingEMIs = [];

  @override
  void initState() {
    super.initState();
    fetchLoanDetails();
  }

  Future<void> fetchLoanDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('loan_details')
          .doc(widget.loanId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> loanData = doc.data() as Map<String, dynamic>;

        // Extract data safely
        double loanAmount = (loanData['LoanAmount'] ?? 0).toDouble();
        int tenureMonths = (loanData['LoanTerm'] ?? 0).toInt();
        String startDateStr = loanData['StartDate'] ?? "";
        double interestRate = (loanData['InterestRate'] ?? 0).toDouble();

        // Convert start date
        DateTime startDate = DateTime.parse(startDateStr);

        // Convert interest rate to monthly rate
        double r = interestRate / (12 * 100); // Monthly interest rate
        int n = tenureMonths;

        // Calculate EMI using the formula
        double emi = (loanAmount * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);

        // Estimate paid amount (assuming payments started on startDate)
        int monthsElapsed = DateTime.now().difference(startDate).inDays ~/ 30;
        double paidAmt = (monthsElapsed * emi).clamp(0, loanAmount);

        // Estimate remaining balance
        double remainingAmt = (loanAmount - paidAmt).clamp(0, loanAmount);

        // Projected end date calculation (startDate + loan term in months)
        DateTime endDate = DateTime(
          startDate.year,
          startDate.month + tenureMonths,
          startDate.day,
        );

        // Adjust the end date in case the month overflows (i.e., if the month number goes above 12)
        while (endDate.month > 12) {
          endDate = DateTime(endDate.year + 1, endDate.month - 12, endDate.day);
        }

        // Calculate next EMI date (same day of the next month)
        DateTime emiDate = (DateTime.now().day < startDate.day)
            ? DateTime(
                DateTime.now().year, DateTime.now().month + 1, startDate.day)
            : DateTime(
                DateTime.now().year, DateTime.now().month + 1, startDate.day);

        // Calculate upcoming EMI dates for the next 6 months
        List<DateTime> emiDates = [];
        for (int i = 0; i < 6; i++) {
          emiDates.add(emiDate.add(Duration(
              days: 30 * i))); // Add 30 days each time for EMI calculation
        }

        setState(() {
          totalLoan = loanAmount;
          remainingBalance = remainingAmt;
          paidAmount = paidAmt;
          monthlyEMI = emi;
          loanStartDate = startDate;
          loanEndDate = endDate;
          nextEmiDate = emiDate;
          progress = calculateProgress();
          upcomingEMIs = emiDates;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching loan details: $e");
      setState(() => isLoading = false);
    }
  }

  double calculateProgress() {
    int totalMonths = loanEndDate.difference(loanStartDate).inDays ~/ 30;
    int monthsElapsed = DateTime.now().difference(loanStartDate).inDays ~/ 30;
    return (monthsElapsed / totalMonths).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Repayment Progress"),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLoanTimeline(),
                  const SizedBox(height: 20),
                  _buildProgressBar(),
                  const SizedBox(height: 20),
                  _buildDueDateHighlight(),
                  const SizedBox(height: 20),
                  _buildUpcomingEMIs(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoanTimeline() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Loan Timeline",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildSummaryRow(Icons.date_range, "Loan Start Date",
                DateFormat('dd MMM yyyy').format(loanStartDate)),
            _buildSummaryRow(Icons.event, "Next EMI Due Date",
                DateFormat('dd MMM yyyy').format(nextEmiDate)),
            _buildSummaryRow(Icons.calendar_today, "Projected End Date",
                DateFormat('dd MMM yyyy').format(loanEndDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Repayment Progress",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 10),
            Text(
              "Progress: ${(progress * 100).toStringAsFixed(1)}%",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateHighlight() {
    int daysLeft = nextEmiDate.difference(DateTime.now()).inDays;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.orangeAccent,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Next EMI Due Date",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  DateFormat('dd MMM yyyy').format(nextEmiDate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Text(
              "$daysLeft days left",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple)),
        ],
      ),
    );
  }

  Widget _buildUpcomingEMIs() {
    int monthsLeft = (remainingBalance / monthlyEMI).ceil();
    DateTime currentDate = DateTime.now();

    // If there are no upcoming EMIs, don't show the schedule.
    if (monthsLeft <= 0) {
      return const SizedBox(); // Empty widget (no upcoming EMIs).
    }

    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Upcoming EMI Schedule",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: monthsLeft,
                  itemBuilder: (context, index) {
                    DateTime emiDate = DateTime(
                        currentDate.year, currentDate.month + index + 1, 1);
                    return ListTile(
                      leading: Icon(
                        Icons.calendar_today,
                        color: index == 0 ? Colors.orange : Colors.deepPurple,
                      ),
                      title: Text("${DateFormat('MMMM yyyy').format(emiDate)}"),
                      subtitle: Text(index == 0 ? "Due Soon" : "Upcoming",
                          style: TextStyle(
                              color: index == 0 ? Colors.orange : Colors.grey)),
                      // trailing: Text(
                      //   "₹${monthlyEMI.toStringAsFixed(0)}",
                      //   style: const TextStyle(
                      //       fontWeight: FontWeight.bold,
                      //       color: Colors.deepPurple),
                      // ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
