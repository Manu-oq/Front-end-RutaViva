# Documentación Técnica Viva — Frontend Ruta Viva

> Última actualización integral: **2026-05-03**
>
> Este documento es la memoria técnica acumulativa del frontend. Está pensado como referencia viva para entender cómo está organizada la app Flutter, qué pantallas existen, cómo se conecta con el backend FastAPI y qué decisiones de integración ya quedaron fijadas.

---

## 1. Objetivo del documento
Este archivo registra de forma trazable y técnica:

- qué está construido hoy en el frontend,
- cómo está organizada la aplicación,
- qué rutas de navegación existen,
- qué endpoints del backend están conectados,
- cómo se gestiona autenticación y sesión,
- cómo se modelan POIs, reviews e itinerarios del lado cliente,
- qué decisiones de arquitectura ya están vigentes,
- qué problemas o limitaciones siguen abiertos,
- y qué pasos deberían seguirse para mantener el frontend alineado con el backend.

La idea es que cualquier persona que entre al proyecto pueda responder, leyendo este documento y el código:

- cómo fluye una acción de usuario desde UI hasta FastAPI,
- qué providers Riverpod controlan cada feature,
- qué datos son mock y qué datos ya vienen desde backend,
- cómo se inyecta el JWT,
- cómo se configuran URLs para Android emulator, web o escritorio,
- y qué piezas faltan para una integración productiva completa.

---

## 2. Reglas de mantenimiento de esta documentación
Este archivo debe actualizarse cuando ocurra cualquiera de estos eventos:

- creación o eliminación de pantallas,
- cambio de rutas GoRouter,
- cambio de providers o estado global,
- conexión de nuevos endpoints,
- cambio de contratos con backend,
- incorporación o eliminación de dependencias,
- modificación del flujo de autenticación,
- cambio de persistencia local,
- resolución de bugs importantes de integración,
- o ajustes que alteren cómo se entiende la arquitectura del frontend.

### Reglas concretas
1. No borrar historial técnico relevante.
2. Registrar decisiones y también su motivación.
3. Especificar archivos modificados cuando el cambio sea importante.
4. Preferir precisión real del estado actual por encima de descripciones vagas.
5. Si el backend cambia contratos, actualizar las secciones de integración.
6. Si una pantalla sigue usando datos mock, declararlo explícitamente.

---

## 3. Estado actual del frontend

## 3.1 Estado general
El frontend ya no es solo una maqueta visual. Actualmente dispone de:

- aplicación Flutter funcional,
- estructura feature-first bajo `lib/features/`,
- navegación con GoRouter,
- estado global con Riverpod,
- cliente HTTP centralizado con Dio,
- configuración por `--dart-define`,
- autenticación contra backend FastAPI con páginas separadas de login y registro,
- edición de perfil turista y preferencias reales,
- activación de modo emprendedor y panel de POIs propios,
- persistencia local de JWT con `shared_preferences`,
- guards de navegación si no existe sesión,
- inyección automática de bearer token en requests protegidas,
- mapa con `flutter_map`, OpenStreetMap y geolocalización,
- carga de POIs reales desde `/api/v1/pois/search`,
- búsqueda semántica conectada a `/api/v1/pois/semantic-search`,
- detalle de POI conectado a `/api/v1/pois/{poi_id}` cuando no existe caché local,
- creación inicial de POIs conectada a `POST /api/v1/pois/`,
- edición/eliminación de POIs propios conectada a `PUT/DELETE /api/v1/pois/{poi_id}`,
- listado de POIs propios conectado a `GET /api/v1/pois/mine`,
- categorías dinámicas conectadas a `GET /api/v1/categories/`,
- asociación persistente de imágenes conectada a `PATCH /api/v1/pois/{poi_id}/media`,
- reviews por POI conectadas a `/api/v1/reviews/poi/{poi_id}`,
- resumen agregado de reviews conectado a `/api/v1/reviews/poi/{poi_id}/summary`,
- creación, edición y eliminación de reviews conectadas a `/api/v1/reviews/`,
- favoritos/bookmarks conectados a `/api/v1/bookmarks/`,
- upload de imágenes conectado a `/api/v1/media/upload`,
- generación de itinerarios conectada a `/api/v1/itineraries/generate`,
- historial de itinerarios conectado a `/api/v1/itineraries/`,
- detalle persistido por ID conectado a `/api/v1/itineraries/{itinerary_id}`,
- visualización de itinerarios generados con nombres reales de POIs cuando el backend los entrega,
- y manejo unificado de errores basado en el formato `{ error, detail }` del backend.

## 3.2 Funcionalidades ya implementadas y operativas a nivel código
### Infraestructura Flutter
- `MaterialApp.router` usa GoRouter.
- `ProviderScope` envuelve toda la app.
- `SharedPreferences` se inicializa antes de `runApp`.
- `DioClient` centraliza base URL, timeouts, logging e inyección de token.

