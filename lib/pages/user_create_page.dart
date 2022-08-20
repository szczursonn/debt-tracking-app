import 'dart:io';

import 'package:debt_tracking_app/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';

class UserCreatePage extends StatefulWidget {
  const UserCreatePage({Key? key}) : super(key: key);

  @override
  State<UserCreatePage> createState() => _UserCreatePageState();
}

class _UserCreatePageState extends State<UserCreatePage> {

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  bool _saving = false;
  String _name = '';
  XFile? _avatar;

  void onSubmitClick() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);
      User user = await DatabaseHelper.instance.createUser(_name);
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
      height: 120,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.collections),
            title: const Text('Select from gallery'),
            onTap: () async {
              var picked = await _picker.pickImage(source: ImageSource.gallery);
              if (!mounted) return;
              if (picked != null) setState(()=>_avatar=picked);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Use the camera'),
            onTap: () async {
              var picked = await _picker.pickImage(source: ImageSource.camera);
              if (!mounted) return;
              if (picked != null) setState(()=>_avatar=picked);
              Navigator.pop(context);
            },
          )
        ],
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
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
          title: const Text('Create new user'),
        ),
        body: Container(
          margin: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Stack(
                  children: [
                    InkWell(
                      onTap: onAvatarClick,
                      child: _avatar == null ? const CircleAvatar(
                        backgroundColor: Colors.amber,
                        radius: 64,
                        child: Icon(Icons.add_a_photo)
                      ) : CircleAvatar(
                        backgroundImage: FileImage(File(_avatar!.path)),
                        radius: 64,
                      ),
                    ),
                    Positioned(
                      right: -8,
                      bottom: 0,
                      child: _avatar != null ? SizedBox(
                        height: 40,
                        child: FloatingActionButton(
                          onPressed: () {setState(()=>_avatar=null);},
                          child: const Icon(Icons.delete)
                        ),
                      ) : Container(),
                    ),
                  ],
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: UnderlineInputBorder()
                  ),
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
