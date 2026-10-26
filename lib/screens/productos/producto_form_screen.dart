import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_client.dart';
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
  final ImagePicker _picker = ImagePicker();

  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _imagenUrlController = TextEditingController();

  bool _isEditing = false;
  bool _isLoadingInitial = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
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
    _imagenUrlController.addListener(() {
      setState(() {});
    });
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
    _imagenUrlController.dispose();
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
          _imagenUrlController.text = producto.imagenUrl ?? '';
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

  Future<void> _seleccionarYSubirImagen(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
        _serverErrorMessage = null;
      });

      final String uploadedUrl = await _productoService.subirImagen(pickedFile);

      if (mounted) {
        setState(() {
          _imagenUrlController.text = uploadedUrl;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen subida con éxito al servidor'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _serverErrorMessage = 'Error al subir la imagen: $e';
        });
      }
    }
  }

  Future<void> _guardar() async {
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
    final String imagenUrl = _imagenUrlController.text.trim();

    if (precio == null || precio <= 0) {
      setState(() {
        _serverErrorMessage = 'El precio debe ser un número decimal mayor a 0';
      });
      return;
    }

    if (cantidad == null || cantidad < 0) {
      setState(() {
        _serverErrorMessage =
            'La cantidad debe ser un número entero mayor o igual a 0';
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
      'imagenUrl': imagenUrl.isEmpty ? null : imagenUrl,
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

  String? _resolvePreviewUrl() {
    final text = _imagenUrlController.text.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }
    final uri = Uri.tryParse(ApiClient.instance.client.options.baseUrl);
    if (uri != null) {
      return '${uri.scheme}://${uri.host}:${uri.port}$text';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _resolvePreviewUrl();

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

                    // SECCIÓN DE IMAGEN
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.image,
                                    color: Color(0xFF1565C0), size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Imagen del Producto',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (previewUrl != null)
                                  TextButton.icon(
                                    onPressed: () {
                                      _imagenUrlController.clear();
                                    },
                                    icon: const Icon(Icons.close,
                                        size: 16, color: Colors.red),
                                    label: const Text(
                                      'Quitar',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Vista previa de imagen
                            Center(
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: _isUploadingImage
                                    ? const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 10),
                                          Text(
                                            'Subiendo imagen al servidor...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      )
                                    : previewUrl != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              previewUrl,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  progress) {
                                                if (progress == null) {
                                                  return child;
                                                }
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stack) {
                                                return const Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.broken_image,
                                                          color: Colors.grey,
                                                          size: 40),
                                                      SizedBox(height: 6),
                                                      Text(
                                                        'URL de imagen no válida',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_photo_alternate_outlined,
                                                  size: 44,
                                                  color: Colors.grey.shade400,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Sin imagen seleccionada',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Botones para tomar foto o elegir de galería
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isUploadingImage
                                        ? null
                                        : () => _seleccionarYSubirImagen(
                                            ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    label: const Text('Tomar foto'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isUploadingImage
                                        ? null
                                        : () => _seleccionarYSubirImagen(
                                            ImageSource.gallery),
                                    icon:
                                        const Icon(Icons.photo_library, size: 18),
                                    label: const Text('De galería'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Campo de texto para URL manual
                            TextFormField(
                              controller: _imagenUrlController,
                              decoration: const InputDecoration(
                                labelText: 'O ingresa una URL de imagen',
                                hintText: 'https://ejemplo.com/imagen.jpg',
                                prefixIcon: Icon(Icons.link),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                        hintText:
                            'Detalles, especificaciones o notas del producto...',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botón de guardar
                    ElevatedButton(
                      onPressed: _isSubmitting || _isUploadingImage
                          ? null
                          : _guardar,
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
