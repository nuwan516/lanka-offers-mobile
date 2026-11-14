import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class OfferImage extends StatelessWidget {
  const OfferImage({
    super.key,
    required this.imageUrl,
    required this.semanticLabel,
    this.height,
  });

  final String? imageUrl;
  final String semanticLabel;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final image =
        url == null || url.isEmpty
            ? _placeholder(context)
            : CachedNetworkImage(
              key: const ValueKey('offer_network_image'),
              imageUrl: url,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (_, __) => _placeholder(context, loading: true),
              errorWidget: (_, __, ___) => _placeholder(context),
            );

    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          key: const ValueKey('offer_image_frame'),
          width: double.infinity,
          height: height,
          child: AspectRatio(aspectRatio: 16 / 9, child: image),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, {bool loading = false}) =>
      Container(
        key: ValueKey(
          loading ? 'offer_image_loading' : 'offer_image_placeholder',
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child:
            loading
                ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Icon(
                  Icons.image_not_supported_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
      );
}
