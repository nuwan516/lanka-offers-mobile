import 'package:equatable/equatable.dart';
import 'location.dart';
import 'validity_period.dart';
import 'contact_info.dart';
import 'quality_score.dart';
import 'engagement_metrics.dart';

abstract class BaseOffer extends Equatable {
  final String uniqueId;
  final String title;
  final String description;
  final String category;
  final List<String> subcategories;
  final List<Location> locations;
  final ValidityPeriod validity;
  final ContactInfo? contact;
  final List<String> images;
  final String? featuredImage;
  final QualityScore quality;
  final EngagementMetrics? metrics;

  BaseOffer({
    required this.uniqueId,
    required this.title,
    required this.description,
    required this.category,
    required this.subcategories,
    required this.locations,
    required this.validity,
    this.contact,
    required this.images,
    this.featuredImage,
    required this.quality,
    this.metrics,
  });

  String get providerName;

  @override
  List<Object?> get props => [
    uniqueId,
    title,
    description,
    category,
    subcategories,
    locations,
    validity,
    contact,
    images,
    featuredImage,
    quality,
    metrics,
  ];
}
