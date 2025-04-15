import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';
import 'package:intl/intl.dart'; // Import the intl package

class LoanHistoryPage extends StatefulWidget {
  const LoanHistoryPage({super.key});

  @override
  State<LoanHistoryPage> createState() => _LoanHistoryPageState();
}

class _LoanHistoryPageState extends State<LoanHistoryPage> {
  List<Map<String, dynamic>> loanHistory = [];
  String filterStatus = "All";
  String? userId;

  @override
  void initState() {
    super.initState();
    // Initialize Firebase (if needed)
    Firebase.initializeApp().then((_) {
      fetchUserId();
    });
  }

  // Fetch the current logged-in user's UID
  Future<void> fetchUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      fetchLoanHistory();
    }
  }

  // Fetch loan history data from Firestore for the logged-in user
  Future<void> fetchLoanHistory() async {
    if (userId == null) return; // Ensure the user ID is not null

    final loanSnapshot = await FirebaseFirestore.instance
        .collection('loan_details')
        .where('uid', isEqualTo: userId) // Filter by logged-in user's UID
        .get();

    List<Map<String, dynamic>> fetchedLoanHistory =
        loanSnapshot.docs.map((doc) {
      DateTime startDate = DateTime.parse(doc['StartDate']);
      int loanTerm = doc['LoanTerm'];
      DateTime endDate = startDate.add(Duration(
          days: loanTerm * 30)); // Assuming 30 days in a month for simplicity

      String status = _calculateLoanStatus(endDate);

      return {
        "date": doc['StartDate'],
        "amount": doc['LoanAmount'].toDouble(),
        "status": status,
        "interestRate": doc['InterestRate'].toDouble(),
        "tenure": doc['LoanTerm'],
        "loanType": doc['LoanPurpose'],
        "expanded": false,
      };
    }).toList();

    // Only update state when the data has been fetched
    if (mounted) {
      setState(() {
        loanHistory = fetchedLoanHistory;
      });
    }
  }

  // Determine if the loan is 'Paid' or 'Ongoing'
  String _calculateLoanStatus(DateTime endDate) {
    DateTime currentDate = DateTime.now();
    if (currentDate.isAfter(endDate)) {
      return "Paid";
    } else {
      return "Ongoing";
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredLoans = filterStatus == "All"
        ? loanHistory
        : loanHistory.where((loan) => loan['status'] == filterStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan History"),
        backgroundColor: Colors.deepPurple,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => filterStatus = value),
            itemBuilder: (context) => ["All", "Paid", "Ongoing"]
                .map((status) =>
                    PopupMenuItem(value: status, child: Text(status)))
                .toList(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 20),
            Expanded(child: _buildLoanList(filteredLoans)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    double totalLoanAmount =
        loanHistory.fold(0, (sum, loan) => sum + (loan["amount"] as double));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      color: Colors.deepPurple.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Loan Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildSummaryRow("Total Loans", "${loanHistory.length}"),
            _buildSummaryRow("Total Amount Borrowed",
                "₹${totalLoanAmount.toStringAsFixed(0)}"),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple)),
        ],
      ),
    );
  }

  Widget _buildLoanList(List<Map<String, dynamic>> loans) {
    return ListView.builder(
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              ListTile(
                leading:
                    const Icon(Icons.account_balance, color: Colors.deepPurple),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${loan['loanType']} Loan",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Date: ${_formatDate(loan['date'])}",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                subtitle: Text("Amount: ₹${loan['amount']}"),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      loan['status'] == "Paid"
                          ? Icons.check_circle
                          : Icons.pending,
                      color:
                          loan['status'] == "Paid" ? Colors.green : Colors.red,
                    ),
                    Text(
                      loan['status'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: loan['status'] == "Paid"
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  setState(() => loan['expanded'] = !loan['expanded']);
                },
              ),
              if (loan['expanded'])
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(Icons.percent, "Interest Rate",
                          "${loan['interestRate']}%"),
                      _buildDetailRow(Icons.schedule, "Loan Tenure",
                          "${loan['tenure']} months"),
                      _buildDetailRow(Icons.money, "EMI",
                          "₹${_calculateEMI(loan['amount'], loan['interestRate'], loan['tenure']).toStringAsFixed(2)}"),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  String _formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    return "${date.day}-${date.month}-${date.year}"; // format as dd-mm-yyyy
  }

  double _calculateEMI(double principal, double rate, int tenure) {
    double monthlyRate = rate / 12 / 100;
    return (principal * monthlyRate * pow(1 + monthlyRate, tenure.toDouble())) /
        (pow(1 + monthlyRate, tenure.toDouble()) - 1);
  }
}
