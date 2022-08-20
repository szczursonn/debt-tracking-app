import 'package:debt_tracking_app/DatabaseHelper.dart';
import 'package:debt_tracking_app/pages/users_selector_page.dart';
import 'package:flutter/material.dart';

import '../models.dart';

class DebtCreatePage extends StatefulWidget {
  const DebtCreatePage({Key? key, this.initialUser}) : super(key: key);

  final User? initialUser;

  @override
  State<DebtCreatePage> createState() => _DebtCreatePageState();
}

class _DebtCreatePageState extends State<DebtCreatePage> {

  final _formKey = GlobalKey<FormState>();

  List<User> _users = [];
  Map<int,TextEditingController> _usersTextControllers = {};

  bool _isSaving = false;
  bool _isAutoDistribute = true;
  String _title = '';
  String? _description;
  DateTime _date = DateTime.now();
  double _autoDistributeError = 0;

  final TextEditingController _amountTextController = TextEditingController(text: '0');
  final TextEditingController _dateTextController = TextEditingController(text: '');

  void onSubmitClick() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      var debt = await DatabaseHelper.instance.createDebt(
        title: _title,
        description: _description,
        date: _date,
        userAmounts: _usersTextControllers.map((key, value) => MapEntry(key, double.parse(value.text)))
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.pop(context, debt);
    }
  }

  void tryAutoDistribute() {
    if (!_isAutoDistribute || _users.isEmpty) return;

    var total = double.tryParse(_amountTextController.text);
    if (total == null) return;

    var chunk = (total/_users.length).ceil();
    var chunkStr = chunk.toStringAsFixed(2);
    for (var controller in _usersTextControllers.values) {
      controller.text = chunkStr;
    }
    
    setState(() {
      _autoDistributeError = total-(double.parse(chunkStr)*_users.length);
    });
  }

  double getRealTotal() {
    double total = 0;
    for (var c in _usersTextControllers.values) {
      double? x = double.tryParse(c.text);
      if (x != null) {
        total+=x;
      }
    }
    return total;
  }

  void onSelectUsersClick() async {
    List<User>? selectedUsers = await Navigator.push(context, MaterialPageRoute(builder: (context) => UsersSelectorPage(previouslySelectedUsers: _users)));
    if (!mounted) return;
    if (selectedUsers != null) {
      setState(() {
        _users = selectedUsers;

        for (var userTextController in _usersTextControllers.values) {
          userTextController.dispose();
        }
        
        _usersTextControllers = {};
        for (var user in _users) {
          var controller = TextEditingController();
          _usersTextControllers[user.id] = controller;
          controller.addListener(() {
            if (!mounted) return;
            var value = double.tryParse(controller.text);
            if (value == null) return;
            if (!_isAutoDistribute) {
              var total = getRealTotal();
              setState(() {
                _amountTextController.text = total.toStringAsFixed(2);
              });
            }
          });
        }
        tryAutoDistribute();
      });
    }
  }

  void onSwitchClick(bool value) async {
    setState(() {
      _isAutoDistribute=value;
      // auto-assign values to users
      if (_isAutoDistribute) {
        tryAutoDistribute();
      }
    });
  }

  void onPickDateClick() async {
    var date = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1900), lastDate: DateTime(2100));
    if (mounted && date != null) {
      setState(() {
        _date = date;
        _dateTextController.text = '${_date.year}/${_date.month}/${_date.day}';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialUser != null) _users.add(widget.initialUser!);
    _amountTextController.addListener(() {
      var num = double.tryParse(_amountTextController.text);
      if (num != null) {
        tryAutoDistribute();
      }
    });
    _dateTextController.text = '${_date.year}/${_date.month}/${_date.day}';
  }
  
  @override
  void dispose() {
    super.dispose();
    _amountTextController.dispose();
    _dateTextController.dispose();
    for (var controller in _usersTextControllers.values) {
      controller.dispose();
    }
  }

  Future<bool> onPop() async {
    if (!_isSaving) Navigator.pop(context, null);

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Record debt'),
        ),
        body: Container(
          margin: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  readOnly: _isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: UnderlineInputBorder()
                  ),
                  onChanged: (String? value) {
                    if (value != null) setState(() => _title = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Title cannot be empty';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  readOnly: _isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: UnderlineInputBorder()
                  ),
                  maxLines: null,
                  onChanged: (String? value) {
                    setState(() => _description = value);
                  },
                ),
                TextFormField(
                  controller: _dateTextController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: UnderlineInputBorder()
                  ),
                  readOnly: true,
                  onTap: onPickDateClick,
                ),
                TextFormField(
                  readOnly: !_isAutoDistribute || _isSaving,
                  controller: _amountTextController,
                  decoration: const InputDecoration(
                    labelText: 'Total',
                    border: UnderlineInputBorder()
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    var number = double.tryParse(value!);
                    if (number == null) {
                      return 'Invalid number';
                    }
                    if (number <= 0) {
                      return 'Total amount must be greater than 0';
                    }
                    return null;
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Switch(
                      value: _isAutoDistribute, 
                      onChanged: onSwitchClick
                    ),
                    const Text('Auto-distribute', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                (_isAutoDistribute && _autoDistributeError.abs() >= 0.01 && _users.isNotEmpty) ? Center(
                  child: Text('Rounding Error: ${_autoDistributeError<0 ? 'Overcharging' : 'Losing'} ${(_autoDistributeError/_users.length).abs().toStringAsFixed(2)}PLN/person (real total: ${getRealTotal().toStringAsFixed(2)} PLN)')
                ) : Container(),
                TextButton(onPressed: _isSaving ? null : onSelectUsersClick, child: const Text('Choose users')),
                Column(
                  children: _users.map((user)=>Card(
                    elevation: 2,
                    child: SizedBox(
                      height: 80,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.amber,
                              child: Text('JD')
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: SizedBox(
                              width: 100,
                              height: 60,
                              child: TextFormField(
                                controller: _usersTextControllers[user.id],
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  labelStyle: TextStyle(
                                    fontSize: 14,
                                  ),
                                  errorStyle: TextStyle(
                                    fontSize: 10,
                                  ),
                                  errorMaxLines: 2,
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                readOnly: _isAutoDistribute || _isSaving,
                                validator: (value) {
                                  var number = double.tryParse(value!);
                                  if (number == null) {
                                    return 'Invalid number';
                                  }
                                  if (number <= 0) {
                                    return 'Must be greater than 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  )).toList(),
                ),
                AspectRatio(
                  aspectRatio: 4.5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: (_isSaving || _users.isEmpty) ? null : onSubmitClick,
                      child: const Text('Create'),
                    ),
                  ),
                ),
              ],
            )
          ),
        ),
      ),
    );
  }
}
