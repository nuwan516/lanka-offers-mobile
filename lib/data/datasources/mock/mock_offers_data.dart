import '../../../domain/entities/bank_offer.dart';
import '../../../domain/entities/shop_offer.dart';
import '../../../domain/entities/promotion.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/discount.dart';
import '../../../domain/entities/validity_period.dart';
import '../../../domain/entities/contact_info.dart';
import '../../../domain/entities/quality_score.dart';
import '../../../domain/entities/engagement_metrics.dart';
import '../../../domain/entities/installment_plan.dart';
import '../../../domain/entities/restrictions.dart';
import '../../../domain/entities/deal.dart';
import '../../../domain/entities/venue.dart';
import '../../../domain/entities/event_date_time.dart';
import '../../../domain/entities/ticketing.dart';
import '../../../domain/entities/price_range.dart';
import '../../../domain/entities/amenities.dart';
import '../../../core/enums/shop_type.dart';
import '../../../core/enums/event_type.dart';
import '../../../core/utils/distance_calculator.dart';

class MockOffersData {
  static final List<BankOffer> _bankOffers = [];
  static final List<ShopOffer> _shopOffers = [];
  static final List<Promotion> _promotions = [];
  static final List<Event> _events = [];

  static bool _initialized = false;

  static void _initialize() {
    if (_initialized) return;

    _generateBankOffers();
    _generateShopOffers();
    _generatePromotions();
    _generateEvents();

    _initialized = true;
  }

  static List<BankOffer> getBankOffers() {
    _initialize();
    return List.from(_bankOffers);
  }

  static List<ShopOffer> getShopOffers() {
    _initialize();
    return List.from(_shopOffers);
  }

  static List<Promotion> getPromotions() {
    _initialize();
    return List.from(_promotions);
  }

  static List<Event> getEvents() {
    _initialize();
    return List.from(_events);
  }

  static List<dynamic> getAllOffers() {
    _initialize();
    return [..._bankOffers, ..._shopOffers, ..._promotions, ..._events];
  }

  static List<dynamic> getOffersByType(String type) {
    _initialize();
    switch (type.toLowerCase()) {
      case 'bankoffer':
        return _bankOffers;
      case 'shopoffer':
        return _shopOffers;
      case 'promotion':
        return _promotions;
      case 'event':
        return _events;
      default:
        return getAllOffers();
    }
  }

