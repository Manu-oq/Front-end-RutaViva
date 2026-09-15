# Documentación técnica — Cliente Flutter Ruta Viva

## 1. Propósito y alcance

Este documento describe el estado actual del cliente Flutter de Ruta Viva. Está dirigido a quien necesite ejecutarlo, revisarlo o extenderlo; no funciona como bitácora ni como registro de etapas del proyecto.

La aplicación consume el backend de Ruta Viva para mostrar puntos de interés, administrar perfiles, favoritos, reseñas e itinerarios, y ofrecer el asistente Ara cuando el backend tiene sus proveedores configurados.

La referencia de contratos HTTP es el backend. Los repositories de este proyecto son la referencia de qué endpoints utiliza el cliente actualmente.

## 2. Arquitectura

```text
main.dart
  └── ProviderScope
       └── MaterialApp.router
            ├── GoRouter y guard de sesión
            ├── Shell de navegación principal
            └── Features
                 ├── repositories y modelos
                 ├── providers/notifiers
                 └── páginas y widgets
                       │
                       ▼
                    DioClient
                       │ REST / SSE
                       ▼
                 Backend FastAPI
```

El proyecto usa una organización práctica `core/` + `features/`. `core/` contiene infraestructura transversal; cada feature concentra sus modelos, acceso a datos, estado y UI. No todas las features requieren las mismas capas, por lo que la estructura no fuerza abstracciones vacías.

## 3. Estructura

```text
lib/
├── core/
│   ├── constants/      configuración de URL de API
│   ├── error/          normalización de errores HTTP
│   ├── network/        Dio, token y refresh
│   ├── router/         rutas, guard y navegación segura
│   ├── storage/        shared_preferences
│   ├── theme/          tema y modo visual
│   ├── utils/          responsive, fechas, ubicación y URL
│   └── widgets/        componentes compartidos
├── features/
│   ├── auth/           sesión, registro y perfiles
│   ├── bookmarks/      favoritos
│   ├── categories/     categorías y estilo visual
│   ├── chat_ai/        asistente Ara y streaming SSE
│   ├── entrepreneur/   dashboards y publicaciones
│   ├── home/           inicio y navegación principal
│   ├── itinerary/      historial, detalle y edición de itinerarios
│   ├── map/            mapa, POIs, contribuciones y geocoding
│   ├── media/          carga de imágenes
│   ├── onboarding/     intereses iniciales
│   ├── reviews/        reseñas
│   ├── user_profile/   perfil y configuración
│   └── weather/        pronóstico
└── main.dart
```

## 4. Configuración y ejecución

La aplicación recibe la URL del backend mediante `--dart-define`. Para Linux, con la API disponible localmente:

```bash
flutter pub get
flutter run -d linux \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 \
  --dart-define=API_ORIGIN=http://127.0.0.1:8000
```

Para Android Emulator usa `10.0.2.2` como origen. `API_BASE_URL` se utiliza para la API y `API_ORIGIN` convierte rutas relativas de media, como `/media/archivo.jpg`, en URLs absolutas.

El cliente no contiene claves de OpenAI, DeepSeek, clima ni base de datos. Esas credenciales pertenecen exclusivamente al backend.

## 5. Infraestructura transversal

| Componente | Responsabilidad |
|---|---|
| Riverpod | Inyección de dependencias y estado de sesión, mapa, chat e itinerarios. |
| GoRouter | Rutas públicas/protegidas, shell principal y navegación tipada. |
| DioClient | Requests, token Bearer, refresh tras 401 y errores normalizados. |
| shared_preferences | Tokens y último itinerario local. |
| AppResponsive | Decisiones de layout para mobile, tablet y escritorio. |
| GlobalLoadingOverlay | Estado de carga transversal. |
| ChatStreamingEffectsListener | Notifica y redirige cuando termina una generación de Ara. |

El router inicia en login. Una sesión autenticada redirige al shell principal, que ofrece Inicio, Chat, Mapa, Rutas y Perfil. Las pantallas de detalle, edición y dashboard se registran fuera o dentro del shell según su navegación requerida.

## 6. Funcionalidad por área

| Área | Comportamiento actual |
|---|---|
| Auth | Registro, login, refresh, logout y edición de usuario/perfil turístico o emprendedor. |
| Inicio y onboarding | Intereses iniciales y acceso a POIs destacados mediante el estado de mapa. |
| Mapa y POIs | Búsqueda cercana y semántica, detalle, categorías, geocoding, aportes turísticos/emprendedor, edición y visitas. |
| Bookmarks y reviews | Favoritos por usuario, listado, creación, edición y resumen de reseñas. |
| Itinerarios | Historial, detalle, generación general, edición de pasos, reorder, reprogramación, clima, visitas, exportación y share. |
| Ara | Sesiones, mensajes, candidatos y generación de itinerario por Server-Sent Events. |
| Emprendedor | Métricas, actividad, publicaciones y dashboard por POI. |
| Media y weather | Carga de imágenes autenticada y pronóstico mostrado en itinerarios. |

## 7. Integración con backend

Los repositories agrupan las llamadas HTTP por dominio:

| Repository | Prefijos utilizados |
|---|---|
| `AuthRepository` | `/auth`, `/users` |
| `PoiRepository`, `GeocodingRepository` | `/pois`, `/itineraries/{id}/pois`, `/geocoding` |
| `CategoryRepository`, `ReviewRepository`, `BookmarkRepository` | `/categories`, `/reviews`, `/bookmarks` |
| `ItineraryRepository`, `WeatherRepository` | `/itineraries`, `/weather` |
| `AraRepository` | `/ara/sessions` y generación SSE |
| `EntrepreneurRepository` | `/entrepreneur` y publicaciones públicas de POIs |
| `MediaRepository` | `/media/upload` |

El flujo de Ara usa SSE para la generación de itinerario. La UI interpreta eventos de estado, advertencia, resultado y error. La disponibilidad de respuestas generativas depende de que el backend tenga sus proveedores externos configurados.

## 8. Datos y demostración

Una instalación nueva del backend no incluye POIs, usuarios ni itinerarios de ejemplo. Para recorrer las pantallas con contenido se necesita conservar un volumen PostgreSQL local existente o cargar datos propios.

Las capturas de `docs/` son demostraciones visuales de la interfaz. No contienen credenciales ni requieren que el repositorio distribuya datos privados.

## 9. Calidad

Desde la raíz del frontend:

```bash
flutter analyze
flutter test
```

Las pruebas cubren modelos, repositories, providers, rutas, utilidades y widgets. La suite no debe depender de una API o proveedor de IA externo activo.

## 10. Consideraciones de mantenimiento

- Mantén endpoints y modelos sincronizados con el backend antes de cambiar una pantalla que los consuma.
- Añade pruebas focalizadas al modificar un repository, provider o widget con lógica.
- Usa `ApiConstants` y `DioClient` para las nuevas llamadas HTTP; no fijes URLs en widgets.
- Conserva las claves y configuraciones sensibles fuera de Flutter.
- `chat_provider.dart` y `map_screen.dart` concentran lógica relevante; los cambios en esas áreas requieren especial cuidado y pruebas de regresión.

## 11. Regla de mantenimiento documental

Actualiza este documento cuando cambie una interfaz, ruta, integración, dependencia estructural o decisión de arquitectura. Escribe en presente y describe comportamiento comprobable. No agregues líneas de tiempo, porcentajes de completitud, fases históricas ni listas de cambios pasados.
