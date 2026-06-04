import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../network/auth_token_provider.dart';

class AuthenticatedNetworkImage extends ConsumerStatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final WidgetBuilder? placeholderBuilder;
  final WidgetBuilder? errorBuilder;

  const AuthenticatedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.placeholderBuilder,
    this.errorBuilder,
  });

  static bool requiresBearerToken(String imageUrl) {
    final resolvedUrl = ApiConstants.resolveBackendUrl(imageUrl);
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(resolvedUrl);
    final backendUri = Uri.tryParse(ApiConstants.backendOrigin);
    return uri != null &&
        backendUri != null &&
        uri.scheme == backendUri.scheme &&
        uri.host == backendUri.host &&
        uri.port == backendUri.port &&
        uri.path.startsWith('/media/');
  }

  @override
  ConsumerState<AuthenticatedNetworkImage> createState() =>
      _AuthenticatedNetworkImageState();
}

class _AuthenticatedNetworkImageState
    extends ConsumerState<AuthenticatedNetworkImage> {
  Future<Uint8List>? _bytesFuture;

  bool get _needsAuth => AuthenticatedNetworkImage.requiresBearerToken(widget.imageUrl);

  @override
  void initState() {
    super.initState();
    if (_needsAuth) {
      _bytesFuture = _fetchBytes();
    }
  }

  @override
  void didUpdateWidget(covariant AuthenticatedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      if (_needsAuth) {
        _bytesFuture = _fetchBytes();
      } else {
        _bytesFuture = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiConstants.resolveBackendUrl(widget.imageUrl);
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return _error(context);
    }

    if (!AuthenticatedNetworkImage.requiresBearerToken(widget.imageUrl)) {
      return Image.network(
        resolvedUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        errorBuilder: (context, error, stackTrace) => _error(context),
      );
    }

    return FutureBuilder<Uint8List>(
      future: _bytesFuture!,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            alignment: widget.alignment,
            errorBuilder: (context, error, stackTrace) => _error(context),
          );
        }
        if (snapshot.hasError) {
          return _error(context);
        }
        return _placeholder(context);
      },
    );
  }

  Future<Uint8List> _fetchBytes() async {
    final resolvedUrl = ApiConstants.resolveBackendUrl(widget.imageUrl);
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      throw StateError('Image URL is empty.');
    }

    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      throw StateError('Bearer token is required for media URL.');
    }

    final response = await Dio().get<dynamic>(
      resolvedUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final data = response.data;
    if (data is Uint8List) {
      return data;
    }
    if (data is List<int>) {
      return Uint8List.fromList(data);
    }
    throw StateError('Unexpected media response type: ${data.runtimeType}.');
  }

  Widget _placeholder(BuildContext context) {
    return widget.placeholderBuilder?.call(context) ??
        SizedBox(width: widget.width, height: widget.height);
  }

  Widget _error(BuildContext context) {
    return widget.errorBuilder?.call(context) ??
        SizedBox(width: widget.width, height: widget.height);
  }
}
