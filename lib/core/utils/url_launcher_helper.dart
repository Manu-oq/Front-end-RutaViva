import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  const UrlLauncherHelper._();

  static Future<void> launchPhone(BuildContext context, String phone) async {
    final value = phone.trim();
    if (value.isEmpty) {
      _showMessage(context, 'No hay teléfono disponible.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: value);
    await _launchOrCopy(
      context,
      uri: uri,
      fallbackValue: value,
      copiedLabel: 'teléfono',
      errorMessage:
          'No se pudo abrir la app de llamadas. Se copió el teléfono.',
    );
  }

  static Future<void> launchEmail(
    BuildContext context,
    String email, {
    String? subject,
  }) async {
    final value = email.trim();
    if (value.isEmpty) {
      _showMessage(context, 'No hay correo disponible.');
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: value,
      queryParameters: subject == null || subject.trim().isEmpty
          ? null
          : {'subject': subject.trim()},
    );
    await _launchOrCopy(
      context,
      uri: uri,
      fallbackValue: value,
      copiedLabel: 'correo',
      errorMessage: 'No se pudo abrir el correo. Se copió la dirección.',
    );
  }

  static Future<void> launchWeb(BuildContext context, String url) async {
    final value = url.trim();
    if (value.isEmpty) {
      _showMessage(context, 'No hay enlace disponible.');
      return;
    }

    final uri = Uri.tryParse(
      value.startsWith('http://') || value.startsWith('https://')
          ? value
          : 'https://$value',
    );

    if (uri == null) {
      await _copyFallback(
        context,
        value: value,
        copiedLabel: 'enlace',
        message: 'El enlace no es válido. Se copió al portapapeles.',
      );
      return;
    }

    await _launchOrCopy(
      context,
      uri: uri,
      fallbackValue: value,
      copiedLabel: 'enlace',
      errorMessage: 'No se pudo abrir el enlace. Se copió al portapapeles.',
    );
  }

  static Future<void> _launchOrCopy(
    BuildContext context, {
    required Uri uri,
    required String fallbackValue,
    required String copiedLabel,
    required String errorMessage,
  }) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return;
      }
    } catch (_) {}

    if (!context.mounted) {
      return;
    }
    await _copyFallback(
      context,
      value: fallbackValue,
      copiedLabel: copiedLabel,
      message: errorMessage,
    );
  }

  static Future<void> _copyFallback(
    BuildContext context, {
    required String value,
    required String copiedLabel,
    required String message,
  }) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    _showMessage(context, '$message $copiedLabel copiado.');
  }

  static void _showMessage(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
