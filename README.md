# Frontend Móvil — Aplicación Flutter con Autenticación JWT y Protección de Servicios

Aplicación móvil desarrollada en **Flutter** para la administración de inventario de productos de un establecimiento comercial. Consume de forma reactiva y en tiempo real la API REST desarrollada en Spring Boot utilizando el cliente HTTP **Dio**, protegida mediante **JSON Web Token (JWT)**, almacenamiento seguro y control de acceso declarativo con **go_router**.

---

## 🔐 Nuevas Características de Autenticación y Seguridad

- **Pantalla de Inicio de Sesión (`LoginScreen`)**:
  - Formulario con validación visual reactiva de campos obligatorios.
  - Conmutador para mostrar u ocultar la contraseña.
  - Botones rápidos con credenciales de prueba precargadas (`admin`, `empleado`, `profesor`).
  - Manejo detallado de errores HTTP 401 (credenciales incorrectas) y caídas de conexión.
- **Protección de Rutas (AuthGuard con `go_router`)**:
  - Restricción total de acceso: los usuarios sin autenticación no pueden ver el Dashboard ni las funciones CRUD; son redirigidos automáticamente al login.
  - Si un usuario autenticado intenta acceder al login, es redirigido al Dashboard.
  - Redirección reactiva ante expiración o invalidación del token.
- **Almacenamiento Local Seguro**:
  - `flutter_secure_storage`: Almacena el `access_token` JWT en hardware seguro (KeyStore en Android / Keychain en iOS).
  - `shared_preferences`: Almacena información pública de la sesión (nombre, email, username, estado de conexión).
- **Inyección Automática de Token JWT**:
  - Interceptor de Dio (`QueuedInterceptorsWrapper`) que agrega la cabecera `Authorization: Bearer <token>` a todas las peticiones a endpoints protegidos.
  - Detección de respuestas 401 Unauthorized para limpiar la sesión local y expulsar al login de inmediato.
- **Pantalla de Información de Sesión (`PerfilScreen`)**:
  - Nombre completo y correo del usuario autenticado.
  - Rol de usuario (`ROLE_ADMIN` / `ROLE_USER`).
  - Estado de autenticación ("Sesión Activa").
  - Indicador seguro de existencia del token (ofuscado, sin exponer la clave completa).
  - Botón de **Cerrar Sesión** con diálogo modal de confirmación.

---

## 📱 Funcionalidades del Inventario (CRUD Completo)

- **Dashboard Principal**:
  - Métricas en tiempo real: Total de Productos, Stock Total y **Valor Económico Total del Inventario** ($\sum \text{precio} \times \text{cantidad}$).
  - Tarjetas de últimos productos agregados con fotografías en alta resolución.
  - Accesos directos a catálogo y formulario.
- **Gestión CRUD de Productos Protegida**:
  - **Listar**: Catálogo interactivo con buscador y filtro en tiempo real.
  - **Consultar Detalle**: Ficha técnica completa con cálculo de valor económico por lote.
  - **Registrar (POST)**: Formulario con selector multimedia (cámara, galería o URL externa).
  - **Editar (PUT)**: Precarga automática de datos existentes y vista previa de imagen.
  - **Eliminar (DELETE)**: Cuadro de diálogo modal de confirmación (`AlertDialog`).

---

## 🛠️ Tecnologías y Librerías Utilizadas

- **Flutter SDK**: 3.44.x / Dart 3.12.x
- **Dio (^5.7.0)**: Cliente HTTP con interceptores JWT y timeouts de 10s.
- **go_router (^14.8.1)**: Enrutamiento declarativo y AuthGuard con `refreshListenable`.
- **flutter_secure_storage (^11.2.0)**: Almacenamiento seguro del token JWT.
- **shared_preferences (^2.5.6)**: Persistencia de datos de sesión.
- **flutter_dotenv (^5.2.1)**: Variables de entorno (`.env`).
- **image_picker (^1.2.4)**: Selección de fotos desde cámara y galería.
- **Material 3**: Componentes visuales y paleta corporativa.

---

## 📁 Estructura del Proyecto

```text
lib/
├── main.dart                       # Inicialización de dotenv, auth e inicio de runApp
├── router/
│   └── app_router.dart             # AuthGuard declarativo y ShellRoute con 3 pestañas
├── models/
│   ├── producto.dart               # Modelo Producto con fromJson / toJson
│   └── usuario.dart                # Modelo Usuario para sesión y perfil
├── services/
│   ├── api_client.dart             # Singleton Dio con interceptor Bearer JWT y control 401
│   ├── auth_service.dart           # Lógica de login, registro, logout y estado reactivo
│   ├── storage_service.dart        # Gestión con flutter_secure_storage y shared_preferences
│   └── producto_service.dart       # Consumo de endpoints protegidos CRUD de productos
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart       # Formulario de inicio de sesión con chips de prueba
│   │   └── perfil_screen.dart      # Vista de información de sesión y botón de cierre
│   ├── dashboard_screen.dart       # Dashboard principal con métricas financieras
│   └── productos/
│       ├── productos_list_screen.dart   # Catálogo con buscador en tiempo real
│       ├── producto_detail_screen.dart  # Detalle completo con imagen
│       └── producto_form_screen.dart    # Formulario unificado de creación y edición
└── widgets/
    ├── stat_card.dart              # Tarjeta reusable para métricas del dashboard
    └── producto_card.dart          # Tarjeta de producto con menú contextual
```

---

## ⚙️ Configuración e Instalación

### 1. Variables de Entorno (`.env`)
```bash
# Para emulador Android (por defecto):
API_BASE_URL=http://10.0.2.2:8080/api

# Para navegador web o emulador iOS:
# API_BASE_URL=http://localhost:8080/api

# Para dispositivo físico Android/iOS (IP de tu computador):
# API_BASE_URL=http://192.168.1.X:8080/api
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Ejecutar la aplicación
```bash
flutter run
```

---

## 🔑 Credenciales de Prueba para Login

| Usuario | Contraseña | Rol | Descripción |
|---------|------------|-----|-------------|
| `admin` | `admin123` | Administrador | Acceso total con privilegios administrativos |
| `empleado` | `empleado123` | Empleado | Acceso estándar a operaciones de inventario |
| `profesor` | `uceva2026` | Auditor / Docente | Cuenta institucional de prueba |
