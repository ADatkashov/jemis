import '../../../core/form_result.dart';
import '../../../core/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/util/format.dart';

// ------------------------------------------------------------------ categories

class AdminCategory {
  const AdminCategory({
    this.id,
    this.parentId,
    required this.slug,
    required this.nameRu,
    required this.nameKk,
    required this.nameEn,
    this.icon,
    this.imageUrl,
    this.sortOrder = 0,
    this.active = true,
  });
  final String? id, parentId, icon, imageUrl;
  final String slug, nameRu, nameKk, nameEn;
  final int sortOrder;
  final bool active;

  factory AdminCategory.fromJson(Map<String, dynamic> j) => AdminCategory(
        id: j['id'] as String?,
        parentId: j['parentId'] as String?,
        slug: asStr(j['slug']),
        nameRu: asStr(j['nameRu']),
        nameKk: asStr(j['nameKk']),
        nameEn: asStr(j['nameEn']),
        icon: j['icon'] as String?,
        imageUrl: j['imageUrl'] as String?,
        sortOrder: asInt(j['sortOrder']),
        active: j['active'] as bool? ?? true,
      );

  Map<String, dynamic> toBody() => {
        'parentId': parentId,
        'slug': slug,
        'nameRu': nameRu,
        'nameKk': nameKk,
        'nameEn': nameEn,
        'icon': icon,
        'imageUrl': imageUrl,
        'sortOrder': sortOrder,
        'active': active,
      };
}

final _slugRe = RegExp(r'^[a-z0-9-]+$');

/// Validates the category form; trims text and drops blank optionals.
FormResult<AdminCategory> validateCategory({
  String? id,
  String? parentId,
  required String slug,
  required String nameRu,
  required String nameKk,
  required String nameEn,
  String icon = '',
  String? imageUrl,
  String sortOrder = '0',
  bool active = true,
}) {
  final s = slug.trim();
  if (s.isEmpty || nameRu.trim().isEmpty || nameKk.trim().isEmpty || nameEn.trim().isEmpty) return const FormResult.fail(FormError.required);
  if (!_slugRe.hasMatch(s)) return const FormResult.fail(FormError.invalidSlug);
  final sort = int.tryParse(sortOrder.trim().isEmpty ? '0' : sortOrder.trim());
  if (sort == null) return const FormResult.fail(FormError.invalidNumber);
  return FormResult.ok(AdminCategory(
    id: id,
    parentId: parentId,
    slug: s,
    nameRu: nameRu.trim(),
    nameKk: nameKk.trim(),
    nameEn: nameEn.trim(),
    icon: icon.trim().isEmpty ? null : icon.trim(),
    imageUrl: imageUrl,
    sortOrder: sort,
    active: active,
  ));
}

// ------------------------------------------------------------------ products

const productUnits = ['PIECE', 'KG', 'G', 'L', 'ML', 'PACK'];

class AdminProduct {
  const AdminProduct({
    this.id,
    required this.categoryId,
    required this.sku,
    this.brand,
    required this.nameRu,
    required this.nameKk,
    required this.nameEn,
    this.descriptionRu,
    this.descriptionKk,
    this.descriptionEn,
    this.unit = 'PIECE',
    this.weighted = false,
    this.stepMilli = 1000,
    this.packLabel,
    this.priceMinor = 0,
    this.oldPriceMinor,
    this.imageUrl,
    this.stockMilli = 0,
    this.reservedMilli = 0,
    this.lowStockMilli = 5000,
    this.active = true,
  });

  final String? id, brand, descriptionRu, descriptionKk, descriptionEn, packLabel, imageUrl;
  final String categoryId, sku, nameRu, nameKk, nameEn, unit;
  final bool weighted, active;
  final int stepMilli, priceMinor, stockMilli, reservedMilli, lowStockMilli;
  final int? oldPriceMinor;

  factory AdminProduct.fromJson(Map<String, dynamic> j) => AdminProduct(
        id: j['id'] as String?,
        categoryId: asStr(j['categoryId']),
        sku: asStr(j['sku']),
        brand: j['brand'] as String?,
        nameRu: asStr(j['nameRu']),
        nameKk: asStr(j['nameKk']),
        nameEn: asStr(j['nameEn']),
        descriptionRu: j['descriptionRu'] as String?,
        descriptionKk: j['descriptionKk'] as String?,
        descriptionEn: j['descriptionEn'] as String?,
        unit: (j['unit'] as String?) ?? 'PIECE',
        weighted: j['weighted'] as bool? ?? false,
        stepMilli: asInt(j['stepMilli']),
        packLabel: j['packLabel'] as String?,
        priceMinor: asInt(j['priceMinor']),
        oldPriceMinor: asIntOrNull(j['oldPriceMinor']),
        imageUrl: j['imageUrl'] as String?,
        stockMilli: asInt(j['stockMilli']),
        reservedMilli: asInt(j['reservedMilli']),
        lowStockMilli: j['lowStockMilli'] == null ? 5000 : asInt(j['lowStockMilli']),
        active: j['active'] as bool? ?? true,
      );
}

