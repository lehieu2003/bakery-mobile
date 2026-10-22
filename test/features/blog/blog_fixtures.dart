import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';

const postsPath = '/api/blog/posts';
const categoriesPath = '/api/blog/categories';
const tagsPath = '/api/blog/tags';

const postsSuccess = 'blog/posts_success.json';
const postsEmpty = 'blog/posts_empty.json';
const categoriesSuccess = 'blog/categories_success.json';
const tagsSuccess = 'blog/tags_success.json';

List<Map<String, dynamic>> fixturePosts() =>
    ((fixtureData(postsSuccess) as Map)['posts'] as List)
        .cast<Map<String, dynamic>>();

List<String> fixtureCategorySlugs() =>
    ((fixtureData(categoriesSuccess) as Map)['categories'] as List)
        .map((j) => (j as Map)['slug'] as String)
        .toList();

List<String> fixtureTagSlugs() =>
    ((fixtureData(tagsSuccess) as Map)['tags'] as List)
        .map((j) => (j as Map)['slug'] as String)
        .toList();

/// The posts fixture served as page `query.page` of 2, with ids made unique
/// per page.
Object pagedPosts(ApiCall call) {
  final page = call.query!['page'] as int;
  final data = fixtureData(postsSuccess) as Map<String, dynamic>;
  return {
    'posts': [
      for (final post in data['posts'] as List)
        {...post as Map<String, dynamic>, 'id': '${post['id']}-p$page'},
    ],
    'pagination': {
      ...data['pagination'] as Map<String, dynamic>,
      'page': page,
      'totalPages': 2,
    },
  };
}

/// Stubs categories + tags with data and posts with [posts].
void stubBlog(FakeApiClient api, {String posts = postsSuccess}) {
  api
    ..stubFixture('GET', categoriesPath, categoriesSuccess)
    ..stubFixture('GET', tagsPath, tagsSuccess)
    ..stubFixture('GET', postsPath, posts);
}