### Autenticación y sesión
- `LoginPage` permite iniciar sesión y `RegisterPage` permite registrar turistas.
- `EditProfilePage` permite actualizar nombre, transporte e intereses reales.
- `AuthRepository` consume:
  - `POST /auth/login`,
  - `POST /auth/register`,
  - `GET /users/me`.
- `AuthNotifier` mantiene:
  - usuario actual,
  - token actual,
  - estado de carga,
  - error legible.
- El JWT se guarda en local storage mediante `AuthTokenStorage`.
- Al iniciar la app, si hay token persistido, se intenta restaurar sesión con `/users/me`.
- Si el token persistido no sirve, se limpia y se redirige a login.

### Navegación protegida
- `appRouterProvider` construye el router a partir del estado de auth.
- Si no hay sesión, cualquier ruta distinta de `/login` redirige a login.
- Si hay sesión y el usuario entra a `/login`, se redirige a home.
- Durante restauración de sesión, el router evita redirecciones prematuras.

### POIs y mapa
- `MapNotifier.loadNearby()` llama `/pois/search`.
- `MapNotifier.semanticSearch()` llama `/pois/semantic-search`.
- `PoiRepository.getPoiById()` llama `/pois/{poi_id}`.
- `PoiRepository.createPoi()` llama `POST /pois/` desde `CreatePoiPage`.
- `PoiRepository.getMyPois()` llama `GET /pois/mine` para panel emprendedor.
- `PoiRepository.updatePoi()` y `deletePoi()` gestionan POIs propios.
- `PoiRepository.appendImage()` llama `PATCH /pois/{poi_id}/media` después de upload.
- `PoiModel` traduce contrato backend español (`nombre`, `descripcion`, etc.) a entidad UI `MapPoint`.
- `ApiConstants.resolveBackendUrl()` convierte rutas relativas tipo `/media/...` a URLs absolutas.

### Reviews
- `ReviewsSection` carga reviews públicas por POI.
- El usuario autenticado puede crear reviews desde el detalle del POI.
- Al crear una review, el frontend invalida el provider de reviews del POI para refrescar la lista.
- La actualización semántica del perfil ocurre en backend mediante background task; el frontend solo muestra confirmación.

### Upload de imágenes
- `ImageUploadPanel` usa `image_picker` para seleccionar imagen desde galería.
- `MediaRepository.uploadImage()` envía multipart/form-data al backend.
- La respuesta `{ "url": "/media/..." }` se resuelve a URL absoluta para previsualización.
- `ImageUploadPanel` asocia la URL al POI con `PATCH /pois/{poi_id}/media` e invalida el detalle del POI.

### Itinerarios
- Home y Chat pueden generar itinerarios desde una intención textual.
- `ItineraryRepository.generateItinerary()` llama `/itineraries/generate`.
- `ItineraryRepository.getMyItineraries()` llama `/itineraries/`.
- `ItineraryRepository.getItineraryById()` llama `/itineraries/{id}`.
- `ItineraryProvider` guarda el itinerario actual después de generar.
- `ItineraryDetailPage` renderiza por ID persistido cuando recibe `itineraryId` y conserva fallback al itinerario actual.
- Los pasos muestran `poi_nombre` y `poi_descripcion` cuando vienen en la respuesta del backend.

## 3.3 Funcionalidades presentes pero aún incompletas
- El token se persiste con `shared_preferences`; para producción móvil convendría evaluar almacenamiento seguro.
- No existe refresh token; el backend emite solo access token.
- Ya existe pantalla dedicada para crear POIs y panel emprendedor para editar/eliminar POIs propios; aún faltan reglas avanzadas, claim de POIs importados y analíticas.
- Upload de imágenes ya queda asociado al POI; falta galería avanzada y permisos finos.
- Ya existe listado histórico de itinerarios; aún faltan acciones avanzadas como eliminar, renombrar o filtrar itinerarios.
- No hay gestión de estado offline.
- No hay tests automatizados para providers, repositories ni pantallas conectadas.
- Home y Profile ya usan estado real de backend/app; Onboarding conserva imágenes decorativas externas, pero sus acciones consultan búsqueda semántica real.
- No hay manejo fino de roles turista/emprendedor en UI.

---

## 4. Stack técnico actual y decisiones vigentes

## 4.1 Framework y lenguaje
- **Flutter** como framework de UI multiplataforma.
- **Dart** como lenguaje.
- Estructura generada para Android, iOS, web, Linux, macOS y Windows.

## 4.2 Estado y navegación
- **Riverpod** para estado global y providers.
- **GoRouter** para navegación declarativa.
- El router se expone como provider para poder reaccionar a auth.