  static List<dynamic> getNearbyOffers(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    _initialize();
    return getAllOffers().where((offer) {
      if (offer.locations.isEmpty) return false;
      final distance = DistanceCalculator.calculateDistance(
        latitude,
        longitude,
        offer.locations.first.latitude,
        offer.locations.first.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  static List<dynamic> searchOffers(String query) {
    _initialize();
    final lowercaseQuery = query.toLowerCase();
    return getAllOffers().where((offer) {
      return offer.title.toLowerCase().contains(lowercaseQuery) ||
          offer.description.toLowerCase().contains(lowercaseQuery) ||
          offer.category.toLowerCase().contains(lowercaseQuery) ||
          offer.providerName.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  static dynamic getOfferById(String id) {
    _initialize();
    return getAllOffers().firstWhere(
      (offer) => offer.uniqueId == id,
      orElse: () => null,
    );
  }

  static void _generateBankOffers() {
    final now = DateTime.now();

    _bankOffers.addAll([
      BankOffer(
        uniqueId: 'hnb_hilton_001',
        bankName: 'HNB',
        title: '20% Off at Hilton Colombo',
        description:
            'Enjoy 20% discount on total bill at Hilton Colombo restaurants. Valid for all HNB cardholders.',
        category: 'Dining',
        subcategories: ['Fine Dining', 'Hotels'],
        merchantName: 'Hilton Colombo',
        discount: Discount(
          type: 'percentage',
          value: 20.0,
          description: '20% off on total bill',
        ),
        applicableCards: ['VISA', 'MASTERCARD', 'CREDIT'],
        locations: [
          Location(
            name: 'Hilton Colombo',
            address: '2 Sir Chittampalam A Gardiner Mawatha, Colombo 02',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9271,
            longitude: 79.8612,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 30)),
          validUntil: now.add(const Duration(days: 60)),
          daysApplicable: 'All Days',
        ),
        contact: ContactInfo(
          phone: ['+94112492492'],
          email: ['info@hilton.com'],
          website: 'https://www.hilton.com/colombo',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Prior reservation required',
            'Cannot be combined with other offers',
            'Valid for dine-in only',
          ],
          bookingRequired: true,
        ),
        images: [
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
        quality: QualityScore(confidenceScore: 0.95, grade: 'A'),
        metrics: EngagementMetrics(
          views: 1250,
          saves: 89,
          clicks: 156,
          popularityScore: 78.5,
        ),
      ),

      BankOffer(
        uniqueId: 'boc_abans_002',
        bankName: 'BOC',
        title: '0% + 12 Months at Abans',
        description:
            'Get 0% interest installment for 12 months on all electronic purchases above Rs. 50,000',
        category: 'Shopping',
        subcategories: ['Electronics', 'Appliances'],
        merchantName: 'Abans',
        installmentPlans: [
          InstallmentPlan(
            interestRate: 0,
            months: 6,
            description: '0% + 6 months',
          ),
          InstallmentPlan(
            interestRate: 0,
            months: 12,
            description: '0% + 12 months',
          ),
          InstallmentPlan(
            interestRate: 0,
            months: 18,
            description: '0% + 18 months',
          ),
        ],
        minTransaction: 50000.0,
        applicableCards: ['CREDIT'],
        locations: [
          Location(
            name: 'Abans Colombo 07',
            address: 'Ward Place, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9124,
            longitude: 79.8647,
          ),
          Location(
            name: 'Abans Nugegoda',
            address: 'High Level Road, Nugegoda',
            district: 'Colombo',
            city: 'Nugegoda',
            latitude: 6.8649,
            longitude: 79.8997,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 15)),
          validUntil: now.add(const Duration(days: 75)),
        ),
        contact: ContactInfo(
          phone: ['+94112304304'],
          website: 'https://www.abans.lk',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Minimum purchase Rs. 50,000',
            'Valid for BOC Credit Cards only',
            'Convert within 7 calendar days',
          ],
        ),
        images: [
          'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=800',
        quality: QualityScore(confidenceScore: 0.92, grade: 'A'),
        metrics: EngagementMetrics(
          views: 2450,
          saves: 234,
          clicks: 389,
          popularityScore: 85.2,
        ),
      ),

      BankOffer(
        uniqueId: 'commercial_keells_003',
        bankName: 'Commercial Bank',
        title: '15% Off at Keells Super',
        description:
            'Get 15% cashback on all purchases at Keells Super outlets. Maximum cashback Rs. 500 per transaction.',
        category: 'Shopping',
        subcategories: ['Supermarket', 'Groceries'],
        merchantName: 'Keells Super',
        discount: Discount(
          type: 'cashback',
          value: 15.0,
          description: '15% cashback (max Rs. 500)',
        ),
        applicableCards: ['DEBIT', 'CREDIT'],
        locations: [
          Location(
            name: 'Keells Super - Liberty Plaza',
            address: 'Liberty Plaza, R. A. De Mel Mawatha, Colombo 03',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8500,
          ),
          Location(
            name: 'Keells Super - Kandy',
            address: 'Dalada Veediya, Kandy',
            district: 'Kandy',
            city: 'Kandy',
            latitude: 7.2906,
            longitude: 80.6337,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 5)),
          validUntil: now.add(const Duration(days: 55)),
        ),
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.keellssuper.com',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Maximum cashback Rs. 500 per transaction',
            'Valid for Commercial Bank cards only',
          ],
        ),
        images: [
          'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
        quality: QualityScore(confidenceScore: 0.90, grade: 'A'),
        metrics: EngagementMetrics(
          views: 3200,
          saves: 456,
          clicks: 678,
          popularityScore: 92.3,
        ),
      ),

      BankOffer(
        uniqueId: 'sampath_ceylon_004',
        bankName: 'Sampath Bank',
        title: 'Buy 1 Get 1 Free at Ceylon Cold Stores',
        description:
            'Buy any ice cream and get another one free. Valid on weekends only.',
        category: 'Dining',
        subcategories: ['Desserts', 'Ice Cream'],
        merchantName: 'Ceylon Cold Stores',
        discount: Discount(
          type: 'bogo',
          value: '1+1',
          description: 'Buy 1 Get 1 Free',
        ),
        applicableCards: ['DEBIT', 'CREDIT'],
        locations: [
          Location(
            name: 'CCS - Bambalapitiya',
            address: 'Galle Road, Bambalapitiya',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.8905,
            longitude: 79.8563,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 10)),
          validUntil: now.add(const Duration(days: 50)),
          daysApplicable: 'Weekends',
        ),
        contact: ContactInfo(phone: ['+94112505050']),
        restrictions: Restrictions(
          keyRestrictions: [
            'Valid on weekends only',
            'Cannot be combined with other offers',
          ],
        ),
        images: [
          'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=800',
        quality: QualityScore(confidenceScore: 0.88, grade: 'B'),
        metrics: EngagementMetrics(
          views: 1890,
          saves: 267,
          clicks: 423,
          popularityScore: 81.7,
        ),
      ),

      BankOffer(
        uniqueId: 'ndb_singer_005',
        bankName: 'NDB',
        title: '10% Off + 0% Installment at Singer',
        description:
            'Get 10% discount plus 0% installment plans on all Singer products. Minimum purchase Rs. 25,000.',
        category: 'Shopping',
        subcategories: ['Electronics', 'Home Appliances'],
        merchantName: 'Singer',
        discount: Discount(
          type: 'percentage',
          value: 10.0,
          description: '10% off',
        ),
        installmentPlans: [
          InstallmentPlan(
            interestRate: 0,
            months: 6,
            description: '0% + 6 months',
          ),
          InstallmentPlan(
            interestRate: 0,
            months: 12,
            description: '0% + 12 months',
          ),
        ],
        minTransaction: 25000.0,
        applicableCards: ['CREDIT'],
        locations: [
          Location(
            name: 'Singer - Galle Road',
            address: 'Galle Road, Colombo 03',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8500,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 20)),
          validUntil: now.add(const Duration(days: 40)),
        ),
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.singer.lk',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Minimum purchase Rs. 25,000',
            'Valid for NDB Credit Cards only',
          ],
        ),
        images: [
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800',
        quality: QualityScore(confidenceScore: 0.91, grade: 'A'),
        metrics: EngagementMetrics(
          views: 2100,
          saves: 312,
          clicks: 445,
          popularityScore: 83.5,
        ),
      ),

      BankOffer(
        uniqueId: 'dfcc_ceylinco_006',
        bankName: 'DFCC',
        title: 'Rs. 500 Off on Insurance Premium',
        description:
            'Get Rs. 500 discount on annual insurance premium payment at Ceylinco Insurance.',
        category: 'Services',
        subcategories: ['Insurance', 'Financial Services'],
        merchantName: 'Ceylinco Insurance',
        discount: Discount(
          type: 'amount',
          value: 500.0,
          description: 'Rs. 500 off',
        ),
        applicableCards: ['CREDIT', 'DEBIT'],
        locations: [
          Location(
            name: 'Ceylinco Insurance - Head Office',
            address: 'No. 69, Janadhipathi Mawatha, Colombo 01',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9344,
            longitude: 79.8428,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 7)),
          validUntil: now.add(const Duration(days: 83)),
        ),
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.ceylinco.com',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Valid for annual premium payments only',
            'Minimum premium Rs. 10,000',
          ],
        ),
        images: [
          'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=800',
        quality: QualityScore(confidenceScore: 0.87, grade: 'B'),
        metrics: EngagementMetrics(
          views: 1450,
          saves: 123,
          clicks: 189,
          popularityScore: 72.3,
        ),
      ),

      BankOffer(
        uniqueId: 'hnb_jetwing_007',
        bankName: 'HNB',
        title: '25% Off at Jetwing Hotels',
        description:
            'Enjoy 25% discount on room rates and dining at all Jetwing Hotels across Sri Lanka.',
        category: 'Travel',
        subcategories: ['Hotels', 'Accommodation'],
        merchantName: 'Jetwing Hotels',
        discount: Discount(
          type: 'percentage',
          value: 25.0,
          description: '25% off',
        ),
        applicableCards: ['CREDIT'],
        locations: [
          Location(
            name: 'Jetwing Colombo Seven',
            address: 'No. 7, Ward Place, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9124,
            longitude: 79.8647,
          ),
          Location(
            name: 'Jetwing Lighthouse',
            address: 'Dadella, Galle',
            district: 'Galle',
            city: 'Galle',
            latitude: 6.0329,
            longitude: 80.2170,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 25)),
          validUntil: now.add(const Duration(days: 65)),
        ),
        contact: ContactInfo(
          phone: ['+94112345678'],
          email: ['reservations@jetwinghotels.com'],
          website: 'https://www.jetwinghotels.com',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Prior booking required',
            'Subject to availability',
            'Cannot be combined with other offers',
          ],
          bookingRequired: true,
        ),
        images: [
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
        quality: QualityScore(confidenceScore: 0.94, grade: 'A'),
        metrics: EngagementMetrics(
          views: 3100,
          saves: 456,
          clicks: 567,
          popularityScore: 89.2,
        ),
      ),

      BankOffer(
        uniqueId: 'boc_odel_008',
        bankName: 'BOC',
        title: 'Rs. 1000 Off at ODEL',
        description:
            'Get Rs. 1000 discount on purchases above Rs. 10,000 at ODEL stores.',
        category: 'Fashion',
        subcategories: ['Clothing', 'Lifestyle'],
        merchantName: 'ODEL',
        discount: Discount(
          type: 'amount',
          value: 1000.0,
          description: 'Rs. 1000 off',
        ),
        minTransaction: 10000.0,
        applicableCards: ['CREDIT', 'DEBIT'],
        locations: [
          Location(
            name: 'ODEL Colombo',
            address: '5 Alexandra Place, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8617,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 12)),
          validUntil: now.add(const Duration(days: 48)),
        ),
        contact: ContactInfo(
          phone: ['+94112682712'],
          website: 'https://www.odel.lk',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Minimum purchase Rs. 10,000',
            'Valid for BOC cards only',
          ],
        ),
        images: [
          'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800',
        quality: QualityScore(confidenceScore: 0.91, grade: 'A'),
        metrics: EngagementMetrics(
          views: 1890,
          saves: 267,
          clicks: 423,
          popularityScore: 81.7,
        ),
      ),

      BankOffer(
        uniqueId: 'commercial_ceyair_009',
        bankName: 'Commercial Bank',
        title: '15% Off on SriLankan Airlines',
        description:
            'Get 15% discount on domestic flights with SriLankan Airlines. Valid for economy class bookings.',
        category: 'Travel',
        subcategories: ['Airlines', 'Flights'],
        merchantName: 'SriLankan Airlines',
        discount: Discount(
          type: 'percentage',
          value: 15.0,
          description: '15% off',
        ),
        applicableCards: ['CREDIT'],
        locations: [
          Location(
            name: 'Bandaranaike International Airport',
            address: 'Katunayake',
            district: 'Gampaha',
            city: 'Katunayake',
            latitude: 7.1756,
            longitude: 79.8842,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 8)),
          validUntil: now.add(const Duration(days: 52)),
        ),
        contact: ContactInfo(
          phone: ['+94117797797'],
          website: 'https://www.srilankan.com',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Valid for economy class only',
            'Advance booking required',
            'Subject to availability',
          ],
          bookingRequired: true,
        ),
        images: [
          'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800',
        quality: QualityScore(confidenceScore: 0.93, grade: 'A'),
        metrics: EngagementMetrics(
          views: 2800,
          saves: 389,
          clicks: 512,
          popularityScore: 87.6,
        ),
      ),

      BankOffer(
        uniqueId: 'sampath_ceyhealth_010',
        bankName: 'Sampath Bank',
        title: '20% Off at Ceylon Hospitals',
        description:
            'Get 20% discount on consultations and diagnostic tests at Ceylon Hospitals.',
        category: 'Healthcare',
        subcategories: ['Hospitals', 'Medical Services'],
        merchantName: 'Ceylon Hospitals',
        discount: Discount(
          type: 'percentage',
          value: 20.0,
          description: '20% off',
        ),
        applicableCards: ['CREDIT', 'DEBIT'],
        locations: [
          Location(
            name: 'Ceylon Hospitals - Colombo',
            address: 'No. 114, Norris Canal Road, Colombo 10',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9344,
            longitude: 79.8728,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 18)),
          validUntil: now.add(const Duration(days: 42)),
        ),
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.ceylonhospitals.com',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Valid for consultations and diagnostic tests',
            'Prior appointment recommended',
          ],
          bookingRequired: true,
        ),
        images: [
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800',
        quality: QualityScore(confidenceScore: 0.89, grade: 'B'),
        metrics: EngagementMetrics(
          views: 1650,
          saves: 198,
          clicks: 267,
          popularityScore: 75.4,
        ),
      ),

      BankOffer(
        uniqueId: 'hnb_ceyair_011',
        bankName: 'HNB',
        title: '10% Cashback on Fuel',
        description:
            'Get 10% cashback on fuel purchases at all Ceylon Petroleum stations. Maximum cashback Rs. 500 per month.',
        category: 'Services',
        subcategories: ['Fuel', 'Automotive'],
        merchantName: 'Ceylon Petroleum',
        discount: Discount(
          type: 'cashback',
          value: 10.0,
          description: '10% cashback (max Rs. 500/month)',
        ),
        applicableCards: ['CREDIT', 'DEBIT'],
        locations: [
          Location(
            name: 'CPC - Galle Road',
            address: 'Galle Road, Colombo 03',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8500,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 14)),
          validUntil: now.add(const Duration(days: 46)),
        ),
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.ceypetco.lk',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Maximum cashback Rs. 500 per month',
            'Valid for HNB cards only',
          ],
        ),
        images: [
          'https://images.unsplash.com/photo-1623241892300-8c37c5a0b0b5?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1623241892300-8c37c5a0b0b5?w=800',
        quality: QualityScore(confidenceScore: 0.90, grade: 'A'),
        metrics: EngagementMetrics(
          views: 3456,
          saves: 512,
          clicks: 678,
          popularityScore: 88.9,
        ),
      ),

      BankOffer(
        uniqueId: 'boc_cargills_012',
        bankName: 'BOC',
        title: '15% Off at Cargills Food City',
        description:
            'Enjoy 15% discount on all purchases at Cargills Food City outlets. Valid on weekends.',
        category: 'Shopping',
        subcategories: ['Supermarket', 'Groceries'],
        merchantName: 'Cargills Food City',
        discount: Discount(
          type: 'percentage',
          value: 15.0,
          description: '15% off',
        ),
        applicableCards: ['CREDIT', 'DEBIT'],
        locations: [
          Location(
            name: 'Cargills - Liberty Plaza',
            address: 'Liberty Plaza, Colombo 03',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8500,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 4)),
          validUntil: now.add(const Duration(days: 26)),
          daysApplicable: 'Weekends',
        ),
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.cargillsceylon.com',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Valid on weekends only',
            'Valid for BOC cards only',
          ],
        ),
        images: [
          'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
        quality: QualityScore(confidenceScore: 0.88, grade: 'B'),
        metrics: EngagementMetrics(
          views: 2345,
          saves: 345,
          clicks: 456,
          popularityScore: 82.1,
        ),
      ),

      BankOffer(
        uniqueId: 'commercial_ceyair_013',
        bankName: 'Commercial Bank',
        title: 'Rs. 2000 Off on Domestic Flights',
        description:
            'Get Rs. 2000 discount on domestic flight bookings with Commercial Bank cards.',
        category: 'Travel',
        subcategories: ['Airlines', 'Flights'],
        merchantName: 'SriLankan Airlines',
        discount: Discount(
          type: 'amount',
          value: 2000.0,
          description: 'Rs. 2000 off',
        ),
        applicableCards: ['CREDIT', 'DEBIT'],
        locations: [
          Location(
            name: 'Bandaranaike International Airport',
            address: 'Katunayake',
            district: 'Gampaha',
            city: 'Katunayake',
            latitude: 7.1756,
            longitude: 79.8842,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 6)),
          validUntil: now.add(const Duration(days: 44)),
        ),
        contact: ContactInfo(
          phone: ['+94117797797'],
          website: 'https://www.srilankan.com',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Valid for domestic flights only',
            'Minimum booking value Rs. 10,000',
          ],
          bookingRequired: true,
        ),
        images: [
          'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800',
        quality: QualityScore(confidenceScore: 0.91, grade: 'A'),
        metrics: EngagementMetrics(
          views: 2345,
          saves: 345,
          clicks: 456,
          popularityScore: 82.3,
        ),
      ),

      BankOffer(
        uniqueId: 'sampath_keells_014',
        bankName: 'Sampath Bank',
        title: '10% Cashback at Keells Super',
        description:
            'Get 10% cashback on all purchases at Keells Super. Maximum cashback Rs. 300 per transaction.',
        category: 'Shopping',
        subcategories: ['Supermarket', 'Groceries'],
        merchantName: 'Keells Super',
        discount: Discount(
          type: 'cashback',
          value: 10.0,
          description: '10% cashback (max Rs. 300)',
        ),
        applicableCards: ['DEBIT', 'CREDIT'],
        locations: [
          Location(
            name: 'Keells Super - Liberty Plaza',
            address: 'Liberty Plaza, Colombo 03',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8500,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 9)),
          validUntil: now.add(const Duration(days: 41)),
        ),
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.keellssuper.com',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Maximum cashback Rs. 300 per transaction',
            'Valid for Sampath Bank cards only',
          ],
        ),
        images: [
          'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
        quality: QualityScore(confidenceScore: 0.89, grade: 'B'),
        metrics: EngagementMetrics(
          views: 3456,
          saves: 489,
          clicks: 612,
          popularityScore: 86.7,
        ),
      ),
    ]);
  }

  static void _generateShopOffers() {
    final now = DateTime.now();

    _shopOffers.addAll([
      ShopOffer(
        uniqueId: 'shop_pizza_hut_001',
        shopName: 'Pizza Hut',
        title: 'Buy 1 Get 1 Free - Large Pizzas',
        description:
            'Buy any large pizza and get another large pizza absolutely free! Valid during happy hours.',
        category: 'Dining',
        subcategories: ['Fast Food', 'Pizza'],
        shopType: ShopType.restaurant,
        discount: Discount(
          type: 'bogo',
          value: '1+1',
          description: 'Buy 1 Get 1 Free',
        ),
        promoCode: 'BOGO2024',
        locations: [
          Location(
            name: 'Pizza Hut - Majestic City',
            address: 'Majestic City, Bambalapitiya',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.8905,
            longitude: 79.8563,
          ),
          Location(
            name: 'Pizza Hut - Kandy City Center',
            address: 'Dalada Veediya, Kandy',
            district: 'Kandy',
            city: 'Kandy',
            latitude: 7.2906,
            longitude: 80.6337,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 5)),
          validUntil: now.add(const Duration(days: 25)),
          daysApplicable: 'Weekdays',
          timeRestrictions: '2PM - 5PM',
        ),
        hoursOfOperation: '11:00 AM - 11:00 PM',
        verified: true,
        verificationDate: now.subtract(const Duration(days: 2)),
        contact: ContactInfo(
          phone: ['+94112505050'],
          website: 'https://www.pizzahut.lk',
        ),
        images: [
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800',
        quality: QualityScore(confidenceScore: 0.88, grade: 'B'),
        metrics: EngagementMetrics(
          views: 3200,
          saves: 456,
          clicks: 678,
          popularityScore: 92.3,
        ),
      ),

      ShopOffer(
        uniqueId: 'shop_odel_fashion_002',
        shopName: 'ODEL',
        title: '30% Off on All Clothing',
        description:
            'End of season sale - Get 30% discount on all clothing items. Limited time offer!',
        category: 'Fashion',
        subcategories: ['Clothing', 'Lifestyle'],
        shopType: ShopType.retail,
        discount: Discount(
          type: 'percentage',
          value: 30.0,
          description: '30% off storewide',
        ),
        minPurchaseAmount: 5000.0,
        locations: [
          Location(
            name: 'ODEL Colombo',
            address: '5 Alexandra Place, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8617,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 10)),
          validUntil: now.add(const Duration(days: 20)),
        ),
        verified: true,
        contact: ContactInfo(
          phone: ['+94112682712'],
          website: 'https://www.odel.lk',
        ),
        images: [
          'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800',
        quality: QualityScore(confidenceScore: 0.91, grade: 'A'),
        metrics: EngagementMetrics(
          views: 1890,
          saves: 267,
          clicks: 423,
          popularityScore: 81.7,
        ),
      ),

      ShopOffer(
        uniqueId: 'shop_paradise_road_003',
        shopName: 'Paradise Road Galleries',
        title: '15% Off on Home Decor',
        description:
            'Get 15% discount on all home decor items and furniture. Perfect for home renovation!',
        category: 'Home & Living',
        subcategories: ['Furniture', 'Home Decor'],
        shopType: ShopType.retail,
        discount: Discount(
          type: 'percentage',
          value: 15.0,
          description: '15% off',
        ),
        locations: [
          Location(
            name: 'Paradise Road Galleries',
            address: 'No. 213, Dharmapala Mawatha, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8617,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 7)),
          validUntil: now.add(const Duration(days: 33)),
        ),
        verified: true,
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.paradiseroad.lk',
        ),
        images: [
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800',
        quality: QualityScore(confidenceScore: 0.86, grade: 'B'),
        metrics: EngagementMetrics(
          views: 1234,
          saves: 156,
          clicks: 234,
          popularityScore: 68.9,
        ),
      ),

      ShopOffer(
        uniqueId: 'shop_ministry_crab_004',
        shopName: 'Ministry of Crab',
        title: 'Lunch Special - 25% Off',
        description:
            'Enjoy 25% discount on lunch menu. Available Monday to Friday from 12PM to 3PM.',
        category: 'Dining',
        subcategories: ['Seafood', 'Fine Dining'],
        shopType: ShopType.restaurant,
        discount: Discount(
          type: 'percentage',
          value: 25.0,
          description: '25% off lunch',
        ),
        locations: [
          Location(
            name: 'Ministry of Crab',
            address: 'Old Dutch Hospital, Colombo 01',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9344,
            longitude: 79.8428,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 3)),
          validUntil: now.add(const Duration(days: 27)),
          daysApplicable: 'Weekdays',
          timeRestrictions: '12PM - 3PM',
        ),
        hoursOfOperation: '12:00 PM - 11:00 PM',
        verified: true,
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.ministryofcrab.com',
        ),
        images: [
          'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800',
        quality: QualityScore(confidenceScore: 0.92, grade: 'A'),
        metrics: EngagementMetrics(
          views: 2456,
          saves: 345,
          clicks: 489,
          popularityScore: 84.2,
        ),
      ),

      ShopOffer(
        uniqueId: 'shop_ceylon_tea_005',
        shopName: 'Ceylon Tea Trails',
        title: 'Free Tea Tasting Session',
        description:
            'Join us for a free tea tasting session and learn about Ceylon tea. Complimentary snacks included.',
        category: 'Dining',
        subcategories: ['Tea', 'Experience'],
        shopType: ShopType.restaurant,
        discount: Discount(
          type: 'freebie',
          value: 0,
          description: 'Free tasting',
        ),
        locations: [
          Location(
            name: 'Ceylon Tea Trails - Galle Face',
            address: 'Galle Face Green, Colombo 03',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9271,
            longitude: 79.8454,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 1)),
          validUntil: now.add(const Duration(days: 29)),
          daysApplicable: 'Weekends',
        ),
        hoursOfOperation: '10:00 AM - 6:00 PM',
        verified: true,
        contact: ContactInfo(phone: ['+94112345678']),
        restrictions: Restrictions(
          keyRestrictions: [
            'Prior booking required',
            'Valid on weekends only',
            'Limited seats available',
          ],
          bookingRequired: true,
        ),
        images: [
          'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=800',
        quality: QualityScore(confidenceScore: 0.85, grade: 'B'),
        metrics: EngagementMetrics(
          views: 987,
          saves: 123,
          clicks: 178,
          popularityScore: 65.4,
        ),
      ),

      ShopOffer(
        uniqueId: 'shop_spa_ceylon_006',
        shopName: 'Spa Ceylon',
        title: '20% Off on Spa Packages',
        description:
            'Relax and rejuvenate with 20% discount on all spa packages. Book your appointment today!',
        category: 'Wellness',
        subcategories: ['Spa', 'Beauty'],
        shopType: ShopType.service,
        discount: Discount(
          type: 'percentage',
          value: 20.0,
          description: '20% off',
        ),
        locations: [
          Location(
            name: 'Spa Ceylon - Odel',
            address: 'ODEL, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8617,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 6)),
          validUntil: now.add(const Duration(days: 34)),
        ),
        verified: true,
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.spaceylon.com',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Prior appointment required',
            'Valid for spa packages only',
          ],
          bookingRequired: true,
        ),
        images: [
          'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=800',
        quality: QualityScore(confidenceScore: 0.89, grade: 'B'),
        metrics: EngagementMetrics(
          views: 1456,
          saves: 198,
          clicks: 267,
          popularityScore: 73.2,
        ),
      ),

      ShopOffer(
        uniqueId: 'shop_keells_007',
        shopName: 'Keells Super',
        title: 'Weekend Special - 20% Off',
        description:
            'Get 20% discount on all items every weekend. Stock up on your favorite products!',
        category: 'Shopping',
        subcategories: ['Supermarket', 'Groceries'],
        shopType: ShopType.retail,
        discount: Discount(
          type: 'percentage',
          value: 20.0,
          description: '20% off',
        ),
        locations: [
          Location(
            name: 'Keells Super - Liberty Plaza',
            address: 'Liberty Plaza, Colombo 03',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8500,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 3)),
          validUntil: now.add(const Duration(days: 27)),
          daysApplicable: 'Weekends',
        ),
        verified: true,
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.keellssuper.com',
        ),
        images: [
          'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
        quality: QualityScore(confidenceScore: 0.91, grade: 'A'),
        metrics: EngagementMetrics(
          views: 2789,
          saves: 412,
          clicks: 567,
          popularityScore: 86.3,
        ),
      ),

      ShopOffer(
        uniqueId: 'shop_dominos_008',
        shopName: 'Domino\'s Pizza',
        title: '50% Off on Large Pizzas',
        description:
            'Enjoy 50% discount on all large pizzas. Valid for online orders only.',
        category: 'Dining',
        subcategories: ['Fast Food', 'Pizza'],
        shopType: ShopType.restaurant,
        discount: Discount(
          type: 'percentage',
          value: 50.0,
          description: '50% off',
        ),
        promoCode: 'PIZZA50',
        locations: [
          Location(
            name: 'Domino\'s - Nugegoda',
            address: 'High Level Road, Nugegoda',
            district: 'Colombo',
            city: 'Nugegoda',
            latitude: 6.8649,
            longitude: 79.8997,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 2)),
          validUntil: now.add(const Duration(days: 28)),
        ),
        hoursOfOperation: '11:00 AM - 11:00 PM',
        verified: true,
        contact: ContactInfo(
          phone: ['+94112345678'],
          website: 'https://www.dominos.lk',
        ),
        restrictions: Restrictions(
          keyRestrictions: [
            'Valid for online orders only',
            'Use promo code PIZZA50',
          ],
        ),
        images: [
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800',
        quality: QualityScore(confidenceScore: 0.89, grade: 'B'),
        metrics: EngagementMetrics(
          views: 4123,
          saves: 567,
          clicks: 789,
          popularityScore: 91.2,
        ),
      ),
    ]);
  }

  static void _generatePromotions() {
    final now = DateTime.now();

    _promotions.addAll([
      Promotion(
        uniqueId: 'promo_flash_phones_001',
        title: 'Flash Sale: Samsung Galaxy S24 - 40% Off',
        description:
            '24-hour flash sale on Samsung Galaxy S24. Limited stock available! Hurry before it\'s gone.',
        providerName: 'Singer Mega',
        category: 'Electronics',
        subcategories: ['Mobile Phones', 'Electronics'],
        promotionType: 'flash_sale',
        urgencyLevel: 'urgent',
        deal: Deal(
          type: 'discount',
          value: 40.0,
          description: '40% discount',
          originalPrice: 280000.0,
          salePrice: 168000.0,
        ),
        stockStatus: 'limited',
        unitsAvailable: 8,
        unitsSold: 42,
        flashDurationHours: 24,
        countdownEnabled: true,
        locations: [
          Location(
            name: 'Singer Mega - Galle Road',
            address: 'Galle Road, Colombo 03',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8500,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(hours: 18)),
          validUntil: now.add(const Duration(hours: 6)),
        ),
        images: [
          'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=800',
        quality: QualityScore(confidenceScore: 0.87, grade: 'B'),
        metrics: EngagementMetrics(
          views: 5670,
          saves: 892,
          clicks: 1234,
          popularityScore: 96.8,
        ),
      ),

      Promotion(
        uniqueId: 'promo_black_friday_002',
        title: 'Black Friday Sale - Up to 50% Off',
        description:
            'Massive Black Friday sale! Get up to 50% discount on electronics, fashion, and home items.',
        providerName: 'ODEL',
        category: 'Shopping',
        subcategories: ['Fashion', 'Electronics', 'Home'],
        promotionType: 'seasonal',
        urgencyLevel: 'high',
        deal: Deal(type: 'discount', value: 50.0, description: 'Up to 50% off'),
        stockStatus: 'available',
        countdownEnabled: true,
        locations: [
          Location(
            name: 'ODEL Colombo',
            address: '5 Alexandra Place, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8617,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 2)),
          validUntil: now.add(const Duration(days: 3)),
        ),
        images: [
          'https://images.unsplash.com/photo-1607082349566-187342175e2f?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1607082349566-187342175e2f?w=800',
        quality: QualityScore(confidenceScore: 0.90, grade: 'A'),
        metrics: EngagementMetrics(
          views: 8900,
          saves: 1234,
          clicks: 2345,
          popularityScore: 94.5,
        ),
      ),

      Promotion(
        uniqueId: 'promo_laptop_sale_003',
        title: 'Laptop Sale - Up to 30% Off',
        description:
            'Massive laptop sale! Get up to 30% discount on all laptops from top brands.',
        providerName: 'Abans',
        category: 'Electronics',
        subcategories: ['Laptops', 'Computers'],
        promotionType: 'limited_time',
        urgencyLevel: 'high',
        deal: Deal(type: 'discount', value: 30.0, description: 'Up to 30% off'),
        stockStatus: 'available',
        countdownEnabled: false,
        locations: [
          Location(
            name: 'Abans - Ward Place',
            address: 'Ward Place, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9124,
            longitude: 79.8647,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 1)),
          validUntil: now.add(const Duration(days: 14)),
        ),
        images: [
          'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=800',
        quality: QualityScore(confidenceScore: 0.92, grade: 'A'),
        metrics: EngagementMetrics(
          views: 4567,
          saves: 678,
          clicks: 890,
          popularityScore: 89.5,
        ),
      ),

      Promotion(
        uniqueId: 'promo_fashion_sale_004',
        title: 'End of Season Fashion Sale - Up to 60% Off',
        description:
            'Massive end of season sale! Get up to 60% discount on all fashion items.',
        providerName: 'ODEL',
        category: 'Fashion',
        subcategories: ['Clothing', 'Accessories'],
        promotionType: 'seasonal',
        urgencyLevel: 'high',
        deal: Deal(type: 'discount', value: 60.0, description: 'Up to 60% off'),
        stockStatus: 'available',
        countdownEnabled: false,
        locations: [
          Location(
            name: 'ODEL Colombo',
            address: '5 Alexandra Place, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8617,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 5)),
          validUntil: now.add(const Duration(days: 15)),
        ),
        images: [
          'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800',
        quality: QualityScore(confidenceScore: 0.93, grade: 'A'),
        metrics: EngagementMetrics(
          views: 6789,
          saves: 987,
          clicks: 1456,
          popularityScore: 92.1,
        ),
      ),

      Promotion(
        uniqueId: 'promo_electronics_005',
        title: 'Tech Week Sale - 30% Off Electronics',
        description:
            'Tech Week special! Get 30% discount on all electronics including smartphones, laptops, and tablets.',
        providerName: 'Singer',
        category: 'Electronics',
        subcategories: ['Mobile Phones', 'Laptops', 'Tablets'],
        promotionType: 'limited_time',
        urgencyLevel: 'normal',
        deal: Deal(type: 'discount', value: 30.0, description: '30% off'),
        stockStatus: 'available',
        countdownEnabled: true,
        locations: [
          Location(
            name: 'Singer - Galle Road',
            address: 'Galle Road, Colombo 03',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9147,
            longitude: 79.8500,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now.subtract(const Duration(days: 3)),
          validUntil: now.add(const Duration(days: 7)),
        ),
        images: [
          'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=800',
        quality: QualityScore(confidenceScore: 0.91, grade: 'A'),
        metrics: EngagementMetrics(
          views: 5234,
          saves: 756,
          clicks: 1023,
          popularityScore: 88.9,
        ),
      ),
    ]);
  }

  static void _generateEvents() {
    final now = DateTime.now();

    _events.addAll([
      Event(
        uniqueId: 'event_colombo_food_fest_001',
        title: 'Colombo Food Festival 2024',
        description:
            'The biggest food festival in Sri Lanka featuring 100+ stalls, celebrity chefs, cooking competitions, and live music. Don\'t miss this culinary extravaganza!',
        providerName: 'Colombo Events',
        category: 'Food & Beverage',
        subcategories: ['Food Festival', 'Entertainment'],
        eventType: EventType.foodFestival,
        organizer: 'Colombo Events Pvt Ltd',
        venue: Venue(
          name: 'Galle Face Green',
          address: 'Galle Road, Colombo 03',
          capacity: 10000,
          indoor: false,
        ),
        eventDateTime: EventDateTime(
          start: now.add(const Duration(days: 15)),
          end: now.add(const Duration(days: 17)),
          doorsOpen: '10:00 AM',
        ),
        ticketing: Ticketing(
          required: true,
          priceRange: PriceRange(min: 500, max: 2000),
          earlyBirdAvailable: true,
          earlyBirdDeadline: now.add(const Duration(days: 7)),
          ticketsAvailable: 3500,
          ticketsSold: 1500,
          bookingUrl: 'https://colombofoodfest.lk/tickets',
        ),
        locations: [
          Location(
            name: 'Galle Face Green',
            address: 'Galle Road, Colombo 03',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9271,
            longitude: 79.8454,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now,
          validUntil: now.add(const Duration(days: 17)),
        ),
        amenities: Amenities(
          parkingAvailable: true,
          wheelchairAccessible: true,
          foodAvailable: true,
          wifiAvailable: false,
        ),
        ageRestriction: 'all_ages',
        familyFriendly: true,
        images: [
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800',
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800',
        quality: QualityScore(confidenceScore: 0.94, grade: 'A'),
        metrics: EngagementMetrics(
          views: 8900,
          saves: 1234,
          clicks: 2345,
          popularityScore: 94.5,
        ),
      ),

      Event(
        uniqueId: 'event_jazz_festival_002',
        title: 'Colombo Jazz Festival 2024',
        description:
            'Experience world-class jazz performances by international and local artists. Three days of amazing music!',
        providerName: 'Jazz Colombo',
        category: 'Entertainment',
        subcategories: ['Music', 'Concert'],
        eventType: EventType.concert,
        organizer: 'Jazz Colombo Productions',
        venue: Venue(
          name: 'Nelum Pokuna Mahinda Rajapaksa Theatre',
          address: 'Ananda Coomaraswamy Mawatha, Colombo 07',
          capacity: 5000,
          indoor: true,
        ),
        eventDateTime: EventDateTime(
          start: now.add(const Duration(days: 30)),
          end: now.add(const Duration(days: 32)),
          doorsOpen: '6:00 PM',
        ),
        ticketing: Ticketing(
          required: true,
          priceRange: PriceRange(min: 2000, max: 10000),
          earlyBirdAvailable: true,
          earlyBirdDeadline: now.add(const Duration(days: 15)),
          ticketsAvailable: 2000,
          ticketsSold: 800,
          bookingUrl: 'https://jazzcolombo.lk/tickets',
        ),
        locations: [
          Location(
            name: 'Nelum Pokuna Theatre',
            address: 'Ananda Coomaraswamy Mawatha, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9124,
            longitude: 79.8647,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now,
          validUntil: now.add(const Duration(days: 32)),
        ),
        amenities: Amenities(
          parkingAvailable: true,
          wheelchairAccessible: true,
          foodAvailable: true,
          wifiAvailable: true,
        ),
        ageRestriction: 'all_ages',
        familyFriendly: true,
        images: [
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
        quality: QualityScore(confidenceScore: 0.92, grade: 'A'),
        metrics: EngagementMetrics(
          views: 5600,
          saves: 789,
          clicks: 1234,
          popularityScore: 88.3,
        ),
      ),

      Event(
        uniqueId: 'event_art_exhibition_003',
        title: 'Contemporary Art Exhibition',
        description:
            'Explore the works of renowned Sri Lankan artists in this exclusive contemporary art exhibition.',
        providerName: 'Colombo Art Gallery',
        category: 'Entertainment',
        subcategories: ['Art', 'Exhibition'],
        eventType: EventType.exhibition,
        organizer: 'Colombo Art Gallery',
        venue: Venue(
          name: 'Colombo Art Gallery',
          address: 'No. 82, Ananda Coomaraswamy Mawatha, Colombo 07',
          capacity: 500,
          indoor: true,
        ),
        eventDateTime: EventDateTime(
          start: now.add(const Duration(days: 20)),
          end: now.add(const Duration(days: 45)),
          doorsOpen: '10:00 AM',
        ),
        ticketing: Ticketing(
          required: false,
          bookingUrl: 'https://colomboart.lk',
        ),
        locations: [
          Location(
            name: 'Colombo Art Gallery',
            address: 'Ananda Coomaraswamy Mawatha, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9124,
            longitude: 79.8647,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now,
          validUntil: now.add(const Duration(days: 45)),
        ),
        amenities: Amenities(
          parkingAvailable: true,
          wheelchairAccessible: true,
          foodAvailable: false,
          wifiAvailable: true,
        ),
        ageRestriction: 'all_ages',
        familyFriendly: true,
        images: [
          'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800',
        quality: QualityScore(confidenceScore: 0.88, grade: 'B'),
        metrics: EngagementMetrics(
          views: 2345,
          saves: 345,
          clicks: 456,
          popularityScore: 78.9,
        ),
      ),

      Event(
        uniqueId: 'event_tech_conference_004',
        title: 'Sri Lanka Tech Summit 2024',
        description:
            'Join leading tech innovators, entrepreneurs, and investors for a day of networking, workshops, and keynote speeches.',
        providerName: 'Tech Lanka',
        category: 'Technology',
        subcategories: ['Conference', 'Technology'],
        eventType: EventType.conference,
        organizer: 'Tech Lanka Events',
        venue: Venue(
          name: 'Cinnamon Grand Hotel',
          address: '77 Galle Road, Colombo 03',
          capacity: 2000,
          indoor: true,
        ),
        eventDateTime: EventDateTime(
          start: now.add(const Duration(days: 25)),
          end: now.add(const Duration(days: 25)),
          doorsOpen: '8:00 AM',
        ),
        ticketing: Ticketing(
          required: true,
          priceRange: PriceRange(min: 5000, max: 15000),
          earlyBirdAvailable: true,
          earlyBirdDeadline: now.add(const Duration(days: 10)),
          ticketsAvailable: 800,
          ticketsSold: 200,
          bookingUrl: 'https://techsummit.lk/tickets',
        ),
        locations: [
          Location(
            name: 'Cinnamon Grand Hotel',
            address: '77 Galle Road, Colombo 03',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9271,
            longitude: 79.8454,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now,
          validUntil: now.add(const Duration(days: 25)),
        ),
        amenities: Amenities(
          parkingAvailable: true,
          wheelchairAccessible: true,
          foodAvailable: true,
          wifiAvailable: true,
        ),
        ageRestriction: '18+',
        familyFriendly: false,
        images: [
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
        quality: QualityScore(confidenceScore: 0.91, grade: 'A'),
        metrics: EngagementMetrics(
          views: 3456,
          saves: 512,
          clicks: 678,
          popularityScore: 85.3,
        ),
      ),

      Event(
        uniqueId: 'event_cooking_workshop_005',
        title: 'Traditional Sri Lankan Cooking Workshop',
        description:
            'Learn to cook authentic Sri Lankan dishes from expert chefs. Includes ingredients and recipe book.',
        providerName: 'Culinary Academy',
        category: 'Food & Beverage',
        subcategories: ['Workshop', 'Cooking'],
        eventType: EventType.workshop,
        organizer: 'Culinary Academy Sri Lanka',
        venue: Venue(
          name: 'Culinary Academy',
          address: 'No. 45, Duplication Road, Colombo 04',
          capacity: 30,
          indoor: true,
        ),
        eventDateTime: EventDateTime(
          start: now.add(const Duration(days: 12)),
          end: now.add(const Duration(days: 12)),
          doorsOpen: '10:00 AM',
        ),
        ticketing: Ticketing(
          required: true,
          priceRange: PriceRange(min: 3000, max: 3000),
          ticketsAvailable: 20,
          ticketsSold: 10,
          bookingUrl: 'https://culinaryacademy.lk/workshops',
        ),
        locations: [
          Location(
            name: 'Culinary Academy',
            address: 'Duplication Road, Colombo 04',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.8905,
            longitude: 79.8563,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now,
          validUntil: now.add(const Duration(days: 12)),
        ),
        amenities: Amenities(
          parkingAvailable: false,
          wheelchairAccessible: true,
          foodAvailable: true,
          wifiAvailable: true,
        ),
        ageRestriction: 'all_ages',
        familyFriendly: true,
        images: [
          'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800',
        quality: QualityScore(confidenceScore: 0.89, grade: 'B'),
        metrics: EngagementMetrics(
          views: 1234,
          saves: 189,
          clicks: 234,
          popularityScore: 72.1,
        ),
      ),

      Event(
        uniqueId: 'event_cricket_match_006',
        title: 'Sri Lanka vs India T20 Match',
        description:
            'Watch the thrilling T20 cricket match between Sri Lanka and India at R. Premadasa Stadium.',
        providerName: 'Sri Lanka Cricket',
        category: 'Sports',
        subcategories: ['Cricket', 'Sports'],
        eventType: EventType.sports,
        organizer: 'Sri Lanka Cricket Board',
        venue: Venue(
          name: 'R. Premadasa Stadium',
          address: 'Khettarama, Colombo 05',
          capacity: 35000,
          indoor: false,
        ),
        eventDateTime: EventDateTime(
          start: now.add(const Duration(days: 40)),
          end: now.add(const Duration(days: 40)),
          doorsOpen: '6:00 PM',
        ),
        ticketing: Ticketing(
          required: true,
          priceRange: PriceRange(min: 1000, max: 5000),
          earlyBirdAvailable: true,
          earlyBirdDeadline: now.add(const Duration(days: 20)),
          ticketsAvailable: 15000,
          ticketsSold: 5000,
          bookingUrl: 'https://srilankacricket.lk/tickets',
        ),
        locations: [
          Location(
            name: 'R. Premadasa Stadium',
            address: 'Khettarama, Colombo 05',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9344,
            longitude: 79.8728,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now,
          validUntil: now.add(const Duration(days: 40)),
        ),
        amenities: Amenities(
          parkingAvailable: true,
          wheelchairAccessible: true,
          foodAvailable: true,
          wifiAvailable: false,
        ),
        ageRestriction: 'all_ages',
        familyFriendly: true,
        images: [
          'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800',
        quality: QualityScore(confidenceScore: 0.95, grade: 'A'),
        metrics: EngagementMetrics(
          views: 12000,
          saves: 2345,
          clicks: 3456,
          popularityScore: 97.8,
        ),
      ),

      Event(
        uniqueId: 'event_cultural_show_007',
        title: 'Traditional Kandyan Dance Performance',
        description:
            'Experience the rich cultural heritage of Sri Lanka with traditional Kandyan dance performances.',
        providerName: 'Cultural Center',
        category: 'Entertainment',
        subcategories: ['Cultural', 'Dance'],
        eventType: EventType.cultural,
        organizer: 'Sri Lanka Cultural Center',
        venue: Venue(
          name: 'Nelum Pokuna Theatre',
          address: 'Ananda Coomaraswamy Mawatha, Colombo 07',
          capacity: 5000,
          indoor: true,
        ),
        eventDateTime: EventDateTime(
          start: now.add(const Duration(days: 18)),
          end: now.add(const Duration(days: 18)),
          doorsOpen: '7:00 PM',
        ),
        ticketing: Ticketing(
          required: true,
          priceRange: PriceRange(min: 1500, max: 4000),
          ticketsAvailable: 2000,
          ticketsSold: 800,
          bookingUrl: 'https://culturalcenter.lk/tickets',
        ),
        locations: [
          Location(
            name: 'Nelum Pokuna Theatre',
            address: 'Ananda Coomaraswamy Mawatha, Colombo 07',
            district: 'Colombo',
            city: 'Colombo',
            latitude: 6.9124,
            longitude: 79.8647,
          ),
        ],
        validity: ValidityPeriod(
          validFrom: now,
          validUntil: now.add(const Duration(days: 18)),
        ),
        amenities: Amenities(
          parkingAvailable: true,
          wheelchairAccessible: true,
          foodAvailable: false,
          wifiAvailable: true,
        ),
        ageRestriction: 'all_ages',
        familyFriendly: true,
        images: [
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800',
        ],
        featuredImage:
            'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800',
        quality: QualityScore(confidenceScore: 0.90, grade: 'A'),
        metrics: EngagementMetrics(
          views: 2789,
          saves: 412,
          clicks: 567,
          popularityScore: 81.5,
        ),
      ),
    ]);
  }
}
