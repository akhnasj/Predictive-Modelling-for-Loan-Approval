import 'dart:math';
import 'package:flutter/material.dart';

class EmiCalculatorPage extends StatefulWidget {
  const EmiCalculatorPage({super.key});

  @override
  _EmiCalculatorPageState createState() => _EmiCalculatorPageState();
}

class _EmiCalculatorPageState extends State<EmiCalculatorPage> {
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _loanTermController = TextEditingController();

  double emiResult = 0;

  void _calculateEMI() {
    double loanAmount = double.tryParse(_loanAmountController.text) ?? 0;
    double interestRate = double.tryParse(_interestRateController.text) ?? 0;
    int loanTerm = int.tryParse(_loanTermController.text) ?? 0;

    if (loanAmount <= 0 || interestRate <= 0 || loanTerm <= 0) {
      setState(() => emiResult = 0);
      return;
    }

    double monthlyInterestRate = (interestRate / 12) / 100;
    int months = loanTerm * 12;

    double emi = (loanAmount *
            monthlyInterestRate *
            pow(1 + monthlyInterestRate, months)) /
        (pow(1 + monthlyInterestRate, months) - 1);

    setState(() {
      emiResult = emi.isFinite ? emi : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EMI Calculator"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Calculate Your Monthly EMI",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTextField("Loan Amount (₹)", _loanAmountController),
            _buildTextField("Interest Rate (%)", _interestRateController),
            _buildTextField("Loan Term (Years)", _loanTermController),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).unfocus(); // Close the keyboard
                  _calculateEMI();
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text("Calculate EMI"),
              ),
            ),
            const SizedBox(height: 30),
            _buildEMIResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildEMIResult() {
    return Center(
      child: Column(
        children: [
          const Text("Your Estimated EMI",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Text(
            emiResult > 0
                ? "₹${emiResult.toStringAsFixed(2)}"
                : "Enter valid values",
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: emiResult > 0 ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _loanTermController.dispose();
    super.dispose();
  }
}
