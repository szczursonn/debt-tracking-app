import 'package:debt_tracking_app/pages/users_selector_page.dart';
import 'package:debt_tracking_app/providers/debt_provider.dart';
import 'package:debt_tracking_app/providers/user_provider.dart';
import 'package:debt_tracking_app/utils.dart';
import 'package:debt_tracking_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/settings_provider.dart';

class DebtCreatePage extends StatefulWidget {
  const DebtCreatePage({Key? key, this.initialUserId}) : super(key: key);

  final int? initialUserId;

  @override
  State<DebtCreatePage> createState() => _DebtCreatePageState();
}

class _DebtCreatePageState extends State<DebtCreatePage> {

  final _formKey = GlobalKey<FormState>();

  List<int> _userIds = [];
  Map<int,TextEditingController> _usersTextControllers = {};
  final TextEditingController _titleTextController = TextEditingController(text: '');
  final TextEditingController _descriptionTextController = TextEditingController(text: '');
  final TextEditingController _amountTextController = TextEditingController(text: '0');
  final TextEditingController _dateTextController = TextEditingController(text: '');

  bool _isSaving = false;
  bool _isAutoDistribute = true;
  DateTime _date = DateTime.now();
  double _autoDistributeError = 0;

  void onSubmitClick() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      var provider = Provider.of<DebtProvider>(context, listen: false);

      await provider.createDebt(
        title: _titleTextController.text,
        description: _descriptionTextController.text.isEmpty ? null : _descriptionTextController.text,
        date: _date,
        userAmounts: _usersTextControllers.map((key, value) => MapEntry(key, double.parse(value.text.replaceAll(',', '.'))))
      );
      if (!mounted) return;

      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  void tryAutoDistribute() {
    if (!_isAutoDistribute || _userIds.isEmpty) return;

    var total = double.tryParse(_amountTextController.text.replaceAll(',', '.'));
    if (total == null) return;

    late String chunk;

    if (_userIds.length > 1) {
      chunk = (total/_userIds.length).ceil().toStringAsFixed(2);
    } else {
      chunk = total.toStringAsFixed(2);
    }
    setState(() {
      for (var controller in _usersTextControllers.values) {
        controller.text = chunk;
      }
      _autoDistributeError = total-(double.parse(chunk)*_userIds.length);
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

    for (var userId in _userIds) {
      var controller = TextEditingController();
      _usersTextControllers[userId] = controller;
      controller.addListener(onUserTextControllerChange(controller));
    }

    tryAutoDistribute();
  }

  void onSelectUsersClick() async {
    var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => UsersSelectorPage(previouslySelectedUsersIds: _userIds)));
    if (!mounted) return;
    if (res is List) {
      setState(() {
        _userIds = res as dynamic;
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
        _dateTextController.text = Utils.formatDate(date);
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
    _dateTextController.text = Utils.formatDate(_date);

    if (widget.initialUserId != null) {
      setState(() {
        _userIds.add(widget.initialUserId!);
        setupUserTextControllers();
      });
    }
  }
  
  @override
  void dispose() {
    super.dispose();
    _titleTextController.dispose();
    _descriptionTextController.dispose();
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

  Widget buildUserCard(int userId) => Selector<UserProvider, User>(
    selector: (context, provider) => provider.getUser(userId)!,
    builder: (context, user, _) => Card(
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
    ),
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
                  controller: _titleTextController,
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
                  controller: _descriptionTextController,
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
                (_isAutoDistribute && _autoDistributeError.abs() >= 0.00001 && _userIds.isNotEmpty) ? Center(
                  child: Consumer<SettingsProvider>(
                    builder: (context, value, _) => Text('Rounding Error: ${_autoDistributeError<0 ? 'Overcharging' : 'Losing'} ${(_autoDistributeError/_userIds.length).abs().toStringAsFixed(3)}${value.currency}/person (real total: ${getRealTotal().toStringAsFixed(2)} ${value.currency})')
                  )
                ) : Container(),
                // CHOOSE USERS BTN
                TextButton(onPressed: _isSaving ? null : onSelectUsersClick, child: const Text('Choose users')),
                // USERS LIST
                Column(
                  children: _userIds.map(buildUserCard).toList(),
                ),
                // SUBMIT BTN
                AspectRatio(
                  aspectRatio: 4.5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: (_isSaving || _userIds.isEmpty) ? null : onSubmitClick,
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
