# Documentación Técnica Viva — Frontend Ruta Viva

> Última actualización integral: **2026-06-06**
>
> Documento maestro del frontend Flutter de Ruta Viva. Su objetivo es describir el estado real del código, la arquitectura aplicada, las integraciones backend activas, la navegación, los providers, los modelos, los widgets relevantes, los cambios históricos importantes y la deuda técnica vigente.

---

## 1. Objetivo del documento

Este archivo existe para que cualquier persona que entre al proyecto pueda entender, leyendo un solo documento:

- qué está construido hoy;
- cómo está organizada la aplicación;
- qué pantallas, rutas y flujos existen;
- cómo se conecta cada feature con backend;
- qué providers/notifiers controlan el estado;
- qué widgets son visuales y cuáles concentran lógica real;
- qué decisiones importantes ya quedaron fijadas;
- qué partes siguen siendo hotspots o deuda técnica.

No debe funcionar como README comercial. Debe funcionar como **memoria técnica operativa**.

### 1.1 Cuándo debe actualizarse

Actualizar este archivo cuando cambie cualquiera de estos aspectos:

- rutas GoRouter;
- contrato de autenticación;
- endpoints backend usados por frontend;
- estructura de features;
- providers globales;
- flujo de generación de itinerarios;
- comportamiento del mapa;
- widgets compartidos importantes;
- soporte responsive/accesibilidad;
- deuda técnica resuelta o nueva.

### 1.2 Reglas de mantenimiento

1. Describir siempre el **estado real del código**.
2. Marcar explícitamente si algo está **activo**, **legacy**, **no conectado**, **incompleto** o **separado en otro flujo**.
3. No borrar historia técnica útil, pero tampoco dejar afirmaciones antiguas como si siguieran vigentes.
4. Si una sección queda demasiado abstracta, bajarla a nivel de archivo, provider o widget.
5. Si el backend cambia, actualizar primero “Integración backend activa” y luego las features que dependen de eso.

---

## 2. Resumen ejecutivo del frontend actual

### 2.1 Estado general

El frontend dejó hace tiempo de ser una maqueta y hoy funciona como app integrada con backend FastAPI. Actualmente incluye:

- aplicación Flutter multiplataforma;
- estado global con Riverpod;
- navegación declarativa con GoRouter;
- cliente HTTP centralizado con Dio;
- persistencia local con `shared_preferences`;
- access token + refresh token + retry automático de requests tras `401`;
- home basada en POIs reales;
- mapa con búsqueda semántica, nearby search, focus de POIs, filtros y geolocalización;
- detalle completo de POI con reviews, fotos y posts públicos;
- CRUD de reviews;
- bookmarks/favoritos;
- historial y detalle de itinerarios;
- edición de pasos con reorder intra-día, drag & drop inter-día, reschedule, replace y delete;
- flujo Ara/chat con generación de itinerarios por SSE;
- `ItineraryMasterDetailPage` para tablet/desktop y layouts landscape activos en mapa e itinerarios;
- `MistNavigation` adaptativa con `NavigationBar` en mobile y `NavigationRail` en tablet/desktop;
- sistema de contribuciones separado para turista vs. emprendedor, con `creationType`, validaciones distintas y endpoints `/pois/tourist/` vs `/pois/entrepreneur/`;
- panel emprendedor, dashboard por POI y gestión de posts;
- responsive design completado en los Lotes A, B y C;
- sistema de feedback unificado con banners, snackbars, skeletons y errores inline;
- **40 archivos de test frontend** y **300 tests pasados, 0 fallidos** (`flutter test` ejecutado el 2026-06-06);
- `flutter analyze` limpio (0 issues el 2026-06-06).

### 2.2 Decisiones vigentes más importantes

- La app sigue una organización por `core/` + `features/`.
- La autenticación vive en `authProvider` y afecta router, requests y shell completo.
- El acceso a backend siempre debería pasar por `DioClient` / repositories.
- El flujo Ara actual es **SSE-only**:
  - usa `POST /api/v1/ara/sessions/{id}/generate-itinerary/stream`;
  - **no usa** sync Ara;
  - **no usa** async/background Ara;
  - **no usa** polling de `generation-status`.
- El chat mantiene el stream y el estado conversacional en provider, no solo en la pantalla.
- El listener global `ChatStreamingEffectsListener` resuelve la UX fuera del chat cuando un itinerario queda listo.
- El flujo general de itinerarios vía `/itineraries/generate` todavía existe como camino separado del módulo Ara.

### 2.3 Cambios recientes que sí cambiaron la arquitectura funcional

- Limpieza de superficie legacy Ara no usada (sync/async/status).
- Soporte completo de `warning` en SSE: parseo + UX visible + acciones sugeridas.
- Notificación in-app global “Itinerario listo”.
- Hardening responsive y accesibilidad en mapa, chat e itinerarios.
- Mejoras defensivas en auth refresh, restore session, permisos y launchers.

---

## 3. Stack técnico y fundamentos transversales

### 3.1 Stack principal

- **Flutter**: framework UI.
- **Dart**: lenguaje.
- **flutter_riverpod**: DI y manejo de estado.
- **go_router**: navegación declarativa.
- **dio**: cliente HTTP.
- **flutter_map** + **latlong2**: render de mapa y coordenadas.
- **geolocator**: permisos y ubicación actual.
- **shared_preferences**: persistencia simple local.
- **image_picker**: selección de imágenes.

### 3.2 Decisiones técnicas activas

#### Estado global
Se usa Riverpod tanto para:
- providers de infraestructura (`apiClientProvider`, `appRouterProvider`, storage);
- notifiers de sesión/estado persistente (`authProvider`, `itineraryProvider`, `chatProvider`, `mapProvider`);
- future providers de lectura (`reviewsByPoiProvider`, `categoriesProvider`, etc.).

#### Navegación
GoRouter modela:
- rutas públicas y protegidas;
- rutas dentro del shell principal;
- rutas externas al shell con transiciones fade;
- navegación segura con `pushNamedSafe`.

#### Red
Todos los repositories comparten `DioClient`, que encapsula:
- base URL;
- timeouts;
- `Authorization: Bearer ...`;
- retry tras `401` si refresh token funciona;
- logging HTTP en debug.

#### Persistencia local
Se persisten hoy:
- `ruta_viva.auth_token`
- `ruta_viva.refresh_token`
- `ruta_viva.last_itinerary`

#### Responsive
No existe un design system adaptativo completo, pero sí una convención pragmática centralizada en `AppResponsive`.

---

## 4. Arquitectura real aplicada en el repo

## 4.1 Estructura física

```text
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── error/
│   ├── network/
│   ├── router/
│   ├── storage/
│   ├── theme/
│   ├── utils/
│   └── widgets/
└── features/
    ├── auth/
    ├── bookmarks/
    ├── categories/
    ├── chat_ai/
    ├── entrepreneur/
    ├── home/
    ├── itinerary/
    ├── map/
    ├── media/
    ├── onboarding/
    ├── reviews/
    ├── user_profile/
    └── weather/
```

## 4.2 Capas reales por feature

La separación predominante es:

- `data/`: models + repositories;
- `domain/`: entidades simples cuando hace falta adaptar o encapsular UI-facing state;
- `presentation/`: pages, widgets, providers/notifiers.

No todas las features tienen las tres capas de forma estricta. El proyecto usa una separación práctica, no dogmática.

### 4.2.1 `core/`
Contiene infraestructura transversal reutilizable por cualquier feature:

- constantes API;
- errores HTTP normalizados;
- cliente de red y token handling;
- router y helpers de navegación;
- storage local;
- theme;
- utilidades;
- widgets compartidos.

### 4.2.2 `features/<feature>/data`
Responsable de:
- mapear JSON backend ↔ modelo Flutter;
- concentrar endpoints;
- aislar Dio y `ApiException` del resto de la UI.

