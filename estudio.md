# Libro Didáctico de Estudio — Frontend Ruta Viva

> Última actualización integral: **2026-06-06**
>
> Este archivo no es un resumen ejecutivo ni una lista de carpetas. Está pensado como un libro de estudio del frontend real del proyecto. La idea es que sirva tanto para aprender Flutter moderno como para entender por qué este código está organizado exactamente así.

---

## Introducción: Propósito de este material

Este documento existe para una meta muy concreta: que puedas abrir cualquier archivo importante del frontend y no sentir que estás mirando una pared de código, sino una conversación técnica con sentido.

No fue escrito para memorizar nombres. Fue escrito para construir criterio.

Eso significa que aquí no solo vamos a responder:

- qué hace un archivo,
- qué hace un provider,
- qué hace una pantalla,
- o qué endpoint llama un repository.

También vamos a responder preguntas más importantes:

- por qué se eligió Flutter para esta tesis;
- por qué el estado vive en Riverpod y no en otra solución;
- por qué la navegación está declarada con GoRouter;
- por qué el cliente HTTP es Dio;
- por qué algunos widgets son `StatefulWidget` y otros no;
- por qué la app guarda tokens en `SharedPreferences` aunque no sea la solución final ideal;
- por qué algunos archivos crecieron tanto;
- y por qué ciertas decisiones del repo son pragmáticas, no académicamente “puras”.

La meta final es esta:

> poder abrir cualquier archivo importante del proyecto y entender no solo lo que hace, sino por qué alguien razonable lo escribiría de esa forma.

Si este material funciona bien, deberías terminar pudiendo explicar:

1. cómo arranca la app;
2. cómo se restaura una sesión;
3. cómo se protege una ruta;
4. cómo se agrega el token a una request;
5. cómo se refresca automáticamente un `401`;
6. cómo una pantalla conversa con un provider;
7. cómo una feature está dividida en `data/`, `domain/` y `presentation/`;
8. cómo el mapa evita colapsar cuando hay muchos marcadores;
9. cómo el chat con Ara procesa un stream SSE;
10. cómo el frontend mantiene coherencia con el backend.

Piensa este archivo como un libro de anatomía del frontend. No te muestra solamente la piel del sistema. Te muestra huesos, músculos, nervios y circulación.

---

## Capítulo 1: Flutter y Dart Moderno

### Introducción

Flutter no es simplemente “una forma de hacer apps móviles”. Flutter es una forma muy específica de pensar la UI: todo es composición de widgets, todo se describe como árbol, y la reconstrucción visual no se considera un accidente sino parte normal del modelo.

Para entender este frontend, primero hay que entender la gramática del lenguaje en que está escrito. En backend uno piensa en request, service, repository, DB session. En Flutter uno piensa en:

- widget tree,
- `BuildContext`,
- `State`,
- reconstrucción,
- renderizado declarativo,
- y flujo asíncrono visible en pantalla.

Sin esa base, el resto del proyecto se ve como una colección rara de clases con nombres bonitos. Con esa base, empieza a verse como una arquitectura coherente.

### Desarrollo

#### 1. Qué es un Widget realmente

Un `Widget` no es “el botón mismo” ni “el texto mismo”. Es una **descripción inmutable** de una porción de UI.

Ese matiz importa mucho.

Cuando escribes:

```dart
Text('Hola')
```

no estás dibujando letras en ese momento. Estás declarando que en este punto del árbol debería existir una representación de texto con ese contenido.

Flutter toma esas descripciones, las compara, y decide qué reconstruir y qué reutilizar.

Una analogía útil:

- el widget es el plano arquitectónico;
- el elemento es la obra en ejecución;
- el render object es la parte física que termina calculando layout y pintura.

En tesis normalmente basta con dominar bien el primer nivel: el widget como declaración.

#### 2. `StatelessWidget` y `StatefulWidget`

`StatelessWidget` se usa cuando el widget no necesita memoria mutable propia.

Ejemplo mental:

- si una card solo recibe datos y los pinta, probablemente es `StatelessWidget`;
- si una pantalla necesita recordar cuál día está seleccionado, si un drag está activo o si un controlador de texto debe vivir entre builds, probablemente necesita estado.

`StatefulWidget` existe cuando la UI necesita conservar algo entre reconstrucciones.

En este proyecto eso aparece mucho en casos como:

- formularios con `TextEditingController`;
- pantallas que necesitan `initState()`;
- temporizadores;
- `MapController`;
- animaciones;
- controladores de drag & drop;
- cachés o banderas efímeras de interacción.

#### 3. `BuildContext`

`BuildContext` suele confundirse con “un helper mágico”.

En realidad es la forma en que un widget sabe **dónde está parado dentro del árbol**.

Por eso desde `BuildContext` puedes:

- leer `Theme.of(context)`;
- leer `MediaQuery.of(context)`;
- navegar;
- encontrar `InheritedWidgets`;
- resolver localización;
- aplicar dependencias visuales del árbol.

No es simplemente un parámetro molesto. Es la coordenada semántica del widget dentro de la UI.

#### 4. `setState`

`setState` no “cambia la UI” directamente. Lo que hace es decirle a Flutter:

> el estado interno de este objeto cambió; vuelve a ejecutar `build()` para esta parte del árbol.

Eso también implica algo importante: **usar `setState` para estado de negocio global es mala idea**. Sirve muy bien para estado local efímero, pero no para autenticación, mapa global, chat o itinerarios persistentes.

Por eso este proyecto combina:

- `setState` para detalles locales de interacción,
- Riverpod para estado compartido o de negocio.

#### 5. Async en Dart: `Future`, `Stream`, `async/await`

Dart tiene un modelo async muy limpio.

##### `Future`

Un `Future<T>` representa un valor que llegará después.

Ejemplo real del proyecto:

- login;
- fetch de usuario actual;
- búsqueda de POIs;
- refresh token;
- submit de formularios.

Cuando un método devuelve un `Future`, la UI no puede asumir que el resultado ya está disponible. Debe esperar.

##### `async/await`

`async/await` permite escribir código asíncrono casi como si fuera secuencial:

```dart
final token = await repository.login(email: email, password: password);
final user = await repository.getMe();
```

Esto es ideal para flujos imperativos como autenticación o submit de formularios.

##### `Stream`

Un `Stream<T>` representa una secuencia de valores a lo largo del tiempo.

En este frontend eso aparece de forma especialmente importante con SSE para Ara.

Un itinerario generado por stream no llega como “un JSON final” solamente. Llega como eventos:

- `status`
- `warning`
- `result`
- `error`

Eso hace que `Stream` sea el modelo correcto: la información va apareciendo por fragmentos.

### Por qué Flutter y no React Native o Ionic

Esta decisión no es solo una preferencia estética. Tiene razones técnicas y pedagógicas.

#### Flutter sobre React Native

Flutter entrega:

- control visual muy fino;
- consistencia fuerte entre plataformas;
- un árbol de renderizado propio;
- buen performance para UI complejas;
- una experiencia excelente para layouts adaptativos y composición visual.

Para una tesis con:

- mapa,
- overlays,
- drag & drop,
- pantallas con densidad visual alta,
- responsive fuerte,
- flujo conversacional,

Flutter es una elección muy razonable.

React Native tiene ventajas de ecosistema y cercanía a React, pero para un proyecto de este tipo Flutter simplifica bastante la consistencia visual y el control del renderizado.

#### Flutter sobre Ionic

Ionic se apoya más en tecnologías web y en una capa híbrida. Para prototipos y apps CRUD simples puede ser suficiente, pero para una app con este nivel de interacción visual, mapas, shell adaptativo y control fino de UI, Flutter ofrece una base más sólida.

#### Flutter como decisión de tesis

Además hay una razón didáctica poderosa:

- obliga a aprender composición real de UI;
- obliga a distinguir estado local vs global;
- obliga a pensar en reconstrucción y layout;
- y obliga a entender asincronía en una app visual real.

En otras palabras: Flutter no solo sirve para construir la app. Sirve para aprender arquitectura de frontend con profundidad.

### Análisis de `main.dart` completo línea por línea

Archivo real:

- `lib/main.dart`

Código relevante:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_storage_provider.dart';
import 'core/widgets/chat_streaming_effects_listener.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/widgets/global_loading_overlay.dart';
```

#### Imports

- `material.dart`: da acceso a Material Design, widgets base y `runApp`.
- `flutter_riverpod.dart`: habilita `ProviderScope`, `ConsumerWidget` y toda la infraestructura de estado.
- `shared_preferences.dart`: necesario para instanciar persistencia antes de arrancar la app.
- `app_router.dart`: define toda la navegación declarativa.
- `local_storage_provider.dart`: expone `SharedPreferences` como dependencia inyectable.
- `chat_streaming_effects_listener.dart`: escucha side effects globales del chat.
- `app_theme.dart`: centraliza tema claro/oscuro y text scaling.
- `theme_mode_provider.dart`: controla modo claro/oscuro.
- `global_loading_overlay.dart`: overlay global de carga.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
```

#### `WidgetsFlutterBinding.ensureInitialized()`

Esta línea le dice a Flutter:

> inicializa el binding antes de usar APIs del framework que dependen de ello.

¿Por qué importa?

Porque `SharedPreferences.getInstance()` necesita que la capa nativa/Flutter ya esté preparada. Sin esa línea, algunas APIs async de plataforma podrían fallar al inicio.

#### `SharedPreferences.getInstance()`

Se obtiene una instancia única de persistencia local. Observa la decisión: la app resuelve esto al arranque y luego la inyecta al árbol de providers.

Eso es mejor que crear instancias de `SharedPreferences` dispersas por todo el repo.

```dart
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const RutaVivaApp(),
    ),
  );
}
```

#### `ProviderScope`

`ProviderScope` es el contenedor raíz de Riverpod. Sin él, los providers no existen.

#### `overrides`

