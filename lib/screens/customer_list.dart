import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flash_chat/model/CustomerProvider.dart';
import 'package:flash_chat/screens/customer_add.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../components/customer.dart';
import '../constants.dart';

final firestore = FirebaseFirestore.instance;
RangeValues currentRangeValues = RangeValues(0, 1000000);
TextEditingController dobStart = TextEditingController();
TextEditingController dobEnd = TextEditingController();
bool isAscending = true;

//TODO: list builder can then be used to do lazy loading.

class CustomerList extends StatefulWidget {
  const CustomerList({Key? key}) : super(key: key);
  static const String id = 'customer_list';

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  String? selectedSort;

  TextEditingController editingController = TextEditingController();
  FocusNode focusNode = FocusNode();
  ScrollController controller = ScrollController();
  Text noResultsText = const Text("No search results found.");

  void _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      print("at the end of list");
      context.read<CustomerProvider>().getNextData();
    }
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    List<Customer> customers = context.watch<CustomerProvider>().customers;
    bool isLoading = context.watch<CustomerProvider>().isLoading;
    bool hasMore = context.watch<CustomerProvider>().hasMore;

    return WillPopScope(
      onWillPop: () {
        Provider.of<CustomerProvider>(context, listen: false).resetAll();
        Navigator.pop(context);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: null,
          title: const Text('⚡️Customer List'),
          backgroundColor: Colors.lightBlueAccent,
          actions: [
            IconButton(
                onPressed: () {
                  print("filter button pressed");
                  focusNode.unfocus();
                  showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return FilterBottomSheet(
                          selectedSort: selectedSort,
                          currentRangeValues: currentRangeValues,
                          setSelectedSort: (selected) {
                            setState(() {
                              selectedSort = selected;
                            });
                          },
                        );
                      });
                },
                icon: Icon(Icons.filter_alt)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.lightBlueAccent,
            onPressed: () {
              Navigator.pushNamed(context, CustomerAdd.id);
            },
            child: Icon(Icons.add)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  Provider.of<CustomerProvider>(context, listen: false)
                      .filterSearchResults(value);
                  if (value.isEmpty) {
                    Provider.of<CustomerProvider>(context, listen: false)
                        .resetFilters();
                  }
                },
                focusNode: focusNode,
                controller: editingController,
                decoration: kTextFieldDecoration.copyWith(
                  labelText: "Search",
                  hintText: "Search",
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: customers.length > 0
                  ? ListView.builder(
                      shrinkWrap: true,
                      controller: controller,
                      itemBuilder: (context, idx) {
                        if (idx < customers.length) {
                          return CustomerListElement(customer: customers[idx]);
                        } else if (hasMore) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else {
                          return Center(
                            child: Text('No more results'),
                          );
                        }
                      },
                      itemCount: customers.length + 1,
                    )
                  : Center(child: noResultsText),
            ),
            // isLoading
            //     ? const Center(
            //         child: CircularProgressIndicator(),
            //       )
            //     : Container(),
            // !hasMore
            //     ? Center(
            //         child: Text('No more results'),
            //       )
            //     : Container(),
          ],
        ),
      ),
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  String? selectedSort;
  final RangeValues currentRangeValues;
  final Function(String?) setSelectedSort;

  FilterBottomSheet(
      {this.selectedSort,
      required this.currentRangeValues,
      required this.setSelectedSort});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final List<String> fields = [
    "First Name",
    "Last Name",
    "Email",
    "Salary",
    "DoB"
  ];

  DateTime? dobS;
  DateTime? dobE;

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<CustomerProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  "Sort by",
                  style: TextStyle(fontSize: 20.0),
                ),
                SizedBox(width: 10.0),
                GestureDetector(
                  child: Icon(
                    isAscending
                        ? Icons.arrow_circle_up_outlined
                        : Icons.arrow_circle_down_outlined,
                    color: isAscending ? Colors.lightBlue : null,
                  ),
                  onTap: () {
                    setState(() {
                      isAscending = !isAscending;
                    });
                  },
                )
              ],
            ),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.spaceBetween,
              children: fields
                  .map((e) => ChoiceChip(
                        label: Text(e),
                        onSelected: (selected) {
                          setState(() {
                            if (e == widget.selectedSort) {
                              widget.selectedSort = null;
                              widget.setSelectedSort(null);
                            } else {
                              widget.selectedSort = e;
                              widget.setSelectedSort(e);
                            }
                          });
                        },
                        selected: widget.selectedSort == e,
                        disabledColor: Colors.black12,
                        selectedColor: Colors.lightBlue,
                      ))
                  .toList(),
            ),
            const Divider(
              height: 10,
              thickness: 2,
            ),
            const Text(
              "Salary",
              style: TextStyle(fontSize: 20.0),
            ),
            RangeSlider(
              values: currentRangeValues,
              min: 0,
              max: 1000000,
              divisions: 10000,
              labels: RangeLabels(
                currentRangeValues.start.round().toString(),
                currentRangeValues.end.round().toString(),
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  currentRangeValues = values;
                });
              },
            ),
            const Divider(
              height: 10,
              thickness: 2,
            ),
            const Text(
              "Date of Birth",
              style: TextStyle(fontSize: 20.0),
            ),
            const SizedBox(
              height: 15.0,
            ),
            TextField(
              controller: dobStart, //editing controller of this TextField
              textAlign: TextAlign.center,
              decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Start DoB', errorText: null),
              readOnly:
                  true, //set it true, so that user will not able to edit text
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2001),
                    firstDate: DateTime(
                        1900), //DateTime.now() - not to allow to choose before today.
                    lastDate: DateTime.now());

                if (pickedDate != null) {
                  print(pickedDate);
                  dobS =
                      pickedDate; //pickedDate output format => 2021-03-10 00:00:00.000
                  String formattedDate =
                      DateFormat('yyyy-MM-dd').format(pickedDate);
                  print(
                      formattedDate); //formatted date output using intl package =>  2021-03-16
                  //you can implement different kind of Date Format here according to your requirement

                  setState(() {
                    dobStart.text =
                        formattedDate; //set output date to TextField value.
                  });
                } else {
                  print("Date is not selected");
                }
              },
            ),
            const SizedBox(
              height: 10.0,
            ),
            TextField(
              controller: dobEnd, //editing controller of this TextField
              textAlign: TextAlign.center,
              decoration: kTextFieldDecoration.copyWith(
                  hintText: 'End DoB', errorText: null),
              readOnly:
                  true, //set it true, so that user will not able to edit text
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2001),
                    firstDate: DateTime(
                        1900), //DateTime.now() - not to allow to choose before today.
                    lastDate: DateTime.now());

                if (pickedDate != null) {
                  print(pickedDate);
                  dobE =
                      pickedDate; //pickedDate output format => 2021-03-10 00:00:00.000
                  String formattedDate =
                      DateFormat('yyyy-MM-dd').format(pickedDate);
                  print(
                      formattedDate); //formatted date output using intl package =>  2021-03-16
                  //you can implement different kind of Date Format here according to your requirement

                  setState(() {
                    dobEnd.text =
                        formattedDate; //set output date to TextField value.
                  });
                } else {
                  print("Date is not selected");
                }
              },
            ),
            const SizedBox(
              height: 15.0,
            ),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              children: [
                Material(
                  elevation: 5.0,
                  color: Colors.lightBlue,
                  borderRadius: BorderRadius.circular(30.0),
                  child: MaterialButton(
                    onPressed: () {
                      print("apply pressed.");
                      provider.sortList(
                          label: widget.selectedSort ?? '', asc: isAscending);

                      if (currentRangeValues.start > 0 ||
                          currentRangeValues.end < 1000000) {
                        print("salary filter applied.");
                        provider.filterBySalary(
                            currentRangeValues.start.toInt(),
                            currentRangeValues.end.toInt());
                      }
                      if (dobS != null && dobE != null) {
                        print(dobS);
                        print(dobE);
                        provider.filterByDob(dobS!, dobE!);
                      }

                      Navigator.pop(context);
                    },
                    minWidth: 200.0,
                    height: 42.0,
                    child: const Text("Apply"),
                  ),
                ),
                Material(
                  elevation: 5.0,
                  color: Colors.lightBlue,
                  borderRadius: BorderRadius.circular(30.0),
                  child: MaterialButton(
                    onPressed: () {
                      provider.resetFilters();
                      widget.setSelectedSort(null);
                      currentRangeValues = const RangeValues(0, 1000000);
                      dobS = dobE = null;
                      dobStart.text = dobEnd.text = '';
                      isAscending = false;
                      Navigator.pop(context);
                    },
                    minWidth: 100.0,
                    height: 42.0,
                    child: const Text("Reset"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
