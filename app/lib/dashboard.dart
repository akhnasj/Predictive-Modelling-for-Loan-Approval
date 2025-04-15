import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loan_approval.dart';
import 'emi_calculator.dart';
import 'loan_summary.dart';
import 'loan_repayment.dart';
import 'loan_history.dart';
import 'edit_profile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<List<String>> _getLoanIds() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('loan_details')
        .where('uid', isEqualTo: userId) // Ensure 'uid' field matches Firestore
        .get();

    return querySnapshot.docs.map((doc) => doc.id).toList(); // Get all loan IDs
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.deepPurple,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _buildDashboardOption(context, "Loan Approval", Icons.assignment,
              const LoanApprovalPage()),
          _buildDashboardOption(context, "EMI Calculator", Icons.calculate,
              const EmiCalculatorPage()),
          GestureDetector(
            onTap: () async {
              List<String> loanIds = await _getLoanIds();
              if (loanIds.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LoanSummaryPage(loanIds: loanIds)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No loans found for this user")),
                );
              }
            },
            child: _buildDashboardCard("Loan Summary", Icons.list),
          ),
          GestureDetector(
            onTap: () async {
              List<String> loanIds = await _getLoanIds();
              if (loanIds.isNotEmpty) {
                // Pass the first loanId or show a selection list to choose a loan
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LoanRepaymentPage(
                          loanId: loanIds.first)), // pass the loanId
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No loans found for this user")),
                );
              }
            },
            child: _buildDashboardCard("Loan Repayment", Icons.payment),
          ),
          _buildDashboardOption(
              context, "Loan History", Icons.history, const LoanHistoryPage()),
          _buildDashboardOption(
              context, "Edit Profile", Icons.person, const EditProfilePage()),
        ],
      ),
    );
  }

  Widget _buildDashboardOption(
      BuildContext context, String title, IconData icon, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: _buildDashboardCard(title, icon),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.deepPurple),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
