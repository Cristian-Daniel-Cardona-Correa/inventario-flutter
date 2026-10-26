import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/api_client.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductoCard({
    super.key,
    required this.producto,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasStock = producto.cantidad > 0;
    final bool lowStock = producto.cantidad > 0 && producto.cantidad <= 5;
    final String? imageUrl =
        producto.resolvedImageUrl(ApiClient.instance.client.options.baseUrl);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Contenedor de Imagen o Avatar con inicial
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 58,
                  height: 58,
                  color: const Color(0xFF1565C0).withOpacity(0.08),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackAvatar(context);
                          },
                        )
                      : _buildFallbackAvatar(context),
                ),
              ),
              const SizedBox(width: 12),

              // Información del Producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            producto.codigo,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              producto.categoria,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '\$${producto.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: !hasStock
                                ? Colors.red.shade50
                                : lowStock
                                    ? Colors.amber.shade50
                                    : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                !hasStock
                                    ? Icons.cancel
                                    : lowStock
                                        ? Icons.warning_amber
                                        : Icons.check_circle,
                                size: 11,
                                color: !hasStock
                                    ? Colors.red
                                    : lowStock
                                        ? Colors.amber.shade800
                                        : Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${producto.cantidad} un.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: !hasStock
                                      ? Colors.red
                                      : lowStock
                                          ? Colors.amber.shade800
                                          : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menú de opciones
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    return Center(
      child: Text(
        producto.nombre.isNotEmpty ? producto.nombre[0].toUpperCase() : 'P',
        style: const TextStyle(
          color: Color(0xFF1565C0),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