## 4.3 Red e integración
- **Dio** como cliente HTTP.
- `DioClient` configura:
  - base URL,
  - timeouts,
  - response JSON,
  - interceptor de token,
  - logging en debug.

## 4.4 Mapas y ubicación
- **flutter_map** para render de mapa.
- **OpenStreetMap** como proveedor de tiles.
- **geolocator** para permisos y ubicación actual.
- **latlong2** para coordenadas.

## 4.5 Persistencia local
- **shared_preferences** para persistir JWT.

### Decisión actual
Se usa `shared_preferences` porque:
- es simple,
- funciona rápido para integración inicial,
- permite restauración de sesión entre reinicios,
- y en web utiliza almacenamiento local.

### Pendiente de seguridad
Para producción móvil, un JWT debería evaluarse con almacenamiento seguro tipo Keychain/Keystore mediante una dependencia especializada.

## 4.6 Multimedia
- **image_picker** para seleccionar imágenes desde galería.
- **Dio multipart/form-data** para subir archivos al backend.

---

## 5. Estructura actual del proyecto

```text
Front-end-TT/
├── README.md
├── documentation.md
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   │   └── api_constants.dart
│   │   ├── error/
│   │   │   └── api_exception.dart
│   │   ├── network/
│   │   │   ├── api_provider.dart
│   │   │   ├── auth_token_provider.dart
│   │   │   └── dio_client.dart
│   │   ├── router/
│   │   │   ├── app_router.dart
│   │   │   └── app_routes.dart
│   │   ├── storage/
│   │   │   └── local_storage_provider.dart
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   └── features/
│       ├── auth/
│       ├── chat_ai/
│       ├── home/
│       ├── itinerary/
│       ├── map/
│       ├── media/
│       ├── onboarding/
│       ├── reviews/
│       └── user_profile/
└── test/
```

---

## 6. Arquitectura aplicada actualmente

## 6.1 Capas prácticas
El proyecto sigue una arquitectura feature-first ligera:

### `lib/core/`
Contiene infraestructura compartida:
- constantes,
- red,
- storage,
- routing,
- tema,
- utilidades,
- widgets reutilizables.

### `lib/features/<feature>/data/`
Contiene integración y modelos de datos:
- modelos que parsean JSON del backend,
- repositories que llaman endpoints,
- providers de repositories.

### `lib/features/<feature>/domain/`
Contiene entidades de dominio UI cuando existen.

### `lib/features/<feature>/presentation/`
Contiene:
- pages,
- providers de estado de pantalla/feature,
- widgets visuales.

## 6.2 Decisión de integración
El frontend no llama a Dio directamente desde widgets grandes. La regla vigente es:

> Widget → Provider/Notifier → Repository → DioClient → Backend.

Esto permite aislar parsing, errores y endpoints fuera de la UI.

## 6.3 Estado real de separación
La separación ya existe en features conectadas:
- Auth tiene models, repository y provider.
- Map tiene model, repository y notifier.
- Itinerary tiene model, repository y notifier.
- Reviews tiene model, repository y widget conectado.
- Media tiene repository y widget conectado.

Todavía hay pantallas con contenido visual estático, especialmente Home, Onboarding y secciones de Profile.

---

## 7. Configuración de API

## 7.1 Archivo central
Archivo:
- `lib/core/constants/api_constants.dart`

Configuraciones:
- `API_BASE_URL`: base del backend versionado, por defecto `http://10.0.2.2:8000/api/v1`.
- `API_ORIGIN`: origen del backend sin `/api/v1`, por defecto `http://10.0.2.2:8000`.
- `connectionTimeout`: 15000 ms.
- `receiveTimeout`: 15000 ms.

## 7.2 Por qué existen dos URLs
El backend expone:
- API funcional bajo `/api/v1`,
- archivos estáticos bajo `/media`.

Por eso:
- requests de API usan `API_BASE_URL`,
- URLs relativas de imágenes usan `API_ORIGIN`.

Ejemplo:

```text
/media/abc.jpg → http://10.0.2.2:8000/media/abc.jpg
```

## 7.3 Comandos útiles
Android emulator:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 \
  --dart-define=API_ORIGIN=http://10.0.2.2:8000
```

Web/escritorio local:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 \
  --dart-define=API_ORIGIN=http://127.0.0.1:8000
```

---

## 8. Seguridad y autenticación en frontend

## 8.1 Login
Flujo:
1. usuario escribe email/password en `LoginPage`,
2. `AuthNotifier.login()` llama `AuthRepository.login()`,
3. repository hace `POST /auth/login`,
4. recibe `access_token`,
5. guarda token en `authTokenProvider`,
6. persiste token con `AuthTokenStorage`,
7. llama `GET /users/me`,
8. guarda usuario actual en estado.

