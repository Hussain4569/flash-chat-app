import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flash_chat/model/CustomerProvider.dart';
import 'package:flash_chat/screens/customer_add.dart';
import 'package:flash_chat/screens/customer_edit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

import '../components/customer.dart';

final firestore = FirebaseFirestore.instance;
List<CustomerListElement> tilesList = [];

//TODO: list builder can then be used to do lazy loading.

class CustomerList extends StatefulWidget {
  const CustomerList({Key? key}) : super(key: key);
  static const String id = 'customer_list';

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  @override
  Widget build(BuildContext context) {
    List<Customer> customers = context.watch<CustomerProvider>().customers;

    return Scaffold(
      appBar: AppBar(
        leading: null,
        title: const Text('⚡️Customer List'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.lightBlueAccent,
          onPressed: () {
            Navigator.pushNamed(context, CustomerAdd.id);
          },
          child: Icon(Icons.add)),
      body: ListView.builder(
        itemBuilder: (context, idx) =>
            CustomerListElement(customer: customers[idx]),
        itemCount: customers.length,
      ),
    );
  }
}

//pagination testing code
Stream<QuerySnapshot<Map<String, dynamic>>> nextPage(var last) {
  return firestore
      .collection('customers')
      .orderBy("firstName")
      .startAfter(last)
      .limit(15)
      .snapshots();
}
