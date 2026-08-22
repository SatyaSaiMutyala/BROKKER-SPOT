/// Immutable snapshot of the property search/filter criteria.
///
/// Maps 1:1 to the backend filter contract on `/announcements/fetch-all`
/// (see the filter query-param doc). Location and property-type are sent as
/// **IDs** (`property_type_id`, `country_id`, `city_id`, `area_id`) — the
/// human-readable names are kept alongside purely so the Filter screen can
/// re-render the current selection without another reference-data lookup.
///
/// `null`/empty fields are simply omitted from the query string, so an empty
/// [PropertyFilter] serializes to `''` and behaves like an unfiltered fetch.
class PropertyFilter {
  /// Global search — searches property name, country, city, area, address.
  /// Driven by the search bar, not the Filter screen.
  final String? search;

  /// 1 = Sell (Buy), 2 = Rent. `null` = All.
  final int? listingType;

  /// 1 = Ready, 2 = In Progress (Off Plan). Only meaningful for Buy.
  final int? propertyStatus;

  /// Rent cadence label ('Yearly' | 'Monthly'). Only meaningful for Rent.
  /// Not part of the documented filter contract yet; sent best-effort and
  /// ignored by the backend if unsupported.
  final String? rentPeriod;

  final String? propertyTypeId;
  final String? propertyTypeName;

  final String? countryId;
  final String? countryName;

  final String? cityId;
  final String? cityName;

  final String? areaId;
  final String? areaName;

  final int? bedrooms;
  final int? bathrooms;

  final double? minPrice;
  final double? maxPrice;

  const PropertyFilter({
    this.search,
    this.listingType,
    this.propertyStatus,
    this.rentPeriod,
    this.propertyTypeId,
    this.propertyTypeName,
    this.countryId,
    this.countryName,
    this.cityId,
    this.cityName,
    this.areaId,
    this.areaName,
    this.bedrooms,
    this.bathrooms,
    this.minPrice,
    this.maxPrice,
  });

  static const empty = PropertyFilter();

  /// True when nothing beyond the free-text [search] is set — i.e. the Filter
  /// screen contributes no constraints.
  /// True when the location facets carry nothing the query would use.
  ///
  /// Checked by name as well as id: [toQueryString] sends the *names*
  /// (`country`/`city`/`area`) and deliberately omits the ids, so a filter
  /// holding only a name is still a real, applied filter. Looking at the id
  /// alone made a country-only selection read as "no filters" — the home feed
  /// then stayed on its unfiltered list and nothing appeared to change.
  bool get _hasNoLocation =>
      countryId == null &&
      countryName == null &&
      cityId == null &&
      cityName == null &&
      areaId == null &&
      areaName == null;

  bool get hasNoFacets =>
      listingType == null &&
      propertyStatus == null &&
      rentPeriod == null &&
      propertyTypeId == null &&
      _hasNoLocation &&
      bedrooms == null &&
      bathrooms == null &&
      minPrice == null &&
      maxPrice == null;

  /// True when this filter would fetch everything (no facets, no search text).
  bool get isEmpty => hasNoFacets && (search == null || search!.trim().isEmpty);

  /// Number of active facet groups — used for the filter-button badge.
  int get activeCount {
    var n = 0;
    if (listingType != null) n++;
    if (propertyStatus != null || rentPeriod != null) n++;
    if (propertyTypeId != null) n++;
    // By name too, for the same reason as [_hasNoLocation] — otherwise the
    // filter badge under-counts a country picked without an id.
    if (countryId != null || countryName != null) n++;
    if (cityId != null || cityName != null) n++;
    if (areaId != null || areaName != null) n++;
    if (bedrooms != null) n++;
    if (bathrooms != null) n++;
    if (minPrice != null || maxPrice != null) n++;
    return n;
  }

  /// Serializes to a query string fragment (`&key=value&...`) ready to append
  /// after `?page=..&perPage=..`. Only non-null fields are included.
  String toQueryString() {
    final buf = StringBuffer();
    void add(String key, Object? value) {
      if (value == null) return;
      final v = value.toString().trim();
      if (v.isEmpty) return;
      buf.write('&$key=${Uri.encodeQueryComponent(v)}');
    }

    add('search', search);
    add('listing_type', listingType);
    add('propertyStatus', propertyStatus);
    add('rentPeriod', rentPeriod?.toLowerCase());
    add('property_type_id', propertyTypeId);
    // Location is filtered by NAME, not id: the backend stores `country_id`/
    // `city_id`/`area_id` as null on announcements and only honors the value-
    // based params (`country`/`city`/`area`). Verified against the dev API —
    // id-based location filters always return 0. If the backend later starts
    // populating the id columns, switch these back to the *_id params.
    add('country', countryName);
    add('city', cityName);
    add('area', areaName);
    add('bedrooms', bedrooms);
    add('bathrooms', bathrooms);
    add('min_price', minPrice?.round());
    add('max_price', maxPrice?.round());
    return buf.toString();
  }

  PropertyFilter copyWith({
    String? search,
    int? listingType,
    int? propertyStatus,
    String? rentPeriod,
    String? propertyTypeId,
    String? propertyTypeName,
    String? countryId,
    String? countryName,
    String? cityId,
    String? cityName,
    String? areaId,
    String? areaName,
    int? bedrooms,
    int? bathrooms,
    double? minPrice,
    double? maxPrice,
  }) {
    return PropertyFilter(
      search: search ?? this.search,
      listingType: listingType ?? this.listingType,
      propertyStatus: propertyStatus ?? this.propertyStatus,
      rentPeriod: rentPeriod ?? this.rentPeriod,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      propertyTypeName: propertyTypeName ?? this.propertyTypeName,
      countryId: countryId ?? this.countryId,
      countryName: countryName ?? this.countryName,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  /// [copyWith] can only *set* values (a `null` argument means "keep"). This
  /// variant lets callers explicitly clear individual fields — needed when the
  /// user deselects a facet or a parent change invalidates a child (e.g.
  /// changing country must clear city + area).
  PropertyFilter cleared({
    bool search = false,
    bool listingType = false,
    bool propertyStatus = false,
    bool rentPeriod = false,
    bool propertyType = false,
    bool country = false,
    bool city = false,
    bool area = false,
    bool bedrooms = false,
    bool bathrooms = false,
    bool price = false,
  }) {
    return PropertyFilter(
      search: search ? null : this.search,
      listingType: listingType ? null : this.listingType,
      propertyStatus: propertyStatus ? null : this.propertyStatus,
      rentPeriod: rentPeriod ? null : this.rentPeriod,
      propertyTypeId: propertyType ? null : propertyTypeId,
      propertyTypeName: propertyType ? null : propertyTypeName,
      countryId: country ? null : countryId,
      countryName: country ? null : countryName,
      cityId: city ? null : cityId,
      cityName: city ? null : cityName,
      areaId: area ? null : areaId,
      areaName: area ? null : areaName,
      bedrooms: bedrooms ? null : this.bedrooms,
      bathrooms: bathrooms ? null : this.bathrooms,
      minPrice: price ? null : minPrice,
      maxPrice: price ? null : maxPrice,
    );
  }
}
