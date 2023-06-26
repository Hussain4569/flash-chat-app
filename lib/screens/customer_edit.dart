import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flash_chat/model/CustomerProvider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

import '../components/customer.dart';
import '../constants.dart';

class CustomerArgument {
  Customer customer;

  CustomerArgument({required this.customer});
}

class CustomerEdit extends StatefulWidget {
  static const String id = 'customer_edit';
  const CustomerEdit({Key? key}) : super(key: key);

  @override
  State<CustomerEdit> createState() => _CustomerEditState();
}

class _CustomerEditState extends State<CustomerEdit> {
  TextEditingController dateInput = TextEditingController();
  String? firstName, lastName, email;
  DateTime? dob;
  int? salary;
  bool firstNameV = false,
      lastNameV = false,
      emailNV = false,
      emailNull = false,
      dobV = false,
      salaryNull = false,
      salaryZero = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  bool checkTextFields() {
    return (firstName == null ||
        lastName == null ||
        dob == null ||
        salary == null ||
        (salary ?? -1) <= 0 ||
        email == null ||
        !EmailValidator.validate(email ?? ''));
  }

  void setValidationChecks() {
    if (checkTextFields()) {
      setState(() {
        firstNameV = firstName == null;
        lastNameV = lastName == null;
        dobV = dob == null;
        salaryNull = salary == null;
        salaryZero = (salary ?? -1) <= 0;
        emailNull = email == null;
        emailNV = !EmailValidator.validate(email ?? '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as CustomerArgument;
    Customer customer = args.customer;
    firstName = customer.firstName;
    lastName = customer.lastName;
    email = customer.email;
    dob = customer.DOB;
    salary = customer.salary;
    dateInput.text = DateFormat('yyyy-MM-dd').format(dob!);

    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
        appBar: AppBar(
          leading: null,
          title: const Text('⚡️Edit Customer'),
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  height: 100.0,
                  child: Image.asset('images/logo.png'),
                ),
                SizedBox(
                  height: 48.0,
                ),
                TextField(
                  textAlign: TextAlign.center,
                  controller: TextEditingController(text: firstName),
                  onChanged: (value) {
                    firstName = value;
                    setValidationChecks();
                  },
                  decoration: kTextFieldDecoration.copyWith(
                      hintText: 'Enter first name',
                      errorText: firstNameV ? 'First name is required' : null),
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                TextField(
                  textAlign: TextAlign.center,
                  controller: TextEditingController(text: lastName),
                  onChanged: (value) {
                    lastName = value;
                    setValidationChecks();
                  },
                  decoration: kTextFieldDecoration.copyWith(
                      hintText: 'Enter last name',
                      errorText: lastNameV ? 'Last name is required' : null),
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(
                  height: 24.0,
                ),
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.center,
                  controller: TextEditingController(text: email),
                  onChanged: (value) {
                    email = value;
                    setValidationChecks();
                  },
                  decoration: kTextFieldDecoration.copyWith(
                      hintText: 'Enter email',
                      errorText: emailNV
                          ? 'Enter a valid email'
                          : (emailNull ? 'Email is required' : null)),
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(
                  height: 24.0,
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  controller: TextEditingController(text: salary.toString()),
                  onChanged: (value) {
                    salary = int.parse(value);
                    setValidationChecks();
                  },
                  decoration: kTextFieldDecoration.copyWith(
                      hintText: 'Enter salary',
                      errorText: salaryNull
                          ? 'Salary is required'
                          : (salaryZero
                              ? 'Salary should be greater than zero'
                              : null)),
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(
                  height: 24.0,
                ),
                TextField(
                  controller: dateInput, //editing controller of this TextField
                  textAlign: TextAlign.center,
                  decoration: kTextFieldDecoration.copyWith(
                      hintText: 'Date of birth',
                      errorText: dobV ? 'DoB required' : null),
                  readOnly:
                      true, //set it true, so that user will not able to edit text
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(
                            1900), //DateTime.now() - not to allow to choose before today.
                        lastDate: DateTime(2010));

                    if (pickedDate != null) {
                      print(pickedDate);
                      dob =
                          pickedDate; //pickedDate output format => 2021-03-10 00:00:00.000
                      String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                      print(
                          formattedDate); //formatted date output using intl package =>  2021-03-16
                      //you can implement different kind of Date Format here according to your requirement

                      setState(() {
                        dateInput.text =
                            formattedDate; //set output date to TextField value.
                        dobV = false;
                      });
                    } else {
                      print("Date is not selected");
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Material(
                    color: Colors.lightBlueAccent,
                    borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                    elevation: 5.0,
                    child: MaterialButton(
                      onPressed: () async {
                        if (checkTextFields()) {
                          setValidationChecks();
                        } else {
                          setState(() {
                            isLoading = true;
                          });
                          await Provider.of<CustomerProvider>(context,
                                  listen: false)
                              .updateCustomer(
                                  Customer(
                                      id: customer.id,
                                      firstName: firstName!,
                                      lastName: lastName!,
                                      email: email!,
                                      DOB: dob!,
                                      salary: salary!),
                                  context);
                          setState(() {
                            isLoading = false;
                          });
                          Navigator.pop(context);
                        }
                      },
                      minWidth: 200.0,
                      height: 42.0,
                      child: const Text(
                        'Edit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}