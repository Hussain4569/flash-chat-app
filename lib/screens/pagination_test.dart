import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../components/customer.dart';

final firestore = FirebaseFirestore.instance;

class PaginationTest extends StatefulWidget {
  static String id = 'pagination_test';

  @override
  State<PaginationTest> createState() => _PaginationTestState();
}

class _PaginationTestState extends State<PaginationTest> {
  List<Customer> customerList = [];
  bool isLoading = false, hasMore = true, firstFetched = false;
  var lastVisible;
  ScrollController controller = ScrollController();

  Future<void> addCustomers() async {
    for (int i = 0; i < 50; i++) {
      await firestore.collection('customers').add({
        'firstName': 'Hussain$i',
        'lastName': 'Mustafa',
        'email': 'hussain$i@gmail.com',
        'dob': DateTime.now(),
        'salary': 25000 + i
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> nextPage(var last) {
    return firestore
        .collection('customers')
        .orderBy("firstName")
        .startAfter(last)
        .limit(10)
        .snapshots();
  }

  void getNextData() {
    if (!hasMore) {
      print('No More Items');
      return;
    }
    setState(() {
      isLoading = true;
    });
    var query = !firstFetched
        ? firestore.collection('customers').orderBy("firstName").limit(15)
        : firestore
            .collection('customers')
            .orderBy("firstName")
            .startAfter([lastVisible['firstName']]).limit(15);
    if (!firstFetched) firstFetched = true;
    query.get().then(
      (documentSnapshots) {
        // Get the last visible document
        lastVisible = documentSnapshots.docs[documentSnapshots.docs.length - 1];

        //add documents to the list
        setState(() {
          customerList.addAll(documentSnapshots.docs.map((e) {
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
        });
        if (documentSnapshots.docs.length <= 10) {
          hasMore = false;
        }
      },
      onError: (e) => print("Error completing: $e"),
    );
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getNextData();
    controller.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      print("at the end of list");
      getNextData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: null,
          title: const Text('⚡️Pagination test'),
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(customerList[index].firstName),
                    subtitle: Text(customerList[index].lastName),
                  );
                },
                controller: controller,
                itemCount: customerList.length,
              ),
            ),
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Container(),
          ],
        ));
  }
}

class StreamBuilderList extends StatelessWidget {
  const StreamBuilderList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore
            .collection('customers')
            .orderBy("firstName")
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var data = snapshot.data!.docs;
            var last = data[data.length - 1];
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(data[index]['firstName']),
                  subtitle: Text(data[index]['lastName']),
                );
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