## 8.2 Registro turista
Flujo:
1. usuario activa modo registro,
2. se envía `POST /auth/register`,
3. si el registro funciona, se llama login automáticamente,
4. si login funciona, se navega a onboarding.

## 8.3 Restauración de sesión
Al iniciar:
1. `main()` inicializa `SharedPreferences`,
2. `ProviderScope` inyecta la instancia,
3. `AuthNotifier.build()` lee token persistido,
4. si existe, lo coloca en `authTokenProvider`,
5. ejecuta `_restoreSession()`,
6. `_restoreSession()` valida token con `/users/me`,
7. si falla, limpia token y sesión.

## 8.4 Inyección de token
Archivo:
- `lib/core/network/dio_client.dart`

Antes de cada request:

```dart
final token = authTokenReader?.call();
if (token != null && token.isNotEmpty) {
  options.headers['Authorization'] = 'Bearer $token';
}
```

## 8.5 Logout
`AccountSettings` llama `AuthNotifier.logout()`:
- limpia token persistido,
- limpia `authTokenProvider`,
- resetea `AuthState`,
- navega a login.

---

## 9. Guards de navegación

Archivo:
- `lib/core/router/app_router.dart`

El router vive en:

```dart
final appRouterProvider = Provider<GoRouter>((ref) { ... });
```

Reglas actuales:
- `/login` es pública.
- Todas las demás rutas requieren sesión.
- Si no hay sesión y se intenta entrar a ruta protegida, redirige a `/login`.
- Si ya hay sesión y se entra a `/login`, redirige a `/`.
- Si hay token persistido y se está restaurando sesión, no se fuerza redirect prematuro.

Rutas actuales:
- `/login`
- `/register`
- `/`
- `/map`
- `/onboarding`
- `/itineraries`
- `/itineraries/:id`
- `/chat`
- `/profile`
- `/profile/edit`
- `/entrepreneur`
- `/pois/create`
- `/pois/:id/edit`
- `/bookmarks`
- `/poi-detail/:id`

---

## 10. Catálogo de integraciones backend

## 10.1 Auth
### `POST /api/v1/auth/login`
Usado por:
- `AuthRepository.login()`

Body:
- `email`
- `password`

Respuesta:
- `access_token`
- `token_type`

### `POST /api/v1/auth/register`
Usado por:
- `AuthRepository.registerTourist()`

Body:
- `user.email`
- `user.password`
- `user.is_active`
- `profile.full_name`
- `profile.has_own_transport`
- `profile.system_preferences`

### `GET /api/v1/users/me`
Usado por:
- restauración de sesión,
- post-login.

Requiere bearer token. Devuelve usuario con `tourist_profile` y `entrepreneur_profile` cuando existen.

### `PUT /api/v1/users/me/tourist-profile`
Usado por:
- `EditProfilePage`

Actualiza nombre, transporte propio e intereses en `system_preferences`.

### `POST /api/v1/users/me/entrepreneur-profile`
Usado por:
- `EntrepreneurDashboardPage`

Activa el modo emprendedor para que nuevos POIs queden asociados al usuario.

## 10.1.1 Categories
### `GET /api/v1/categories/`
Usado por:
- `categoriesProvider`
- `CreatePoiPage`

Carga la taxonomía real sembrada en backend.

## 10.2 POIs
### `GET /api/v1/pois/search`
Usado por:
- `MapNotifier.loadNearby()`

Query:
- `lat`
- `lon`
- `radius`

### `GET /api/v1/pois/semantic-search`
Usado por:
- `MapNotifier.semanticSearch()`

Query:
- `query`
- `lat`
- `lon`
- `radius`

Puede usar bearer token opcional para personalización.

### `GET /api/v1/pois/{poi_id}`
Usado por:
- `poiDetailProvider`
- `PoiDetailFullPage` cuando no hay caché local.


### `POST /api/v1/pois/`
Usado por:
- `PoiRepository.createPoi()`
- `CreatePoiPage`

Body:
- `nombre`
- `descripcion`
- `tipo_acceso`
- `telefono_publico`
- `email_publico`
- `multimedia_urls`
- `category_ids`
- `latitude`
- `longitude`

Requiere bearer token. El backend genera embedding automáticamente y asocia `entrepreneur_id` si el usuario autenticado tiene perfil emprendedor.

### `GET /api/v1/pois/mine`
Usado por:
- `EntrepreneurDashboardPage`

Lista POIs propios del emprendedor autenticado.

### `PUT /api/v1/pois/{poi_id}` y `DELETE /api/v1/pois/{poi_id}`
Usado por:
- `EditPoiPage`
- acciones del panel emprendedor

Requiere emprendedor autenticado dueño del POI.

### `PATCH /api/v1/pois/{poi_id}/media`
Usado por:
- `ImageUploadPanel`
- `PoiRepository.appendImage()`

Body:
- `image_url`

