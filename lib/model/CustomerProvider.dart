import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../components/customer.dart';

final firestore = FirebaseFirestore.instance;

class CustomerProvider extends ChangeNotifier {
  List<Customer> customers = [];
  List<Customer> originalCopy = [];
  bool isLoading = false, hasMore = true, firstFetched = false;
  dynamic lastVisible;
  final int docLimit = 10;

  void toggleIsLoading() {
    isLoading = !isLoading;
    notifyListeners();
  }

  void getNextData() {
    print("Get Next Data");
    if (!hasMore) {
      print('No More Items');
      return;
    }
    toggleIsLoading();
    var query = !firstFetched
        ? firestore.collection('customers').orderBy("firstName").limit(docLimit)
        : firestore
            .collection('customers')
            .orderBy("firstName")
            .startAfter([lastVisible['firstName']]).limit(docLimit);
    if (!firstFetched) {
      print("First Fetch");
      firstFetched = true;
    }
    query.get().then(
      (documentSnapshots) {
        // Get the last visible document
        lastVisible = documentSnapshots.docs[documentSnapshots.docs.length - 1];

        //add documents to the list
        customers.addAll(documentSnapshots.docs.map((e) {
          return Customer(
            id: e.id,
            firstName: e['firstName'],
            lastName: e['lastName'],
            fullName: e['firstName'] + ' ' + e['lastName'],
            email: e['email'],
            dob: e['dob'].toDate(),
            salary: e['salary'],
          );
        }).toList());
        originalCopy.addAll(documentSnapshots.docs.map((e) {
          return Customer(
            id: e.id,
            firstName: e['firstName'],
            lastName: e['lastName'],
            fullName: e['firstName'] + ' ' + e['lastName'],
            email: e['email'],
            dob: e['dob'].toDate(),
            salary: e['salary'],
          );
        }).toList());
        notifyListeners();
        if (documentSnapshots.docs.length < docLimit) {
          hasMore = false;
        }
      },
      onError: (e) => print("Error completing: $e"),
    );
    toggleIsLoading();
  }

  // Future<void> createCustomersList() async {
  //   customers = [];
  //   originalCopy = [];
  //   toggleIsLoading();
  //   await firestore.collection("customers").get().then((querySnapshot) {
  //     for (var docSnapshot in querySnapshot.docs) {
  //       var data = docSnapshot.data();
  //       print(data);
  //       print(docSnapshot.id);
  //       customers.add(
  //         Customer(
  //           id: docSnapshot.id,
  //           firstName: data['firstName'],
  //           lastName: data['lastName'],
  //           fullName: data['firstName'] + ' ' + data['lastName'],
  //           email: data['email'],
  //           dob: data['dob'].toDate(),
  //           salary: data['salary'],
  //         ),
  //       );
  //     }
  //     originalCopy.addAll(customers);
  //     toggleIsLoading();
  //   }, onError: (e) => print(e));
  //   notifyListeners();
  // }

  Future<void> addCustomer(String fN, String lN, String email, DateTime dob,
      int salary, BuildContext context) async {
    toggleIsLoading();
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
        fullName: '$fN $lN',
        email: email,
        dob: dob,
        salary: salary));
    toggleIsLoading();
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer, BuildContext context) async {
    toggleIsLoading();
    await firestore.collection('customers').doc(customer.id).update({
      'firstName': customer.firstName,
      'lastName': customer.lastName,
      'email': customer.email,
      'dob': customer.dob,
      'salary': customer.salary
    });
    int idx = customers.indexWhere((element) => element.id == customer.id);
    customers[idx] = customer;
    toggleIsLoading();
    notifyListeners();
  }

  Future<void> deleteCustomer(Customer customer, BuildContext context) async {
    toggleIsLoading();
    await firestore.collection('customers').doc(customer.id).delete();
    customers
        .removeAt(customers.indexWhere((element) => element.id == customer.id));
    toggleIsLoading();
    notifyListeners();
  }

  void sortList({required String label, bool asc = false}) {
    if (asc) {
      if (label == "First Name") {
        customers.sort((a, b) =>
            a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()));
      } else if (label == "Last Name") {
        customers.sort((a, b) =>
            a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()));
      } else if (label == "Email") {
        customers.sort(
            (a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()));
      } else if (label == "Salary") {
        customers.sort((a, b) => a.salary.compareTo(b.salary));
      } else if (label == "DoB") {
        customers.sort((a, b) => a.dob.compareTo(b.dob));
      } else {
        print("no such field.");
      }
    } else {
      if (label == "First Name") {
        customers.sort((a, b) =>
            b.firstName.toLowerCase().compareTo(a.firstName.toLowerCase()));
      } else if (label == "Last Name") {
        customers.sort((a, b) =>
            b.lastName.toLowerCase().compareTo(a.lastName.toLowerCase()));
      } else if (label == "Email") {
        customers.sort(
            (a, b) => b.email.toLowerCase().compareTo(a.email.toLowerCase()));
      } else if (label == "Salary") {
        customers.sort((a, b) => b.salary.compareTo(a.salary));
      } else if (label == "DoB") {
        customers.sort((a, b) => b.dob.compareTo(a.dob));
      } else {
        print("no such field.");
      }
    }

    notifyListeners();
  }

  void filterBySalary(int start, int end) {
    customers = [];
    customers = originalCopy
        .where((element) => (element.salary >= start && element.salary <= end))
        .toList();
    notifyListeners();
  }

  void filterByDob(DateTime start, DateTime end) {
    customers = [];
    customers = originalCopy
        .where((element) => (element.dob.compareTo(start) > 0 &&
            element.dob.compareTo(end) < 0))
        .toList();
    notifyListeners();
  }

  void filterSearchResults(String query) {
    customers = [];
    customers = originalCopy
        .where(
            (item) => item.fullName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }

  void resetFilters() {
    customers = [];
    customers.addAll(originalCopy);
    notifyListeners();
  }

  void resetAll() {
    isLoading = false;
    hasMore = true;
    firstFetched = false;
    lastVisible = null;
    customers = [];
    originalCopy = [];
    notifyListeners();
  }
}
