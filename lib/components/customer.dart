import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flash_chat/model/CustomerProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../screens/customer_edit.dart';

final firestore = FirebaseFirestore.instance;

class CustomerListElement extends StatelessWidget {
  final Customer customer;
  bool isLoading = false;
  SnackBar snackBar = SnackBar(content: Text("1 customer deleted."));

  void showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alert"),
          content: Text("Are you sure you want to delete?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                await Provider.of<CustomerProvider>(context, listen: false)
                    .deleteCustomer(customer, context);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  CustomerListElement({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        color: const Color(0xFFE3E3E3),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: const Icon(Icons.edit),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        CustomerEdit.id,
                        arguments: CustomerArgument(customer: customer),
                      );
                    },
                  ),
                  Text(
                    '${customer.firstName} ${customer.lastName}',
                    style: const TextStyle(
                        fontSize: 20.0, fontWeight: FontWeight.w500),
                  ),
                  GestureDetector(
                    child: Icon(Icons.delete),
                    onTap: () {
                      showAlertDialog(context);
                    },
                  )
                ],
              ),
              Text(customer.email,
                  style: const TextStyle(
                      fontSize: 15.0, fontWeight: FontWeight.w400)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DOB: ${DateFormat('yyyy-MM-dd').format(customer.DOB)}',
                      style: const TextStyle(
                          fontSize: 15.0, fontWeight: FontWeight.w300)),
                  Text('Salary: ${customer.salary}',
                      style: const TextStyle(
                          fontSize: 15.0, fontWeight: FontWeight.w300)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Customer {
  String id = '', firstName = '', lastName = '', email = '';
  DateTime DOB;
  int salary = 0;

  Customer(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.DOB,
      required this.salary});
}
