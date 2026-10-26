import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/producto.dart';
import '../../services/api_client.dart';
import '../../services/producto_service.dart';

class ProductoDetailScreen extends StatefulWidget {
  final int id;

  const ProductoDetailScreen({super.key, required this.id});

  @override
  State<ProductoDetailScreen> createState() => _ProductoDetailScreenState();
}

class _ProductoDetailScreenState extends State<ProductoDetailScreen> {
  final ProductoService _productoService = ProductoService();
  Producto? _producto;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final producto = await _productoService.obtenerPorId(widget.id);
      if (mounted) {
        setState(() {
          _producto = producto;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmarEliminar() async {
    if (_producto == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar producto'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar permanentemente "${_producto!.nombre}" de la base de datos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _productoService.eliminar(widget.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "${_producto!.nombre}" eliminado'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_producto?.nombre ?? 'Detalle del Producto'),
        actions: [
          if (_producto != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: () async {
                await context.push('/productos/${widget.id}/editar');
                _cargarDetalle();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: _confirmarEliminar,
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarDetalle,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final p = _producto!;
    final bool hasStock = p.cantidad > 0;
    final String? imageUrl =
        p.resolvedImageUrl(ApiClient.instance.client.options.baseUrl);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen destacada del producto
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No se pudo cargar la imagen',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Tarjeta Principal de Información
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nombre,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID de registro: #${p.id}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  _buildDetailRow(
                    icon: Icons.qr_code,
                    label: 'Código Único',
                    value: p.codigo,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    icon: Icons.category,
                    label: 'Categoría',
                    value: p.categoria,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    icon: Icons.payments,
                    label: 'Precio Unitario',
                    value: '\$${p.precio.toStringAsFixed(2)}',
                    color: const Color(0xFF2E7D32),
                    isBold: true,
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    icon: Icons.inventory_2,
                    label: 'Cantidad en Inventario',
                    value: '${p.cantidad} unidades ${!hasStock ? '(Agotado)' : ''}',
                    color: hasStock ? Colors.blue : Colors.red,
                    isBold: true,
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    icon: Icons.calculate,
                    label: 'Valor Económico Acumulado',
                    value: '\$${p.valorTotal.toStringAsFixed(2)}',
                    color: Colors.purple,
                    isBold: true,
                  ),

                  if (p.descripcion != null && p.descripcion!.isNotEmpty) ...[
                    const Divider(height: 32),
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.descripcion!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Botones de acción inferior
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.push('/productos/${widget.id}/editar');
                    _cargarDetalle();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar Producto'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF1565C0)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmarEliminar,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: isBold ? color : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
