import 'dart:typed_data';

import 'package:debt_tracking_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models.dart';

class UserCreatePage extends StatefulWidget {
  const UserCreatePage({Key? key, this.editedUserId}) : super(key: key);

  final int? editedUserId;

  @override
  State<UserCreatePage> createState() => _UserCreatePageState();
}

class _UserCreatePageState extends State<UserCreatePage> {

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final TextEditingController _nameTextController = TextEditingController(text: '');

  bool _saving = false;
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
      
      var userProvider = Provider.of<UserProvider>(context, listen: false);

      if (widget.editedUserId == null) {
        await userProvider.createUser(_nameTextController.text, _avatar);
      } else {
        await userProvider.updateUser(User(
          id: widget.editedUserId!, 
          name: _nameTextController.text, 
          avatar: _avatar
        ));
      }
      
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context);
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
    if (widget.editedUserId != null) {
      var provider = Provider.of<UserProvider>(context, listen: false);
      var user = provider.getUser(widget.editedUserId!);
      if (user != null) {
        setState(() {
          _nameTextController.text = user.name;
          _avatar = user.avatar;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _nameTextController.dispose();
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
          title: Text(widget.editedUserId == null ? 'Create new user' : 'Edit user'),
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
                    child: Icon(Icons.add_a_photo, size: 32)
                  ) : CircleAvatar(
                    backgroundImage: MemoryImage(_avatar!),
                    radius: 64,
                  ),
                ),
                TextFormField(
                  controller: _nameTextController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: UnderlineInputBorder()
                  ),
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
                      child: Text(widget.editedUserId == null ? 'Create' : 'Edit'),
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
