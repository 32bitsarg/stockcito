import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/cliente.dart';
import '../../../services/datos/datos.dart';

// Importar widgets refactorizados
import 'widgets/clientes_header.dart';
import 'widgets/clientes_busqueda.dart';
import 'widgets/clientes_lista.dart';
import 'widgets/clientes_formulario.dart';
import 'widgets/clientes_confirmacion_eliminar.dart';

// Importar funciones
import 'functions/clientes_functions.dart';

class GestionClientesScreen extends StatefulWidget {
  const GestionClientesScreen({super.key});

  @override
  State<GestionClientesScreen> createState() => _GestionClientesScreenState();
}

class _GestionClientesScreenState extends State<GestionClientesScreen> {
  final DatosService _datosService = DatosService();
  List<Cliente> _clientes = [];
  bool _isLoading = true;
  String _filtroBusqueda = '';

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    try {
      final clientes = await _datosService.getClientes();
      setState(() {
        _clientes = clientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ClientesFunctions.showErrorSnackBar(context, ClientesFunctions.getCargaErrorText(e.toString()));
      }
    }
  }

  List<Cliente> get _clientesFiltrados {
    return ClientesFunctions.filterClientes(_clientes, _filtroBusqueda);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  ClientesHeader(onNuevoCliente: _nuevoCliente),
                  const SizedBox(height: 24),
                  // Búsqueda
                  ClientesBusqueda(
                    filtroBusqueda: _filtroBusqueda,
                    onBusquedaChanged: (value) => setState(() => _filtroBusqueda = value),
                    onLimpiarBusqueda: () => setState(() => _filtroBusqueda = ''),
                  ),
                  const SizedBox(height: 24),
                  // Lista de clientes
                  ClientesLista(
                    clientes: _clientesFiltrados,
                    onEditarCliente: _editarCliente,
                    onEliminarCliente: _eliminarCliente,
                  ),
                ],
              ),
            ),
    );
  }

  void _nuevoCliente() {
    _mostrarFormularioCliente();
  }

  void _editarCliente(Cliente cliente) {
    _mostrarFormularioCliente(cliente: cliente);
  }

  void _mostrarFormularioCliente({Cliente? cliente}) {
    final isEditing = cliente != null;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ClientesFormulario(
              isEditing: isEditing,
              cliente: cliente,
              onGuardar: _guardarCliente,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardarCliente({
    required bool isEditing,
    Cliente? cliente,
    required String nombre,
    required String telefono,
    required String email,
    required String direccion,
    required String notas,
  }) async {
    try {
      if (isEditing && cliente != null) {
        // Actualizar cliente existente
        final clienteActualizado = ClientesFunctions.updateCliente(
          cliente: cliente,
          nombre: nombre,
          telefono: telefono,
          email: email,
          direccion: direccion,
          notas: notas,
        );
        await _datosService.updateCliente(clienteActualizado);
      } else {
        // Crear nuevo cliente
        final nuevoCliente = ClientesFunctions.createCliente(
          nombre: nombre,
          telefono: telefono,
          email: email,
          direccion: direccion,
          notas: notas,
        );
        await _datosService.saveCliente(nuevoCliente);
      }

      // Cerrar modal y recargar datos
      Navigator.of(context).pop();
      await _loadClientes();

      if (mounted) {
        final mensaje = isEditing 
            ? ClientesFunctions.getActualizacionSuccessText()
            : ClientesFunctions.getCreacionSuccessText();
        ClientesFunctions.showSuccessSnackBar(context, mensaje);
      }
    } catch (e) {
      if (mounted) {
        ClientesFunctions.showErrorSnackBar(context, ClientesFunctions.getGuardadoErrorText(e.toString()));
      }
    }
  }

  Future<void> _eliminarCliente(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => ClientesConfirmacionEliminar(
        cliente: cliente,
        onConfirmar: (cliente) => Navigator.of(context).pop(true),
      ),
    );

    if (confirmar == true) {
      try {
        await _datosService.deleteCliente(cliente.id!);
        await _loadClientes();

        if (mounted) {
          ClientesFunctions.showSuccessSnackBar(
            context, 
            ClientesFunctions.getEliminacionSuccessText(cliente.nombre)
          );
        }
      } catch (e) {
        if (mounted) {
          ClientesFunctions.showErrorSnackBar(
            context, 
            ClientesFunctions.getEliminacionErrorText(e.toString())
          );
        }
      }
    }
  }
}