Requiere bearer token. Persiste la URL en `multimedia_urls` y devuelve el POI actualizado.

## 10.3 Itinerarios
### `POST /api/v1/itineraries/generate`
Usado por:
- `ItineraryRepository.generateItinerary()`
- `AIInputBar`
- `ChatInputField`

Body:
- `query`
- `lat`
- `lon`
- `radius`
- `start_date`
- `end_date`

Requiere usuario turista autenticado.

Respuesta esperada actual:
- `id`
- `tourist_id`
- `title`
- `start_date`
- `end_date`
- `status`
- `steps[]`
  - `id`
  - `itinerary_id`
  - `poi_id`
  - `poi_nombre`
  - `poi_descripcion`
  - `step_order`
  - `arrival_time`
  - `departure_time`
  - `ai_context`


### `GET /api/v1/itineraries/`
Usado por:
- `ItineraryRepository.getMyItineraries()`
- `ItineraryHistoryPage`

Requiere turista autenticado. Devuelve los itinerarios persistidos del usuario con pasos enriquecidos.

### `GET /api/v1/itineraries/{itinerary_id}`
Usado por:
- `ItineraryRepository.getItineraryById()`
- `ItineraryDetailPage(itineraryId: id)`

Requiere turista autenticado. Devuelve `404` si el itinerario no existe o no pertenece al usuario actual.

## 10.4 Reviews
### `GET /api/v1/reviews/poi/{poi_id}`
Usado por:
- `ReviewsSection`

Carga reseñas públicas del POI.

### `GET /api/v1/reviews/poi/{poi_id}/summary`
Usado por:
- `reviewSummaryByPoiProvider`
- `ReviewsSection`

Devuelve promedio, total y distribución por estrellas.

### `POST /api/v1/reviews/`
Usado por:
- formulario de `ReviewsSection`

Body:
- `poi_id`
- `rating_stars`
- `text_content`

Requiere turista autenticado.

### `PUT /api/v1/reviews/{review_id}`
Usado por:
- acciones de edición en `ReviewsSection`

Requiere turista autenticado y dueño de la review.

### `DELETE /api/v1/reviews/{review_id}`
Usado por:
- acciones de eliminación en `ReviewsSection`

Requiere turista autenticado y dueño de la review.

## 10.4.1 Bookmarks
### `GET /api/v1/bookmarks/`
Usado por:
- `BookmarksPage`

### `GET /api/v1/bookmarks/{poi_id}`
Usado por:
- `BookmarkButton`

### `POST /api/v1/bookmarks/{poi_id}` / `DELETE /api/v1/bookmarks/{poi_id}`
Usado por:
- toggle de favoritos en detalle de POI

Requiere turista autenticado.

## 10.5 Media
### `POST /api/v1/media/upload`
Usado por:
- `ImageUploadPanel`

Formato:
- multipart/form-data
- campo `file`

Respuesta:
- `url`

---

## 11. Modelos frontend principales

## 11.1 Auth
### `TokenModel`
Campos:
- `accessToken`
- `tokenType`

### `UserModel`
Campos:
- `id`
- `email`
- `isActive`
- `createdAt`

## 11.2 POIs
### `PoiModel`
Representa el contrato backend:
- `id`
- `nombre`
- `descripcion`
- `tipoAcceso`
- `telefonoPublico`
- `emailPublico`
- `multimediaUrls`
- `categoryIds`
- `latitude`
- `longitude`
- `distanciaMetros`

### `MapPoint`
Entidad UI:
- `id`
- `name`
- `coordinates`
- `category`
- `categoryIds`
- `description`
- `imageUrl`
- `phone`
- `email`
- `distanceMeters`
- `isLocalAuthentic`
- `amenities`

Mapeo de categorías base:
- `1`: Naturaleza
- `2`: Gastronomía
- `3`: Turismo
- `4`: Alojamiento
- `5`: Cultura

## 11.3 Itinerarios
### `ItineraryModel`
Campos:
- `id`
- `touristId`
- `title`
- `startDate`
- `endDate`
- `status`
- `steps`

### `ItineraryStepModel`
Campos:
- `id`
- `itineraryId`
- `poiId`
- `poiNombre`
- `poiDescripcion`
- `stepOrder`
- `arrivalTime`
- `departureTime`
- `aiContext`

Getters importantes:
- `title`: usa `ai_context.title`, luego `poiNombre`, luego `Parada N`.
- `reason`: usa `ai_context.reason`, luego `poiDescripcion`, luego texto fallback.

## 11.4 Reviews
### `ReviewModel`
Campos:
- `id`
- `poiId`
- `touristId`
- `ratingStars`
- `textContent`
- `createdAt`

---

## 12. Providers actuales

## 12.1 Core/network
- `dioProvider`
- `apiClientProvider`
- `authTokenProvider`

