import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as app;
import '../../../../data/models/user_model.dart';
import '../providers/users_provider.dart';
import '../../../farms/presentation/providers/farms_provider.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(usersProvider.notifier).loadUsers();
      ref.read(farmsProvider.notifier).loadFarms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(usersProvider.notifier).loadUsers();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(usersProvider.notifier).loadUsers();
        },
        child: _buildBody(usersState),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Usuario'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildBody(UsersState state) {
    if (state.isLoading && state.users.isEmpty) {
      return const LoadingWidget(message: 'Cargando usuarios...');
    }

    if (state.error != null && state.users.isEmpty) {
      return app.ErrorWidget(
        message: state.error!,
        onRetry: () {
          ref.read(usersProvider.notifier).loadUsers();
        },
      );
    }

    if (state.users.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = state.users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay usuarios registrados',
            style: AppTextStyles.textTheme.headlineMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea el primer usuario presionando el botón +',
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showUserDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Crear Usuario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navegar a detalle de usuario
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _getRoleColor(
                  user.role ?? 'Worker',
                ).withValues(alpha: 0.1),
                child: Icon(
                  _getRoleIcon(user.role ?? 'Worker'),
                  color: _getRoleColor(user.role ?? 'Worker'),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${user.firstName} ${user.lastName}',
                            style: AppTextStyles.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!user.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'INACTIVO',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRoleText(user.role ?? 'Worker'),
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: _getRoleColor(user.role ?? 'Worker'),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.email,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            user.phone!,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showUserDialog(context, user);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, user);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDialog(BuildContext context, UserModel? user) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(
      text: user?.username ?? '',
    );
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController(
      text: user?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: user?.lastName ?? '',
    );
    final identificationController = TextEditingController(
      text: user?.identification ?? '',
    );
    final phoneController = TextEditingController(text: user?.phone ?? '');

    String selectedRole = user?.role ?? 'Worker';
    int? selectedFarmId = user?.assignedFarm;
    bool isActive = user?.isActive ?? true;

    final farmsState = ref.read(farmsProvider);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(user == null ? 'Nuevo Usuario' : 'Editar Usuario'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      hintText: 'Ingrese el usuario',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el usuario';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      hintText: 'usuario@ejemplo.com',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el correo';
                      }
                      if (!value.contains('@')) {
                        return 'Ingrese un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: user == null
                          ? 'Contraseña'
                          : 'Contraseña (opcional)',
                      hintText: 'Ingrese la contraseña',
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (user == null && (value == null || value.isEmpty)) {
                        return 'Por favor ingrese una contraseña';
                      }
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ingrese el nombre',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                      hintText: 'Ingrese el apellido',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el apellido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: identificationController,
                    decoration: const InputDecoration(
                      labelText: 'Identificación',
                      hintText: 'Ingrese la cédula',
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      hintText: 'Ingrese el teléfono',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Admin',
                        child: Text('Administrador'),
                      ),
                      DropdownMenuItem(
                        value: 'Farm Manager',
                        child: Text('Gerente de Granja'),
                      ),
                      DropdownMenuItem(
                        value: 'Worker',
                        child: Text('Trabajador'),
                      ),
                      DropdownMenuItem(
                        value: 'Veterinarian',
                        child: Text('Veterinario'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedRole = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedFarmId,
                    decoration: const InputDecoration(
                      labelText: 'Granja Asignada',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin asignar'),
                      ),
                      ...farmsState.farms.map(
                        (farm) => DropdownMenuItem(
                          value: farm.id,
                          child: Text(farm.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedFarmId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Usuario Activo'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop();

                  final data = {
                    'username': usernameController.text,
                    'email': emailController.text,
                    'first_name': firstNameController.text,
                    'last_name': lastNameController.text,
                    'role': selectedRole,
                    'is_active': isActive,
                    if (passwordController.text.isNotEmpty)
                      'password': passwordController.text,
                    if (identificationController.text.isNotEmpty)
                      'identification': identificationController.text,
                    if (phoneController.text.isNotEmpty)
                      'phone': phoneController.text,
                    if (selectedFarmId != null) 'assigned_farm': selectedFarmId,
                  };

                  if (user == null) {
                    await ref
                        .read(usersProvider.notifier)
                        .createUser(
                          username: data['username'] as String,
                          email: data['email'] as String,
                          password: data['password'] as String,
                          firstName: data['first_name'] as String,
                          lastName: data['last_name'] as String,
                          identification:
                              data['identification'] as String? ?? '',
                          phone: data['phone'] as String? ?? '',
                          role: data['role'] as String,
                          assignedFarm: data['assigned_farm'] as int?,
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Usuario creado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    await ref
                        .read(usersProvider.notifier)
                        .updateUser(
                          id: user.id,
                          username: data['username'] as String?,
                          email: data['email'] as String?,
                          firstName: data['first_name'] as String?,
                          lastName: data['last_name'] as String?,
                          identification: data['identification'] as String?,
                          phone: data['phone'] as String?,
                          role: data['role'] as String?,
                          assignedFarm: data['assigned_farm'] as int?,
                          isActive: data['is_active'] as bool?,
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Usuario actualizado exitosamente'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(user == null ? 'Crear' : 'Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Está seguro de que desea eliminar al usuario ${user.firstName} ${user.lastName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(usersProvider.notifier).deleteUser(user.id);
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario eliminado exitosamente'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'Admin':
        return 'Administrador';
      case 'Farm Manager':
        return 'Gerente de Granja';
      case 'Worker':
        return 'Trabajador';
      case 'Veterinarian':
        return 'Veterinario';
      default:
        return role;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Farm Manager':
        return Icons.business;
      case 'Worker':
        return Icons.construction;
      case 'Veterinarian':
        return Icons.medical_services;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.purple;
      case 'Farm Manager':
        return Colors.blue;
      case 'Worker':
        return Colors.orange;
      case 'Veterinarian':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