String? _blankToNull(String s) => s.trim().isEmpty ? null : s.trim();

/// Form values of the product dialog; [priceText]/[oldPriceText] are what the user typed (tenge).
class ProductInput {
  const ProductInput({
    this.id,
    required this.categoryId,
    required this.sku,
    this.brand = '',
    required this.nameRu,
    required this.nameKk,
    required this.nameEn,
    this.descriptionRu = '',
    this.descriptionKk = '',
    this.descriptionEn = '',
    this.unit = 'PIECE',
    this.weighted = false,
    this.stepText = '1000',
    this.packLabel = '',
    required this.priceText,
    this.oldPriceText = '',
    this.imageUrl = '',
    this.lowStockMilli = 5000,
    this.active = true,
  });
  final String? id;
  final String categoryId, sku, brand, nameRu, nameKk, nameEn, descriptionRu, descriptionKk, descriptionEn, unit, stepText, packLabel, priceText, oldPriceText, imageUrl;
  final bool weighted, active;
  final int lowStockMilli;

  /// Validates and builds the request body. The previous price must exceed the price.
  FormResult<Map<String, dynamic>> toBody() {
    if (sku.trim().isEmpty || nameRu.trim().isEmpty || nameKk.trim().isEmpty || nameEn.trim().isEmpty) {
      return const FormResult.fail(FormError.required);
    }
    final price = parseMoney(priceText);
    final old = oldPriceText.trim().isEmpty ? null : parseMoney(oldPriceText);
    if (price == null || (oldPriceText.trim().isNotEmpty && old == null)) return const FormResult.fail(FormError.invalidPrice);
    if (old != null && old <= price) return const FormResult.fail(FormError.prevPriceHigher);
    final step = int.tryParse(stepText.trim());
    if (step == null || step < 1) return const FormResult.fail(FormError.invalidNumber);
    return FormResult.ok({
      'categoryId': categoryId,
      'sku': sku.trim(),
      'brand': _blankToNull(brand),
      'nameRu': nameRu.trim(),
      'nameKk': nameKk.trim(),
      'nameEn': nameEn.trim(),
      'descriptionRu': _blankToNull(descriptionRu),
      'descriptionKk': _blankToNull(descriptionKk),
      'descriptionEn': _blankToNull(descriptionEn),
      'unit': unit,
      'weighted': weighted,
      'stepMilli': step,
      'packLabel': _blankToNull(packLabel),
      'priceMinor': price,
      'oldPriceMinor': old,
      'imageUrl': _blankToNull(imageUrl),
      'lowStockMilli': lowStockMilli,
      'active': active,
    });
  }
}

class ProductQuery {
  const ProductQuery({this.q = '', this.page = 0});
  final String q;
  final int page;
  @override
  bool operator ==(Object other) => other is ProductQuery && other.q == q && other.page == page;
  @override
  int get hashCode => Object.hash(q, page);
}

class CatalogAdminRepository {
  CatalogAdminRepository(this._api);
  final ApiClient _api;

  Future<List<AdminCategory>> categories() async => asList(await _api.get('/admin/categories')).map(AdminCategory.fromJson).toList();
  Future<void> saveCategory(AdminCategory c) =>
      c.id == null ? _api.post('/admin/categories', body: c.toBody()) : _api.put('/admin/categories/${c.id}', body: c.toBody());

  Future<Paged<AdminProduct>> products(ProductQuery q) async {
    final r = await _api.get('/admin/products', query: {'size': 25, 'page': q.page, 'q': q.q});
    return Paged.fromJson(r as Map<String, dynamic>, AdminProduct.fromJson);
  }

  Future<void> saveProduct(String? id, Map<String, dynamic> body) =>
      id == null ? _api.post('/admin/products', body: body) : _api.put('/admin/products/$id', body: body);

  Future<void> adjustStock(String id, int deltaMilli, String reason) =>
      _api.post('/admin/products/$id/stock', body: {'deltaMilli': deltaMilli, 'reason': reason});
}

/// Stock adjustment form: signed quantity ("10", "-2.5") plus a mandatory reason.
FormResult<({int delta, String reason})> validateStockAdjustment(String delta, String reason) {
  final d = parseSignedQuantity(delta);
  if (d == null || reason.trim().isEmpty) return const FormResult.fail(FormError.enterQtyReason);
  return FormResult.ok((delta: d, reason: reason.trim()));
}