### 4.2.3 `features/<feature>/presentation`
Responsable de:
- componer pantallas y widgets;
- manejar estado local o notifiers;
- traducir errores/reintentos a UX.

### 4.2.4 `domain/`
Se usa donde tiene sentido, no en todas las features. Ejemplo claro:
- `chat_ai/domain/entities/message_entity.dart`
- `map/domain/entities/map_point.dart`

## 4.3 Acoplamientos importantes y aceptados

El código tiene algunos acoplamientos deliberados:

- `HomePage` depende de `mapProvider` como fuente principal de POIs destacados.
- `ChatNotifier` depende de `itineraryProvider`, `itineraryRepository`, `mapProvider` y `poiRepository` para cerrar el loop completo de Ara.
- `ItineraryDetailPage` dispara navegación o sesiones de chat para cambiar pasos.
- `PoiDetailFullPage` incorpora widgets de reviews, media y posts públicos.
- `EntrepreneurDashboardPage` y `PoiDashboardPage` dependen de `poiRepository`, `entrepreneurRepository`, `reviewsSection` y navegación cruzada.

Esto no invalida la arquitectura, pero sí explica por qué algunas pantallas/notifiers se volvieron grandes.

---

## 5. Bootstrapping e infraestructura global

## 5.1 `main.dart`

Responsabilidades de `main.dart`:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. inicializar `SharedPreferences`
3. inyectar `sharedPreferencesProvider` via override
4. montar `ProviderScope`
5. construir `MaterialApp.router`
6. envolver toda la app con:
   - `ChatStreamingEffectsListener`
   - `GlobalLoadingOverlay`
7. aplicar:
   - `AppTheme.lightTheme`
   - `AppTheme.darkTheme`
   - `themeModeProvider`

## 5.2 `ApiConstants`

`lib/core/constants/api_constants.dart` define:

- origen por defecto Android emulator: `http://10.0.2.2:8000`
- origen local general/web: `http://127.0.0.1:8000`
- override de base URL completa: `API_BASE_URL`
- override de origen backend: `API_ORIGIN`
- `baseUrl = $backendOrigin/api/v1` si no hay override completo
- helper `resolveBackendUrl(...)` para transformar rutas relativas `/media/...`

### Implicación práctica
El frontend asume que los repositories usan paths relativos como `/auth/login`, `/pois/search`, etc., y `DioClient` los resuelve contra `ApiConstants.baseUrl`.

## 5.3 `DioClient`

Archivo: `lib/core/network/dio_client.dart`

Capacidades:

- agrega bearer token en `onRequest` si existe y la request no está marcada con `skipAuth`;
- en `401` puede intentar refresh si:
  - existe `refreshAuthToken`;
  - no tiene `skipAuthRefresh`;
  - no hizo ya `didRefreshRetry`;
- reejecuta la request original con el token refrescado;
- si el retry falla, propaga el error final;
- en debug agrega `LogInterceptor`.

## 5.4 `api_provider.dart`

Archivo: `lib/core/network/api_provider.dart`

Responsabilidades:

- crea instancia `Dio` base;
- crea `DioClient` con closures para leer token y refrescar token;
- si refresh funciona:
  - actualiza token en memoria;
  - actualiza token en storage;
  - opcionalmente actualiza refresh token;
- si refresh falla:
  - limpia access token;
  - limpia refresh token;
  - limpia token en memoria.

## 5.5 Storage local

Archivo: `lib/core/storage/local_storage_provider.dart`

Contiene:

- `sharedPreferencesProvider`
- `authTokenStorageProvider`
- `refreshTokenStorageProvider`
- `AuthTokenStorage`
- `RefreshTokenStorage`

No usa cifrado; es persistencia simple.

## 5.6 `GlobalLoadingOverlay`

Archivo: `lib/core/widgets/global_loading_overlay.dart`

Partes:

- `GlobalLoadingNotifier`: contador entero de cargas globales.
- `globalLoadingProvider`: expose del contador.
- `GlobalLoadingOverlay`: si `count > 0`, cubre la UI con overlay oscuro y `CircularProgressIndicator`.

Observación: es una infraestructura disponible, pero no todas las features la usan de manera uniforme.

## 5.7 `ChatStreamingEffectsListener`

Archivo: `lib/core/widgets/chat_streaming_effects_listener.dart`

Responsabilidades:

- escuchar `chatPendingNavigationProvider`;
- evitar navegación duplicada o múltiples snackbars superpuestos;
- mostrar `SnackBar` flotante cuando un itinerario SSE queda listo;
- permitir abrir detalle con CTA “Ver”;
- consumir la navegación pendiente al mostrar la notificación.

Es una pieza clave del flujo background-friendly de Ara.

## 5.8 `AppResponsive`

Archivo: `lib/core/utils/responsive.dart`

Expone:

- `screenSize(context)`
- `isMobile(context)`
- `isTablet(context)`
- `isDesktop(context)`
- `isLandscape(context)`
- `isCompactHeight(context)`
- `safePadding(context)`
- `value<T>(...)` para resolver variantes por breakpoint
- `pagePadding(context)`
- `compactPagePadding(context)`
- `maxContentWidth(context)`
- `cardRadius(context)`
- `cardPadding(context)`
- `shouldReduceMotion`

Uso típico:
- constricciones de ancho máximo;
- paddings globales;
- card radius consistente;
- diferenciación mobile/tablet/desktop.

---

## 6. Rutas y navegación

## 6.1 Catálogo de rutas

Definido en `lib/core/router/app_routes.dart`.

### Paths
- `/login`
- `/register`
- `/home`
- `/map`
- `/map/focused`
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
- `/entrepreneur/pois/:id/dashboard`
- `/entrepreneur/pois/:id/posts`

### Names
- `login`
- `register`
- `home`
- `map`
- `focused_map`
- `onboarding`
- `itinerary_history`
- `itinerary_detail`
- `chat`
- `profile`
- `edit_profile`
- `entrepreneur`
- `create_poi`
- `edit_poi`
- `bookmarks`
- `poi_detail`
- `poi_dashboard`
- `poi_posts`

## 6.2 Estructura de `app_router.dart`

### Rutas públicas directas
- LoginPage
- RegisterPage

### Rutas no-shell con fade transition
- onboarding
- itinerary detail
- bookmarks
- edit profile
- entrepreneur dashboard
- POI dashboard
- POI posts management
- create POI
- edit POI
- POI detail full
- focused map

### Shell principal (`MistNavigation`)
- HomePage
- ChatScreen
- MapScreen
- ItineraryHistoryPage
- ProfileScreen

## 6.3 Guard de auth

La lógica activa de redirect:

- si no hay sesión y la ruta no es login/register → redirige a `/login`
- si hay sesión y entra a login/register → redirige a `/home`
- si hay restauración de sesión en progreso con token presente → no redirige todavía

## 6.4 `MistNavigation`

Archivo: `lib/features/home/presentation/widgets/mist_navigation.dart`

Responsabilidades:

- renderizar navegación principal adaptativa;
- usar `NavigationBar` en mobile;
- usar `NavigationRail` en tablet/desktop;
- decidir condicionalmente mobile vs. tablet/desktop con `AppResponsive`;
- extender el rail cuando el viewport supera `800px` de ancho;
- mapear la ruta actual a `selectedIndex` / `railSelectedIndex`;
- manejar `goNamed(...)` según el destino;
- disparar resets/cargas del mapa cuando se vuelve a Home o Mapa.

Detalles relevantes:

- el orden visual del rail no es igual al del bottom nav: en rail queda `Inicio`, `Mapa`, `Itinerarios`, `Chat`, `Perfil`;
- el rail aplica `hoverColor` suave en desktop para mejorar affordance sin ruido visual;
- la shell principal sigue centralizada en `ShellRoute`, pero dejó de ser mobile-only.

