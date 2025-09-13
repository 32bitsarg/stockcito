import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/cliente.dart';
import '../../../widgets/windows_button.dart';
import '../functions/clientes_functions.dart';

class ClientesLista extends StatelessWidget {
  final List<Cliente> clientes;
  final Function(Cliente) onEditarCliente;
  final Function(Cliente) onEliminarCliente;

  const ClientesLista({
    super.key,
    required this.clientes,
    required this.onEditarCliente,
    required this.onEliminarCliente,
  });

  @override
  Widget build(BuildContext context) {
    if (clientes.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la tabla
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Clientes Registrados (${clientes.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Lista de clientes
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return _buildClienteCard(context, cliente);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard(BuildContext context, Cliente cliente) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar del cliente
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Información del cliente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(context, cliente.telefono, Icons.phone),
                    const SizedBox(width: 8),
                    if (ClientesFunctions.hasEmail(cliente))
                      _buildInfoChip(context, cliente.email, Icons.email),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(context, ClientesFunctions.getComprasText(cliente.totalCompras), Icons.shopping_bag),
                    const SizedBox(width: 8),
                    _buildInfoChip(context, ClientesFunctions.getGastoTotalText(cliente.totalGastado), Icons.attach_money),
                  ],
                ),
              ],
            ),
          ),
          // Botones de acción
          Row(
            children: [
              WindowsButton(
                text: 'Editar',
                type: ButtonType.secondary,
                onPressed: () => onEditarCliente(cliente),
                icon: Icons.edit,
              ),
              const SizedBox(width: 8),
              WindowsButton(
                text: 'Eliminar',
                type: ButtonType.secondary,
                onPressed: () => onEliminarCliente(cliente),
                icon: Icons.delete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay clientes registrados',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comienza agregando tu primer cliente',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          WindowsButton(
            text: 'Nuevo Cliente',
            type: ButtonType.primary,
            onPressed: () => onEditarCliente(Cliente(
              nombre: '',
              telefono: '',
              email: '',
              direccion: '',
              fechaRegistro: DateTime.now(),
              notas: '',
            )),
            icon: Icons.person_add,
          ),
        ],
      ),
    );
  }
}
