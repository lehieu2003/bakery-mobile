import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';

const bannersPath = '/api/public/banners';
const categoriesPath = '/api/public/categories';
const bestSellersPath = '/api/public/products/best-sellers';
const personalizedPath = '/api/public/products/personalized';
const productsPath = '/api/public/products';
const filtersPath = '/api/public/products/filters';

const bannersSuccess = 'catalog/banners_success.json';
const categoriesSuccess = 'catalog/categories_success.json';
const bestSellersSuccess = 'catalog/best_sellers_success.json';
const bestSellersEmpty = 'catalog/best_sellers_empty.json';
const personalizedSuccess = 'catalog/personalized_success.json';
const personalizedEmpty = 'catalog/personalized_empty.json';
const productsSuccess = 'catalog/products_success.json';
const productsEmpty = 'catalog/products_empty.json';
const filtersSuccess = 'catalog/filters_success.json';

List<String> idsOf(String fixtureName, String listKey) =>
    ((fixtureData(fixtureName) as Map)[listKey] as List)
        .map((j) => (j as Map)['id'] as String)
        .toList();

int productsTotal() =>
    ((fixtureData(productsSuccess) as Map)['pagination'] as Map)['total']
        as int;

/// Stubs every request the home screen makes on open.
void stubHome(
  FakeApiClient api, {
  String bestSellers = bestSellersSuccess,
  String personalized = personalizedSuccess,
}) {
  api
    ..stubFixture('GET', bannersPath, bannersSuccess)
    ..stubFixture('GET', categoriesPath, categoriesSuccess)
    ..stubFixture('GET', bestSellersPath, bestSellers)
    ..stubFixture('GET', personalizedPath, personalized)
    ..stub('GET', '/api/notifications', (_) => {'notifications': []})
    ..stub('GET', '/api/wishlist', (_) => {'wishlist': []});
}

/// The products fixture served as page `query.page`, with ids made unique
/// per page (the real list is never repeated across pages).
Object pagedProducts(ApiCall call) {
  final page = call.query!['page'] as int;
  final data = fixtureData(productsSuccess) as Map<String, dynamic>;
  return {
    ...data,
    'products': [
      for (final product in data['products'] as List)
        {...product as Map<String, dynamic>, 'id': '${product['id']}-p$page'},
    ],
    'pagination': {...data['pagination'] as Map<String, dynamic>, 'page': page},
  };
}

/// Stubs filters + products for the search screen.
void stubSearch(FakeApiClient api, {String products = productsSuccess}) {
  api
    ..stubFixture('GET', filtersPath, filtersSuccess)
    ..stubFixture('GET', productsPath, products);
}
