import 'package:debt_tracking_app/DatabaseHelper.dart';
import 'package:debt_tracking_app/pages/users_selector_page.dart';
import 'package:debt_tracking_app/widgets/UserAvatar.dart';
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
  final TextEditingController _amountTextController = TextEditingController(text: '0');
  final TextEditingController _dateTextController = TextEditingController(text: '');

  bool _isSaving = false;
  bool _isAutoDistribute = true;
  String _title = '';
  String? _description;
  DateTime _date = DateTime.now();
  double _autoDistributeError = 0;

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

    var total = double.tryParse(_amountTextController.text.replaceAll(',', '.'));
    if (total == null) return;

    var chunk = (total/_users.length).ceil();
    var chunkStr = chunk.toStringAsFixed(2);
    
    setState(() {
      for (var controller in _usersTextControllers.values) {
        controller.text = chunkStr;
      }
      _autoDistributeError = total-(double.parse(chunkStr)*_users.length);
    });
  }

  double getRealTotal() {
    double total = 0;
    for (var c in _usersTextControllers.values) {
      double? x = double.tryParse(c.text.replaceAll(',', '.'));
      if (x != null) {
        total+=x;
      }
    }
    return total;
  }

  void setupUserTextControllers() {
    disposeUserTextControllers();

    for (var user in _users) {
      var controller = TextEditingController();
      _usersTextControllers[user.id] = controller;
      controller.addListener(onUserTextControllerChange(controller));
    }

    tryAutoDistribute();
  }

  void onSelectUsersClick() async {
    List<User>? selectedUsers = await Navigator.push(context, MaterialPageRoute(builder: (context) => UsersSelectorPage(previouslySelectedUsers: _users)));
    if (!mounted) return;
    if (selectedUsers != null) {
      setState(() {
        _users = selectedUsers;
        setupUserTextControllers();
      });
    }
  }

  // Function<Function<void>>
  VoidCallback onUserTextControllerChange(TextEditingController controller) => () {
    if (!mounted) return;
    var value = double.tryParse(controller.text.replaceAll(',', '.'));
    if (value == null) return;
    if (!_isAutoDistribute) {
      setState(() {
        _amountTextController.text = getRealTotal().toStringAsFixed(2);
      });
    }
  };

  void onSwitchClick(bool value) async {
    setState(() {
      _isAutoDistribute=value;
      if (_isAutoDistribute) { // set to true: autodistribute
        tryAutoDistribute();
      } else { // set to false: correct the total
        _amountTextController.text = getRealTotal().toStringAsFixed(2);
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
    
    _amountTextController.addListener(() {
      var num = double.tryParse(_amountTextController.text.replaceAll(',', '.'));
      if (num != null) {
        tryAutoDistribute();
      }
    });
    _dateTextController.text = '${_date.year}/${_date.month}/${_date.day}';

    if (widget.initialUser != null) {
      setState(() {
        _users.add(widget.initialUser!);
        setupUserTextControllers();
      });
    }
  }
  
  @override
  void dispose() {
    super.dispose();
    _amountTextController.dispose();
    _dateTextController.dispose();
    disposeUserTextControllers();
  }

  void disposeUserTextControllers() {
    for (var userTextController in _usersTextControllers.values) {
      userTextController.dispose();
    }
    _usersTextControllers = {};
  }

  Future<bool> onPop() async {
    if (!_isSaving) Navigator.pop(context, null);
    return false;
  }

  Widget buildUserCard(User user) => Card(
    elevation: 2,
    child: SizedBox(
      height: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ListTile(
            leading: UserAvatar(user: user),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                  var number = double.tryParse(value!.replaceAll(',', '.'));
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
  );

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
                // TITLE
                TextFormField(
                  readOnly: _isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Debt title',
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
                // DESCRIPTION
                TextFormField(
                  readOnly: _isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Additional info e.g. place or circumstances',
                    border: UnderlineInputBorder()
                  ),
                  maxLines: null,
                  onChanged: (String? value) {
                    setState(() => _description = value);
                  },
                ),
                // DATE
                TextFormField(
                  controller: _dateTextController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: UnderlineInputBorder()
                  ),
                  readOnly: true,
                  onTap: onPickDateClick,
                ),
                // TOTAL AMOUNT
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
                // AUTO-DISTRIBUTE SWITCH
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
                // ROUNDING ERROR MSG
                (_isAutoDistribute && _autoDistributeError.abs() >= 0.01 && _users.isNotEmpty) ? Center(
                  child: Text('Rounding Error: ${_autoDistributeError<0 ? 'Overcharging' : 'Losing'} ${(_autoDistributeError/_users.length).abs().toStringAsFixed(2)}PLN/person (real total: ${getRealTotal().toStringAsFixed(2)} PLN)')
                ) : Container(),
                // CHOOSE USERS BTN
                TextButton(onPressed: _isSaving ? null : onSelectUsersClick, child: const Text('Choose users')),
                // USERS LIST
                Column(
                  children: _users.map(buildUserCard).toList(),
                ),
                // SUBMIT BTN
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
