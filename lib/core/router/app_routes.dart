abstract final class AppRoutes {
  static const splash = '/splash';

  static const home = '/';
  static const products = '/products';
  static const categories = '/categories';
  static const cart = '/cart';
  static const profile = '/profile';

  static const productDetail = '/products/:productId';
  static const categoryProducts = '/categories/:categoryId';
  static const search = '/search';
  static const wishlist = '/wishlist';

  static const checkout = '/cart/checkout';
  static const orderSuccess = '/cart/checkout/success';

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otpVerify = '/otp-verify';

  static const orders = '/profile/orders';
  static const addresses = '/profile/addresses';
  static const settings = '/profile/settings';
  static const about = '/profile/about';
  static const contact = '/profile/contact';
  static const terms = '/profile/terms';
  static const privacy = '/profile/privacy';

  static String productDetailPath(String id) => '/products/$id';
  static String categoryProductsPath(String id) => '/categories/$id';
}