Aquí aparece una de las mejores ideas del proyecto: `sharedPreferencesProvider` no crea la instancia por sí solo, sino que **exige ser sobreescrito**. Eso permite:

- inyección limpia en producción,
- control total en tests,
- cero singletons ocultos.

Esta técnica es clave en Riverpod porque convierte dependencias globales en dependencias explícitas y testeables.

#### `RutaVivaApp`

Es la raíz visual real de la aplicación.

```dart
class RutaVivaApp extends ConsumerWidget {
  const RutaVivaApp({super.key});
```

Se usa `ConsumerWidget` porque esta raíz necesita leer providers, concretamente:

- el router,
- el modo de tema.

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
```

#### `ref.watch(...)`

- `appRouterProvider`: entrega un `GoRouter` configurado con redirect y rutas.
- `themeModeProvider`: indica si el tema está en light, dark o system.

La raíz observa ambos porque si alguno cambia, debe reconstruirse.

```dart
    return MaterialApp.router(
```

No se usa `MaterialApp` clásico, sino `MaterialApp.router`, porque la navegación está desacoplada y gestionada por GoRouter.

```dart
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: AppTheme.clampedTextScaler(context),
          ),
          child: ChatStreamingEffectsListener(
            child: Stack(children: [child!, const GlobalLoadingOverlay()]),
          ),
        );
      },
```

Este bloque es muy importante.

##### `builder`

Permite envolver toda la app con capas transversales.

##### `MediaQuery.copyWith(textScaler: ...)`

El proyecto reescribe el `textScaler` global para clamarlo entre `0.8` y `1.4`. Esto es una decisión de accesibilidad pragmática:

- respeta escalado del sistema,
- pero evita que escalas extremas rompan layouts sensibles.

##### `ChatStreamingEffectsListener`

Es una capa global que escucha efectos del chat incluso cuando el usuario no está parado en la pantalla de chat. Esto permite mostrar feedback o navegación cuando Ara termina un itinerario en segundo plano dentro de la app.

##### `Stack(... GlobalLoadingOverlay())`

Otra decisión arquitectónica interesante: el loading global no depende de cada pantalla. Se superpone a la app completa.

```dart
      title: 'Ruta Viva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