Destinos visibles:
- Inicio
- Chat / Mapa / Itinerarios / Perfil según variante visual

## 6.5 `pushNamedSafe`

Archivo: `lib/core/router/safe_navigation.dart`

Resuelve un problema real: duplicación de navegación por taps repetidos o race conditions de UI.

Mecanismo:

- genera lock key por destino;
- evita push si ya se está empujando lo mismo;
- opcionalmente evita push si ya está en esa misma location;
- usa debounce temporal para liberar lock automáticamente.

---

## 7. Autenticación y sesión

## 7.1 Archivos principales

- `features/auth/data/models/token_model.dart`
- `features/auth/data/models/user_model.dart`
- `features/auth/data/repositories/auth_repository.dart`
- `features/auth/presentation/pages/login_page.dart`
- `features/auth/presentation/pages/register_page.dart`
- `features/auth/presentation/providers/auth_provider.dart`

## 7.2 Modelo `TokenModel`

Representa:
- `accessToken`
- `tokenType`
- `refreshToken`

Contratos esperados del backend:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "bearer"
}
```

## 7.3 Modelo `UserModel`

Representa:
- identidad base (`id`, `email`, `isActive`, `avatarUrl`, `createdAt`)
- `TouristProfileModel`
- `EntrepreneurProfileModel`

Helpers clave:
- `displayName`
- `isEntrepreneur`
- `TouristProfileModel.interests`

## 7.4 `AuthRepository`

Endpoints usados:
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/register`
- `GET /users/me`
- `PUT /users/me/tourist-profile`
- `PATCH /users/me`
- `POST /users/me/entrepreneur-profile`

## 7.5 `AuthNotifier`

Estado modelado:
- `user`
- `token`
- `isLoading`
- `errorMessage`

Responsabilidades:
- restaurar sesión desde access token;
- restaurar sesión desde refresh token;
- persistir tokens al login;
- limpiar tokens al logout/fallo irrecoverable;
- editar perfil turista;
- activar perfil emprendedor;
- traducir `ApiException` a errores legibles.

## 7.6 Estado real hoy

Es importante que el documento deje esto explícito:

- **sí existe refresh token en frontend**;
- **sí existe interceptor 401 + auto-refresh**;
- el problema de auth no está en la ausencia de esa infraestructura, sino en una posible desalineación de contrato backend si algo falla.

---

## 8. Integración backend activa

## 8.1 Endpoints usados hoy por el frontend

