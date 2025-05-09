// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../auth_model.dart';

// class EditProfilePage extends StatefulWidget {
//   const EditProfilePage({super.key});

//   @override
//   State<EditProfilePage> createState() => _EditProfilePageState();
// }

// class _EditProfilePageState extends State<EditProfilePage> {
//   late TextEditingController _emailController;
//   late TextEditingController _passwordController;

//   @override
//   void initState() {
//     super.initState();
//     final auth = Provider.of<AuthModel>(context, listen: false);
//     _emailController = TextEditingController(text: auth.email);
//     _passwordController = TextEditingController(text: auth.password);
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _saveChanges() {
//     final newEmail = _emailController.text.trim();
//     final newPassword = _passwordController.text.trim();

//     if (newEmail.isNotEmpty && newPassword.isNotEmpty) {
//       Provider.of<AuthModel>(context, listen: false).login(newEmail, newPassword);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('تم حفظ التغييرات')),
//       );
//       Navigator.pop(context);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('الرجاء ملء كل الحقول')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('تعديل الحساب')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: const InputDecoration(labelText: 'كلمة المرور'),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _saveChanges,
//               child: const Text('حفظ التغييرات'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
