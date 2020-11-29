import 'Deposits.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deposit Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Calculator'),
    );
  }
}

class DepositWork extends StatefulWidget {
  final Deposit deposit;

  // DepositWork({Key key, @required this.deposit}) : super(key: key);
  const DepositWork(this.deposit);

  @override
  _DepositWorkState createState() => new _DepositWorkState();
}

class _DepositWorkState extends State<DepositWork> {
  int _duration = 0;
  double _amount = -1;
  double _addAmount = -1;
  double _removeAmount = -1;

  @override
  Widget build(BuildContext context) {
    setState(() {
      _amount = widget.deposit.amount;
    });
    setState(() {
      _duration = widget.deposit.duration;
    });
    return Scaffold(
        appBar: AppBar(title: Text("Deposit")),
        body:  Scrollbar(
                child: SingleChildScrollView(
                    child: Container(
                        margin: EdgeInsets.all(5),
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                  'Working with deposit "' +
                                      widget.deposit.name +
                                      '"',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold)),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: <Widget>[
                                        Text(
                                            'Deposit type: ' +
                                                widget.deposit.type,
                                            style: TextStyle(fontSize: 22)),
                                        Text(
                                            'Money on deposit: ' +
                                                _amount.toStringAsFixed(2),
                                            style: TextStyle(fontSize: 22)),
                                        Text(
                                            'Duration: ' + _duration.toString(),
                                            style: TextStyle(fontSize: 22)),
                                        Text(
                                            'Interest rate: ' +
                                                widget.deposit.yearlyPercents
                                                    .toStringAsFixed(2),
                                            style: TextStyle(fontSize: 22)),
                                        Text(
                                            'Money accumulated: ' +
                                                widget.deposit.percentsCumm
                                                    .toStringAsFixed(2),
                                            style: TextStyle(fontSize: 22)),
                                      ])),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      child: Text('Add to deposit'),
                                      onPressed: !(widget.deposit.type ==
                                                  "Accumulative Term Deposit" ||
                                              widget.deposit.type ==
                                                  "Expenses Term Deposit")
                                          ? null
                                          : () {
                                              AccumulativeTermDeposit deposit =
                                                  widget.deposit;
                                              if (_addAmount > 0) {
                                                deposit.addAmount(_addAmount);
                                                setState(() {
                                                  _amount =
                                                      widget.deposit.amount;
                                                });
                                              }
                                            },
                                    ),
                                    Expanded(
                                        child: TextFormField(
                                            onChanged: (String value) => {
                                                  setState(() {
                                                    _addAmount =
                                                        double.parse(value);
                                                  })
                                                },
                                            keyboardType: TextInputType.number,
                                            inputFormatters: <
                                                TextInputFormatter>[
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'[0-9\.]')),
                                            ],
                                            decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                labelText: "")))
                                  ]),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      child: Text('Remove from deposit'),
                                      onPressed: (widget.deposit.type !=
                                              "Expenses Term Deposit")
                                          ? null
                                          : () {
                                              ExpensesTermDeposit deposit =
                                                  widget.deposit;
                                              if (_removeAmount > 0) {
                                                deposit.removeAmount(
                                                    _removeAmount);
                                                setState(() {
                                                  _amount =
                                                      widget.deposit.amount;
                                                });
                                              }
                                            },
                                    ),
                                    Expanded(
                                        child: TextFormField(
                                            onChanged: (String value) => {
                                                  setState(() {
                                                    _removeAmount =
                                                        double.parse(value);
                                                  })
                                                },
                                            keyboardType: TextInputType.number,
                                            inputFormatters: <
                                                TextInputFormatter>[
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'[0-9\.]')),
                                            ],
                                            decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                labelText: "")))
                                  ]),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      child: Text('Wait month'),
                                      onPressed: () {
                                        widget.deposit.waitMonth();
                                        setState(() {
                                          _amount = widget.deposit.amount;
                                        });
                                        setState(() {
                                          _duration = widget.deposit.duration;
                                        });
                                      },
                                    ),
                                    ElevatedButton(
                                      child: Text('Save'),
                                      onPressed: () {
                                        _saveDeposit();
                                      },
                                    ),
                                    ElevatedButton(
                                      child: Text('Exit to menu'),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => MyHomePage(
                                                  title: 'Calculator')),
                                        );
                                      },
                                    )
                                  ])
                            ])))));
  }

  void _saveDeposit() async {
    if (kIsWeb) {
      _saveDepositWeb();
    } else {
      if (await Permission.storage.request().isGranted) {
        String dirPath = await FilePicker.platform.getDirectoryPath();
        String filename = widget.deposit.name;
        File file = File('$dirPath/$filename.json');
        var json = jsonEncode(widget.deposit.toJson());
        file.writeAsString(json, flush: true);
      }
    }
  }

  void _saveDepositWeb() {
    String filename = widget.deposit.name;
    final blob = html.Blob([jsonEncode(widget.deposit.toJson())]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = '$filename.json';
    html.document.body.children.add(anchor);

    anchor.click();

    html.document.body.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}

class NewDeposit extends StatefulWidget {
  _NewDepositState createState() => _NewDepositState();
}

bool checkDepositCorrectness(
    type, name, currency, amount, yearlyPercents, capitalization, months) {
  print([type, name, currency, amount, yearlyPercents, capitalization, months]);
  return (yearlyPercents > 0 &&
      amount > 0 &&
      currency != "" &&
      (type == "Demand Deposit" ||
          type == "Expenses Term Deposit" ||
          type == "Saving Term Deposit" ||
          type == "Accumulative Term Deposit") &&
      (type == "Demand Deposit" || months > 0 && months % 3 == 0));
}

Deposit selectDeposit(
    type, name, currency, amount, yearlyPercents, capitalization, months) {
  if (type == "Demand Deposit")
    return DemandDeposit(
        name, currency, amount, yearlyPercents, capitalization);
  if (type == "Expenses Term Deposit")
    return ExpensesTermDeposit(
        name, currency, amount, yearlyPercents, capitalization, months);
  if (type == "Saving Term Deposit")
    return SavingTermDeposit(
        name, currency, amount, yearlyPercents, capitalization, months);
  return AccumulativeTermDeposit(
      name, currency, amount, yearlyPercents, capitalization, months);
}

class _NewDepositState extends State<NewDeposit> {
  String _checkedType = "";
  bool _enableTerm = true;
  bool _capitalization = false;
  String _name = "";
  String _currency = "";
  double _amount = -1;
  double _yearlyPercents = -1;
  int _months = -1;
  List<String> _checked = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("New Deposit")),
        body: Center(
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.all(5),
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Text('Creating new deposit',
                        style: TextStyle(fontSize: 35)),
                    Text(
                      'Please, select deposit type:',
                    ),
                    CheckboxGroup(
                      labels: <String>[
                        "Demand Deposit",
                        "Expenses Term Deposit",
                        "Saving Term Deposit",
                        "Accumulative Term Deposit",
                      ],
                      checked: _checked,
                      onSelected: (List selected) => setState(() {
                        if (selected.length > 1) {
                          selected.removeAt(0);
                        }
                        _checkedType = selected[0];
                        if (_checkedType == "Demand Deposit")
                          setState(() {
                            _enableTerm = false;
                          });
                        else
                          setState(() {
                            _enableTerm = true;
                          });
                        _checked = selected;
                      }),
                    ),
                    Text(
                      'Please select deposit properties:',
                    ),
                    Row(
                      children: [
                        Checkbox(
                          onChanged: (bool newValue) => {
                            setState(() {
                              _capitalization = newValue;
                            })
                          },
                          tristate: false,
                          value: _capitalization,
                          activeColor: Color(0xFF6200EE),
                        ),
                        Text('With Capitalization'),
                      ],
                      // mainAxisAlignment: MainAxisAlignment.,
                    ),
                    TextFormField(
                        onChanged: (String value) => {
                              setState(() {
                                _name = value;
                              })
                            },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Deposit name")),
                    TextFormField(
                        onChanged: (String value) => {
                              setState(() {
                                _currency = value;
                              })
                            },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Deposit currency")),
                    TextFormField(
                        onChanged: (String value) => {
                              setState(() {
                                _amount = double.parse(value);
                              })
                            },
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                        ],
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Initial deposit amount")),
                    TextFormField(
                        onChanged: (String value) => {
                              setState(() {
                                _yearlyPercents = double.parse(value);
                              })
                            },
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                        ],
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Yearly interest in %")),
                    TextFormField(
                        onChanged: (String value) => {
                              setState(() {
                                _months = int.parse(value);
                              })
                            },
                        keyboardType: TextInputType.number,
                        enabled: _enableTerm,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Term in months")),
                    FloatingActionButton(
                      onPressed: () => {
                        if (checkDepositCorrectness(
                            _checkedType,
                            _name,
                            _currency,
                            _amount,
                            _yearlyPercents,
                            _capitalization,
                            _months))
                          {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DepositWork(
                                      selectDeposit(
                                          _checkedType,
                                          _name,
                                          _currency,
                                          _amount,
                                          _yearlyPercents,
                                          _capitalization,
                                          _months))),
                            )
                          }
                      },
                      tooltip: 'Create',
                      child: Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        IconButton(icon: Icon(Icons.list), onPressed: _pushAbout),
      ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text('Welcome to Deposit Calculator!\n\n',
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
            Text('Please, select action:', style: TextStyle(fontSize: 25)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              ElevatedButton(
                child: Text('Open existing deposit'),
                onPressed: () {
                  _loadJson().then((Deposit deposit) => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DepositWork(deposit)),
                      ));
                },
              ),
              ElevatedButton(
                child: Text('Create new deposit'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NewDeposit()),
                  );
                },
              ),
            ])
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: Icon(Icons.add),
      // ),
    );
  }

  Future<Deposit> _loadJson() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'], withData: true);

    PlatformFile file = result.files.first;
    String content = utf8.decode(file.bytes);
    return Deposit.fromJson(jsonDecode(content));
  }

  void _pushAbout() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          final text = '''
Calculator for different types of bank deposits

This app was made by Oleh Borovik as part of 'Cross-platform and Multi-platform Technologies' course.

User guide:
1) Select deposit by either:
1.a) Load existing deposit file by pressing an 'Open existing deposit' button on the main page.
1.b) Create new deposit.
1.b.1) Press 'Create new deposit' button.
1.b.2) Select deposit type and fill in every needed field. 
1.b.3) Press 'Create' button.

2) Work with deposit.
2.1) All necessary information about the deposit is displayed on a screen.
2.2) Press 'Wait month' to update information after 1 month passed.
2.3) Press 'Save' to save deposit file.   
2.4) Press 'Exit to menu' to exit to p.1).
''';
          return Scaffold(
              appBar: AppBar(
                title: Text('About Page'),
              ),
              body: Container(
                padding: EdgeInsets.all(20),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ));
        },
      ),
    );
  }
}
