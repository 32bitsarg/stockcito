import 'package:flutter/material.dart';
import '../../../models/cliente.dart';
import '../functions/clientes_functions.dart';

class ClientesConfirmacionEliminar extends StatelessWidget {
  final Cliente cliente;
  final Function(Cliente) onConfirmar;

  const ClientesConfirmacionEliminar({
    super.key,
    required this.cliente,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: Text(ClientesFunctions.getEliminacionText(cliente.nombre)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirmar(cliente);
          },
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
