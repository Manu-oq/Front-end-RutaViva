import 'package:flutter/material.dart';

/// Visual descriptor (icon + color) used to render a POI pin on the map.
///
/// Decoupled from any specific category enum: the lookup is done by the
/// numeric category id coming from the backend via [categoryStyleFor].
class CategoryStyle {
  final IconData icon;
  final Color color;

  const CategoryStyle({required this.icon, required this.color});
}

/// Fallback used when the category id is `null`, the POI has no categories,
/// or the id is not present in the local mapping (e.g. a new backend id
/// the client hasn't been updated to know about yet).
const CategoryStyle _fallbackStyle = CategoryStyle(
  icon: Icons.location_on,
  color: Colors.grey,
);

/// Resolves the visual [CategoryStyle] for a category [id], preserving the
/// exact icons and colors historically rendered by `custom_map_marker.dart`.
///
/// Theme-aware colors (secondary, primary, tertiary) are read from the
/// provided [scheme] so the helper can stay pure (no `BuildContext`) while
/// still adapting to the active theme.
///
/// IDs map to the seeded categories on the backend:
/// - 1 → Naturaleza
/// - 2 → Gastronomía
/// - 3 → Turismo
/// - 4 → Alojamiento
/// - 5 → Cultura
/// - 6 → Trekking/Senderismo
/// - 7 → Lagos/Ríos/Playas
/// - 8 → Montañas/Volcanes/Miradores
/// - 9 → Termas/Bienestar
/// - 10 → Parques/Reservas
/// - 11 → Museos/Patrimonio
/// - 12 → Aventura/Deportes
/// - 13 → Servicios turísticos/Información
/// - 14 → Transporte/Accesos
/// - 15 → Artesanía/Compras locales
///
/// Any other id (or `null`) returns the fallback style.
CategoryStyle categoryStyleFor(int? id, ColorScheme scheme) {
  switch (id) {
    case 1:
      // Naturaleza — preserves the literal `Colors.green.shade700` used
      // historically (not theme-derived) for visual parity.
      return const CategoryStyle(icon: Icons.park, color: Color(0xFF388E3C));
    case 2:
      return CategoryStyle(icon: Icons.restaurant, color: scheme.secondary);
    case 3:
      return CategoryStyle(icon: Icons.explore, color: scheme.primary);
    case 4:
      return CategoryStyle(icon: Icons.hotel, color: scheme.tertiary);
    case 5:
      return CategoryStyle(icon: Icons.museum, color: scheme.primary);
    case 6:
      return const CategoryStyle(
        icon: Icons.hiking_rounded,
        color: Color(0xFF2E7D32),
      );
    case 7:
      return const CategoryStyle(
        icon: Icons.water_rounded,
        color: Color(0xFF0277BD),
      );
    case 8:
      return const CategoryStyle(
        icon: Icons.terrain_rounded,
        color: Color(0xFF6D4C41),
      );
    case 9:
      return const CategoryStyle(
        icon: Icons.spa_rounded,
        color: Color(0xFF00897B),
      );
    case 10:
      return const CategoryStyle(
        icon: Icons.forest_rounded,
        color: Color(0xFF1B5E20),
      );
    case 11:
      return const CategoryStyle(
        icon: Icons.account_balance_rounded,
        color: Color(0xFF5E35B1),
      );
    case 12:
      return const CategoryStyle(
        icon: Icons.kayaking_rounded,
        color: Color(0xFFE65100),
      );
    case 13:
      return const CategoryStyle(
        icon: Icons.info_outline_rounded,
        color: Color(0xFF455A64),
      );
    case 14:
      return const CategoryStyle(
        icon: Icons.directions_bus_rounded,
        color: Color(0xFF546E7A),
      );
    case 15:
      return const CategoryStyle(
        icon: Icons.storefront_rounded,
        color: Color(0xFFAD1457),
      );
    default:
      return _fallbackStyle;
  }
}
