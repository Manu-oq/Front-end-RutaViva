import 'package:flutter/material.dart';

class TermsAcceptanceCard extends StatelessWidget {
  final bool accepted;
  final bool hasError;
  final bool enabled;
  final VoidCallback onOpenTerms;

  const TermsAcceptanceCard({
    super.key,
    required this.accepted,
    required this.hasError,
    required this.enabled,
    required this.onOpenTerms,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: hasError ? 0.45 : 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            accepted ? Icons.verified_rounded : Icons.article_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accepted
                      ? 'Términos y condiciones aceptados'
                      : 'Debes leer y aceptar los términos y condiciones para crear tu cuenta.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasError ? theme.colorScheme.error : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Presiona “Crear cuenta” o “Leer términos” para revisarlos y aceptar.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: enabled ? onOpenTerms : null,
            child: Text(accepted ? 'Ver' : 'Leer términos'),
          ),
        ],
      ),
    );
  }
}

Future<bool> showTermsAndConditionsDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _TermsAndConditionsDialog(),
  );
  return result ?? false;
}

class _TermsAndConditionsDialog extends StatelessWidget {
  const _TermsAndConditionsDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      title: const Text('Términos y condiciones'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
        child: SingleChildScrollView(
          child: Text(
            kTermsAndConditionsText,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Acepto y continuar'),
        ),
      ],
    );
  }
}

const String kTermsAndConditionsText = '''
TÉRMINOS Y CONDICIONES DE USO — RUTA VIVA

Última actualización: mayo 2026

1. ACEPTACIÓN
Al registrarte y utilizar Ruta Viva, aceptas estos términos y condiciones en su totalidad. Si no estás de acuerdo con alguna parte, no debes utilizar la aplicación.

2. DESCRIPCIÓN DEL SERVICIO
Ruta Viva es una plataforma de turismo inteligente que conecta viajeros con emprendedores locales en la Región de La Araucanía, Chile. Ofrece recomendaciones personalizadas de lugares, itinerarios generados por inteligencia artificial, reseñas comunitarias y herramientas de gestión para emprendedores turísticos.

3. CUENTA DE USUARIO
Eres responsable de mantener la confidencialidad de tu contraseña y de todas las actividades que ocurran bajo tu cuenta. La cuenta es personal e intransferible.

4. CONTENIDO GENERADO POR USUARIOS
Al publicar reseñas, fotos, comentarios o cualquier contenido, garantizas que es original y no infringe derechos de terceros. Concedes a Ruta Viva una licencia no exclusiva, libre de regalías y mundial para usar, mostrar y distribuir dicho contenido dentro de la plataforma.

5. DATOS PERSONALES
Tus datos personales se tratan de acuerdo a nuestra Política de Privacidad y la legislación aplicable. No compartimos información personal con terceros sin tu consentimiento explícito.

6. USO ACEPTABLE
No debes usar la plataforma para fines ilegales, dañinos, fraudulentos o que violen derechos de terceros. Nos reservamos el derecho de suspender cuentas que incumplan estos términos.

7. PROPIEDAD INTELECTUAL
Todo el contenido original de Ruta Viva (diseño, código, algoritmos, marca) es propiedad de sus creadores. No se permite copia, distribución o ingeniería inversa sin autorización.

8. LIMITACIÓN DE RESPONSABILIDAD
Ruta Viva se proporciona "tal cual". No garantizamos la disponibilidad continua ni la exactitud absoluta de las recomendaciones. Los viajeros son responsables de verificar la información de los lugares antes de visitarlos.

9. MODIFICACIONES
Podemos actualizar estos términos en cualquier momento. Los cambios significativos se notificarán con antelación razonable a través de la aplicación o correo electrónico.

10. CONTACTO
Para consultas sobre estos términos: info@rutaviva.app
''';
