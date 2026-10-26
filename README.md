# Frontend Móvil — Aplicación Flutter de Gestión de Inventario

Aplicación móvil desarrollada en **Flutter** para la administración integral de inventario de productos de un establecimiento comercial. Consume de forma reactiva y en tiempo real la API REST desarrollada en Spring Boot utilizando el cliente HTTP **Dio**.

---

## 📱 Características de la Aplicación

- **Dashboard Principal**:
  - Indicadores en tiempo real: Total de productos, Total de unidades en stock y **Valor económico total del inventario** ($\sum \text{precio} \times \text{cantidad}$).
  - Actualización reactiva de métricas tras cada operación de inventario.
  - Accesos directos a la gestión de productos y registro rápido.
- **Gestión CRUD Completa**:
  - **Listar**: Catálogo interactivo con nombre, código, categoría, precio y stock. Incluye buscador y filtro en tiempo real.
  - **Consultar Detalle**: Ficha técnica completa de cada producto con cálculo de valor económico por lote.
  - **Registrar (POST)**: Formulario con validación visual para almacenar nuevos productos.
  - **Editar (PUT)**: Edición con precarga de datos existentes y validación de código único.
  - **Eliminar (DELETE)**: Eliminación con cuadro de diálogo modal de confirmación.
- **Navegación Fluida con go_router**:
  - Navegación declarativa con barra inferior (`NavigationBar`) entre Dashboard y Catálogo.
  - Rutas dinámicas para detalle (`/productos/:id`) y edición (`/productos/:id/editar`).
- **Manejo de Estados y Errores**:
  - Estados de carga con indicadores visuales (`CircularProgressIndicator`).
  - Pantallas dedicadas para error de conexión con botón de reintento.
  - Estado vacío amigable cuando no hay registros en la base de datos.
  - Notificaciones flotantes (`SnackBar`) para confirmar operaciones o señalar fallos.

---

## 🛠️ Tecnologías y Librerías Utilizadas

- **Flutter SDK**: 3.x / Dart 3.x
- **Dio (^5.7.0)**: Cliente HTTP para peticiones RESTful, configuración de timeouts e interceptores.
- **go_router (^14.0.0)**: Enrutamiento declarativo con soporte para `ShellRoute`.
- **flutter_dotenv (^5.2.1)**: Gestión de variables de entorno mediante archivo `.env`.
- **Material 3**: Componentes visuales modernos y paleta de colores coherente.

---

## 📁 Estructura del Proyecto

El proyecto implementa una arquitectura limpia y modular con estricta separación de responsabilidades:

```text
lib/
├── main.dart                       # Inicialización de dotenv y runApp con MaterialApp.router
├── router/
│   └── app_router.dart             # Configuración de go_router y barra de navegación ShellRoute
├── models/
│   └── producto.dart               # Modelo de datos Producto con serialización fromJson / toJson
├── services/
│   ├── api_client.dart             # Cliente Singleton de Dio con BaseOptions e interceptores
│   └── producto_service.dart       # Lógica de consumo de endpoints CRUD y mapeo de excepciones
├── screens/
│   ├── dashboard_screen.dart       # Pantalla principal con métricas financieras y accesos
│   └── productos/
│       ├── productos_list_screen.dart   # Listado general con buscador y pull-to-refresh
│       ├── producto_detail_screen.dart  # Detalle completo del producto
│       └── producto_form_screen.dart    # Formulario unificado de creación y edición
└── widgets/
    ├── stat_card.dart              # Tarjeta reusable para métricas del dashboard
    └── producto_card.dart          # Tarjeta de producto para el catálogo con menú de acciones
```

---

## ⚙️ Configuración e Instalación

### 1. Prerrequisitos
- Flutter SDK instalado (`flutter --version`).
- Backend en Spring Boot corriendo en el puerto `8080`.
- Emulador Android, simulador iOS, navegador web o dispositivo físico.

### 2. Configuración de Variables de Entorno
Crea o edita el archivo `.env` en la raíz del proyecto Flutter:

```bash
# Para emulador Android (por defecto):
API_BASE_URL=http://10.0.2.2:8080/api

# Para navegador web o emulador iOS:
# API_BASE_URL=http://localhost:8080/api

# Para dispositivo físico Android/iOS (reemplazar con la IP local de tu PC):
# API_BASE_URL=http://192.168.1.50:8080/api
```

### 3. Instalar dependencias
```bash
flutter pub get
```

### 4. Ejecutar la aplicación
```bash
flutter run
```

O para ejecutar directamente en la web (si está habilitado):
```bash
flutter run -d chrome
```

---

## 🔌 Consumo de la API Backend

La clase `ProductoService` se comunica directamente con los siguientes endpoints implementados en Spring Boot:

| Acción | Método HTTP | Endpoint | Descripción |
| :--- | :--- | :--- | :--- |
| **Listar** | `GET` | `/api/productos` | Obtiene la lista de todos los productos en JSON |
| **Consultar** | `GET` | `/api/productos/{id}` | Obtiene el detalle de un producto específico |
| **Registrar** | `POST` | `/api/productos` | Envía el payload JSON para crear un nuevo registro |
| **Actualizar** | `PUT` | `/api/productos/{id}` | Envía los datos modificados para actualizar |
| **Eliminar** | `DELETE`| `/api/productos/{id}` | Elimina el registro por su identificador |