## 12.2 Storage
- `sharedPreferencesProvider`
- `authTokenStorageProvider`

## 12.3 Auth
- `authRepositoryProvider`
- `authProvider`

Métodos relevantes:
- `updateTouristProfile()`
- `activateEntrepreneurProfile()`

## 12.4 Map/POIs
- `poiRepositoryProvider`
- `poiDetailProvider`
- `mapProvider`

## 12.4.1 Categories
- `categoryRepositoryProvider`
- `categoriesProvider`
- `categoryNameMapProvider`

## 12.4.2 Bookmarks
- `bookmarkRepositoryProvider`
- `bookmarkedPoisProvider`
- `bookmarkStatusProvider`

## 12.4.3 Entrepreneur/POIs propios
- `myPoisProvider`
- `poiModelDetailProvider`

## 12.5 Itinerarios
- `itineraryRepositoryProvider`
- `itineraryHistoryProvider`
- `itineraryDetailProvider`
- `itineraryProvider`

## 12.6 Reviews
- `reviewRepositoryProvider`
- `reviewsByPoiProvider`
- `reviewSummaryByPoiProvider`

## 12.7 Media
- `mediaRepositoryProvider`

## 12.8 Onboarding
- `interestsProvider`

---

## 13. Flujo de pantallas principales

## 13.1 Login
Pantalla:
- `LoginPage`

Responsabilidad:
- iniciar sesión contra `/auth/login`,
- restaurar usuario con `/users/me`,
- mostrar errores de auth,
- navegar a Home si la sesión es válida.

## 13.2 Register
Pantalla:
- `RegisterPage`

Responsabilidad:
- registrar turista contra `/auth/register`,
- enviar nombre completo, transporte propio e intereses iniciales en `system_preferences`,
- hacer login automático si el registro funciona.

## 13.3 Home
Pantalla:
- `HomePage`

Responsabilidad actual:
- mostrar saludo con usuario autenticado,
- cargar POIs reales desde `mapProvider`,
- destacar el primer POI real como hero card,
- mostrar otros POIs reales como lista,
- acceso a mapa,
- input Ara para generar itinerario.

## 13.4 Chat AI
Pantalla:
- `ChatScreen`

Responsabilidad actual:
- conversación simple con Ara,
- envío de intención al generador de itinerarios,
- navegación a detalle si se genera ruta.

Estado:
- no existe endpoint de chat libre; se usa generación de itinerarios como backend real.

## 13.5 Map
Pantalla:
- `MapScreen`

Responsabilidad:
- mostrar mapa OSM,
- cargar POIs cercanos,
- refrescar POIs según centro del mapa,
- mover a ubicación actual si el usuario da permiso,
- abrir sheet de detalle.

## 13.6 Detalle de POI
Pantalla:
- `PoiDetailFullPage`

Responsabilidad:
- mostrar información real del POI,
- recuperar detalle por UUID si no existe en caché local,
- mostrar upload de imágenes y asociarlas al POI,
- mostrar reviews y resumen agregado,
- crear, editar y eliminar reviews propias,
- guardar/quitar favoritos.


## 13.6.1 Crear POI
Pantalla:
- `CreatePoiPage`

Responsabilidad:
- cargar categorías reales desde backend,
- validar nombre, descripción, categorías y coordenadas,
- llamar `POST /api/v1/pois/`,
- refrescar POIs cercanos en `MapNotifier`,
- navegar al detalle del POI creado.

## 13.7 Historial y detalle de itinerario
Pantallas:
- `ItineraryHistoryPage`
- `ItineraryDetailPage`

Responsabilidad:
- listar itinerarios persistidos del turista autenticado,
- abrir un itinerario persistido por ID,
- mantener fallback al itinerario recién generado en memoria,
- renderizar pasos narrativos,
- mostrar nombres reales de POIs enriquecidos por backend.

## 13.8 Profile
Pantallas:
- `ProfileScreen`
- `EditProfilePage`

Responsabilidad:
- mostrar usuario autenticado,
- mostrar nombre real, intereses y estado emprendedor,
- editar perfil turista y preferencias reales,
- mostrar métricas reales del estado actual de app: POIs cargados, paradas del itinerario y sesión activa,
- permitir logout.

## 13.9 Emprendedor y POIs propios
Pantallas:
- `EntrepreneurDashboardPage`
- `EditPoiPage`

Responsabilidad:
- activar perfil emprendedor,
- listar POIs propios,
- navegar a creación de POI,
- editar y eliminar POIs propios.

---

## 14. Manejo de errores

Archivo:
- `lib/core/error/api_exception.dart`

El backend devuelve errores con forma:

```json
{
  "error": "Validation Error",
  "detail": "..."
}
```

`ApiException.fromDioException()` intenta extraer:
- `error`,
- `detail`,
- status code.

Los repositories transforman `DioException` en `ApiException` para que UI y providers muestren mensajes legibles.

