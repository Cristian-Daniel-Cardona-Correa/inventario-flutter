import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/producto.dart';
import '../../services/producto_service.dart';

class ProductoFormScreen extends StatefulWidget {
  final int? productoId;

  const ProductoFormScreen({super.key, this.productoId});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductoService _productoService = ProductoService();

  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _categoriaController = TextEditingController();

  bool _isEditing = false;
  bool _isLoadingInitial = false;
  bool _isSubmitting = false;
  String? _serverErrorMessage;

  // Categorías sugeridas
  final List<String> _categoriasSugeridas = [
    'Computadores',
    'Periféricos',
    'Monitores',
    'Audio',
    'Almacenamiento',
    'Accesorios',
    'Mobiliario',
    'Impresoras',
    'Redes',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.productoId != null;
    if (_isEditing) {
      _cargarProductoExistente();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _cantidadController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductoExistente() async {
    setState(() {
      _isLoadingInitial = true;
    });

    try {
      final producto = await _productoService.obtenerPorId(widget.productoId!);
      if (mounted) {
        setState(() {
          _nombreController.text = producto.nombre;
          _codigoController.text = producto.codigo;
          _descripcionController.text = producto.descripcion ?? '';
          _precioController.text = producto.precio.toString();
          _cantidadController.text = producto.cantidad.toString();
          _categoriaController.text = producto.categoria;
          _isLoadingInitial = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverErrorMessage = e.toString();
          _isLoadingInitial = false;
        });
      }
    }
  }

  Future<void> _guardar() async {
    // Limpiar mensaje previo
    setState(() {
      _serverErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String nombre = _nombreController.text.trim();
    final String codigo = _codigoController.text.trim();
    final String descripcion = _descripcionController.text.trim();
    final double? precio = double.tryParse(_precioController.text.trim());
    final int? cantidad = int.tryParse(_cantidadController.text.trim());
    final String categoria = _categoriaController.text.trim();

    if (precio == null || precio <= 0) {
      setState(() {
        _serverErrorMessage = 'El precio debe ser un número decimal mayor a 0';
      });
      return;
    }

    if (cantidad == null || cantidad < 0) {
      setState(() {
        _serverErrorMessage = 'La cantidad debe ser un número entero mayor o igual a 0';
      });
      return;
    }

    final data = {
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion.isEmpty ? null : descripcion,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria,
    };

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isEditing) {
        await _productoService.actualizar(widget.productoId!, data);
      } else {
        await _productoService.crear(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Producto "$nombre" actualizado correctamente'
                  : 'Producto "$nombre" registrado con éxito',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverErrorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_serverErrorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _serverErrorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Producto *',
                        hintText: 'Ej: Monitor LG 27 pulgadas',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Código único
                    TextFormField(
                      controller: _codigoController,
                      decoration: const InputDecoration(
                        labelText: 'Código Único *',
                        hintText: 'Ej: MON-002',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El código es obligatorio y debe ser único';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Categoría
                    TextFormField(
                      controller: _categoriaController,
                      decoration: InputDecoration(
                        labelText: 'Categoría *',
                        hintText: 'Selecciona o escribe una categoría',
                        prefixIcon: const Icon(Icons.category_outlined),
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (cat) {
                            _categoriaController.text = cat;
                          },
                          itemBuilder: (context) => _categoriasSugeridas
                              .map(
                                (c) => PopupMenuItem(
                                  value: c,
                                  child: Text(c),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La categoría es obligatoria';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fila de Precio y Cantidad
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _precioController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Precio Unitario *',
                              hintText: '0.00',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El precio es requerido';
                              }
                              final n = double.tryParse(value.trim());
                              if (n == null || n <= 0) {
                                return 'Mayor a 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cantidadController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad *',
                              hintText: '0',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              final n = int.tryParse(value.trim());
                              if (n == null || n < 0) {
                                return '0 o mayor';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (Opcional)',
                        hintText: 'Detalles, especificaciones o notas del producto...',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botón de guardar
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing
                                  ? 'Actualizar Producto'
                                  : 'Registrar Producto',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