### Auth
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/register`
- `GET /users/me`
- `PUT /users/me/tourist-profile`
- `PATCH /users/me`
- `POST /users/me/entrepreneur-profile`

### Categories
- `GET /categories/`

### POIs / mapa / geocoding
- `GET /pois/search`
- `GET /pois/semantic-search`
- `GET /pois/{poi_id}`
- `POST /pois/`
- `PUT /pois/{poi_id}`
- `DELETE /pois/{poi_id}`
- `GET /pois/mine`
- `PATCH /pois/{poi_id}/media`
- `POST /pois/{poi_id}/visit`
- `GET /itineraries/{itinerary_id}/pois`
- `GET /geocoding/search`

### Reviews
- `GET /reviews/poi/{poi_id}`
- `GET /reviews/poi/{poi_id}/summary`
- `POST /reviews/`
- `PUT /reviews/{review_id}`
- `DELETE /reviews/{review_id}`

### Bookmarks
- `GET /bookmarks/`
- `GET /bookmarks/{poi_id}`
- `POST /bookmarks/{poi_id}`
- `DELETE /bookmarks/{poi_id}`

### Media
- `POST /media/upload`

### Weather
- `GET /weather/forecast`

### Entrepreneur
- `GET /entrepreneur/me/metrics`
- `GET /entrepreneur/me/income`
- `GET /entrepreneur/me/posts`
- `POST /entrepreneur/me/posts`
- `PATCH /entrepreneur/me/posts/{post_id}`
- `DELETE /entrepreneur/me/posts/{post_id}`
- `GET /entrepreneur/pois/{poi_id}/analytics`
- `GET /entrepreneur/pois/{poi_id}/activity`
- `GET /entrepreneur/pois/{poi_id}/posts`
- `POST /entrepreneur/pois/{poi_id}/posts`
- `PATCH /entrepreneur/pois/{poi_id}/posts/{post_id}`
- `DELETE /entrepreneur/pois/{poi_id}/posts/{post_id}`
- `PUT /entrepreneur/pois/{poi_id}/posts/{post_id}/pin`
- `PUT /entrepreneur/pois/{poi_id}/posts/reorder`
- `GET /pois/{poi_id}/posts` (público)

### Itinerary general (no Ara)
- `GET /itineraries/`
- `GET /itineraries/{id}`
- `POST /itineraries/generate`
- `DELETE /itineraries/{id}`
- `PATCH /itineraries/{id}/status`
- `POST /itineraries/{id}/steps`
- `PATCH /itineraries/{id}/steps/{step_id}`
- `DELETE /itineraries/{id}/steps/{step_id}`
- `PATCH /itineraries/{id}/steps/reorder`
- `PATCH /itineraries/{id}/steps/reorder-with-times`
- `PATCH /itineraries/{id}/steps/{step_id}/reschedule`
- `GET /itineraries/{id}/weather`
- `POST /itineraries/{id}/steps/{step_id}/visit`
- `GET /itineraries/{id}/visits`

### Ara / chat
- `POST /ara/sessions`
- `POST /ara/sessions/{session_id}/messages`
- `POST /ara/sessions/{session_id}/generate-itinerary/stream`

## 8.2 Endpoints Ara no usados por el frontend actual

Confirmación vigente:

- `POST /ara/sessions/{id}/generate-itinerary` → **no usado**
- `POST /ara/sessions/{id}/generate-itinerary/async` → **no usado**
- `GET /ara/sessions/{id}/generation-status` → **no usado**

## 8.3 Implicación arquitectónica

Backend puede tratar el flujo Ara sync/async como código legacy respecto a este frontend. El endpoint Ara verdaderamente crítico para frontend actual es el **stream SSE**.

---

## 9. Modelos y entidades principales

## 9.1 Chat / Ara

### `MessageAction`
Describe quick replies/acciones renderizables. Propiedades:
- `id`
- `label`
- `prompt`
- `type`

Helpers:
- `isGenerate`
- `isViewProgress`
- `isRetryStreaming`

### `MessageItineraryCard`
Representa un card de itinerario incrustado en un mensaje.

### `MessageCandidatePoi`
Representa un POI sugerido por Ara. Incluye:
- identidad
- descripción
- categorías
- coordenadas
- imagen
- distancia
- `actionValue`
- `poiRole`

Helper:
- `hasCoordinates`

### `MessageEntity`
Es la unidad renderizable del chat.

Campos relevantes:
- `text`
- `isUser`
- `timestamp`
- `isTyping`
- `turnType`
- `evidenceLevel`
- `actions`
- `itineraryCard`
- `candidatePois`
- `selectedActionId`
- `actionsLocked`
- `disclaimerText`
- `messageType`
- `progressPhase`

Es importante porque el provider ya no renderiza directamente DTOs de backend, sino esta entidad UI más rica.

### `AraSessionModel` y relacionados
`ara_session_model.dart` concentra varios modelos:
- quick replies
- mensajes del assistant
- search center
- candidate POIs
- intención
- progreso del viaje
- preferencias
- request/result de generación
- eventos SSE (`status`, `warning`, `result`, `error`)

Es uno de los archivos con más densidad de contratos backend de la app.

## 9.2 Itinerary

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
Campos funcionalmente importantes:
- identidad del paso e itinerary;
- `poiId`, `poiName`, `poiDescription`;
- `stepOrder`;
- `arrivalTime`, `departureTime`;
- `dayIndex`, `dayDate`, `dayLabel`;
- `aiContext`;
- timestamps.

Helpers importantes:
- `title`
- `reason`
- `tips`
- `recommendedDuration`
- `copyWith(...)`

### `PaginatedItinerariesModel`
Usado para lectura paginada del historial.

### `StepVisitModel`
Representa visitas marcadas a pasos del itinerario.

## 9.3 Reviews

### `ReviewModel`
Campos:
- `id`
- `poiId`
- `touristId`
- `authorName`
- `ratingStars`
- `textContent`
- `createdAt`

### `ReviewSummaryModel`
Campos:
- `poiId`
- `averageRating`
- `totalReviews`
- `ratingDistribution`

## 9.4 POIs / mapa

### `PoiModel`
DTO backend de POI.

Campos importantes:
- identidad y metadata básica;
- contacto;
- media;
- horarios;
- `visitRules`;
- categorías;
- coordenadas;
- distancia;
- estado de verificación;
- score de confianza.

### `VisitRulesModel`
Representa reglas de visita que Ara o backend pueden usar para calidad de itinerario:
- daylight
- night suitability
- latest start time
- access notes
- confidence

### `MapPoint`
Entidad UI/domain usada por mapa y varias pantallas de consumo. Es la representación ya adaptada para frontend.

### `CategoryModel`
Modelo simple de categorías backend:
- `id`
- `name`
- `iconUrl`

## 9.5 Entrepreneur

### `EntrepreneurMetricsModel`
Métricas agregadas del emprendedor:
- placesCount
- visitsCount
- reviewsCount
- favoritesCount

### `EntrepreneurIncomeModel`
Representa ingresos actuales o estado de pasarela:
- gross/net/pending
- currency
- status
- detail

### `EntrepreneurPostModel`
Modelo de post asociado a POI o emprendedor.

### `PoiAnalyticsModel`
Analytics por POI:
- visits
- clicks
- favorites
- reviews
- avgRating
- weeklyVisits
- monthlyGrowth

### `PoiActivityEvent`
Evento de actividad reciente por POI:
- `type`
- `timestamp`
- `data`

---

## 10. Providers y notifiers actuales

## 10.1 Infraestructura

- `sharedPreferencesProvider`
- `authTokenStorageProvider`
- `refreshTokenStorageProvider`
- `authTokenProvider`
- `dioProvider`
- `apiClientProvider`
- `appRouterProvider`
- `themeModeProvider`
- `globalLoadingProvider`

## 10.2 Auth

- `authProvider` (`NotifierProvider<AuthNotifier, AuthState>`)

## 10.3 Categories

- `categoryRepositoryProvider`
- `categoriesProvider`
- `categoryNameMapProvider`
- `categoriesByIdProvider`

## 10.4 Map / POIs

- `poiRepositoryProvider`
- `poiDetailProvider`
- `poiModelDetailProvider`
- `myPoisProvider`
- `itineraryPoisProvider`
- `mapProvider`

## 10.5 Reviews

- `reviewRepositoryProvider`
- `reviewsByPoiProvider`
- `reviewSummaryByPoiProvider`

## 10.6 Bookmarks

- `bookmarkRepositoryProvider`
- `bookmarkedPoisProvider`
- `bookmarkStatusProvider`

## 10.7 Itinerary

- `itineraryRepositoryProvider`
- `itineraryHistoryProvider`
- `itineraryDetailProvider`
- `itineraryProvider`

## 10.8 Chat / Ara

- `araRepositoryProvider`
- `chatProvider`
- providers derivados de progreso/navigation expuestos desde `chat_provider.dart`

## 10.9 Entrepreneur

- `entrepreneurRepositoryProvider`
- `entrepreneurMetricsProvider`
- `entrepreneurIncomeProvider`
- `entrepreneurPostsProvider`
- `poiAnalyticsProvider`
- `poiActivityProvider`
- `poiPostsProvider`
- `poiPublicPostsProvider`

## 10.10 Media

- `mediaRepositoryProvider`

## 10.11 Weather

- `weatherRepositoryProvider`
- `weatherForecastProvider`

## 10.12 Onboarding

- `interestsProvider`

---

## 11. Features detalladas

## 11.1 `auth`

### Objetivo
Gestionar ciclo de vida completo de sesión y perfil base del usuario.

### Pantallas
- `LoginPage`
- `RegisterPage`

### Estado
- `AuthNotifier` gobierna el estado completo de autenticación.

### Flujos clave
- login
- register + login automático
- restore session por access token
- restore session por refresh token
- logout
- update tourist profile
- activate entrepreneur profile

### Comentario arquitectónico
Es una feature relativamente limpia, con separación clara repository/provider/UI.

## 11.2 `home`

### Objetivo
Servir como portada conectada a POIs reales con visual destacado y entrada rápida a mapa/detalle.

### Componentes principales
- `HomePage`
- `HomeHeader`
- `DestinationHeroCard`
- `DestinationSkeleton`
- `MistNavigation`

### `HomePage`
Responsabilidades:
- disparar carga nearby al inicio si hace falta;
- usar `mapProvider` como data source;
- renderizar estado loading/empty/error/content;
- mostrar CTA de emergencia fija.

### `DestinationHeroCard`
Es el hero visual principal de la portada:
- imagen autenticada/fallback;
- pills de categoría y distancia;
- CTA “Ver en mapa”;
- CTA “Ver detalles”.

## 11.3 `categories`

### Objetivo
Resolver nombres e identidad visual de categorías desde backend.

### Valor práctico
Permite que home, mapa, detalle y entrepreneur no dependan de enums antiguos hardcodeados para el catálogo.

## 11.4 `map`

### Objetivo
Mapear POIs, búsquedas, foco geográfico, filtros y CRUD de lugares.

### Repository principal: `PoiRepository`
Capacidades:
- `getPoisForItinerary`
- `createPoi`
- `appendImage`
- `getMyPois`
- `updatePoi`
- `deletePoi`
- `recordVisit`
- `searchNearby`
- `semanticSearch`
- `getPoiById`

Comentario importante: la creación de POIs ya distingue explícitamente `tourist` vs. `entrepreneur`, tanto en UI como en endpoint (`/pois/tourist/` y `/pois/entrepreneur/`).

### Provider: `MapNotifier`
Responsabilidades:
- modo global vs. overrides temporales;
- nearby search;
- semantic search;
- filtrado por categoría;
- show itinerary POIs;
- show single POI;
- selección y focus;
- manejo de errores y loading.

### `MapScreen`
Es uno de los archivos más complejos del repo.

#### Qué hace
- renderiza `FlutterMap`;
- aplica estrategia de densidad de markers;
- usa `CustomMapMarker`;
- maneja búsqueda textual y fallback a geocoding;
- gestiona pull-to-refresh manual del mapa;
- muestra header, filtros, resultados de búsqueda, notices y rail de acciones;
- permite localizar usuario;
- usa layout landscape real: mapa al `60%` y panel lateral al `40%`;
- delega el panel lateral landscape a `_MapLandscapePanel`.

#### Ajustes responsive recientes
- las cards de resultados de búsqueda ahora usan ancho proporcional al viewport (`45%`, acotado entre `160` y `220`);
- en landscape el mapa deja de depender de overlays absolutos para todo el contenido secundario;
- el panel lateral agrega `Scrollbar` visible en desktop;
- antes de pintar markers se validan bounds/tamaños finitos para evitar glitches visuales.

#### Qué no hace
- no es responsable de ejecutar requests directas al backend por sí sola: eso vive en provider/repository;
- no persiste estado fuera de `mapProvider` y su estado local efímero.

### `PoiDetailFullPage`
Responsabilidades:
- resolver cache local o fetch por ID;
- registrar visita una vez;
- componer:
  - gallery header
  - title card
  - descripción
  - horarios y access notes
  - posts públicos
  - amenities
  - contacto
  - upload de imágenes
  - reviews

### `CreatePoiPage` / `EditPoiPage`
Responsabilidades:
- formularios de POI;
- categorías;
- imagen principal/medios;
- coordenadas;
- contacto;
- navegación de retorno;
- validación distinta según `creationType` turista/emprendedor.

### `LocationPickerSheet`
Responsabilidades:
- búsqueda geocodificada dentro del picker;
- ajuste de altura con `MediaQuery.viewInsetsOf(context).bottom` cuando aparece el teclado;
- `SafeArea` + `isScrollControlled` para no cortar contenido;
- selección fina de coordenadas sin romper el layout en desktop o compact height.

### Widgets importantes de la feature
- `CustomMapMarker`
- `LocationPickerSheet`
- `PoiGalleryHeader`
- `PoiDetailSheet`
- `PoiFormHero`
- `PoiImageUploadField`
- `AccessTypeSelector`
- `AmenityItem`
- `AuthenticitySeal`
- `_MapLandscapePanel`

## 11.5 `reviews`

### Objetivo
Gestionar opinión pública sobre POIs.

### `ReviewRepository`
Capacidades:
- `getByPoi`
- `create`
- `getSummaryByPoi`
- `update`
- `delete`

### `ReviewsSection`
Responsabilidades:
- leer lista y summary;
- detectar review propia del usuario;
- renderizar formulario, notices y lista;
- abrir edición vía diálogo;
- pedir confirmación de borrado;
- invalidar providers al mutar.

### Comentario
Aunque es “solo un widget”, en la práctica encapsula toda la sub-feature de reviews.

## 11.6 `bookmarks`

### Objetivo
Permitir guardar lugares y consultarlos después.

### `BookmarkRepository`
Capacidades:
- `getBookmarkedPois`
- `isBookmarked`
- `add`
- `remove`

### `BookmarksPage`
Responsabilidades:
- renderizar header visual;
- mostrar lista, vacío o error;
- refrescar favoritos.

### `BookmarkButton`
Responsabilidades:
- modo compacto o extendido;
- optimistic UI simple;
- snackbars de confirmación/error;
- invalidar providers tras add/remove.

## 11.7 `chat_ai`

### Objetivo
Ser la interfaz conversacional con Ara para refinar viajes, recopilar preferencias y disparar generación de itinerarios.

### `AraRepository`
Capacidades activas:
- `createSession`
- `sendMessage`
- `generateItineraryStream`

### SSE actual
El stream reconoce explícitamente:
- `status`
- `result`
- `warning`
- `error`

### `ChatNotifier`
Es uno de los mayores hotspots lógicos del proyecto.

#### Qué controla
- sesión Ara;
- fechas del viaje;
- lista de mensajes;
- estado de carga/typing;
- quick replies;
- candidate POIs;
- progreso resumido del viaje;
- progreso de stream;
- apertura manual o automática del SSE;
- retry del streaming;
- resultado final y navegación pendiente.

#### Qué renderiza indirectamente
A través de `MessageEntity`, `ChatBubble`, `TripProgressBar` y la pantalla.

### `ChatScreen`
Responsabilidades:
- contenedor scrollable del chat;
- autoscroll cuando crecen mensajes;
- banner del último itinerario disponible;
- integración de `ChatHeader`, `TripProgressBar` y `ChatInputField`;
- botón manual “Que lo arme Ara” cuando el flujo lo permite.

### `ChatBubble`
Responsabilidades:
- mensajes user/assistant;
- typing/progress bar;
- pills de evidencia;
- disclaimers;
- itinerary card;
- cards/listados de candidate POIs;
- quick replies/acciones.

### `TripProgressBar`
Responsabilidades:
- mostrar resumen de días ya estructurados;
- lodging sugerido;
- permitir pedir a Ara foco sobre un día en particular.

### `ChatHeader`
Responsabilidades:
- branding de Ara;
- volver atrás con fallback;
- acceso a historial de rutas.

### `ChatInputField`
Responsabilidades:
- texto;
- rango de fechas;
- feedback local de validación;
- placeholder de futura voz;
- bloqueo del input mientras el flujo lo exige.

## 11.8 `itinerary`

### Objetivo
Persistir, listar, abrir y editar superficialmente itinerarios generados.

### `ItineraryRepository`
Capacidades activas:
- historial paginado;
- detalle por ID;
- generación general `/itineraries/generate`;
- update status;
- add/delete/update step;
- reorder steps;
- reorder with times;
- reschedule step;
- weather;
- visits.

### `ItineraryNotifier`
Responsabilidades:
- mantener `current`;
- persistir último itinerario en storage;
- refrescar el actual;
- exponer errorMessage;
- aún incluye `generate(...)` para el flujo general no-Ara.

### `ItineraryMasterDetailPage`
Archivo: `lib/features/itinerary/presentation/pages/itinerary_master_detail_page.dart`

Responsabilidades:
- actuar como entrypoint adaptativo para la ruta de historial;
- mostrar solo `ItineraryHistoryPage` en mobile portrait;
- mostrar master-detail lado a lado en mobile landscape, tablet y desktop;
- sincronizar selección local con `itineraryProvider.current`.

### `ItineraryHistoryPage`
Responsabilidades:
- listar historial del usuario;
- navegar a detalle;
- soportar refresh y estados vacíos/error;
- funcionar también como panel embebido dentro del master-detail.

### `ItineraryDetailPage`
Sigue siendo una pantalla grande, pero ya no opera como un único god object autosuficiente.

#### Qué hace
- fetch por ID o fallback al itinerario current;
- delega mutaciones y derivaciones a `ItineraryDetailController` (`lib/features/itinerary/presentation/providers/itinerary_detail_notifier.dart`);
- weather dashboard;
- selector de día;
- listado de pasos por día;
- reorder intra-día;
- drag & drop inter-día;
- reschedule;
- delete step;
- change step vía chat;
- apertura de POIs del día en mapa;
- warnings por pasos fuera de rango.

#### Adaptación responsive reciente
- usa `OrientationBuilder`;
- en landscape divide el contenido en 2 columnas funcionales: pasos a la izquierda y panel contextual a la derecha;
- conserva drawer lateral de drop mientras se arrastra entre días;
- en desktop activa `Scrollbar` visible.

#### Day filtering actual
- `DaySelector` filtra por un solo día seleccionado;
- ya no existe el modo `Ver todos` en esta pantalla;
- el selector se adapta con `Wrap` o lista horizontal según ancho/text scale.

#### Widgets internos importantes
- `ItineraryHero`;
- `WeatherSection`;
- `DaySelector`;
- `GeneratedStep`;
- `RescheduleDialog`;
- `InterDayDragDrawer`;
- `DragFlyingProxy`;
- `DayDropSection`;
- `ItineraryInfoBanners`.

## 11.9 `entrepreneur`

### Objetivo
Cubrir el lado emprendedor del producto, tanto a nivel general como por POI.

### `EntrepreneurRepository`
Capacidades:
- métricas propias;
- income;
- posts propios globales;
- analytics por POI;
- actividad por POI;
- CRUD de posts por POI;
- pin/unpin;
- reorder de posts;
- feed público por POI.

### `EntrepreneurDashboardPage`
Dos modos:
1. usuario aún no activado como emprendedor;
2. usuario emprendedor con panel completo.

#### Modo activación
- formulario RUT;
- `activateEntrepreneurProfile`;
- invalidación de `myPoisProvider`.

#### Modo dashboard
- hero;
- métricas;
- listado de lugares propios;
- accesos a analíticas, posts, edición y detalle;
- grid adaptativo de lugares: 1 columna en mobile, 2 en tablet y 3 en desktop.

#### Detalle responsive útil
- `_PlacesSection` decide lista vertical vs. `GridView` según breakpoint;
- `_PlaceCard` usa `LayoutBuilder` para alternar layout horizontal/vertical cuando el ancho disponible es estrecho;
- desktop usa `Scrollbar` visible en el dashboard principal.

### `PoiDashboardPage`
Responsabilidades:
- analytics de un POI;
- performance section;
- activity feed;
- reviews del lugar.

### `PoiPostsManagementPage`
Responsabilidades:
- fetch posts del POI;
- crear/editar/eliminar post;
- pin/unpin;
- reorder optimista;
- feedback banner local;
- límites de cantidad.

### `PoiPostsView`
Responsabilidades:
- mostrar feed público resumido de publicaciones dentro del detalle del POI.

## 11.10 `user_profile`

### Objetivo
Mostrar y editar la identidad del usuario autenticado.

### `ProfileScreen`
Responsabilidades:
- consumir `authProvider`;
- renderizar skeleton / error / contenido;
- mostrar `ProfileHeader` y `AccountSettings`.

### `ProfileHeader`
Responsabilidades:
- hero visual del perfil;
- inicial del usuario;
- account status;
- summary line;
- pills de intereses.

### `AccountSettings`
Responsabilidades:
- accesos a edición de perfil;
- bookmarks;
- entrepreneur;
- logout;
- organización de tiles de configuración.

### `EditProfilePage`
Responsabilidades:
- editar nombre;
- editar intereses;
- editar transporte propio;
- feedback y submit.

## 11.11 `media`

### Objetivo
Subir imágenes desde el dispositivo y asociarlas al POI.

### `ImageUploadPanel`
Responsabilidades:
- abrir galería;
- subir bytes al backend;
- asociar URL al POI;
- refrescar detalle del POI;
- refrescar mapa global;
- mostrar preview y feedback.

## 11.12 `weather`

### Objetivo
Pedir pronóstico estructurado y volverlo usable en itinerary detail.

### `WeatherRepository`
Responsabilidades:
- llamar `/weather/forecast`;
- parsear listas bajo `daily`, `days` o `items`;
- ignorar texto libre `forecast` cuando no es estructurado.

## 11.13 `onboarding`

### Objetivo
Servir como superficie de exploración semántica basada en vibes e intereses.

### `VibeSelectionPage`
Responsabilidades:
- lanzar búsquedas semánticas reales desde clicks de vibes;
- usar `interestsProvider` para refinamiento;
- decidir si continuar al inicio o abrir mapa con búsqueda.

### Widgets principales
- `VibeCard`
- `InterestsSelector`
- `InterestTag`

---

## 12. Widgets compartidos y su papel real

## 12.1 Feedback y errores

### `AppFeedbackBanner`
Banner reusable de feedback con variantes (`error`, `warning`, `info`, `success`) y opciones compactas o dismiss.

### `InlineErrorWidget`
Widget reusable de error con CTA de retry.

### `ErrorBanner`
Versión más simple orientada a formularios o errores inline pequeños.

### `EmptyStateWidget`
Estado vacío reusable sin mucha lógica.

### `SkeletonContainer`
Bloque skeleton base sobre el que se construyen estados de carga más ricos.

## 12.2 Imagen y multimedia

### `AuthenticatedNetworkImage`
Resuelve imágenes remotas del backend y fallback/error. Se usa mucho en cards, hero sections y uploads.

## 12.3 Layout / estilo

### `GlassContainer`
Contenedor translúcido reutilizable, especialmente visible en input/chat y overlays.

### `SectionCard`
Estándar visual para bloques de contenido dentro de POI detail y dashboards.

### `CustomButton`
Botón estilizado reusable, usado en onboarding y otras superficies simples.

## 12.4 Navegación y atajos

### `AppBackButton`
Centraliza el patrón de back con fallback explícito.

### `EmergencyButton`
CTA visible en Home para emergencias.

### `TermsAndConditions`
Texto/acciones legales o informativas reutilizables en auth/onboarding cuando aplica.

---

## 13. Responsive, accesibilidad y UX técnica

## 13.1 Qué está mejor resuelto hoy

- `AppResponsive` ya opera como base transversal real de breakpoints, paddings y `maxContentWidth(...)`;
- la app clampa `textScaler` globalmente desde `AppTheme.clampedTextScaler(...)`;
- el shell principal, mapa, itinerarios y dashboard emprendedor ya no dependen de una única variante mobile;
- el hardening reciente priorizó evitar overflow, mejorar keyboard handling y reducir layouts frágiles.

## 13.2 Lote A — hardening base

Incluyó mejoras transversales de bajo nivel que impactan muchas pantallas a la vez:

- clamp global de text scale entre `0.8` y `1.4`;
- expansión del uso de `SafeArea` en shell y pantallas de scroll principal;
- `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` en formularios y listas largas;
- manejo explícito del teclado en `LocationPickerSheet` mediante `MediaQuery.viewInsetsOf(context).bottom`;
- ajustes de paddings y alturas para compact height;
- targets y constraints más razonables en botones/acciones flotantes.

## 13.3 Lote B — layouts adaptativos grandes

Aquí quedó resuelto el salto real hacia tablet/desktop y landscape útil:

- `MistNavigation` usa `NavigationRail` en tablet/desktop y `NavigationBar` en mobile;
- el rail se extiende cuando el ancho supera `800px`;
- la ruta de itinerarios entra por `ItineraryMasterDetailPage`, con master-detail en tablet/desktop y también en mobile landscape;
- `ItineraryDetailPage` usa `OrientationBuilder` y layout de 2 columnas en landscape;
- `MapScreen` usa layout landscape `60/40` con `_MapLandscapePanel`;
- `EntrepreneurDashboardPage` usa grid de 2 columnas en tablet y 3 en desktop.

## 13.4 Lote C — pulido visual, overflow y affordance

Este lote se enfocó en detalles que suelen romperse tarde:

- proliferación de `maxLines` + `TextOverflow.ellipsis` en cards, headers y celdas densas;
- `DaySelector` adaptable con `Wrap` cuando el ancho o el text scale ya no toleran una sola fila;
- hover state explícito en `NavigationRail` para desktop;
- `Scrollbar` visible en desktop para itinerarios, mapa landscape y dashboard emprendedor;
- bounds/tamaños finitos antes de pintar marker layers en mapa;
- uso más consistente de `ConstrainedBox`, `ClipRRect` y límites decorativos para evitar desbordes visuales.

## 13.5 Deuda UX aún visible

- no hay suite de screenshot/golden tests multi-device;
- varias pantallas siguen con demasiada responsabilidad visual y de estado;
- la adaptación a landscape y compact height sigue resuelta de forma pragmática por pantalla, no desde un sistema de layout más declarativo;
- web/desktop tienen mejoras claras, pero aún faltan pruebas sistemáticas de navegación por teclado y focus traversal.

---

## 14. Testing y validación

## 14.1 Cantidad actual de tests

Existen **40 archivos `*_test.dart`** bajo `test/`.

Resultado validado hoy:

- **300 tests pasados, 0 fallidos** en `flutter test` (2026-06-06);
- **0 issues** en `flutter analyze` (2026-06-06).

## 14.2 Cobertura visible por área

### Core
- errores HTTP
- router
- sanitizer de texto público
- responsive
- widgets compartidos
- listener global de chat streaming
- routing de `CreatePoiPage` con `creationType`

### Auth
- repository
- provider

### Chat AI
- modelos SSE/Ara
- provider de chat
- candidate POI card
- chat bubble
- chat input field
- trip progress bar

### Entrepreneur
- modelos
- repository
- dashboard responsive (lista mobile, grid tablet/desktop, scrollbar desktop)

### Itinerary
- repository
- provider
- contrato de POIs para itinerario
- `ItineraryDetailPage`
- `ItineraryHistoryPage`
- `ItineraryMasterDetailPage`
- drag & drop inter-día
- selector de día sin `Ver todos`

### Map
- modelos POI
- repository
- provider
- `CreatePoiPage`
- `MyContributionsPage`
- marker logic
- custom marker

### Home / Navigation
- `MistNavigation` responsive (`NavigationBar` vs `NavigationRail`)

### Onboarding
- interests provider

### User profile
- profile screen

### Weather
- repository

## 14.3 Qué cubren bien

- serialización/deserialización;
- contratos backend importantes;
- rutas protegidas;
- parsing SSE;
- warning/result en Ara;
- side effects del listener global;
- navegación adaptativa (`MistNavigation`);
- master-detail de itinerarios;
- separación turista/emprendedor en contribuciones;
- drag & drop inter-día.

## 14.4 Qué sigue faltando

- cobertura más integral de `MapScreen` completo (interacciones, overlays y landscape real);
- más pruebas widget para variantes landscape/desktop de `ItineraryDetailPage` y dashboards emprendedor;
- golden tests multi-breakpoint;
- escenarios de error cross-feature más integrados.

---

## 15. Deuda técnica y límites actuales

## 15.1 Deuda que ya salió del bucket crítico

Fixes que antes eran deuda visible y hoy deben considerarse resueltos o sustancialmente mitigados:

- `MistNavigation` ya no es solo mobile: existe variante tablet/desktop con `NavigationRail`;
- `ItineraryDetailPage` dejó de concentrar toda la lógica de mutación en un único widget: hoy usa `ItineraryDetailController` y widgets extraídos;
- el selector de días rígido fue reemplazado por `DaySelector` adaptable y filtrado por día;
- el drag & drop inter-día ya existe y tiene cobertura de tests;
- el alta de contribuciones ya separa turista vs. emprendedor de forma explícita en frontend y repository.

## 15.2 Hotspots grandes que siguen vigentes

Archivos especialmente grandes o cargados de responsabilidad al 2026-06-06:

- `lib/features/map/presentation/pages/map_screen.dart` — **1,877 líneas**;
- `lib/features/chat_ai/presentation/providers/chat_provider.dart` — **1,223 líneas**;
- `lib/features/itinerary/presentation/pages/itinerary_detail_page.dart` — **919 líneas**;
- `lib/features/entrepreneur/presentation/pages/entrepreneur_dashboard_page.dart` — **892 líneas**;
- `lib/features/entrepreneur/presentation/pages/poi_posts_page.dart` — **742 líneas**;
- `lib/features/entrepreneur/presentation/pages/poi_dashboard_page.dart` — **711 líneas**.

## 15.3 Riesgos arquitectónicos reales

- acoplamiento funcional alto entre chat, itineraries y map;
- lógica todavía grande en notifiers/páginas en lugar de coordinadores más pequeños;
- responsive quedó mucho mejor, pero sigue resuelto de forma pragmática y no desde un design system/layout system más estricto.

## 15.4 Seguridad y persistencia

- tokens en `shared_preferences` siguen siendo válidos para esta etapa, pero no equivalen a almacenamiento seguro móvil final.

## 15.5 Notificaciones y background real

- la app **sí** muestra notificación in-app cuando Ara termina;
- la app **no** implementa todavía push/local notification del sistema para app en background/cerrada.

## 15.6 Itinerarios: coexistencia de dos mundos

Hoy coexisten:

1. flujo general `/itineraries/generate`
2. flujo Ara por SSE

No están mezclados a nivel de endpoint, pero sí conviene documentarlo siempre para evitar malentendidos de backend o frontend futuro.

## 15.7 Deuda nueva o todavía poco visible

- no existe todavía una suite de golden/screenshot tests multi-breakpoint;
- `poi_dashboard_page.py` existe vacío dentro de `lib/features/entrepreneur/presentation/pages/` y debería eliminarse o justificarse;
- web/desktop mejoraron bastante, pero aún faltan pruebas sistemáticas de focus, teclado y accesibilidad no táctil.

---

## 16. Historial técnico resumido y ordenado

## 16.1 Etapa inicial (2026-04-30)

- bootstrap del proyecto Flutter;
- primeras estructuras visuales;
- base de `core/` + `features/`.

## 16.2 Primera integración backend (2026-05-02)

- conexión auth inicial;
- persistencia JWT;
- guards de navegación;
- primeras conexiones reales a POIs, itinerarios, media y reviews.

## 16.3 Consolidación funcional (2026-05-03)

- categorías data-driven;
- bookmarks;
- perfil editable;
- activación emprendedor;
- edición/eliminación de POIs;
- mejoras de navegación y UX.

## 16.4 Dashboards, posts y mejoras de itinerario (2026-05-20)

- dashboard emprendedor por POI;
- posts asociados a POIs;
- reorder de posts;
- analytics y activity;
- reschedule/reorder de pasos de itinerario;
- clima en itinerarios;
- fixes de navegación cross-shell;
- sincronización de contratos backend.

## 16.5 Migración Ara a SSE-only (posterior)

- confirmación de que frontend Ara usa solo SSE;
- cleanup de rutas sync/async/status no usadas;
- backend puede tratar esas rutas como legacy respecto a este frontend.

## 16.6 Soporte de `warning` en SSE

- parser SSE extendido para `warning`;
- render UX del warning en el chat;
- quick replies sugeridas al usuario sin romper el stream.

## 16.7 Notificación global de itinerario listo

- listener global añadido en `main.dart`;
- snackbar flotante “Itinerario listo” con CTA “Ver”.

## 16.8 Hardening responsive/accesibilidad/documentación

- mejoras de refresh;
- mejoras de touch targets;
- mejor text scaling;
- mapa e itinerario más robustos;
- saneamiento y actualización integral de `documentation.md`.

---

## 17. Deuda Técnica Conocida (Frontend)

### 17.1 Crítica (Bloquea Producción)

Ninguna. El proyecto compila, la app funciona, y los flujos principales están operativos.

### 17.2 Alta (Afecta Mantenibilidad / Extensión)

| # | Item | Impacto | Plan |
|---|------|---------|------|
| 1 | `chat_provider.dart` (1,223 líneas) | God Notifier con demasiadas responsabilidades mezcladas. Agregar features nuevas al chat sigue siendo costoso y riesgoso. | Extraer sub-notifiers/coordinadores por sesión, streaming, navegación y UI |
| 2 | `map_screen.dart` (1,877 líneas) | God Widget todavía grande. El jank principal mejoró, pero clustering/markers/layout siguen concentrados en un solo archivo. | Seguir extrayendo paneles, overlays y lógica de densidad/cálculo |
| 3 | Acoplamiento `itinerary ↔ chat_ai` | `itinerary_detail_page.dart` sigue importando `chat_provider.dart` para iniciar reemplazos de pasos vía chat. | Crear coordinador/interfaz en `core/coordination/` o adapter de navegación/acciones |

### 17.3 Media (Tests / Pulido)

| # | Item | Impacto | Plan |
|---|------|---------|------|
| 4 | No hay golden/screenshot tests multi-breakpoint | Se pueden romper layouts responsive sin señal temprana en CI. | Agregar golden tests clave para mobile, tablet, desktop y landscape |
| 5 | `ItineraryDetailController` no tiene suite unitaria directa | La lógica está mejor separada pero hoy se valida sobre todo vía widget tests. | Agregar tests unitarios del controller y payloads de reorder |
| 6 | `debugPrint` en producción | Hay 24 ocurrencias en `lib/`. No bloquea, pero ensucia logs y mezcla tracing con UI. | Reemplazar por logger estructurado o encapsular con `kDebugMode` |

### 17.4 Baja (Nice to Have)

| # | Item | Plan |
|---|------|------|
| 7 | Formatear todos los archivos con `dart format` | Correr `dart format lib test` y commitear |
| 8 | Agregar `analysis_options.yaml` más estricto | Incluir `unused_import`, `avoid_print`, `prefer_final`, etc. |
| 9 | Eliminar o justificar `poi_dashboard_page.py` vacío | Limpiar artefacto residual dentro de `lib/features/entrepreneur/presentation/pages/` |

---

## 18. Estado actual y refactorización completada (2026-06-06)

### 18.1 Fases 1-3 del Frontend (MVP + Fixes)

| Fase | Estado | Lo que se hizo |
|------|--------|----------------|
| Fase 1 | ✅ | Widgets base del chat y flujo inicial integrados |
| Fase 2.1-2.4 | ✅ | Slot Detector, Persistencia de Slots, Ara Pregunta Primero, Validación OSRM por slot |
| Fase 2.5 | ✅ | `all_slots_filled`, botón condicional, filtrado de quick replies |
| Fase 2.6 | ✅ | Slots de comida genéricos (`is_generic: true`, `poi_id: null`) funcionando end-to-end |
| Fase 3 | ✅ | Drag & drop entre días con persistencia, feedback visual y cobertura de tests |
| Hardening responsive A/B/C | ✅ | clamp de text scale, layouts landscape, `NavigationRail`, master-detail, grids, hover/scrollbars y control de overflows |

### 18.2 Quick Wins (Backend)

| # | Cambio | Archivo | Impacto |
|---|--------|---------|---------|
| Q1 | `asyncio.gather` en `_search_diverse_pois` | `tool_orchestrator.py` | Búsquedas de categoría en paralelo |
| Q2 | Batch `get_pois_by_ids` en `_build_itinerary` | `tool_orchestrator.py` | 1 query en vez de N |
| Q3 | `asyncio.gather` en `_resolve_poi_reference` | `tool_orchestrator.py` | Resolución de nombres en paralelo |
| Q4 | Logging en endpoints | `ara.py`, `itineraries.py`, `ara_conversation_orchestrator.py` | Traza en producción |
| Q5 | Eliminar `ItineraryRepository` import muerto | `tool_orchestrator.py` | Limpieza |

### 18.3 Refactor de `itinerary_detail_page.dart`: estado real hoy

| Métrica | Antes del refactor | Después inmediato | Estado actual 2026-06-06 |
|---------|--------------------|-------------------|---------------------------|
| **Líneas** | 1,910 | 438 | 919 |
| **Clases en el archivo** | 29 | 3 | 5 |
| **Controller** | no existía | creado | sigue vigente |
| **Widgets extraídos** | — | 9 archivos | siguen vigentes + drawer/proxy inter-día |

Interpretación correcta: el refactor **sí funcionó** y sacó la lógica central del widget principal, pero el archivo volvió a crecer por soporte landscape, overlays adaptativos y drag & drop inter-día. Ya no es el mismo god object monolítico, aunque sigue siendo un hotspot.

**Archivos relevantes creados o incorporados en esta etapa:**
- `lib/features/itinerary/presentation/pages/itinerary_master_detail_page.dart`
- `lib/features/itinerary/presentation/widgets/inter_day_drag_drawer.dart`
- `lib/features/itinerary/presentation/widgets/drag_flying_proxy.dart`
- `lib/features/itinerary/presentation/widgets/day_selector.dart`
- `lib/features/itinerary/presentation/widgets/day_drop_section.dart`
- `lib/features/itinerary/presentation/providers/itinerary_detail_notifier.dart`

### 18.4 Fixes de performance y estructura aplicados

| Fix | Archivo | Resultado |
|-----|---------|-----------|
| `ItineraryDetailController` para mutaciones/derivaciones | `itinerary_detail_notifier.dart` | menos lógica imperative mezclada en la página |
| `ValueNotifier<(LatLng, double)>` en mapa completo | `map_screen.dart` | menos jank en pan/zoom |
| validación de bounds finitos antes de marker layer | `map_screen.dart` | menos fragilidad visual en mapa |
| `LayoutBuilder` en cards/layouts densos | varias pantallas | menos overflows en tablet/desktop |
| `OrientationBuilder` en itinerarios | `itinerary_detail_page.dart` | landscape funcional de 2 columnas |

### 18.5 Limpieza y consolidación recientes

| Cambio | Impacto |
|--------|---------|
| Shell principal ahora entra por `MistNavigation` adaptativa | navegación coherente en mobile, tablet y desktop |
| contribuciones separadas turista/emprendedor | contratos frontend más explícitos y menos ambigüedad de validación |
| `CreatePoiPage` validada por `creationType` | el flujo emprendedor exige contacto público; el turista no |
| `MyContributionsPage` y dashboard emprendedor conviven sin mezclar responsabilidades | aportes propios vs. catálogo de negocios mejor delimitado |

### 18.6 Tests

| Suite | Total | Pasados | Fallidos | Estado |
|-------|-------|---------|----------|--------|
| Frontend tests (`flutter test`) | 300 | 300 | 0 | ✅ Limpio |
| Archivos `*_test.dart` frontend | 40 | — | — | ✅ Activos |
| `flutter analyze` | — | — | 0 issues | ✅ Limpio |

### 18.7 Estado actual del proyecto

> **El frontend está aproximadamente entre 92% y 93% de completitud funcional.** Las Fases 1, 2 y 3 están completas, el responsive design de los Lotes A/B/C ya está aplicado, el drag & drop inter-día funciona con tests, el sistema de contribuciones quedó separado para turista/emprendedor y la shell principal ya cubre mobile/tablet/desktop. La deuda técnica restante se concentra sobre todo en hotspots grandes (`map_screen.dart`, `chat_provider.dart`, dashboards emprendedor) y en automatización visual/accesibilidad avanzada.

---

## 19. Estado de verdad al cierre de esta documentación

Si alguien necesita una lectura ultrarrápida y correcta del proyecto hoy, estas son las afirmaciones verdaderas:

1. El frontend usa Flutter, Riverpod, GoRouter y Dio.
2. Sí existe refresh token y retry tras `401`.
3. Los tokens se guardan en `shared_preferences`.
4. Home reutiliza `mapProvider` como fuente principal de POIs destacados.
5. El mapa, los POIs, reviews, bookmarks, media, entrepreneur dashboards y weather están conectados a backend real.
6. Ara genera itinerarios mediante **SSE**, no vía sync/async Ara.
7. El SSE soporta `status`, `warning`, `result` y `error`.
8. Hay notificación in-app global cuando un itinerario Ara queda listo.
9. El flujo general `/itineraries/generate` sigue existiendo y es distinto del flujo Ara.
10. **Drag & Drop entre días está implementado y funciona, incluyendo drawer lateral y persistencia de reorder.**
11. **El sistema de contribuciones separa turista vs. emprendedor desde ruta, validación y endpoint.**
12. **`MistNavigation` ya es adaptativa: `NavigationBar` en mobile y `NavigationRail` en tablet/desktop.**
13. **`ItineraryMasterDetailPage` está activa para itinerarios en tablet/desktop y también en mobile landscape.**
14. **`itinerary_detail_page.dart` sí fue refactorizado, pero hoy mide 919 líneas; la lógica principal quedó extraída en `ItineraryDetailController`.**
15. **`chat_provider.dart` sigue siendo un God Notifier grande: 1,223 líneas al 2026-06-06.**
16. **`flutter test` pasa con 300/300 y `flutter analyze` está limpio.**
17. `documentation.md` es el documento maestro y debe mantenerse alineado con el código real.