---

## 15. Limitaciones y pendientes reales

## 15.1 Seguridad local
- `shared_preferences` no es almacenamiento seguro para secretos en producción móvil.
- No existe refresh token.

## 15.2 Asociación de imágenes a POIs
- El upload funciona contra `/media/upload`.
- La asociación persistente funciona contra `PATCH /pois/{poi_id}/media`.
- Falta galería avanzada, reordenamiento, eliminación de imágenes y permisos finos por dueño/rol.

## 15.3 Itinerarios históricos
- El historial y detalle por ID ya están conectados.
- Faltan acciones avanzadas: eliminar, renombrar, filtrar por fecha/estado y exportar/compartir itinerario.

## 15.4 Reviews avanzadas
- Ya se listan, crean, editan y eliminan reviews propias.
- Ya se muestra resumen agregado: promedio, total de reviews y distribución por estrellas.
- Falta moderación, paginación y recálculo histórico más sofisticado del perfil tras eliminar reviews.

## 15.5 Tests
Faltan pruebas de:
- auth provider,
- router guards,
- repositories con Dio mock,
- parsing de modelos,
- widgets conectados.

## 15.6 UX de carga y errores
- Algunos estados de loading son simples.
- Falta skeleton completo para mapa, reviews e itinerario.

## 15.7 Roles
- La UI ya distingue turista vs emprendedor mediante `entrepreneur_profile`.
- Existe panel emprendedor básico para POIs propios.
- Falta autorización fina por roles, onboarding específico emprendedor, métricas y claim de POIs importados.

---

## 16. Comandos de trabajo útiles

Instalar dependencias:

```bash
flutter pub get
```

Analizar:

```bash
flutter analyze
```

Tests:

```bash
flutter test
```

Formato:

```bash
dart format lib test
```

Run Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 --dart-define=API_ORIGIN=http://10.0.2.2:8000
```

Run web/escritorio:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=API_ORIGIN=http://127.0.0.1:8000
```

---

## 17. Registro evolutivo por sesión

### [2026-04-30] Estructura visual inicial Flutter

#### Objetivo
- construir una app visual navegable para Ruta Viva,
- establecer estética base,
- separar features principales.

#### Estado resultante
- navegación base con GoRouter,
- pantallas Login, Home, Map, Onboarding, Itinerary, Chat y Profile,
- widgets visuales reutilizables,
- mapa con puntos mock,
- itinerario mock narrativo.

---

### [2026-05-02] Primera conexión backend-front

#### Objetivo
- comenzar a reemplazar datos mock por endpoints reales del backend.

#### Cambios realizados
- `DioClient` quedó centralizado,
- se agregó inyección de bearer token,
- se crearon repositories de auth, POI e itinerario,
- se conectó login/register/me,
- se conectó mapa a búsqueda cercana y semántica,
- se conectó detalle de POI por UUID,
- se conectó generación de itinerarios.

#### Estado resultante
- frontend capaz de consumir POIs reales,
- itinerario generado desde backend,
- auth básica en memoria.

---

### [2026-05-02] Persistencia JWT, guards, reviews, media e itinerarios enriquecidos

#### Objetivo
- completar los siguientes pasos naturales de integración frontend-backend.

#### Cambios realizados
- se agregó `shared_preferences`,
- se creó `AuthTokenStorage`,
- `AuthNotifier` restaura sesión al iniciar,
- `GoRouter` pasó a provider con guards de auth,
- se agregó feature `reviews`,
- se agregó `ReviewsSection` al detalle de POI,
- se agregó feature `media`,
- se agregó `ImageUploadPanel`,
- se agregó `image_picker`,
- se actualizó `ItineraryStepModel` para leer `poi_nombre` y `poi_descripcion`,
- se creó este documento `documentation.md`.

#### Estado resultante
- sesión persistente,
- rutas protegidas,
- reviews visibles y creables,
- upload de imagen conectado,
- itinerario renderizado con nombres reales de POIs cuando backend los entrega.

---

## 18. Estado final al cierre de esta actualización
Hoy el frontend puede:

- registrar turistas,
- iniciar sesión,
- persistir JWT localmente,
- restaurar sesión al abrir la app,
- proteger rutas privadas,
- inyectar bearer token automáticamente,
- cargar POIs reales en mapa,
- abrir detalle de POI,
- cargar y crear reviews,
- subir imágenes al backend local,
- generar itinerarios reales,
- mostrar pasos de itinerario con nombres y descripciones reales de POIs,
- resolver URLs relativas de media,
- y manejar errores backend de forma legible.

La siguiente etapa natural sería:
- asociar imágenes subidas a POIs mediante endpoint de edición,
- agregar acciones avanzadas al historial de itinerarios,
- crear UI de emprendedor,
- añadir tests de providers/repositories,
- endurecer almacenamiento seguro de token,
- agregar refresh token si el backend lo implementa,
- y reemplazar secciones mock restantes por datos reales.


