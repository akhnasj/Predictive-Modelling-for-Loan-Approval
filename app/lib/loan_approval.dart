import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Ensure Firebase is initialized
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LoanApprovalApp());
}

class LoanApprovalApp extends StatelessWidget {
  const LoanApprovalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loan Approval System',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.blueGrey[50],
      ),
      home: const LoanApprovalPage(),
    );
  }
}

class LoanApprovalPage extends StatefulWidget {
  const LoanApprovalPage({super.key});

  @override
  _LoanApprovalState createState() => _LoanApprovalState();
}

class _LoanApprovalState extends State<LoanApprovalPage> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();
  final TextEditingController loanAmountController = TextEditingController();
  final TextEditingController creditScoreController = TextEditingController();
  final TextEditingController monthsEmployedController =
      TextEditingController();
  final TextEditingController numCreditLinesController =
      TextEditingController();
  final TextEditingController interestRateController = TextEditingController();
  final TextEditingController loanTermController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();

  String education = "Bachelor's";
  String employmentType = "Full-time";
  String maritalStatus = "Single";
  String hasMortgage = "No";
  String hasDependents = "No";
  String loanPurpose = "Home";
  String hasCoSigner = "No";
  String defaultStatus = "No";
  String resultMessage = "";
  DateTime? startDate;

  Future<void> checkLoanApproval() async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.47.104:8000/predict"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Age": int.parse(ageController.text),
          "Income": int.parse(incomeController.text),
          "LoanAmount": int.parse(loanAmountController.text),
          "CreditScore": int.parse(creditScoreController.text),
          "MonthsEmployed": int.parse(monthsEmployedController.text),
          "NumCreditLines": int.parse(numCreditLinesController.text),
          "InterestRate": double.parse(interestRateController.text),
          "LoanTerm": int.parse(loanTermController.text),
          "BankName": bankNameController.text,
          "StartDate": startDate?.toIso8601String() ?? "",
          "Education": education,
          "EmploymentType": employmentType,
          "MaritalStatus": maritalStatus,
          "HasMortgage": hasMortgage,
          "HasDependents": hasDependents,
          "LoanPurpose": loanPurpose,
          "HasCoSigner": hasCoSigner,
          "Default": defaultStatus
        }),
      );

      final data = jsonDecode(response.body);
      setState(() {
        resultMessage = data["loan_approval"];
      });

      if (data["loan_approval"] == "Approved") {
        await _saveLoanDetails();
      }
    } catch (e) {
      setState(() {
        resultMessage = "Error: Unable to fetch data";
      });
    }
  }

  Future<void> _saveLoanDetails() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String? uid;

    try {
      // Fetch the currently logged-in user's email
      String? userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) {
        debugPrint("User is not logged in.");
        return;
      }

      // Retrieve the uid from the 'users' collection based on email
      QuerySnapshot userQuery = await firestore
          .collection("users")
          .where("email", isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        debugPrint("No user found with email: $userEmail");
        return;
      }

      uid = userQuery.docs.first["uid"]; // Get the uid from Firestore

      // Add loan details to Firestore with UID
      DocumentReference docRef =
          await firestore.collection("loan_details").add({
        "uid": uid, // Store the user's UID from Firestore
        "Age": int.parse(ageController.text),
        "Income": int.parse(incomeController.text),
        "LoanAmount": int.parse(loanAmountController.text),
        "CreditScore": int.parse(creditScoreController.text),
        "MonthsEmployed": int.parse(monthsEmployedController.text),
        "NumCreditLines": int.parse(numCreditLinesController.text),
        "InterestRate": double.parse(interestRateController.text),
        "LoanTerm": int.parse(loanTermController.text),
        "BankName": bankNameController.text,
        "StartDate": startDate?.toIso8601String() ?? "",
        "Education": education,
        "EmploymentType": employmentType,
        "MaritalStatus": maritalStatus,
        "HasMortgage": hasMortgage,
        "HasDependents": hasDependents,
        "LoanPurpose": loanPurpose,
        "HasCoSigner": hasCoSigner,
        "Default": defaultStatus,
        "LoanStatus": "Approved",
        "Timestamp": FieldValue.serverTimestamp(),
      });

      // Update the document with the generated loan ID
      await docRef.update({"lid": docRef.id});

      debugPrint("Loan details saved successfully with lid: ${docRef.id}");
    } catch (e) {
      debugPrint("Error saving loan details: $e");
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
      });
    }
    print("Current User: ${FirebaseAuth.instance.currentUser?.email}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Approval Form"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(ageController, "Age", TextInputType.number),
            _buildTextField(incomeController, "Income", TextInputType.number),
            _buildTextField(
                loanAmountController, "Loan Amount", TextInputType.number),
            _buildTextField(
                creditScoreController, "Credit Score", TextInputType.number),
            _buildTextField(monthsEmployedController, "Months Employed",
                TextInputType.number),
            _buildTextField(numCreditLinesController, "Number of Credit Lines",
                TextInputType.number),
            _buildTextField(
                interestRateController, "Interest Rate", TextInputType.number),
            _buildTextField(
                loanTermController, "Loan Term", TextInputType.number),
            _buildTextField(
                bankNameController, "Bank Name", TextInputType.text),
            _buildDatePicker(context),
            _buildDropdown(
                "Education",
                ["Bachelor's", "High School", "Master's", "PhD"],
                education, (value) {
              setState(() => education = value!);
            }),
            _buildDropdown(
                "Employment Type",
                ["Full-time", "Part-time", "Self-employed", "Unemployed"],
                employmentType, (value) {
              setState(() => employmentType = value!);
            }),
            _buildDropdown("Marital Status", ["Single", "Married", "Divorced"],
                maritalStatus, (value) {
              setState(() => maritalStatus = value!);
            }),
            _buildDropdown(
                "Loan Purpose",
                ["Home", "Auto", "Education", "Business", "Other"],
                loanPurpose, (value) {
              setState(() => loanPurpose = value!);
            }),
            _buildRadioButtonGroup("Co-signer", ["Yes", "No"], hasCoSigner,
                (value) => setState(() => hasCoSigner = value!)),
            _buildRadioButtonGroup("Mortgage", ["Yes", "No"], hasMortgage,
                (value) => setState(() => hasMortgage = value!)),
            _buildRadioButtonGroup("Default", ["Yes", "No"], defaultStatus,
                (value) => setState(() => defaultStatus = value!)),
            _buildRadioButtonGroup(
                "Dependents",
                ["0", "1", "2", "3"],
                hasDependents,
                (value) => setState(() => hasDependents = value!)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: checkLoanApproval,
              child: const Text("Check Approval",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Text(resultMessage,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      TextInputType keyboardType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType, // Dynamic keyboard type
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options,
      String selectedValue, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration:
            InputDecoration(labelText: label, border: OutlineInputBorder()),
        value: selectedValue,
        items: options
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRadioButtonGroup(String label, List<String> options,
      String selectedValue, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6), // Spacing between label and radio buttons
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200], // Light background for better visibility
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              children: options.map((option) {
                return RadioListTile<String>(
                  title: Text(
                    option,
                    style: const TextStyle(fontSize: 16),
                  ),
                  value: option,
                  groupValue: selectedValue,
                  onChanged: onChanged,
                  activeColor: Colors.blue, // Adjust to your app’s theme
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _selectStartDate(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Start Date",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          child: Text(startDate == null
              ? "Select Date"
              : "${startDate!.day}-${startDate!.month}-${startDate!.year}"),
        ),
      ),
    );
  }
}
