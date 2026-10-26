import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/money.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart';
import '../data/catalog_repository.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key, this.categoryId, this.sort, this.discounted = false, this.focusSearch = false});
  final String? categoryId;
  final String? sort;
  final bool discounted;
  final bool focusSearch;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productListProvider.notifier).setFilter(ProductFilter(categoryId: widget.categoryId, sort: widget.sort ?? 'popularity', discounted: widget.discounted));
    });
  }

  @override
  void didUpdateWidget(CatalogScreen old) {
    super.didUpdateWidget(old);
    if (old.categoryId != widget.categoryId || old.sort != widget.sort || old.discounted != widget.discounted) {
      _search.clear();
      ref.read(productListProvider.notifier).setFilter(ProductFilter(categoryId: widget.categoryId, sort: widget.sort ?? 'popularity', discounted: widget.discounted));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
      ref.read(productListProvider.notifier).loadMore();
    }
  }

  /// Debounced: only the last keystroke in a 350 ms window hits the backend; older requests are cancelled.
  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final n = ref.read(productListProvider.notifier);
      n.setFilter(ref.read(productListProvider).filter.copyWith(query: q));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final state = ref.watch(productListProvider);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final filter = state.filter;
    final notifier = ref.read(productListProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.catalogTitle),
        actions: [
          IconButton(
            tooltip: l.filters,
            onPressed: () => _openFilters(context),
            icon: Badge(isLabelVisible: filter.hasActiveFilters || filter.sort != 'popularity', child: const Icon(Icons.tune)),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
          child: TextField(
            controller: _search,
            autofocus: widget.focusSearch,
            textInputAction: TextInputAction.search,
            onChanged: _onQuery,
            decoration: InputDecoration(
              hintText: l.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty ? null : IconButton(tooltip: l.close, icon: const Icon(Icons.close), onPressed: () {
                _search.clear();
                _onQuery('');
                setState(() {});
              }),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: Space.l), children: [
            Padding(
              padding: const EdgeInsets.only(right: Space.s),
              child: ChoiceChip(label: Text(l.allCategories), selected: filter.categoryId == null, onSelected: (_) => notifier.setFilter(filter.copyWith(categoryId: null))),
            ),
            for (final c in categories.where((c) => c.parentId == null))
              Padding(
                padding: const EdgeInsets.only(right: Space.s),
                child: ChoiceChip(label: Text(c.name), selected: filter.categoryId == c.id, onSelected: (_) => notifier.setFilter(filter.copyWith(categoryId: c.id))),
              ),
          ]),
        ),
        Expanded(child: _body(context, state)),
      ]),
    );
  }

  Widget _body(BuildContext context, ProductListState state) {
    final l = context.l;
    if (state.items.isEmpty) {
      if (state.error != null) return ErrorView(error: state.error!, onRetry: () => ref.read(productListProvider.notifier).retry());
      if (state.loading || state.page < 0) {
        return GridView.count(padding: const EdgeInsets.all(Space.l), crossAxisCount: 2, mainAxisSpacing: Space.m, crossAxisSpacing: Space.m, childAspectRatio: 0.62, children: List.generate(6, (_) => const ProductCardSkeleton()));
      }
      return EmptyView(
        icon: Icons.search_off,
        title: l.noResults,
        hint: l.noResultsHint,
        actionLabel: state.filter.hasActiveFilters || state.filter.query.isNotEmpty ? l.resetFilters : null,
        onAction: () {
          _search.clear();
          ref.read(productListProvider.notifier).setFilter(ProductFilter(categoryId: state.filter.categoryId));
        },
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(productListProvider.notifier).reload(),
      child: GridView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(Space.l),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: Space.m, crossAxisSpacing: Space.m, childAspectRatio: 0.62),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= state.items.length) {
            return state.error != null
                ? Center(child: OutlinedButton(onPressed: () => ref.read(productListProvider.notifier).retry(), child: Text(l.retry)))
                : const ProductCardSkeleton();
          }
          return ProductCard(product: state.items[i]);
        },
      ),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    final l = context.l;
    var f = ref.read(productListProvider).filter;
    final minC = TextEditingController(text: f.minPriceMinor == null ? '' : (f.minPriceMinor! / 100).toStringAsFixed(0));
    final maxC = TextEditingController(text: f.maxPriceMinor == null ? '' : (f.maxPriceMinor! / 100).toStringAsFixed(0));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.fromLTRB(Space.l, 0, Space.l, MediaQuery.of(ctx).viewInsets.bottom + Space.l),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.sortBy, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: Space.s),
              Wrap(spacing: Space.s, children: [
                for (final (key, label) in [('popularity', l.sortPopularity), ('price_asc', l.sortPriceAsc), ('price_desc', l.sortPriceDesc), ('name', l.sortName), ('newest', l.sortNewest)])
                  ChoiceChip(label: Text(label), selected: f.sort == key, onSelected: (_) => setSheet(() => f = f.copyWith(sort: key))),
              ]),
              const SizedBox(height: Space.l),
              Text(l.priceRange, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: Space.s),
              Row(children: [
                Expanded(child: TextField(controller: minC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.priceFrom))),
                const SizedBox(width: Space.m),
                Expanded(child: TextField(controller: maxC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.priceTo))),
              ]),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l.onlyInStock), value: f.inStock, onChanged: (v) => setSheet(() => f = f.copyWith(inStock: v))),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l.onlyDiscounted), value: f.discounted, onChanged: (v) => setSheet(() => f = f.copyWith(discounted: v))),
              const SizedBox(height: Space.s),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(productListProvider.notifier).setFilter(ProductFilter(query: f.query, categoryId: f.categoryId));
                      Navigator.pop(ctx);
                    },
                    child: Text(l.resetFilters),
                  ),
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final lo = minC.text.trim().isEmpty ? null : parseMoneyInput(minC.text);
                      final hi = maxC.text.trim().isEmpty ? null : parseMoneyInput(maxC.text);
                      ref.read(productListProvider.notifier).setFilter(f.copyWith(minPriceMinor: lo, maxPriceMinor: hi));
                      Navigator.pop(ctx);
                    },
                    child: Text(l.applyFilters),
                  ),
                ),
              ]),
            ]),
          ),
        );
      }),
    );
    minC.dispose();
    maxC.dispose();
  }
}
