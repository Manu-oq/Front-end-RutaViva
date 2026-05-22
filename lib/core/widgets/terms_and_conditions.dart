import 'package:flutter/material.dart';

class TermsAndConditionsSection extends StatefulWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const TermsAndConditionsSection({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<TermsAndConditionsSection> createState() =>
      _TermsAndConditionsSectionState();
}

class _TermsAndConditionsSectionState extends State<TermsAndConditionsSection> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          constraints: const BoxConstraints(maxHeight: 180),
          child: SingleChildScrollView(
            child: Text(
              kTermsAndConditionsText,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _accepted,
          onChanged: widget.enabled
              ? (value) {
                  setState(() => _accepted = value ?? false);
                  widget.onChanged(_accepted);
                }
              : null,
          title: Text(
            'He leído y acepto los términos y condiciones',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _accepted
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          activeColor: theme.colorScheme.primary,
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