```

Aquí quedan configurados:

- título de aplicación;
- eliminación del banner debug;
- tema claro;
- tema oscuro;
- modo activo;
- router completo.

### Conclusión

`main.dart` es pequeño, pero conceptualmente contiene media arquitectura del frontend.

Desde ahí ya ves:

- inyección de dependencias;
- tema global;
- router declarativo;
- persistencia inicial;
- efecto global del chat;
- estrategia de accesibilidad.

Es un excelente ejemplo de cómo un archivo corto puede tener muchísimo peso arquitectónico.

---

## Capítulo 2: Arquitectura de Estado con Riverpod

### Introducción

El frontend moderno no se rompe por no saber pintar botones. Se rompe por no saber dónde vive el estado, quién lo cambia, cuándo se reconstruye la UI y cómo se testea todo eso sin dolor.

Riverpod es la respuesta elegida por este proyecto para ese problema.

### Desarrollo

#### 1. Qué es un provider

Un provider es una unidad declarativa de dependencia o estado.

Puede representar:

- un valor simple;
- un servicio;
- un repository;
- un notifier de estado;
- un `Future` derivado;
- una familia de valores parametrizados.

Riverpod permite pensar el sistema como un grafo de dependencias observable y testeable.

#### 2. `read`, `watch`, `listen`

##### `ref.read(...)`

Se usa cuando quieres leer algo **sin suscribirte**.

Ejemplo:

- dentro de un submit;
- dentro de una mutación;
- dentro de un repository provider;
- para disparar métodos de un notifier.

##### `ref.watch(...)`

Se usa cuando quieres que el widget o provider se reconstruya si ese valor cambia.

Ejemplo:

- una pantalla observa `authProvider`;
- la raíz observa `themeModeProvider`;
- una pantalla observa un `FutureProvider` de detalle.

##### `ref.listen(...)`

Se usa cuando quieres reaccionar a cambios con side effects, no solo reconstruir.

Ejemplo clave del proyecto:

- el router escucha `authProvider` para refrescar redirects;
- `AuthNotifier.build()` escucha `authTokenProvider` para invalidar sesión si el token desaparece.

#### 3. `Notifier` y estado explícito

En este proyecto se usa mucho `Notifier<T>` en vez de depender de clases más mágicas.

Eso obliga a expresar claramente:

- cuál es el estado completo;
- cuál es el estado inicial;
- qué mutaciones existen;
- cómo se propagan errores.

Esto es visible en clases como:

- `AuthNotifier`
- `MapNotifier`
- `ChatNotifier`
- `ItineraryNotifier`

#### 4. Por qué Riverpod y no Provider, Bloc o MobX

##### Riverpod sobre Provider

`Provider` clásico funciona, pero depende más fuerte del árbol de widgets y tiene más fragilidad conceptual con `BuildContext`.

Riverpod mejora varias cosas:

- independencia del árbol visual;
- tipado más claro;
- overrides elegantes en tests;
- composición mejor de dependencias;
- menos acoplamiento accidental entre UI y estado.

##### Riverpod sobre Bloc

Bloc da mucha estructura, pero a veces demasiada ceremonia para un proyecto donde:

- hay muchas features,
- pero el equipo necesita velocidad,
- y varias pantallas combinan estado local con estado global.

Riverpod es más liviano y expresivo para este caso.

##### Riverpod sobre MobX

MobX es reactivo y cómodo, pero más implícito. Riverpod hace más explícitas las dependencias. Para tesis y mantenibilidad eso suele ser mejor, porque obliga a entender de dónde sale cada valor.

### Cómo se organiza el estado en este proyecto

#### Infraestructura

- `sharedPreferencesProvider`
- `authTokenProvider`
- `apiClientProvider`

#### Estado de autenticación

- `authProvider`

#### Estado de mapa

- `mapProvider`

#### Estado de itinerario actual

- `itineraryProvider`

#### Estado conversacional

- `chatProvider`

#### Estado derivado/fetches parametrizados

- `poiDetailProvider`
- `itineraryDetailProvider`
- `itineraryWeatherProvider`
- `itineraryHistoryProvider`
- `myPoisProvider`
- `entrepreneurPoisProvider`

Esto muestra una decisión importante: no todo es un notifier mutable. Mucho del estado se modela mejor como consulta derivada o fetch declarativo.

### Análisis de `authProvider`

Archivo:

- `lib/features/auth/presentation/providers/auth_provider.dart`

#### Qué estado modela

```dart
class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;
```

Este estado responde preguntas reales de producto:

- ¿hay usuario?
- ¿hay token?
- ¿la sesión se está restaurando?
- ¿hubo error de auth?

#### Decisión importante: `isAuthenticated`

```dart
bool get isAuthenticated => token != null && user != null;
```

No basta con tener token. El proyecto considera autenticación válida cuando también hay usuario cargado. Eso evita estados “medio autenticados”.

#### Restauración de sesión

`build()` hace algo muy importante:

- lee token persistido;
- lee refresh token persistido;
- intenta restaurar la sesión automáticamente.

Eso significa que el provider no es solo contenedor de estado: también es **máquina de arranque de sesión**.

#### Microtareas

```dart
Future.microtask(() => _restoreSession(storedToken));
```

Esto evita hacer trabajo async bloqueando directamente `build()`. Es una técnica útil para arrancar side effects después de construir el estado inicial.

#### Interacción con `authTokenProvider`

`AuthNotifier` escucha el token in-memory. Si el token desaparece mientras la sesión sigue marcada como autenticada, el provider resetea estado.

Eso protege consistencia.

#### Responsabilidades del notifier

- login;
- registro turista;
- logout;
- restore por access token;
- restore por refresh token;
- actualización de perfil turista;
- activación de perfil emprendedor.

Es un notifier importante, pero todavía razonablemente enfocado.

### Análisis de `mapProvider`

Archivo:

- `lib/features/map/presentation/providers/map_provider.dart`

`MapState` es interesante porque no guarda solo “una lista de puntos”. Guarda modos de trabajo diferentes:

- `points`: POIs globales canónicos;
- `mapViewPoints`: override temporal de vista;
- `itineraryPoints`: puntos de un itinerario;
- `focusedPoint`: un POI focalizado;
- `selectedPoint`: POI seleccionado en UI;
- `selectedCategoryIds`: filtros activos;
- `center`: centro actual lógico.

La propiedad más reveladora es:

```dart
bool get isGlobalMode => filteredItineraryId == null && focusedPoiId == null;
```

Eso muestra que el mapa no es solo una pantalla. Es una superficie que puede operar en varios modos:

- mapa global;
- mapa de itinerario;
- mapa focalizado;
- mapa con override temporal de búsqueda.

Este diseño evita tener cuatro providers distintos para el mismo mapa, aunque el costo es una estructura de estado más rica.

### Análisis de `chatProvider`

Archivo:

- `lib/features/chat_ai/presentation/providers/chat_provider.dart`

Este es el notifier más complejo del repo.

Hereda de:

```dart
class ChatNotifier extends Notifier<List<MessageEntity>>
```

Eso ya dice algo importante: el estado principal visible es la lista de mensajes. Pero además el notifier guarda muchísimo estado auxiliar privado:

- `_sessionId`
- `_sessionStartDate`
- `_sessionEndDate`
- `_isBusy`
- `_uiState`
- `_progress`
- timers de streaming
- flags de background
- ids de navegación pendiente
- replacement mode

Esto es útil para producto, pero es exactamente la razón por la que el archivo se convirtió en hotspot.

Aun así, tiene una lógica clara:

1. inicia sesión Ara;
2. envía mensajes;
3. procesa respuestas;
4. maneja quick replies;
5. arranca generación por SSE;
6. transforma stream en estado de UI;
7. coordina navegación hacia itinerarios.

En otras palabras: es medio chat engine y medio coordinator de experiencia.

### Análisis de `itineraryProvider`

Archivo:

- `lib/features/itinerary/presentation/providers/itinerary_provider.dart`

Es mucho más simple que `chatProvider`.

Qué hace:

- guarda itinerario actual;
- lo persiste en `SharedPreferences`;
- lo refresca desde backend;
- todavía soporta generación directa por `/itineraries/generate`.

Eso muestra algo interesante de la arquitectura: no todo necesita el mismo nivel de complejidad. Riverpod permite usar la mínima maquinaria necesaria por caso.

### Ejemplo real

Un patrón real repetido en el proyecto es este:

```dart
final categories = ref.watch(categoriesProvider);
final isEntrepreneurCreation = _isEntrepreneurCreation;
```

La pantalla observa datos asíncronos declarativos y al mismo tiempo usa estado local efímero (`_isEntrepreneurCreation`) para detalles de interacción. Esa combinación es muy típica en Flutter bien usado.

### Conclusión

Riverpod en este proyecto no es una moda. Es la columna vertebral del estado.

Permite:

- separar dependencias de UI;
- probar lógica con overrides;
- modelar estado global de forma explícita;
- y mantener un equilibrio razonable entre pragmatismo y estructura.

---

## Capítulo 3: Navegación Declarativa con GoRouter

### Introducción

La navegación en apps medianas deja de ser “abre esta pantalla” y pasa a ser “mantén coherencia entre auth, shell, deep links, rutas protegidas y contextos adaptativos”.

Por eso este proyecto usa GoRouter.

### Desarrollo

#### 1. Qué es navegación declarativa

En navegación imperativa uno suele decir:

- empuja esta pantalla;
- vuelve atrás;
- abre este modal.

En navegación declarativa además importa describir:

- qué rutas existen;
- qué nombres tienen;
- cuáles son públicas;
- cuáles viven bajo shell;
- cuándo redirigir automáticamente.

GoRouter convierte eso en una tabla de rutas central con reglas claras.

#### 2. Por qué GoRouter y no Navigator 1.0

Navigator 1.0 funciona, pero se vuelve más manual y disperso cuando el proyecto crece.

GoRouter aporta:

- rutas nombradas;
- paths legibles;
- `redirect` centralizado;
- soporte simple para `ShellRoute`;
- manejo de parámetros y `extra` más limpio;
- una integración más legible para apps con auth.

Para este frontend eso es ideal, porque la app tiene:

- login/register;
- shell principal;
- rutas fuera del shell;
- detalle de POIs;
- itinerarios;
- chat;
- dashboard emprendedor;
- formularios con distintas entradas.

### Explicar rutas, `ShellRoute`, `redirect`, `extra`

#### `GoRoute`

Define una ruta concreta.

#### `ShellRoute`

Permite envolver varias rutas con una misma estructura visual. Aquí esa estructura es `MistNavigation`.

Eso significa que:

- home,
- chat,
- map,
- itineraries,
- profile

comparten shell de navegación principal.

#### `redirect`

Es la lógica central de protección.

No se delega a cada pantalla decidir si el usuario está autenticado. Se decide en el router.

#### `extra`

Permite pasar información no-path de forma controlada. En este proyecto se usa, por ejemplo, para definir fallback route al abrir mapa focalizado.

### Cómo protegemos rutas con auth

Regla actual del repo:

- si no hay sesión y la ruta no es login/register, se redirige a `/login`;
- si hay sesión y el usuario intenta entrar a login/register, se redirige a `/home`;
- si hay restauración de sesión en progreso con token ya presente, no se fuerza redirect todavía.

Esa tercera regla es sutil y muy importante. Evita flicker y redirecciones prematuras mientras la app todavía está validando una sesión persistida.

### Análisis de `app_router.dart` completo

Archivo:

- `lib/core/router/app_router.dart`

#### Paso 1: imports

El archivo importa páginas de múltiples features. Esto es intencional: el router es uno de los pocos lugares donde es correcto que exista visión transversal del sistema.

#### Paso 2: `_fadeTransitionPage`

```dart
Page<dynamic> _fadeTransitionPage({
  required LocalKey key,
  required Widget child,
})
```

Esta función encapsula una decisión de UX:

- muchas rutas fuera del shell usan fade transition consistente.

Eso evita repetir `CustomTransitionPage` en cada ruta.

#### Paso 3: provider del router

```dart
final appRouterProvider = Provider<GoRouter>((ref) {
```

El router mismo es una dependencia de Riverpod. Esto permite:

- reconstrucción si cambia auth;
- testeo controlado;
- composición limpia con otros providers.

#### Paso 4: `_GoRouterRefreshStream`

```dart
final authRefresh = _GoRouterRefreshStream();
```

Se usa como `refreshListenable` del router. Cuando auth cambia, el router se vuelve a evaluar y puede redirigir.

#### Paso 5: escucha de auth

```dart
ref
  ..onDispose(authRefresh.dispose)
  ..listen<AuthState>(authProvider, (previous, next) => authRefresh.notify());
```

Esto une dos mundos:

- Riverpod sabe cuándo cambia auth;
- GoRouter necesita una señal para reevaluar redirects.

La clase `ChangeNotifier` es el puente.

#### Paso 6: `initialLocation`

```dart
initialLocation: AppRoutes.login,
```

La app siempre arranca conceptualmente en login. Si hay sesión restaurable, el redirect resolverá el destino real.

#### Paso 7: `redirect`

```dart
redirect: (context, state) {
  final authState = ref.read(authProvider);
```

Se usa `read`, no `watch`, porque quien controla reevaluación es `refreshListenable`.

#### Paso 8: distinguir rutas públicas

```dart
final isPublicAuthRoute =
    state.matchedLocation == AppRoutes.login ||
    state.matchedLocation == AppRoutes.register;
```

Login y register son las únicas rutas públicas de auth en esta lógica.

#### Paso 9: sesión en restauración

```dart
final isRestoringSession = authState.isLoading && authState.token != null;
```

Esta condición está muy bien pensada. Significa:

- hay token recuperado,
- la app todavía valida usuario,
- no redirijas todavía.

#### Paso 10: reglas de redirect

```dart
if (isRestoringSession) return null;
if (!isAuthenticated && !isPublicAuthRoute) return AppRoutes.login;
if (isAuthenticated && isPublicAuthRoute) return AppRoutes.home;
return null;
```

Es corto, pero poderoso. Protege casi toda la app con unas pocas reglas claras.

#### Paso 11: rutas directas

Hay rutas no-shell como:

- login
- register
- onboarding
- itinerary detail
- bookmarks
- edit profile
- entrepreneur dashboard
- poi dashboard
- poi posts
- create poi
- my contributions
- edit poi
- poi detail
- focused map

Observa un patrón útil: muchas usan `pageBuilder` con `_fadeTransitionPage` en vez de `builder` directo. Eso centraliza transición.

#### Paso 12: `creationType` en create POI

```dart
final creationType =
    state.uri.queryParameters['creationType'] ?? 'tourist';
```

Esta línea convierte un matiz de producto en contrato de navegación.

La misma pantalla `CreatePoiPage` cambia comportamiento según query param. No se duplican pantallas; se parametriza el flujo.

#### Paso 13: `focusedMap` y `extra`

```dart
final fallbackRouteName = state.extra is String
    ? state.extra! as String
    : AppRouteNames.chat;
```

Aquí `extra` se usa para pasar intención contextual de retorno. Es una forma ligera de navegación contextual sin inflar el path.

#### Paso 14: `ShellRoute`

```dart
ShellRoute(
  builder: (context, state, child) => MistNavigation(child: child),
```

Esta es una de las decisiones arquitectónicas más importantes del frontend.

No se monta la navegación inferior o lateral manualmente en cada pantalla. Se monta una sola vez como shell. Las rutas hijas heredan ese contenedor.

#### Paso 15: rutas dentro del shell

- `/home`
- `/chat`
- `/map`
- `/itineraries`
- `/profile`

Esto coincide con la navegación principal visible para el usuario.

### Ejemplo real

El archivo `app_routes.dart` centraliza strings y nombres:

```dart
class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  ...
}
```

Esto evita literales dispersos y reduce bugs por typos.

### Conclusión

GoRouter en este proyecto no solo navega. También:

- protege auth;
- define shell principal;
- modela variantes de flujo;
- y ayuda a que la app se comporte de forma coherente incluso cuando la sesión se restaura en segundo plano.

---

## Capítulo 4: Comunicación HTTP con Dio

### Introducción

El frontend no conversa con el backend “haciendo fetch suelto”. La comunicación HTTP es una capa arquitectónica completa:

- token;
- refresh automático;
- timeouts;
- headers;
- errores;
- logging;
- retries.

Dio es la herramienta elegida para eso.

### Desarrollo

#### 1. Por qué Dio y no `http`

El package `http` es suficiente para requests simples. Pero este proyecto necesita mucho más:

- interceptors;
- reintento automático;
- modificación centralizada de requests;
- control de opciones por request;
- stream response para SSE;
- mejor modelado de errores.

Dio resuelve todo eso de forma más elegante.

#### 2. Interceptors

Un interceptor es una pieza que se ejecuta alrededor de cada request o response.

En este proyecto sirve para:

- inyectar el `Authorization` header;
- detectar `401`;
- intentar refresh token;
- reintentar la request original si el refresh funciona.

Eso evita repetir lógica de auth en cada repository.

#### 3. Retries y refresh token

El patrón real del repo es:

1. sale request con access token;
2. backend responde `401`;
3. interceptor pregunta si puede refrescar;
4. si hay refresh token, intenta `/auth/refresh`;
5. si obtiene nuevo access token, reejecuta la request original;
6. si no, deja caer el error.

Este patrón es exactamente el tipo de problema donde Dio brilla.

### Cómo manejamos 401 + refresh token automático

Hay dos piezas que colaboran:

- `DioClient`
- `api_provider.dart`

`DioClient` sabe **cómo** reintentar.

`api_provider.dart` sabe **cómo obtener** el nuevo token y evitar múltiples refresh simultáneos.

### Análisis de `dio_client.dart` completo

Archivo:

- `lib/core/network/dio_client.dart`

#### Constructor

```dart
class DioClient {
  final Dio _dio;
  final String? Function()? authTokenReader;
  final Future<String?> Function()? refreshAuthToken;
```

Muy buena decisión: `DioClient` no sabe por sí mismo dónde vive el token. Lo recibe por función.

Eso desacopla infraestructura HTTP del sistema de estado.

#### Configuración base

```dart
_dio
  ..options.baseUrl = ApiConstants.baseUrl
  ..options.connectTimeout = ...
  ..options.receiveTimeout = ...
  ..options.responseType = ResponseType.json;
```

Aquí se fija contrato global:

- base URL;
- timeout de conexión;
- timeout de respuesta;
- formato esperado.

#### Interceptor de request

```dart
onRequest: (options, handler) {
  if (options.extra['skipAuth'] == true) {
    return handler.next(options);
  }
  final token = authTokenReader?.call();
  if (token != null && token.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  return handler.next(options);
},
```

Esto hace que el token viaje automáticamente en casi toda request.

La excepción es explícita: `skipAuth`.

Esa decisión es importante porque evita condicionales repartidos por los repositories. Cuando una request no debe llevar auth, lo declara en `Options.extra`.

#### Interceptor de error

```dart
final shouldTryRefresh =
    error.response?.statusCode == 401 &&
    refreshAuthToken != null &&
    request.extra['skipAuthRefresh'] != true &&
    request.extra['didRefreshRetry'] != true;
```

Esta condición encapsula muchísimo criterio:

- solo si fue `401`;
- solo si existe mecanismo de refresh;
- no refresques si la request marcó que no debe hacerlo;
- no entres en loop refrescando infinitamente.

#### Retry real

```dart
final refreshedToken = await refreshAuthToken!.call();
...
request.extra['didRefreshRetry'] = true;
request.headers['Authorization'] = 'Bearer $refreshedToken';
final response = await _dio.fetch<dynamic>(request);
return handler.resolve(response);
```

Aquí la request original se vuelve a ejecutar con el nuevo token.

Eso da la sensación al resto de la app de que el refresh es casi transparente.

#### Logging en debug

```dart
if (kDebugMode) {
  _dio.interceptors.add(
    LogInterceptor(requestBody: false, responseBody: true),
  );
}
```

Otro detalle pragmático correcto:

- logs ricos en desarrollo;
- sin meter ese costo automáticamente en producción.

#### Métodos wrapper

`get`, `post`, `put`, `patch`, `delete` simplemente envuelven `_dio`.

Esto parece trivial, pero da un punto único de entrada si luego quieres extender comportamiento.

### `api_provider.dart`: la otra mitad del sistema

Archivo:

- `lib/core/network/api_provider.dart`

Aquí hay una decisión muy buena:

```dart
Future<String?>? refreshInFlight;
```

Esto evita tormenta de refresh.

Si varias requests fallan con `401` al mismo tiempo, no se lanzan diez refresh paralelos. Todas comparten el mismo `Future` en vuelo.

Eso es una mejora real de robustez.

La función `_refreshAuthToken`:

- lee refresh token desde storage;
- crea un `Dio` limpio para refrescar;
- llama `/auth/refresh`;
- guarda nuevos tokens;
- limpia tokens si falla.

Usar un `Dio` aparte para refresh también es inteligente: evita loops raros de interceptores sobre sí mismos.

### Ejemplo real

En `AuthRepository.refreshToken(...)` se marca:

```dart
options: Options(extra: {'skipAuthRefresh': true, 'skipAuth': true}),
```

Eso significa:

- no agregues access token;
- no intentes refrescar el refresh request.

Es una protección pequeña pero crítica.

### Conclusión

La capa HTTP del proyecto está bien pensada porque separa responsabilidades:

- DioClient intercepta;
- api provider resuelve refresh;
- repositories traducen endpoints a métodos de dominio frontend.

Eso es más mantenible que meter lógica HTTP avanzada dentro de cada feature.

---

## Capítulo 5: Persistencia Local

### Introducción

Toda app real necesita recordar algo. La pregunta nunca es “si persistimos”, sino **qué persistimos, dónde y con qué riesgos**.

### Desarrollo

#### 1. `SharedPreferences`

`SharedPreferences` es persistencia simple de clave-valor.

Es útil para:

- tokens;
- flags;
- preferencias ligeras;
- último objeto serializable pequeño.

No es una base de datos. No es almacenamiento seguro fuerte. Es un bloc de notas persistente.

#### 2. `SecureStorage`

En apps móviles maduras, tokens sensibles idealmente irían a soluciones tipo secure storage.

Entonces, ¿por qué aquí no?

### Por qué guardamos tokens en `SharedPreferences` y sus limitaciones

Razones pragmáticas del proyecto:

- simplicidad de integración;
- velocidad de desarrollo;
- facilidad de testeo;
- suficiente para etapa de tesis/MVP funcional.

Limitaciones:

- no es almacenamiento endurecido de nivel producción final;
- la exposición local es mayor que en secure storage;
- no debería asumirse como diseño final para una app comercial endurecida.

La decisión correcta aquí no es fingir que es perfecto. Es documentar honestamente que es suficiente para esta etapa y por qué.

### Qué se persiste y qué no

#### Sí se persiste

- access token (`ruta_viva.auth_token`)
- refresh token (`ruta_viva.refresh_token`)
- último itinerario (`ruta_viva.last_itinerary`)

#### No se persiste globalmente como storage base

- estado visual efímero;
- mensajes completos del chat como historial offline;
- estado de overlays;
- selección visual del mapa;
- búsquedas temporales.

Eso distingue bien entre estado de sesión y estado de interacción.

### Análisis de `local_storage_provider.dart`

Archivo:

- `lib/core/storage/local_storage_provider.dart`

#### `sharedPreferencesProvider`

```dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main().');
});
```

Esta línea es excelente desde diseño.

El provider no crea la dependencia. Obliga a que sea inyectada.

Beneficios:

- testabilidad;
- control explícito;
- evita singletons invisibles.

#### Wrappers tipados

```dart
final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage(ref.watch(sharedPreferencesProvider));
});
```

En vez de hacer `prefs.getString(...)` por toda la app, se crean wrappers dedicados:

- `AuthTokenStorage`
- `RefreshTokenStorage`

Eso encapsula claves y reduce duplicación.

#### Métodos de storage

```dart
String? readToken()
Future<void> saveToken(String token)
Future<void> clearToken()
```

Son mínimos, y eso está bien. La abstracción no hace demasiado ni demasiado poco.

### Ejemplo real

`ItineraryNotifier.build()` usa `SharedPreferences` para restaurar el último itinerario serializado. Esto permite que el usuario no pierda inmediatamente el contexto actual si reinicia la app.

### Conclusión

La persistencia local del frontend es pequeña pero estratégica.

No intenta guardar todo. Guarda solo lo necesario para:

- mantener sesión;
- restaurar contexto útil;
- no complicar el sistema con almacenamiento innecesario.

---

## Capítulo 6: Arquitectura por Features

### Introducción

Uno de los errores clásicos en proyectos medianos es ordenar el repo solo por tipo técnico:

- todos los models juntos,
- todos los services juntos,
- todos los widgets juntos,
- todos los controllers juntos.

Eso parece limpio al principio, pero escala mal. Por eso este proyecto usa una organización feature-first.

### Desarrollo

## `core/` vs `features/`

### `core/`

Contiene lo transversal:

- router;
- theme;
- storage;
- red;
- utilidades;
- widgets compartidos;
- constantes;
- errores.

Es la infraestructura común.

### `features/`

Contiene capacidades de negocio del producto:

- `auth`
- `home`
- `map`
- `itinerary`
- `chat_ai`
- `entrepreneur`
- `reviews`
- `bookmarks`
- `onboarding`
- `user_profile`
- etc.

Cada feature intenta concentrar su propia lógica relevante.

### Por qué no usamos MVC o MVVM puro

Porque el frontend real de Flutter rara vez encaja elegantemente en una pureza de libro.

El proyecto mezcla ideas de capas, pero prioriza legibilidad y pragmatismo.

Razones:

- Flutter ya trae una división natural entre UI declarativa y lógica;
- Riverpod resuelve gran parte del rol que en MVVM ocuparía ViewModel;
- los repositories ya encapsulan infraestructura de datos;
- forzar una capa abstracta extra para todo habría agregado ceremonia.

### Cómo se organiza: `data/`, `domain/`, `presentation/`

#### `data/`

- models
- repositories

Aquí vive la conversación con backend y serialización.

#### `domain/`

Se usa más livianamente. No es una domain layer estricta al estilo DDD. Suele contener entidades frontend útiles como `MapPoint`.

#### `presentation/`

- pages
- widgets
- providers/notifiers

Aquí vive la experiencia visual y el estado cercano a UI.

### Análisis de una feature completa: `map/`

La feature `map/` es una gran candidata porque cruza casi todo:

- repository;
- provider;
- models;
- entities;
- página compleja;
- formularios;
- widgets especializados.

#### `data/models/poi_model.dart`

Traduce JSON backend a estructura consumible por frontend.

#### `domain/entities/map_point.dart`

Da una representación más conveniente para el mapa que un POI backend crudo.

#### `data/repositories/poi_repository.dart`

Encapsula endpoints:

- búsqueda cercana;
- búsqueda semántica;
- detalle;
- creación;
- edición;
- delete;
- visitas.

#### `presentation/providers/map_provider.dart`

Mantiene el estado visual-lógico del mapa.

#### `presentation/pages/map_screen.dart`

Convierte ese estado en experiencia visual interactiva.

#### `presentation/pages/create_poi_page.dart`

Es el formulario más importante de la feature.

### Ejemplo real

La separación turista/emprendedor se resuelve así:

- el router recibe `creationType`;
- `CreatePoiPage` adapta validaciones y texto;
- `PoiRepository` elige endpoint;
- los tests validan ambos flujos.

Eso es feature-first bien aplicado: el comportamiento se reparte donde corresponde sin duplicar pantallas completas.

### Conclusión

La arquitectura por features no es solo orden visual. Es una forma de reducir costo cognitivo.

Cuando alguien entra a `features/map`, debería poder encontrar ahí casi toda la historia funcional del mapa.

---

## Capítulo 7: Widgets y Renderizado

### Introducción

Saber Flutter no es solo saber que existe `build()`. Es saber **cuándo un widget debe recordar cosas**, **qué estado merece vivir afuera**, y **qué costo mental tiene cada elección**.

### Desarrollo

## `StatelessWidget`, `StatefulWidget`, `ConsumerWidget`, `ConsumerStatefulWidget`

### `StatelessWidget`

Ideal para componentes presentacionales puros.

### `StatefulWidget`

Ideal cuando hay:

- controladores;
- timers;
- `MapController`;
- selección efímera;
- caches locales;
- animaciones.

### `ConsumerWidget`

Combina presentación con lectura simple de providers sin necesitar estado local mutable propio.

Ejemplo: `RutaVivaApp`, `MistNavigation`.

### `ConsumerStatefulWidget`

Es la combinación más poderosa cuando una pantalla necesita tanto Riverpod como estado local y ciclo de vida.

Ejemplos reales:

- `MapScreen`
- `CreatePoiPage`
- varias pantallas complejas de itinerario.

### Por qué algunos widgets son stateful y otros no

La regla práctica del proyecto es sana:

- si el estado es local y efímero, probablemente `StatefulWidget`;
- si el estado es compartido o de negocio, provider;
- si solo presentas datos, `StatelessWidget` o `ConsumerWidget`.

### Ciclo de vida: `initState`, `didUpdateWidget`, `dispose`

#### `initState`

Se usa para preparar recursos una sola vez.

Ejemplos:

- crear `TextEditingController`;
- crear `MapController`;
- cargar valores iniciales desde provider.

#### `didUpdateWidget`

Se usa cuando cambian props y el estado interno debe reaccionar.

En este repo es muy útil en páginas de detalle de itinerario cuando cambia el itinerario recibido.

#### `dispose`

Se usa para liberar:

- controllers;
- timers;
- notifiers;
- streams.

Ignorar `dispose` en Flutter es como olvidar cerrar archivos o conexiones: no explota de inmediato siempre, pero degrada el sistema.

### Análisis de widgets complejos reales

#### `CreatePoiPage`

Es `ConsumerStatefulWidget` porque necesita:

- controllers de texto;
- `GlobalKey<FormState>`;
- leer providers;
- manejar submit;
- abrir picker de ubicación;
- mantener flags efímeras.

#### `MistNavigation`

Es `ConsumerWidget` porque:

- no necesita memoria mutable propia;
- sí necesita leer provider de mapa;
- calcula visualmente shell según tamaño.

#### `MapScreen`

Es `ConsumerStatefulWidget` porque combina:

- estado local de interacción;
- Riverpod;
- controllers;
- timers;
- caching local;
- effects de ciclo de vida.

### Ejemplo real

Patrón típico del proyecto:

```dart
@override
void dispose() {
  _camera.dispose();
  _markerDensity.dispose();
  _autoRefreshTimer?.cancel();
  _searchController.dispose();
  _mapController.dispose();
  super.dispose();
}
```

Esto es Flutter responsable: si creaste recursos vivos, los limpias.

### Conclusión

Escoger el tipo correcto de widget no es decoración. Es una decisión de arquitectura local.

Buen frontend en Flutter = saber qué vive en el árbol, qué vive en Riverpod y qué vive solo mientras el usuario interactúa.

---

## Capítulo 8: Renderizado de Mapas

### Introducción

El mapa es probablemente la superficie visual más exigente del frontend. No es solo una pantalla con markers. Es un sistema de exploración, búsqueda, filtros, geolocalización, responsive y performance.

### Desarrollo

## `flutter_map`, `TileLayer`, `MarkerLayer`, polylines

El proyecto usa `flutter_map`, que es una librería basada en tiles y ecosistema abierto.

### `FlutterMap`

Es el contenedor principal del mapa.

### `TileLayer`

Define la fuente visual de mosaicos. En este proyecto se usa OpenStreetMap.

### `MarkerLayer`

Pinta marcadores calculados por la lógica del mapa.

### Polylines

Aunque no son el foco dominante del archivo actual, conceptualmente representan recorridos o trazados en mapas. Son útiles cuando un itinerario requiere mostrar ruta visual.

## Por qué `flutter_map` y no Google Maps

Razones plausibles y coherentes con el proyecto:

- menor dependencia de servicios propietarios;
- mejor alineación con stack abierto;
- suficiente para exploración POI y overlays del producto;
- menor complejidad de claves, billing y restricciones;
- más afinidad con datos OSM y geocoding público usados en el backend.

Google Maps podría ofrecer ventajas, pero para esta tesis `flutter_map` es una decisión razonable y consistente.

## Cómo manejamos densidad de markers, clustering y búsquedas

El proyecto no usa un clustering sofisticado de librería como corazón del sistema. En cambio, aplica una estrategia propia de **densidad adaptativa**.

Eso se ve en:

- `_markerDensity`
- `_computeVisibleMarkers(...)`
- `_stableMarkersCache`
- `_markerSignature(...)`

La idea no es mostrar todo siempre. Es mostrar lo suficiente según:

- zoom;
- búsqueda activa;
- selección;
- foco;
- distancia al centro visible.

Esto reduce ruido visual y ayuda al performance.

## Análisis de `map_screen.dart`

Archivo:

- `lib/features/map/presentation/pages/map_screen.dart`

Este es el archivo más complejo del repo por varias razones simultáneas:

1. combina UI muy rica;
2. conversa con provider en tiempo real;
3. maneja mapas y gestures;
4. tiene responsive fuerte;
5. tiene caching y heurísticas de performance;
6. soporta búsqueda, geocoding, filtros y recarga.

### Anatomía conceptual del archivo

#### 1. Estado local principal

- `_mapController`
- `_searchController`
- `_camera`
- `_markerDensity`
- `_autoRefreshTimer`
- `_activeMapSearchQuery`
- `_isResolvingSearch`
- `_pullRefreshOffset`
- `_isPullRefreshing`
- `_stableMarkersCache`

Esto ya explica por qué no podía ser `StatelessWidget`.

#### 2. Control de cámara

```dart
void _updateCamera(LatLng center, double zoom) {
  _camera.value = (center, zoom);
  final nextDensity = _MarkerDensity.fromZoom(zoom);
  if (_markerDensity.value != nextDensity) {
    _markerDensity.value = nextDensity;
  }
}
```

Aquí la cámara no solo sirve para mover el mapa. También determina cuántos marcadores deben verse.

#### 3. Protección contra render inválido

```dart
bool _canBuildMarkerLayer(BuildContext context) {
  ...
  final bounds = camera.visibleBounds;
  return bounds.north.isFinite && ...
}
```

Esto es un ejemplo excelente de ingeniería pragmática.

En vez de asumir que todo está siempre listo, el archivo valida:

- tamaños finitos;
- layout existente;
- bounds válidos.

Eso evita glitches y errores difíciles de rastrear.

#### 4. Inicialización

`initState()`:

- crea controller;
- sincroniza cámara inicial con estado actual del mapa;
- decide si cargar nearby automáticamente.

Esto evita que la pantalla llegue vacía o en modo incoherente.

#### 5. Búsqueda semántica con fallback geocoding

`_searchMap()` hace algo muy didáctico:

1. toma query;
2. intenta `semanticSearch`;
3. si no hay resultados, intenta geocoding;
4. si geocoding encuentra coordenadas, mueve mapa;
5. vuelve a intentar búsqueda semántica alrededor del nuevo centro;
6. si aún no hay puntos, carga nearby de esa nueva zona.

Eso es muy buen diseño UX: no se queda en un “no hubo resultados” demasiado pronto.

#### 6. Pull to refresh de mapa

El mapa no usa un `RefreshIndicator` clásico encima del `FlutterMap`. Implementa una lógica propia con gesto vertical y umbral.

Eso muestra que a veces en Flutter hay que construir comportamiento específico, no solo combinar widgets estándar.

#### 7. Auto refresh por desplazamiento

`_scheduleViewportRefresh(center)` usa debounce y distancia mínima.

La pregunta de diseño aquí es:

> si el usuario se movió mucho en un mapa global, ¿deberíamos refrescar resultados automáticamente?

La respuesta del proyecto es sí, pero con control:

- debounce de 800 ms;
- distancia mínima de 8000 metros;
- no hacerlo si el mapa no está en modo global.

#### 8. Landscape real 60/40

Cuando hay landscape:

- izquierda: mapa `60%`
- derecha: `_MapLandscapePanel` `40%`

Esta es una mejora importante respecto a apps que solo “estiran” la variante mobile.

#### 9. Cards de resultados proporcionales

Las search cards usan ancho proporcional al viewport:

- 45% del ancho,
- acotado entre 160 y 220.

Es un detalle pequeño, pero mejora muchísimo robustez visual.

### Qué enseña este archivo

`map_screen.dart` enseña varias lecciones profundas:

- el estado local sigue siendo necesario aunque exista Riverpod;
- performance visual se trabaja con heurísticas, no solo con teoría;
- responsive serio no se resuelve con un único `if (isMobile)`;
- la UI puede ser a la vez declarativa y muy sofisticada.

### Ejemplo real

```dart
if (stateAfterSearch.visiblePoints.isEmpty) {
  final locations = await ref
      .read(geocodingRepositoryProvider)
      .search(...);
```

Ese fallback es una gran muestra de UX robusta: si la semántica no encuentra algo, la app intenta entender el lugar geográficamente.

### Conclusión

El mapa es el mejor laboratorio del proyecto para aprender Flutter serio.

Si entiendes bien `map_screen.dart`, entiendes:

- controladores,
- performance,
- Riverpod + estado local,
- responsive complejo,
- composición visual,
- y heurísticas reales de producto.

---

## Capítulo 9: Flujo Conversacional con SSE

### Introducción

El módulo Ara convierte el frontend en algo más que un cliente CRUD. Aquí la app sostiene una conversación, procesa eventos progresivos y coordina una experiencia de generación asistida.

### Desarrollo

## Qué son los Server-Sent Events

SSE es un mecanismo donde el servidor mantiene abierta una respuesta y va enviando eventos de texto secuenciales.

No es polling y no es WebSocket.

Se parece más a decir:

> mantén esta puerta abierta y avísame a medida que tengas novedades.

Para Ara eso calza perfecto porque la generación de itinerario tiene fases.

## Por qué SSE y no polling o WebSockets

### SSE sobre polling

Polling sería algo como:

- pregunta si ya terminó,
- espera,
- vuelve a preguntar,
- espera,
- vuelve a preguntar.

Eso introduce:

- más latencia percibida;
- más ruido de red;
- más complejidad de sincronización.

### SSE sobre WebSockets

WebSockets son bidireccionales y poderosos, pero también más complejos de operar. Aquí el frontend no necesita canal bidireccional permanente sofisticado para generación final. Necesita recibir eventos progresivos de una operación que el servidor ya está ejecutando.

SSE es más simple y suficiente.

## Cómo parseamos `status`, `warning`, `result`, `error`

Archivo clave:

- `lib/features/chat_ai/data/repositories/ara_repository.dart`

El método `generateItineraryStream(...)`:

1. hace POST al endpoint de stream;
2. pide `ResponseType.stream`;
3. consume líneas;
4. agrupa por evento SSE;
5. decodifica JSON;
6. mapea cada tipo a un modelo de evento.

Fragmento real:

```dart
return switch (currentEvent) {
  'status' => AraGenerationStatusEvent.fromJson(json),
  'result' => AraGenerationResultEvent(
    AraGenerateItineraryResponse.fromJson(json),
  ),
  'warning' => AraGenerationWarningEvent.fromJson(json),
  'error' => AraGenerationErrorEvent(...),
  _ => null,
};
```

Eso convierte protocolo textual en tipos fuertes del frontend.

## Análisis de `chat_provider.dart`

Archivo:

- `lib/features/chat_ai/presentation/providers/chat_provider.dart`

Este notifier es complejo porque combina tres capas:

1. estado visible del chat;
2. coordinación de sesión Ara;
3. side effects de generación y navegación.

### Estado principal

El estado expuesto es `List<MessageEntity>`.

Eso tiene una virtud: la UI piensa en mensajes, no en protocolo backend crudo.

### Estado privado adicional

El notifier guarda muchos campos privados porque el chat necesita más que una lista:

- sesión actual;
- rango de fechas;
- estado de busy;
- estado de UI;
- progreso del viaje;
- progreso del streaming;
- navegación pendiente;
- background mode;
- replacement mode.

### `AraChatUiState`

```dart
enum AraChatUiState {
  idle,
  sendingMessage,
  araTyping,
  generatingItinerary,
  pollingGeneration,
  error,
}
```

Aunque hoy el flujo principal es SSE, el enum todavía refleja el hecho histórico y arquitectónico de que existieron o convivieron otras fases.

### Inicio de sesión desde Home

`startSessionFromHome(...)`:

- toma mensaje inicial;
- construye rango de fechas;
- agrega mensaje de usuario;
- muestra thinking local;
- llama `createSession`;
- reemplaza thinking por respuesta real.

Ese patrón ayuda a UX: el usuario siente reacción inmediata antes de que llegue backend.

### Modo replacement

El notifier detecta si una conversación está reemplazando una parada del itinerario. Eso muestra algo importante:

- el chat no es un módulo aislado;
- es un coordinador de flujos del producto.

### Stream progress

Hay timers para:

- marcar espera del primer evento;
- manejar inicio diferido;
- soportar background mode dentro de la app.

Eso es sofisticado, pero realista. Un flujo de IA no siempre responde instantáneamente.

### Riesgo arquitectónico

La contracara es clara: el archivo creció mucho. Hoy es un god notifier grande.

Eso no invalida la solución, pero sí marca deuda técnica futura.

### Ejemplo real

La factory:

```dart
factory TripProgressData.fromAraProgress(AraProgressModel? p) {
```

muestra otra decisión sana: la UI no depende directamente del modelo backend crudo. Lo adapta a una estructura de presentación propia.

### Conclusión

El módulo SSE del frontend enseña tres cosas muy valiosas:

- cómo integrar streaming en Flutter;
- cómo traducir protocolo a tipos fuertes;
- cómo una feature de IA obliga a coordinar UI, estado y navegación al mismo tiempo.

---

## Capítulo 10: Responsive Design y Accesibilidad

### Introducción

Este frontend no nació siendo plenamente responsive. Evolucionó hacia eso. Y esa evolución es didácticamente valiosa, porque muestra cómo una app real pasa de “funciona en mi celular” a “tolera contextos variados sin romperse”.

### Desarrollo

## `MediaQuery`, `LayoutBuilder`, `OrientationBuilder`

### `MediaQuery`

Sirve para leer:

- tamaño de pantalla;
- orientación;
- insets del teclado;
- padding seguro;
- escalado de texto.

### `LayoutBuilder`

Sirve para decidir comportamiento según constraints reales del widget, no solo del dispositivo global.

Muy útil cuando una card puede estar en una columna estrecha dentro de una pantalla grande.

### `OrientationBuilder`

Permite reaccionar a portrait/landscape, especialmente útil en itinerarios.

## Por qué no usamos un design system completo

Razones pragmáticas:

- la app es una tesis aplicada, no una plataforma de componentes enterprise;
- el equipo priorizó entrega funcional y evolución incremental;
- muchas decisiones responsive se descubrieron al endurecer pantallas reales.

Eso tiene costo: menos uniformidad sistémica. Pero también tiene una ventaja: mucha adaptación aterrizada a problemas concretos.

## Cómo evolucionó: de “funciona en mi celular” a “funciona en todo”

### Lote A

Hardening base:

- clamp de text scale;
- más `SafeArea`;
- mejor keyboard handling;
- mejor compact height;
- mejores touch targets.

### Lote B

Layouts grandes:

- `NavigationRail`;
- master-detail de itinerarios;
- landscape real en mapa;
- grids en entrepreneur.

### Lote C

Pulido fino:

- `maxLines` y ellipsis;
- scrollbars;
- hover states;
- bounds decorativos y clipping más robusto.

## Análisis de `AppResponsive`

Archivo:

- `lib/core/utils/responsive.dart`

`AppResponsive` define dos breakpoints base:

```dart
static const double mobile = 600;
static const double tablet = 900;
```

Eso produce tres zonas:

- `< 600`: mobile
- `600-899`: tablet
- `>= 900`: desktop

### Método `value<T>`

```dart
static T value<T>(BuildContext context, {
  required T mobile,
  T? tablet,
  required T desktop,
})
```

Es un helper muy útil porque evita repetir `if`s por todas partes.

### Padding y ancho máximo

`pagePadding`, `compactPagePadding` y `maxContentWidth` expresan una filosofía clara:

- en mobile se ocupa casi todo el ancho;
- en tablet/desktop se centra contenido y se limita lectura.

Eso mejora UX y legibilidad.

### Accesibilidad

`shouldReduceMotion` muestra sensibilidad a preferencias del sistema.

### Ejemplo real

`MistNavigation` usa `AppResponsive.isTablet(context)` y `AppResponsive.isDesktop(context)` para decidir bottom nav o rail.

### Conclusión

El responsive del proyecto es pragmático, incremental y ya bastante maduro. No nace de un design system súper abstracto; nace de resolver pantallas reales hasta que dejaron de romperse.

---

## Capítulo 11: Formularios y Validación

### Introducción

Un formulario no es solo una colección de inputs. Es un contrato entre:

- usuario,
- frontend,
- backend,
- y reglas del negocio.

`CreatePoiPage` es el mejor caso de estudio para esto.

### Desarrollo

## `TextFormField`, validators, `FormKey`

### `GlobalKey<FormState>`

Permite validar el formulario completo de forma coordinada.

### `TextEditingController`

Permite:

- leer valores;
- inicializarlos;
- modificarlos programáticamente;
- sincronizar con otras interacciones.

### Validators

Los validators hacen validación local antes de golpear backend. Eso ahorra viajes innecesarios y mejora UX.

## Cómo validamos en frontend y en backend

Regla sana del proyecto:

- frontend valida formato y consistencia inmediata;
- backend sigue siendo autoridad final.

Ejemplos:

- lat/lon deben ser numéricos;
- categoría no puede estar vacía;
- teléfono y email públicos son obligatorios para flujo emprendedor;
- backend igualmente valida payload final.

## UX de errores: inline vs banner vs snackbar

### Inline

Útil para errores pegados al input.

### Banner

Útil para errores del formulario completo o de submit.

### Snackbar

Útil para feedback transitorio de éxito o eventos no estructurales.

El proyecto usa los tres según contexto.

## Análisis de `CreatePoiPage`

Archivo:

- `lib/features/map/presentation/pages/create_poi_page.dart`

### Por qué es `ConsumerStatefulWidget`

Porque necesita:

- controllers;
- `FormKey`;
- estado efímero de submit;
- provider de categorías;
- provider de mapa;
- apertura de picker de ubicación.

### Inicialización con centro del mapa

```dart
final center = ref.read(mapProvider).center;
```

Esto conecta el formulario con contexto espacial real del usuario.

### Decisión `creationType`

```dart
bool get _isEntrepreneurCreation => widget.creationType == 'entrepreneur';
```

Con una sola pantalla se resuelven dos productos:

- aporte turista;
- alta emprendedor.

### Validación diferencial

- turista puede dejar contacto vacío;
- emprendedor debe publicar contacto útil.

Esto está testeado explícitamente.

### Submit

`_submit()` valida en capas:

1. `FormState.validate()`
2. categorías seleccionadas
3. parseo de coordenadas
4. llamada a repository
5. refresh de mapa
6. invalidación de providers relacionados
7. feedback y navegación

Esto es muy buen flujo de formulario real.

### Ejemplo real de feedback

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Lugar creado correctamente.')),
);
```

Feedback breve para éxito.

### Conclusión

`CreatePoiPage` muestra cómo un formulario bien hecho combina:

- validación local;
- dependencia de estado global;
- UX clara;
- contratos backend;
- y navegación final coherente.

---

## Capítulo 12: Testing en Flutter

### Introducción

Testear frontend no es “probar que existe un botón”. Es validar comportamiento, contratos y decisiones de arquitectura. En este repo el testing está bastante orientado a comportamiento real.

### Desarrollo

## Widget tests, unit tests, mocks

### Unit tests

Sirven para:

- modelos;
- repositories;
- helpers;
- lógica acotada.

### Widget tests

Sirven para:

- comprobar renderizado;
- interacción;
- ramas visuales;
- integración UI + provider.

### Mocks/fakes

Se usan para simular repositories o dependencias sin backend real.

## Por qué testeamos X y no Y

Se prioriza mucho:

- contratos backend importantes;
- auth;
- navegación;
- responsive crítico;
- formularios de negocio;
- drag & drop de itinerarios;
- parsing SSE y comportamiento del chat.

Se cubre menos todavía:

- golden tests;
- screenshots multi-device;
- integración visual completa de pantallas muy pesadas.

Esa priorización es razonable: primero se aseguran flujos delicados y contratos frágiles.

## Cómo manejamos provider overrides en tests

Esta es una de las grandes fortalezas del stack.

Ejemplo real:

```dart
final container = ProviderContainer(
  overrides: [
    sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
  ],
);
```

Esto permite aislar lógica con gran precisión.

En widget tests:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      categoriesProvider.overrideWith((ref) async => _categories),
      poiRepositoryProvider.overrideWith((ref) => repo),
    ],
    child: MaterialApp.router(routerConfig: router),
  ),
);
```

La UI cree estar en entorno real, pero todo está controlado.

## Análisis de tests reales del proyecto

### `auth_provider_test.dart`

Valida:

- autenticación exitosa;
- errores de login;
- persistencia de tokens;
- limpieza en logout.

Aprendizaje clave: el provider se prueba como sistema, no solo como clase aislada.

### `mist_navigation_test.dart`

Valida:

- bottom nav en mobile;
- rail en tablet;
- rail extendido > 800 px;
- hover theme en desktop.

Esto es excelente porque testea decisiones responsive reales.

### `create_poi_page_test.dart`

Valida:

- diferencia turista vs emprendedor;
- endpoint correcto;
- validación de teléfono;
- validación de email;
- parseo de coordenadas.

Es un ejemplo muy bueno de test funcional de formulario.

### Conclusión

El testing del repo no intenta demostrar perfección. Intenta asegurar que lo más delicado del producto siga siendo verdad cuando el código cambia.

Eso es exactamente lo que una buena suite debe hacer.

---

## Capítulo 13: Integración Backend-Frontend

### Introducción

Un frontend integrado no vive de “requests sueltos”. Vive de contratos. Si el backend cambia y el frontend no se entera, la app se rompe. Si el frontend serializa mal, la app se rompe. Si el DTO no refleja la realidad del backend, la app se rompe silenciosamente.

### Desarrollo

## Contratos, serialización y DTOs

En este proyecto los modelos de `data/models/` funcionan como DTOs frontend.

Ejemplos:

- `UserModel`
- `TokenModel`
- `PoiModel`
- `ItineraryModel`
- `AraSessionModel`

Estos modelos hacen varias cosas:

- parsean JSON;
- limpian o normalizan campos;
- exponen getters útiles para presentación;
- separan contrato backend de uso visual.

## Cómo mantenemos sincronizado con backend

Se hace por varias capas:

1. repositories con endpoints explícitos;
2. modelos que reflejan JSON real;
3. tests de serialización y contrato;
4. documentación viva (`documentation.md` y este `estudio.md`).

## Qué pasa cuando backend cambia

Idealmente el flujo correcto es:

1. cambia contrato backend;
2. fallan tests o deja de compilar parseo;
3. se actualizan models/repositories;
4. se ajustan providers o widgets si cambió semántica.

### Análisis de modelos y repositories

#### `AuthRepository`

Traduce endpoints de auth a métodos semánticos:

- `login`
- `refreshToken`
- `logout`
- `registerTourist`
- `getMe`
- `updateTouristProfile`
- `patchCurrentUser`
- `activateEntrepreneurProfile`

Eso evita que la UI piense en URLs.

#### `PoiRepository`

Es especialmente interesante porque además codifica decisiones de producto:

```dart
static String _createPoiEndpoint(String creationType) {
  return switch (creationType) {
    'entrepreneur' => '/pois/entrepreneur/',
    _ => '/pois/tourist/',
  };
}
```

La ruta se vuelve parte del contrato de negocio.

#### `AraRepository`

Convierte protocolo conversacional y stream en una API Dart usable.

#### `ItineraryRepository`

Encapsula mutaciones ricas:

- generate;
- reorder;
- reorder with times;
- reschedule;
- visits;
- weather.

#### `PoiModel`

Hace un trabajo valioso transformando backend a `MapPoint` consumible por UI de mapa.

#### `ItineraryModel`

Normaliza fechas y define semántica útil como `isEditable`.

#### `AraSessionModel`

Es probablemente el modelo más complejo, porque backend de chat entrega una mezcla de:

- conversación,
- quick replies,
- centros de búsqueda,
- candidatos POI,
- progreso,
- metadata de turno.

### Ejemplo real

`AraCandidatePoiModel.fromJson(...)` busca múltiples claves posibles (`id`, `poi_id`, `uuid`; `name`, `title`, `label`).

Eso revela una actitud práctica frente a contratos IA/backend: el frontend se vuelve algo tolerante a variaciones razonables del payload.

### Conclusión

La integración frontend-backend del proyecto está bastante madura porque no depende solo de “pegarle a endpoints”. Tiene una capa intermedia clara de repositories y models que protege al resto de la app.

---

## Capítulo 14: Decisiones de Arquitectura del Proyecto

### Introducción

Toda arquitectura es una colección de renuncias. Elegir una herramienta es también decidir qué complejidades aceptas y cuáles evitas.

### Desarrollo

## Por qué Flutter sobre otras tecnologías

Porque ofrece:

- control visual fino;
- muy buena experiencia para UI compleja;
- consistencia multiplataforma;
- buena combinación de productividad y performance.

## Por qué Riverpod sobre Bloc/MobX/Provider

Porque ofrece:

- menos ceremonia que Bloc;
- más explicitud que MobX;
- mejor desacoplamiento que Provider clásico;
- overrides de test muy potentes.

## Por qué GoRouter sobre Navigator

Porque el proyecto necesita:

- rutas declarativas;
- redirect central;
- shell principal;
- named routes;
- parámetros y `extra` claros.

## Por qué Dio sobre `http`

Porque el proyecto necesita:

- interceptors;
- refresh token automático;
- soporte stream;
- control fino por request;
- mejor ergonomía de error.

## Por qué feature-first sobre layer-first

Porque reduce costo cognitivo y escala mejor en producto mediano.

## Por qué `Stateful` vs `Stateless` en cada caso

- `Stateful` cuando hay controladores, timers, memoria efímera o lifecycle;
- `Stateless` cuando solo presentas;
- `ConsumerWidget` cuando observas providers sin estado propio;
- `ConsumerStatefulWidget` cuando necesitas ambos mundos.

## Por qué sin domain layer estricta

Porque el proyecto prioriza pragmatismo.

Sí existe `domain/` donde aporta valor, pero no se fuerza una capa abstracta pesada entre todo. Eso reduce ceremonia y acelera desarrollo.

### Conclusión

La arquitectura de este frontend no busca pureza ideológica. Busca equilibrio entre:

- claridad,
- velocidad,
- testabilidad,
- y suficiencia técnica para una tesis compleja.

---

## Apéndice A: Mapa de Archivos

### `lib/main.dart`
- Qué hace: arranca la app, inyecta `SharedPreferences`, aplica tema, router y wrappers globales.
- Por qué existe: es el punto de composición raíz.
- Decisiones: provider override, text scale clamp, overlay global.
- Relación: depende de router, theme, storage y listeners globales.

### `lib/core/router/app_router.dart`
- Qué hace: define navegación completa.
- Por qué existe: centraliza rutas, shell y redirects.
- Decisiones: `ShellRoute`, fade transitions, protección auth.
- Relación: depende de authProvider y casi todas las páginas principales.

### `lib/core/router/app_routes.dart`
- Qué hace: concentra paths y route names.
- Por qué existe: evitar strings dispersos.
- Decisiones: nombres estables para navegación segura.
- Relación: lo usa todo el sistema de navegación.

### `lib/core/network/dio_client.dart`
- Qué hace: wrapper HTTP con interceptors.
- Por qué existe: centralizar token y retry.
- Decisiones: refresh automático y logging debug.
- Relación: lo consumen repositories vía `apiClientProvider`.

### `lib/core/network/api_provider.dart`
- Qué hace: crea `DioClient` y resuelve refresh token.
- Por qué existe: componer HTTP con Riverpod.
- Decisiones: deduplicar refresh en vuelo.
- Relación: depende de token provider y storage.

### `lib/core/network/auth_token_provider.dart`
- Qué hace: token in-memory.
- Por qué existe: desacoplar token activo de storage.
- Decisiones: notifier mínimo.
- Relación: leído por `DioClient` y `AuthNotifier`.

### `lib/core/storage/local_storage_provider.dart`
- Qué hace: expone `SharedPreferences` y wrappers de token.
- Por qué existe: persistencia simple e inyectable.
- Decisiones: override obligatorio en `main()`.
- Relación: auth e itinerary lo usan directamente.

### `lib/core/utils/responsive.dart`
- Qué hace: breakpoints y helpers responsive.
- Por qué existe: evitar lógica duplicada de layout.
- Decisiones: mobile < 600, tablet < 900.
- Relación: usado transversalmente por widgets y páginas.

### `lib/features/auth/presentation/providers/auth_provider.dart`
- Qué hace: sesión, login, logout, restore, refresh.
- Por qué existe: auth global.
- Decisiones: autenticación válida = token + user.
- Relación: router, perfil y features protegidas dependen de él.

### `lib/features/auth/data/repositories/auth_repository.dart`
- Qué hace: traduce endpoints de auth.
- Por qué existe: aislar HTTP de UI.
- Decisiones: `Options.extra` para refresh/login.
- Relación: consumido por `AuthNotifier`.

### `lib/features/map/presentation/providers/map_provider.dart`
- Qué hace: maneja modos del mapa.
- Por qué existe: estado global/focalizado/itinerario.
- Decisiones: múltiples listas según modo.
- Relación: home, map screen, itinerary y POI creation.

### `lib/features/map/presentation/pages/map_screen.dart`
- Qué hace: renderiza experiencia principal del mapa.
- Por qué existe: exploración geográfica y semántica.
- Decisiones: densidad de markers, layout 60/40, auto refresh.
- Relación: depende de mapProvider, geocoding y categories.

### `lib/features/map/presentation/pages/create_poi_page.dart`
- Qué hace: formulario para crear POIs.
- Por qué existe: captura aportes turista y emprendedor.
- Decisiones: `creationType`, validación diferencial.
- Relación: router, poiRepository, categoriesProvider, mapProvider.

### `lib/features/map/data/repositories/poi_repository.dart`
- Qué hace: CRUD y búsquedas de POIs.
- Por qué existe: encapsular contratos del mapa.
- Decisiones: endpoint distinto por tipo de creación.
- Relación: mapProvider, formularios, contributions y entrepreneur.

### `lib/features/map/data/models/poi_model.dart`
- Qué hace: parsea JSON de POI y lo convierte a `MapPoint`.
- Por qué existe: separar contrato backend de uso UI.
- Decisiones: resolución de media flexible.
- Relación: repository y mapa.

### `lib/features/chat_ai/presentation/providers/chat_provider.dart`
- Qué hace: lógica del chat con Ara y streaming.
- Por qué existe: coordinar conversación e itinerarios.
- Decisiones: notifier grande con mucho estado privado.
- Relación: itinerary, map, araRepository, listener global.

### `lib/features/chat_ai/data/repositories/ara_repository.dart`
- Qué hace: sesiones, mensajes y SSE.
- Por qué existe: encapsular protocolo Ara.
- Decisiones: parseo fuerte de eventos.
- Relación: consumido por chatProvider.

### `lib/features/chat_ai/data/models/ara_session_model.dart`
- Qué hace: modela respuestas complejas de Ara.
- Por qué existe: traducir IA/backend a Dart usable.
- Decisiones: tolerancia a payloads variados.
- Relación: araRepository y chatProvider.

### `lib/features/itinerary/presentation/providers/itinerary_provider.dart`
- Qué hace: guarda itinerario actual y lo persiste.
- Por qué existe: contexto rápido de itinerario.
- Decisiones: persistencia simple JSON en prefs.
- Relación: chat, detail pages y storage.

### `lib/features/itinerary/presentation/providers/itinerary_detail_notifier.dart`
- Qué hace: controller de mutaciones y lógica del detalle.
- Por qué existe: sacar lógica pesada de la página.
- Decisiones: state + controller local por pantalla.
- Relación: `ItineraryDetailPage` y repository.

### `lib/features/itinerary/presentation/pages/itinerary_detail_page.dart`
- Qué hace: muestra y edita detalle de itinerario.
- Por qué existe: superficie principal de consumo de itinerarios.
- Decisiones: orientation builder, drawer inter-día, controller extraído.
- Relación: itinerary provider, chat provider, map.

### `lib/features/itinerary/presentation/pages/itinerary_master_detail_page.dart`
- Qué hace: entrada adaptativa a historial y detalle.
- Por qué existe: master-detail real en tablet/desktop.
- Decisiones: mobile portrait distinto del resto.
- Relación: itinerary history + itinerary detail.

### `lib/features/home/presentation/widgets/mist_navigation.dart`
- Qué hace: shell de navegación principal.
- Por qué existe: unificar bottom nav y rail.
- Decisiones: rail extendido sobre 800 px, hover color.
- Relación: ShellRoute y mapProvider.

### `lib/features/entrepreneur/presentation/pages/entrepreneur_dashboard_page.dart`
- Qué hace: dashboard general emprendedor.
- Por qué existe: modo negocio del producto.
- Decisiones: grid responsive, panel de activación RUT.
- Relación: authProvider, entrepreneur repo, poi repo.

---

## Apéndice B: Flujos de Usuario Detallados

### 1. Login completo

1. Usuario escribe email y password en UI.
2. Pantalla llama `authProvider.notifier.login(...)`.
3. `AuthNotifier` pone `isLoading`.
4. `AuthRepository.login(...)` pega a `/auth/login`.
5. `TokenModel` parsea respuesta.
6. access token se guarda in-memory y en `SharedPreferences`.
7. refresh token se guarda en `SharedPreferences`.
8. `AuthRepository.getMe()` trae usuario.
9. `AuthState` queda autenticado.
10. router se refresca.
11. redirect saca al usuario de `/login` hacia `/home`.

### 2. Crear POI

1. Usuario abre `CreatePoiPage`.
2. Router pasa `creationType`.
3. Pantalla inicializa coordenadas desde `mapProvider.center`.
4. Usuario completa nombre, descripción, categorías y ubicación.
5. Si es emprendedor, también contacto público.
6. `FormState.validate()` corre validators.
7. `_submit()` chequea categorías y parseo lat/lon.
8. `PoiRepository.createPoi(...)` elige endpoint correcto.
9. Backend responde con POI creado.
10. `mapProvider.loadNearby(...)` refresca contexto geográfico.
11. Se invalidan `myPoisProvider` y `entrepreneurPoisProvider`.
12. Se muestra snackbar de éxito.
13. Navega a detalle del POI creado.

### 3. Generar itinerario

1. Usuario conversa en chat.
2. `chatProvider` inicia o usa sesión Ara.
3. UI muestra mensajes y thinking local.
4. `AraRepository` envía mensaje o crea sesión.
5. Si el flujo ya está listo, se dispara `generateItineraryStream(...)`.
6. El stream emite `status`, `warning`, `result` o `error`.
7. `chatProvider` transforma eventos a estado visual.
8. Al recibir `result`, queda itinerario listo.
9. El listener global puede notificar incluso fuera del chat.
10. Usuario navega al detalle del itinerario.

### 4. Reordenar pasos de itinerario

1. Usuario mantiene presionada una parada.
2. Aparece `LongPressDraggable` con `DragFlyingProxy`.
3. Si arrastra a otro día, aparece `InterDayDragDrawer`.
4. `ItineraryDetailController` recalcula posición y payload.
5. Se llama endpoint de reorder con `day_index` y `position`.
6. Si backend confirma, estado queda persistido.
7. Si falla, se muestra feedback y se puede revertir.
8. La UI mantiene coherencia visual durante el proceso.

---

## Apéndice C: Futuras Mejoras

### Qué falta

- golden tests multi-breakpoint;
- refactor mayor de `chat_provider.dart`;
- seguir extrayendo `map_screen.dart`;
- revisar accesibilidad de teclado/focus para desktop/web;
- endurecer storage de tokens si el proyecto evoluciona a producto más formal.

### Qué podría mejorarse

- coordinadores más explícitos entre chat, itinerarios y mapa;
- logging estructurado en vez de `debugPrint` disperso;
- domain layer un poco más clara en partes críticas si el tamaño sigue creciendo;
- screenshot testing de pantallas complejas.

### Roadmap sugerido

#### Corto plazo

- tests unitarios para `ItineraryDetailController`;
- limpieza de archivos residuales;
- más cobertura landscape/desktop.

#### Mediano plazo

- dividir `chatProvider` por responsabilidades;
- extraer paneles y lógica del mapa;
- endurecer rutas y coordinadores cross-feature.

#### Largo plazo

- estrategia de observabilidad frontend;
- secure storage;
- golden suite madura;
- design system más sistemático si el producto sigue creciendo.

---

## Cierre general

Si tuvieras que resumir este frontend en una sola idea, sería esta:

> es una aplicación Flutter pragmática, con buenas decisiones de arquitectura, algunos hotspots grandes, y un grado de madurez suficiente como para estudiar frontend moderno en un caso real, no de juguete.

Las grandes lecciones que deja este repo son:

- Flutter no es solo UI bonita; es arquitectura visual y de estado.
- Riverpod vale mucho cuando quieres testabilidad y explicitud.
- GoRouter simplifica muchísimo una app protegida por auth.
- Dio resuelve con elegancia problemas reales de token y retry.
- Feature-first reduce ruido mental.
- El responsive serio se construye con iteraciones, no con slogans.
- Integrar IA en frontend obliga a pensar streams, coordinación y UX de espera.

Si después de leer este archivo puedes abrir:

- `main.dart`,
- `app_router.dart`,
- `dio_client.dart`,
- `auth_provider.dart`,
- `map_provider.dart`,
- `chat_provider.dart`,
- `map_screen.dart`,
- `create_poi_page.dart`,

y explicar por qué están hechos así, entonces este libro cumplió su propósito.
