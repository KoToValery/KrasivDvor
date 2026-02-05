import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider_new.dart';
import '../../../models/client.dart';

class ContactManagementScreen extends StatefulWidget {
  const ContactManagementScreen({super.key});

  @override
  State<ContactManagementScreen> createState() =>
      _ContactManagementScreenState();
}

class _ContactManagementScreenState extends State<ContactManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление на контакти'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddContactDialog(),
            tooltip: 'Добави контакт',
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contacts,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Все още няма контакти',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавете контакти за ландшафтен архитект и градинар',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddContactDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Добави първи контакт'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: adminProvider.contacts.length,
            itemBuilder: (context, index) {
              final contact = adminProvider.contacts[index];
              return _buildContactCard(contact);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getContactColor(contact.type),
          child: Icon(
            _getContactIcon(contact.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.role),
            if (contact.phone != null) Text(contact.phone!),
            if (contact.email != null) Text(contact.email!),
            if (contact.address != null) Text(contact.address!),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditContactDialog(contact),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(contact),
            ),
          ],
        ),
        onTap: () => _showContactDetails(contact),
      ),
    );
  }

  Color _getContactColor(String type) {
    switch (type.toLowerCase()) {
      case 'architect':
        return Colors.blue;
      case 'gardener':
        return Colors.green;
      case 'contractor':
        return Colors.orange;
      case 'supplier':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getContactIcon(String type) {
    switch (type.toLowerCase()) {
      case 'architect':
        return Icons.architecture;
      case 'gardener':
        return Icons.eco;
      case 'contractor':
        return Icons.construction;
      case 'supplier':
        return Icons.local_shipping;
      default:
        return Icons.person;
    }
  }

  void _showAddContactDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    String selectedType = 'architect';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добави нов контакт'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Type
                  Text(
                    'Тип контакт',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'architect', label: Text('Архитект')),
                      ButtonSegment(value: 'gardener', label: Text('Градинар')),
                      ButtonSegment(
                          value: 'contractor', label: Text('Изпълнител')),
                      ButtonSegment(
                          value: 'supplier', label: Text('Доставчик')),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        selectedType = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Име *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Моля въведете име';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role
                  TextFormField(
                    controller: roleController,
                    decoration: const InputDecoration(
                      labelText: 'Длъжност/Роля *',
                      prefixIcon: Icon(Icons.work),
                      hintText: 'например: Ландшафтен архитект',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Моля въведете длъжност';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Телефон',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Address
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Адрес',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отказ'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _addContact(
                    type: selectedType,
                    name: nameController.text,
                    role: roleController.text,
                    phone: phoneController.text.isEmpty
                        ? null
                        : phoneController.text,
                    email: emailController.text.isEmpty
                        ? null
                        : emailController.text,
                    address: addressController.text.isEmpty
                        ? null
                        : addressController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Добави'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditContactDialog(Contact contact) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: contact.name);
    final roleController = TextEditingController(text: contact.role);
    final phoneController = TextEditingController(text: contact.phone ?? '');
    final emailController = TextEditingController(text: contact.email ?? '');
    final addressController =
        TextEditingController(text: contact.address ?? '');
    String selectedType = contact.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Редактирай контакт'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Type
                  Text(
                    'Тип контакт',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'architect', label: Text('Архитект')),
                      ButtonSegment(value: 'gardener', label: Text('Градинар')),
                      ButtonSegment(
                          value: 'contractor', label: Text('Изпълнител')),
                      ButtonSegment(
                          value: 'supplier', label: Text('Доставчик')),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        selectedType = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Име *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Моля въведете име';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role
                  TextFormField(
                    controller: roleController,
                    decoration: const InputDecoration(
                      labelText: 'Длъжност/Роля *',
                      prefixIcon: Icon(Icons.work),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Моля въведете длъжност';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Телефон',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Address
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Адрес',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отказ'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _updateContact(
                    contact,
                    type: selectedType,
                    name: nameController.text,
                    role: roleController.text,
                    phone: phoneController.text.isEmpty
                        ? null
                        : phoneController.text,
                    email: emailController.text.isEmpty
                        ? null
                        : emailController.text,
                    address: addressController.text.isEmpty
                        ? null
                        : addressController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Запази'),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDetails(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.work, contact.role),
              if (contact.phone != null)
                _buildDetailRow(Icons.phone, contact.phone!),
              if (contact.email != null)
                _buildDetailRow(Icons.email, contact.email!),
              if (contact.address != null)
                _buildDetailRow(Icons.location_on, contact.address!),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getContactColor(contact.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(_getContactIcon(contact.type),
                        color: _getContactColor(contact.type)),
                    const SizedBox(width: 8),
                    Text(_getContactTypeLabel(contact.type)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Затвори'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _getContactTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'architect':
        return 'Ландшафтен архитект';
      case 'gardener':
        return 'Градинар';
      case 'contractor':
        return 'Изпълнител';
      case 'supplier':
        return 'Доставчик';
      default:
        return 'Контакт';
    }
  }

  void _showDeleteConfirmation(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изтриване на контакт'),
        content: Text(
            'Сигурни ли сте, че искате да изтриете контакта "${contact.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteContact(contact);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Изтрий'),
          ),
        ],
      ),
    );
  }

  void _addContact({
    required String type,
    required String name,
    required String role,
    String? phone,
    String? email,
    String? address,
  }) {
    final adminProvider = context.read<AdminProvider>();
    adminProvider
        .addContact(
      type: type,
      name: name,
      role: role,
      phone: phone,
      email: email,
      address: address,
    )
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Контактът "$name" е добавен успешно')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Грешка при добавяне: $error')),
      );
    });
  }

  void _updateContact(
    Contact contact, {
    required String type,
    required String name,
    required String role,
    String? phone,
    String? email,
    String? address,
  }) {
    final adminProvider = context.read<AdminProvider>();
    adminProvider
        .updateContact(
      contact,
      type: type,
      name: name,
      role: role,
      phone: phone,
      email: email,
      address: address,
    )
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Контактът "$name" е обновен успешно')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Грешка при обновяване: $error')),
      );
    });
  }

  void _deleteContact(Contact contact) {
    final adminProvider = context.read<AdminProvider>();
    adminProvider.deleteContact(contact).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Контактът "${contact.name}" е изтрит успешно')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Грешка при изтриване: $error')),
      );
    });
  }
}