---

### [2026-05-03] Complemento de frontend y reemplazo de mocks principales

#### Objetivo
- separar login y registro,
- mejorar UX de autenticación,
- conectar Home/Profile/Onboarding de forma más directa con datos reales,
- reducir mockups visibles donde ya existen datos de backend.

#### Cambios realizados
- `LoginPage` quedó dedicada solo a iniciar sesión, con formulario validado y CTA a registro.
- se creó `RegisterPage` funcional, con nombre, email, contraseña, transporte propio e intereses.
- se agregó ruta pública `/register`.
- Home ahora carga POIs reales desde `mapProvider` y deja de mostrar el hero mock `Salto de la China`.
- Onboarding ejecuta búsqueda semántica real según vibes o intereses seleccionados y abre el mapa.
- Profile deja de mostrar identidad/métricas mock y usa usuario autenticado + estado real de POIs/itinerario.

#### Estado resultante
- Las pantallas principales ya están conectadas a datos reales cuando existen endpoints disponibles.
- Quedan pendientes features más específicas como edición/eliminación de POIs, UI emprendedor, perfil editable y tareas de calidad técnica.


---

### [2026-05-03] Historial de itinerarios, detalle persistido y creación de POI

#### Objetivo
- cerrar el primer bloque de 3 conexiones backend-front priorizadas: historial de itinerarios, detalle persistido por ID y creación de POI.

#### Cambios realizados
- `authTokenProvider` migró a `NotifierProvider` para compatibilidad con Riverpod actual y corregir el error `StateProvider` no definido.
- se agregó `ItineraryHistoryPage` y la ruta `/itineraries`.
- `ItineraryDetailPage` ahora puede cargar por `itineraryId` desde `/itineraries/{id}`.
- `ItineraryRepository` incorporó `getMyItineraries()` y `getItineraryById()`.
- Home y Chat navegan al detalle persistido usando el ID devuelto por backend.
- se agregó `CreatePoiPage` y la ruta `/pois/create`.
- `PoiRepository.createPoi()` llama `POST /pois/` y refresca el mapa al crear exitosamente.
- Profile y navegación inferior incorporan accesos a historial y creación de POI.
- el widget test inicial se ajustó para inicializar `SharedPreferences` mock.

#### Estado resultante
- los itinerarios generados quedan accesibles desde historial y por URL con ID,
- el detalle ya no depende exclusivamente del estado en memoria,
- el frontend puede crear POIs reales autenticados,
- `flutter analyze` queda sin issues y `flutter test` pasa.


---

### [2026-05-03] Categorías backend, media persistente, reviews avanzadas y favoritos

#### Objetivo
- cerrar el segundo bloque de 4 conexiones backend-front priorizadas.

#### Cambios realizados
- se creó feature `categories` en frontend y `GET /categories/` en backend.
- `CreatePoiPage` dejó de usar categorías hardcodeadas y ahora carga la taxonomía backend.
- `ImageUploadPanel` ahora sube imagen y la asocia al POI mediante `PATCH /pois/{poi_id}/media`.
- `PoiDetailFullPage` refresca detalle real por provider para reflejar media actualizada.
- `ReviewsSection` muestra resumen agregado, permite editar y eliminar reviews propias.
- se agregó feature `bookmarks`, ruta `/bookmarks`, `BookmarkButton` y endpoints backend de favoritos.
- `DioClient` incorporó métodos `put`, `patch` y `delete`.

#### Estado resultante
- categorías, imágenes, reviews avanzadas y favoritos ya están conectados a backend.
- `flutter analyze` queda sin issues y `flutter test` pasa.


---

### [2026-05-03] Perfil editable, flujo emprendedor y edición de POIs

#### Objetivo
- cerrar las 3 partes funcionales pendientes antes de pasar a calidad técnica.

#### Cambios realizados
- `UserModel` ahora parsea `tourist_profile` y `entrepreneur_profile`.
- se agregó `EditProfilePage` y ruta `/profile/edit`.
- `AuthRepository/AuthNotifier` pueden actualizar perfil turista y activar perfil emprendedor.
- se agregó `EntrepreneurDashboardPage` y ruta `/entrepreneur`.
- se agregó `EditPoiPage` y ruta `/pois/:id/edit`.
- `PoiRepository` incorporó `getMyPois`, `updatePoi` y `deletePoi`.
- `ProfileScreen` muestra nombre real, intereses y estado emprendedor.

#### Estado resultante
- el turista puede editar preferencias reales,
- el usuario puede activar modo emprendedor,
- los POIs propios se listan, editan y eliminan desde frontend,
- `flutter analyze` queda sin issues y `flutter test` pasa.
