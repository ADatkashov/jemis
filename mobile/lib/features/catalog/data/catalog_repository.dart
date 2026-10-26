import 'package:dio/dio.dart';

import '../../../core/models.dart';
import '../../../core/network/api_client.dart';

class ProductFilter {
  const ProductFilter({this.query = '', this.categoryId, this.sort = 'popularity', this.minPriceMinor, this.maxPriceMinor, this.inStock = false, this.discounted = false});
  final String query;
  final String? categoryId;
  final String sort;
  final int? minPriceMinor;
  final int? maxPriceMinor;
  final bool inStock;
  final bool discounted;

  ProductFilter copyWith({String? query, Object? categoryId = _keep, String? sort, Object? minPriceMinor = _keep, Object? maxPriceMinor = _keep, bool? inStock, bool? discounted}) =>
      ProductFilter(
        query: query ?? this.query,
        categoryId: identical(categoryId, _keep) ? this.categoryId : categoryId as String?,
        sort: sort ?? this.sort,
        minPriceMinor: identical(minPriceMinor, _keep) ? this.minPriceMinor : minPriceMinor as int?,
        maxPriceMinor: identical(maxPriceMinor, _keep) ? this.maxPriceMinor : maxPriceMinor as int?,
        inStock: inStock ?? this.inStock,
        discounted: discounted ?? this.discounted,
      );

  static const _keep = Object();

  bool get hasActiveFilters => minPriceMinor != null || maxPriceMinor != null || inStock || discounted;

  Map<String, dynamic> toQuery(int page, int size) => {
        'page': page,
        'size': size,
        'sort': sort,
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (categoryId != null) 'categoryId': categoryId,
        if (minPriceMinor != null) 'minPrice': minPriceMinor,
        if (maxPriceMinor != null) 'maxPrice': maxPriceMinor,
        if (inStock) 'inStock': true,
        if (discounted) 'discounted': true,
      };

  @override
  bool operator ==(Object other) =>
      other is ProductFilter &&
      other.query == query &&
      other.categoryId == categoryId &&
      other.sort == sort &&
      other.minPriceMinor == minPriceMinor &&
      other.maxPriceMinor == maxPriceMinor &&
      other.inStock == inStock &&
      other.discounted == discounted;

  @override
  int get hashCode => Object.hash(query, categoryId, sort, minPriceMinor, maxPriceMinor, inStock, discounted);
}

class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  Future<HomeFeed> home() async => HomeFeed.fromJson(await _api.get('/catalog/home') as Map<String, dynamic>);

  Future<List<Category>> categories() async =>
      (await _api.get('/catalog/categories') as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();

  /// Search runs on the backend; [cancel] aborts an obsolete request when the user keeps typing.
  Future<Paged<Product>> products(ProductFilter f, int page, {int size = 20, CancelToken? cancel}) async =>
      Paged.fromJson(await _api.get('/catalog/products', query: f.toQuery(page, size), cancel: cancel) as Map<String, dynamic>, Product.fromJson);

  Future<ProductDetail> product(String id) async =>
      ProductDetail.fromJson(await _api.get('/catalog/products/$id') as Map<String, dynamic>);
}
