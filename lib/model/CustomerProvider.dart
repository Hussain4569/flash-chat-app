import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../components/customer.dart';

final firestore = FirebaseFirestore.instance;

class CustomerProvider extends ChangeNotifier {
  List<Customer> customers = [];

  Future<void> createCustomersList(BuildContext context) async {
    customers = [];
    await firestore.collection("customers").get().then((querySnapshot) {
      for (var docSnapshot in querySnapshot.docs) {
        var data = docSnapshot.data();
        print(data);
        print(docSnapshot.id);
        customers.add(
          Customer(
            id: docSnapshot.id,
            firstName: data['firstName'],
            lastName: data['lastName'],
            email: data['email'],
            DOB: data['dob'].toDate(),
            salary: data['salary'],
          ),
        );
      }
    }, onError: (e) => print(e));
  }

  Future<void> addCustomer(String fN, String lN, String email, DateTime dob,
      int salary, BuildContext context) async {
    var docRef = await firestore.collection('customers').add({
      'firstName': fN,
      'lastName': lN,
      'email': email,
      'dob': dob,
      'salary': salary
    });
    customers.add(Customer(
        id: docRef.id,
        firstName: fN,
        lastName: lN,
        email: email,
        DOB: dob,
        salary: salary));
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer, BuildContext context) async {
    await firestore.collection('customers').doc(customer.id).update({
      'firstName': customer.firstName,
      'lastName': customer.lastName,
      'email': customer.email,
      'dob': customer.DOB,
      'salary': customer.salary
    });
    int idx = customers.indexWhere((element) => element.id == customer.id);
    customers[idx] = customer;
    notifyListeners();
  }

  Future<void> deleteCustomer(Customer customer, BuildContext context) async {
    await firestore.collection('customers').doc(customer.id).delete();
    customers
        .removeAt(customers.indexWhere((element) => element.id == customer.id));
    notifyListeners();
  }

  void showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Alert"),
          content: const Text(
              "An error occurred while connecting to the internet. Please check your iternet connection and try again."),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
