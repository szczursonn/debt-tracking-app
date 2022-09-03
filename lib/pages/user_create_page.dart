import 'dart:typed_data';

import 'package:debt_tracking_app/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';

class UserCreatePage extends StatefulWidget {
  const UserCreatePage({Key? key, this.editedUser}) : super(key: key);

  final User? editedUser;

  @override
  State<UserCreatePage> createState() => _UserCreatePageState();
}

class _UserCreatePageState extends State<UserCreatePage> {

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  bool _saving = false;
  String _name = '';
  Uint8List? _avatar;

  Future pickImage(ImageSource source) async {
    XFile? file = await _picker.pickImage(source: source, imageQuality: 20, maxHeight: 256, maxWidth: 256);
    if (file == null) return;
    var avatar = await file.readAsBytes();

    if (!mounted) return;
    Navigator.pop(context);
    setState(() {
      _avatar = avatar;
    });
  }

  void onSubmitClick() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);
      late User user;
      if (widget.editedUser == null) {
        user = await DatabaseHelper.instance.createUser(_name, _avatar);
      } else {
        user = await DatabaseHelper.instance.updateUser(User.fromMap({
          'id': widget.editedUser!.id,
          'name': _name,
          'avatar': _avatar
        }));
      }
      
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, user);
    }
  }

  void onAvatarClick() {
    showModalBottomSheet(context: context, builder: (context) => Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10)
        )
      ),
      height: _avatar == null ? 120 : 180,
      child: Column(
        children: [
          _avatar == null ? Container() : ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Remove avatar'),
            onTap: () {
              setState(() {
                _avatar = null;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.collections),
            title: const Text('Select from gallery'),
            onTap: () => pickImage(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Use the camera'),
            onTap: () => pickImage(ImageSource.camera),
          ),
        ],
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
    if (widget.editedUser != null) {
      setState(() {
        _name = widget.editedUser!.name;
        _avatar = widget.editedUser!.avatar;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_saving) Navigator.pop(context, null);

        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editedUser == null ? 'Create new user' : 'Edit user'),
        ),
        body: Container(
          margin: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                InkWell(
                  onTap: onAvatarClick,
                  child: _avatar == null ? const CircleAvatar(
                    backgroundColor: Colors.amber,
                    radius: 64,
                    child: Icon(Icons.add_a_photo)
                  ) : CircleAvatar(
                    backgroundImage: MemoryImage(_avatar!),
                    radius: 64,
                  ),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: UnderlineInputBorder()
                  ),
                  initialValue: widget.editedUser?.name,
                  onChanged: (String? value) {
                    if (value != null) setState(() => _name = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name cannot be empty';
                    }
                    return null;
                  },
                ),
                AspectRatio(
                  aspectRatio: 4.5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: _saving ? null : onSubmitClick,
                      child: Text(widget.editedUser == null ? 'Create' : 'Edit'),
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
