# 📱 5amat Handmade — Flutter App Master Plan
> Full-stack Flutter × WordPress/WooCommerce Mobile App Blueprint

---

## 📋 Table of Contents
1. [App Store Acceptance Analysis](#1-app-store-acceptance-analysis)
2. [Tech Stack](#2-tech-stack)
3. [WordPress Setup & Plugin Stack](#3-wordpress-setup--plugin-stack)
4. [App Architecture](#4-app-architecture)
5. [Screen-by-Screen Breakdown](#5-screen-by-screen-breakdown)
6. [WordPress Remote Control System (PHP Snippets)](#6-wordpress-remote-control-system-php-snippets)
7. [WhatsApp Checkout Flow](#7-whatsapp-checkout-flow)
8. [OneSignal Push Notifications](#8-onesignal-push-notifications)
9. [Deep Linking](#9-deep-linking)
10. [Creative Feature Ideas](#10-creative-feature-ideas)
11. [Folder Structure](#11-folder-structure)
12. [Development Phases & Timeline](#12-development-phases--timeline)
13. [Environment & CI/CD](#13-environment--cicd)

---

## 1. App Store Acceptance Analysis

### ✅ Will the app be accepted?

**Short answer: YES — with conditions.**

| Concern | Status | Notes |
|---|---|---|
| No payment gateway | ✅ Safe | WhatsApp redirect = no in-app purchases, no 30% Apple cut issue |
| WhatsApp redirect for orders | ✅ Allowed | Considered "contact seller" flow, widely accepted |
| Push notifications (OneSignal) | ✅ Allowed | Must ask permission on first launch |
| Deep linking | ✅ Allowed | Standard practice |
| E-commerce content | ✅ Allowed | Handmade products are fine |
| Real transactions in-app | ⛔ Would be rejected | You are NOT doing this — safe |

### ⚠️ Things You MUST Do for Approval

#### Apple App Store
- [ ] Add Privacy Policy URL (required for any app with accounts)
- [ ] Add proper App Privacy "nutrition label" in App Store Connect (declare data you collect: name, phone, address)
- [ ] Explain the WhatsApp checkout in App Review notes: *"Users complete orders via WhatsApp message to the seller — no in-app payment processing occurs"*
- [ ] Request push notification permission with a **purpose string** in Info.plist: `"We send you order updates and exclusive offers"`
- [ ] Do NOT call it a "checkout" button — call it **"Send Order via WhatsApp"** or **"Contact to Order"**

#### Google Play Store
- [ ] Fill out Data Safety section — declare name, phone, location (approximate)
- [ ] Target SDK 34+ (required from 2024)
- [ ] Add a privacy policy page (can be hosted on your WordPress site)

---

## 2. Tech Stack

```
Flutter (Dart) — Cross-platform UI
├── State Management   → Riverpod (or BLoC)
├── HTTP/API           → Dio + Retrofit
├── Local Storage      → Hive (cart, favourites, user prefs)
├── Navigation         → GoRouter (required for deep linking)
├── Images             → CachedNetworkImage
├── Push Notifications → OneSignal Flutter SDK
├── WhatsApp           → url_launcher
├── Deep Links         → app_links + GoRouter
├── Ads (optional)     → google_mobile_ads
└── Crash Reporting    → Firebase Crashlytics

WordPress Backend
├── WooCommerce        → Products, Categories, Orders API
├── WooCommerce REST API (v3) → All product/category data
├── ACF (Advanced Custom Fields) → App settings, banners, text
├── Custom REST Endpoints (PHP) → App config, notifications trigger
└── OneSignal WP Plugin → Push from WordPress dashboard
```

### Key Flutter Packages (`pubspec.yaml`)

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  dio: ^5.4.3
  retrofit: ^4.1.0
  hive_flutter: ^1.1.0
  go_router: ^14.0.0
  cached_network_image: ^3.3.1
  onesignal_flutter: ^5.2.5
  url_launcher: ^6.2.5
  app_links: ^6.1.0
  carousel_slider: ^5.0.0
  flutter_staggered_grid_view: ^0.7.0
  badges: ^3.1.2
  shimmer: ^3.0.0
  lottie: ^3.1.0
  share_plus: ^9.0.0
  image_picker: ^1.1.2
  connectivity_plus: ^6.0.3
```

---

## 3. WordPress Setup & Plugin Stack

### Required Plugins

| Plugin | Purpose | Free/Paid |
|---|---|---|
| **WooCommerce** | Products, orders, categories | Free |
| **Advanced Custom Fields (ACF)** | App remote config panel | Free |
| **OneSignal Push Notifications** | Send notifications from WP dashboard | Free |
| **JWT Authentication for WP REST API** | Secure login tokens | Free |
| **WP Application Passwords** | API auth (built into WP 5.6+) | Built-in |
| **WooCommerce Blocks** | Optional | Free |

### ACF Setup — App Remote Control Panel

Create an ACF Options Page called **"App Settings"** with these fields:

```
Group: App Banner
  - banner_images[] (image repeater)
  - banner_links[] (URL or product ID)

Group: App Text
  - home_welcome_text (text)
  - home_subtitle (text)
  - promo_badge_text (text, e.g. "NEW", "HOT", "SALE")

Group: App Config
  - maintenance_mode (true/false)
  - maintenance_message (textarea)
  - force_update_version (text, e.g. "1.2.0")
  - force_update_message (textarea)
  - whatsapp_number (text, e.g. "201XXXXXXXXX")
  - whatsapp_greeting_text (textarea)

Group: Featured Products
  - featured_product_ids[] (relationship field → WooCommerce products)

Group: Deep Link Promotions
  - promo_deep_link (text)
  - promo_banner (image)
```

---

## 4. App Architecture

### Clean Architecture Layers

```
lib/
├── core/
│   ├── api/          ← Dio client, interceptors, WooCommerce base URL
│   ├── theme/        ← Colors, typography, spacing
│   ├── router/       ← GoRouter with deep link config
│   └── utils/        ← Extensions, helpers
│
├── features/
│   ├── home/
│   ├── shop/
│   ├── product_detail/
│   ├── categories/
│   ├── cart/
│   ├── checkout/     ← WhatsApp order screen
│   ├── favourites/
│   ├── profile/
│   ├── notifications/
│   └── search/
│
└── shared/
    ├── widgets/      ← Reusable UI components
    ├── models/       ← Product, Category, CartItem, AppConfig
    └── providers/    ← Global Riverpod providers
```

### API Base Configuration

```dart
// lib/core/api/api_client.dart

class ApiClient {
  static const String baseUrl = 'https://5amat-handmade.com/wp-json';
  static const String wcBase  = '$baseUrl/wc/v3';
  static const String appBase = '$baseUrl/app/v1'; // Custom endpoints

  // WooCommerce keys (read-only consumer key/secret)
  // Store securely using --dart-define or flutter_secure_storage
  static const String ck = String.fromEnvironment('WC_CK');
  static const String cs = String.fromEnvironment('WC_CS');
}
```

---

## 5. Screen-by-Screen Breakdown

### 5.1 Splash & Onboarding

```
SplashScreen
  ├── Show logo + animation (Lottie)
  ├── Call /app/v1/config endpoint
  ├── Check: force_update_version → show update dialog if needed
  ├── Check: maintenance_mode → show maintenance screen if true
  └── Navigate to HomeScreen

OnboardingScreen (first launch only)
  ├── 3 slides: "Handmade with love", "Browse categories", "Order via WhatsApp"
  ├── Store "onboarding_seen" in Hive
  └── Request notification permission (OneSignal) on last slide
```

### 5.2 Home Screen

```
HomeScreen
├── AppBar: Logo + Search icon + Cart badge icon
├── BannerCarousel (auto-play, from ACF banner_images[])
│     └── Each banner tap → deep link or product detail
├── WelcomeText (from ACF home_welcome_text)
├── HorizontalCategoryScroller
│     └── Tapping a category → ShopScreen filtered by category
├── Section: "Featured Products"
│     └── Horizontal scroll card grid (from ACF featured_product_ids[])
├── Section: "New Arrivals"
│     └── 2-column grid, latest WooCommerce products
├── Section: "Flash Sale" (if promo_badge_text == "SALE")
│     └── Products with sale_price set
└── BottomNavigationBar (5 tabs: Home, Shop, Cart, Favourites, Profile)
```

### 5.3 Shop Screen

```
ShopScreen
├── Search Bar (client-side filter or WooCommerce search API)
├── Filter Chips: Category, Price, Sort (newest, popular, price asc/desc)
├── StaggeredGridView of ProductCards
│     Each ProductCard shows:
│     ├── Product image (CachedNetworkImage)
│     ├── Product name
│     ├── Price (with strikethrough if on sale)
│     ├── Heart icon (add to favourites)
│     └── "Add to Cart" quick button
└── Pagination (load more on scroll)
```

### 5.4 Product Detail Screen

```
ProductDetailScreen
├── Image gallery (PageView with dots indicator)
├── Product name + price
├── Sale badge (if applicable)
├── Description (HTML rendered via flutter_html)
├── Variations (if product has attributes, e.g. color, size)
├── Quantity selector (+/-)
├── "Add to Cart" button
├── "Add to Favourites" heart button
├── Share button → share product link
├── Related Products horizontal scroll
└── Route: /product/:id (supports deep linking)
```

### 5.5 Categories Screen

```
CategoriesScreen
├── Grid of category cards with image + name
├── Category image from WooCommerce category thumbnail
└── Tap → ShopScreen filtered by category_id
```

### 5.6 Cart Screen

```
CartScreen (stored in Hive — fully offline)
├── List of CartItems (image, name, qty, price)
├── Swipe to delete
├── Quantity +/- per item
├── Promo code field (optional, for future)
├── Order Summary: subtotal, items count
└── "Proceed to Order" button → CheckoutScreen
```

### 5.7 Checkout / WhatsApp Order Screen

```
CheckoutScreen
├── Form fields:
│   ├── Full Name *
│   ├── Phone Number *
│   ├── City / Governorate (dropdown — Egyptian cities)
│   ├── Full Address *
│   ├── Notes (optional)
│   └── Preferred Delivery Time (optional)
├── Order Summary (read-only, from cart)
├── "Confirm & Send via WhatsApp" button
│     └── Builds message → opens WhatsApp
└── "Order sent!" success animation (Lottie) after WhatsApp opens
```

**WhatsApp Message Template:**
```
🌸 طلب جديد - 5امات هاندميد 🌸

👤 الاسم: [name]
📱 رقم الهاتف: [phone]
🏙️ المحافظة: [city]
📍 العنوان: [address]

🛍️ الطلبات:
[item 1: name × qty = price]
[item 2: name × qty = price]
...

💰 الإجمالي: [total] ج.م

📝 ملاحظات: [notes]
⏰ وقت التسليم المفضل: [time]
```

### 5.8 Favourites Screen

```
FavouritesScreen
├── Stored in Hive (product IDs)
├── Re-fetches product data from WooCommerce API on load
├── Same ProductCard as ShopScreen
├── Empty state: cute Lottie animation + "No favourites yet"
└── Swipe to remove
```

### 5.9 Profile Screen

```
ProfileScreen
├── Guest mode (no login required — just local data)
├── Display: saved name, phone from last order
├── My Orders History (stored locally in Hive)
├── Favourites count shortcut
├── Settings:
│   ├── Language toggle (Arabic/English — optional)
│   ├── Notifications toggle
│   └── About / Privacy Policy (opens WebView)
└── Contact Us → opens WhatsApp
```

### 5.10 Search Screen

```
SearchScreen
├── Search input (debounced 500ms)
├── Recent searches (from Hive)
├── Live results from WooCommerce ?search= param
└── Empty state with suggestions
```

---

## 6. WordPress Remote Control System (PHP Snippets)

Add all snippets to your theme's `functions.php` or a custom plugin, or use the **Code Snippets** plugin.

### 6.1 Register App Config Endpoint

```php
// GET /wp-json/app/v1/config
// Returns banners, texts, whatsapp number, force update, maintenance

add_action('rest_api_init', function () {
    register_rest_route('app/v1', '/config', [
        'methods'  => 'GET',
        'callback' => 'app_get_config',
        'permission_callback' => '__return_true',
    ]);
});

function app_get_config() {
    $options = [
        // Banners
        'banners' => [],

        // App text (from ACF options)
        'home_welcome_text'   => get_field('home_welcome_text', 'option'),
        'home_subtitle'       => get_field('home_subtitle', 'option'),
        'promo_badge_text'    => get_field('promo_badge_text', 'option'),

        // WhatsApp
        'whatsapp_number'     => get_field('whatsapp_number', 'option'),
        'whatsapp_greeting'   => get_field('whatsapp_greeting_text', 'option'),

        // Force update
        'force_update_version' => get_field('force_update_version', 'option'),
        'force_update_message' => get_field('force_update_message', 'option'),

        // Maintenance
        'maintenance_mode'    => (bool) get_field('maintenance_mode', 'option'),
        'maintenance_message' => get_field('maintenance_message', 'option'),

        // Featured product IDs
        'featured_product_ids' => [],

        // Promo deep link
        'promo_deep_link'     => get_field('promo_deep_link', 'option'),
        'promo_banner'        => '',
    ];

    // Build banners array
    $banners_raw = get_field('banner_images', 'option');
    if (is_array($banners_raw)) {
        foreach ($banners_raw as $i => $row) {
            $options['banners'][] = [
                'image' => $row['image']['url'] ?? '',
                'link'  => $row['link'] ?? '',
            ];
        }
    }

    // Build featured products
    $featured_raw = get_field('featured_product_ids', 'option');
    if (is_array($featured_raw)) {
        $options['featured_product_ids'] = array_map(fn($p) => $p->ID, $featured_raw);
    }

    // Promo banner image
    $promo_img = get_field('promo_banner', 'option');
    if ($promo_img) {
        $options['promo_banner'] = $promo_img['url'];
    }

    return rest_ensure_response($options);
}
```

### 6.2 Send Push Notification from WordPress (OneSignal)

```php
// Adds a "Send App Notification" meta box to WooCommerce products
// and an "App Notifications" admin menu page

// ---- Admin Menu Page ----
add_action('admin_menu', function () {
    add_menu_page(
        'App Notifications',
        '📱 App Notifications',
        'manage_options',
        'app-notifications',
        'app_notifications_page',
        'dashicons-bell',
        58
    );
});

function app_notifications_page() {
    if (isset($_POST['send_notif'])) {
        $title   = sanitize_text_field($_POST['notif_title']);
        $message = sanitize_textarea_field($_POST['notif_message']);
        $link    = sanitize_text_field($_POST['notif_link']); // deep link e.g. 5amat://product/123

        $result = app_send_onesignal_notification($title, $message, $link);
        echo '<div class="notice notice-success"><p>Notification sent! Response: ' . esc_html(json_encode($result)) . '</p></div>';
    }
    ?>
    <div class="wrap">
        <h1>📱 Send App Push Notification</h1>
        <form method="post">
            <table class="form-table">
                <tr>
                    <th>Title</th>
                    <td><input type="text" name="notif_title" class="regular-text" required /></td>
                </tr>
                <tr>
                    <th>Message</th>
                    <td><textarea name="notif_message" rows="4" class="large-text" required></textarea></td>
                </tr>
                <tr>
                    <th>Deep Link (optional)</th>
                    <td>
                        <input type="text" name="notif_link" class="regular-text"
                               placeholder="5amat://product/123 or 5amat://category/rings" />
                        <p class="description">Leave empty for home screen. Use deep link format for specific screens.</p>
                    </td>
                </tr>
            </table>
            <?php submit_button('Send Notification', 'primary', 'send_notif'); ?>
        </form>
    </div>
    <?php
}

// ---- OneSignal API Call ----
function app_send_onesignal_notification($title, $message, $url = '') {
    $onesignal_app_id   = 'YOUR_ONESIGNAL_APP_ID';   // Replace with your OneSignal App ID
    $onesignal_rest_key = 'YOUR_ONESIGNAL_REST_KEY';  // Replace with your REST API Key

    $payload = [
        'app_id'            => $onesignal_app_id,
        'included_segments' => ['All'],
        'headings'          => ['en' => $title, 'ar' => $title],
        'contents'          => ['en' => $message, 'ar' => $message],
    ];

    if (!empty($url)) {
        $payload['url'] = $url; // OneSignal will open this URL/deep link on tap
        $payload['data'] = ['deep_link' => $url];
    }

    $response = wp_remote_post('https://onesignal.com/api/v1/notifications', [
        'headers' => [
            'Content-Type'  => 'application/json',
            'Authorization' => 'Basic ' . $onesignal_rest_key,
        ],
        'body'    => json_encode($payload),
        'timeout' => 30,
    ]);

    return json_decode(wp_remote_retrieve_body($response), true);
}
```

### 6.3 Auto-notify on New Product Published

```php
// Automatically sends a push notification when a new product is published

add_action('transition_post_status', function ($new_status, $old_status, $post) {
    if ($new_status === 'publish' && $old_status !== 'publish' && $post->post_type === 'product') {
        $product = wc_get_product($post->ID);
        if (!$product) return;

        $title   = '🌸 منتج جديد وصل!';
        $message = $product->get_name() . ' — اضغط لتشوفيه';
        $link    = '5amat://product/' . $post->ID;

        app_send_onesignal_notification($title, $message, $link);
    }
}, 10, 3);
```

### 6.4 Custom Endpoint: Featured Products with Full Data

```php
// GET /wp-json/app/v1/featured-products
// Returns full product objects for featured IDs set in ACF

add_action('rest_api_init', function () {
    register_rest_route('app/v1', '/featured-products', [
        'methods'             => 'GET',
        'callback'            => 'app_get_featured_products',
        'permission_callback' => '__return_true',
    ]);
});

function app_get_featured_products() {
    $ids_raw = get_field('featured_product_ids', 'option');
    if (empty($ids_raw)) return rest_ensure_response([]);

    $ids = array_map(fn($p) => $p->ID, $ids_raw);

    $products = [];
    foreach ($ids as $id) {
        $product = wc_get_product($id);
        if (!$product || !$product->is_visible()) continue;

        $image_id  = $product->get_image_id();
        $image_url = $image_id ? wp_get_attachment_image_url($image_id, 'woocommerce_single') : wc_placeholder_img_src();

        $products[] = [
            'id'            => $product->get_id(),
            'name'          => $product->get_name(),
            'price'         => $product->get_price(),
            'regular_price' => $product->get_regular_price(),
            'sale_price'    => $product->get_sale_price(),
            'on_sale'       => $product->is_on_sale(),
            'image'         => $image_url,
            'permalink'     => get_permalink($id),
            'slug'          => $product->get_slug(),
        ];
    }

    return rest_ensure_response($products);
}
```

### 6.5 Deep Link Generator for Products & Categories

```php
// Adds a "App Deep Link" field to product and category edit screens

// --- Product Edit Page ---
add_action('woocommerce_product_options_general_product_data', function () {
    global $post;
    $deep_link = '5amat://product/' . $post->ID;
    echo '<div class="options_group">';
    echo '<p class="form-field"><label>📱 App Deep Link</label>';
    echo '<input type="text" value="' . esc_attr($deep_link) . '" readonly style="background:#f0f0f0;width:300px;" />';
    echo '<span class="description"> Copy this to share a direct link to this product in the app.</span>';
    echo '</p></div>';
});

// --- Category Page (Term Edit) ---
add_action('product_cat_edit_form_fields', function ($term) {
    $deep_link = '5amat://category/' . $term->term_id;
    echo '<tr class="form-field">';
    echo '<th>📱 App Deep Link</th>';
    echo '<td>';
    echo '<input type="text" value="' . esc_attr($deep_link) . '" readonly style="background:#f0f0f0;width:300px;" />';
    echo '<p class="description">Copy this to deep link to this category in the app.</p>';
    echo '</td></tr>';
});
```

### 6.6 Receive WhatsApp Order Log (Optional)

```php
// POST /wp-json/app/v1/log-order
// Flutter app calls this after WhatsApp redirect to log the order attempt

add_action('rest_api_init', function () {
    register_rest_route('app/v1', '/log-order', [
        'methods'             => 'POST',
        'callback'            => 'app_log_order',
        'permission_callback' => '__return_true',
    ]);
});

function app_log_order(WP_REST_Request $request) {
    $data = $request->get_json_params();

    // Store as a custom post type "app_order_log" or in a custom DB table
    $post_id = wp_insert_post([
        'post_type'   => 'app_order_log', // register this CPT
        'post_title'  => 'Order from ' . sanitize_text_field($data['name'] ?? 'Unknown'),
        'post_status' => 'publish',
        'meta_input'  => [
            'customer_name'  => sanitize_text_field($data['name'] ?? ''),
            'customer_phone' => sanitize_text_field($data['phone'] ?? ''),
            'customer_city'  => sanitize_text_field($data['city'] ?? ''),
            'order_items'    => json_encode($data['items'] ?? []),
            'order_total'    => floatval($data['total'] ?? 0),
            'order_notes'    => sanitize_textarea_field($data['notes'] ?? ''),
            'sent_at'        => current_time('mysql'),
        ],
    ]);

    if (is_wp_error($post_id)) {
        return new WP_Error('log_failed', 'Failed to log order', ['status' => 500]);
    }

    return rest_ensure_response(['success' => true, 'log_id' => $post_id]);
}
```

---

## 7. WhatsApp Checkout Flow

### Flutter Implementation

```dart
// lib/features/checkout/checkout_screen.dart

class CheckoutScreen extends ConsumerStatefulWidget { ... }

class _CheckoutScreenState extends ConsumerStatefulWidget {
  final _formKey = GlobalKey<FormState>();
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController   = TextEditingController();
  String _selectedCity = 'القاهرة';

  Future<void> _sendOrder(List<CartItem> cartItems) async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Build message
    final items = cartItems.map((item) =>
      '• ${item.name} × ${item.qty} = ${item.totalPrice} ج.م'
    ).join('\n');

    final total = cartItems.fold(0.0, (sum, i) => sum + i.totalPrice);

    final message = '''
🌸 طلب جديد - 5امات هاندميد 🌸

👤 الاسم: ${_nameController.text}
📱 رقم الهاتف: ${_phoneController.text}
🏙️ المحافظة: $_selectedCity
📍 العنوان: ${_addressController.text}

🛍️ الطلبات:
$items

💰 الإجمالي: ${total.toStringAsFixed(2)} ج.م

📝 ملاحظات: ${_notesController.text.isEmpty ? '-' : _notesController.text}
''';

    // 2. Get WhatsApp number from app config
    final config = ref.read(appConfigProvider).value;
    final number = config?.whatsappNumber ?? '201XXXXXXXXX';
    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/$number?text=$encoded';

    // 3. Log order to WordPress (fire and forget)
    _logOrderToWordPress(cartItems, total);

    // 4. Launch WhatsApp
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      // 5. Clear cart
      ref.read(cartProvider.notifier).clearCart();
      // 6. Show success
      _showSuccessAnimation();
    }
  }
}
```

---

## 8. OneSignal Push Notifications

### Flutter Setup

```dart
// lib/main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // OneSignal init
  OneSignal.initialize('YOUR_ONESIGNAL_APP_ID');
  OneSignal.Notifications.requestPermission(true);

  // Handle notification tap → deep link
  OneSignal.Notifications.addClickListener((event) {
    final deepLink = event.notification.additionalData?['deep_link'] as String?;
    if (deepLink != null) {
      // Use GoRouter to navigate
      router.push(Uri.parse(deepLink).path);
    }
  });

  runApp(const ProviderScope(child: App()));
}
```

### Notification Categories (send from WordPress admin)

| Trigger | Title | Message | Deep Link |
|---|---|---|---|
| New product | 🌸 منتج جديد! | [product name] متاح الآن | `5amat://product/:id` |
| Sale starts | 🔥 عرض محدود! | خصم حتى [date] | `5amat://shop?filter=sale` |
| Category promo | 💍 أساور جديدة | شوفي أحدث التصاميم | `5amat://category/:id` |
| Re-engagement | 👋 وحشتينا! | شوفي الجديد في المتجر | `5amat://home` |
| Custom | Admin sets | Admin sets | Admin sets |

---

## 9. Deep Linking

### URL Scheme + Universal Links Strategy

**Custom Scheme:** `5amat://`
**Universal/App Links:** `https://5amat-handmade.com/app/...`

### Route Map

| Deep Link | Screen |
|---|---|
| `5amat://home` | HomeScreen |
| `5amat://shop` | ShopScreen |
| `5amat://shop?filter=sale` | ShopScreen filtered to sale items |
| `5amat://product/123` | ProductDetailScreen (id: 123) |
| `5amat://category/45` | ShopScreen filtered to category 45 |
| `5amat://favourites` | FavouritesScreen |
| `5amat://cart` | CartScreen |
| `5amat://promo` | Special promo screen (from ACF) |

### GoRouter Configuration

```dart
// lib/core/router/app_router.dart

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) => null,
  routes: [
    GoRoute(path: '/',          builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/shop',      builder: (_, s) => ShopScreen(filter: s.uri.queryParameters['filter'])),
    GoRoute(path: '/product/:id', builder: (_, s) => ProductDetailScreen(id: s.pathParameters['id']!)),
    GoRoute(path: '/category/:id', builder: (_, s) => ShopScreen(categoryId: s.pathParameters['id'])),
    GoRoute(path: '/cart',      builder: (_, __) => const CartScreen()),
    GoRoute(path: '/favourites',builder: (_, __) => const FavouritesScreen()),
    GoRoute(path: '/promo',     builder: (_, __) => const PromoScreen()),
  ],
);
```

### WordPress: Add apple-app-site-association & assetlinks

```php
// Serve deep link verification files from WordPress

add_action('init', function () {
    add_rewrite_rule('^\.well-known/apple-app-site-association$', 'index.php?aasa=1', 'top');
    add_rewrite_rule('^\.well-known/assetlinks\.json$', 'index.php?assetlinks=1', 'top');
});

add_filter('query_vars', fn($vars) => array_merge($vars, ['aasa', 'assetlinks']));

add_action('template_redirect', function () {
    if (get_query_var('aasa')) {
        header('Content-Type: application/json');
        echo json_encode([
            'applinks' => [
                'apps' => [],
                'details' => [[
                    'appID'  => 'TEAMID.com.yourcompany.5amat', // Replace
                    'paths'  => ['/app/*'],
                ]]
            ]
        ]);
        exit;
    }
    if (get_query_var('assetlinks')) {
        header('Content-Type: application/json');
        echo json_encode([[
            'relation' => ['delegate_permission/common.handle_all_urls'],
            'target'   => [
                'namespace'              => 'android_app',
                'package_name'           => 'com.yourcompany.fiveamat', // Replace
                'sha256_cert_fingerprints' => ['YOUR_SHA256_FINGERPRINT']
            ]
        ]]);
        exit;
    }
});
```

---

## 10. Creative Feature Ideas

### 🎨 10.1 "Make a Custom Order" Flow
Allow users to describe a custom handmade piece they want.
- Screen with text field + image upload (optional photo of inspiration)
- Sends via WhatsApp with photo using `share_plus`
- **WordPress side:** ACF field to enable/disable this feature remotely

### 💌 10.2 Wishlist Share
- Generate a shareable link to a user's wishlist
- Deep link: `5amat://wishlist?ids=12,45,78`
- Friends can view the wishlist in-app (read-only)
- **PHP:** `GET /app/v1/wishlist?ids=12,45,78` returns product data

### 🎁 10.3 "Gift This" Feature
- Wrap any product as a gift → special WhatsApp message template
- Includes "gift note" field and gift wrap icon on order message
- Toggle on/off from ACF: `gift_wrap_available` field

### 🔔 10.4 "Back in Stock" Alerts
- On out-of-stock product → "Notify me when available" button
- Saves product ID + device OneSignal player ID to WordPress via REST
- WordPress admin sees a list; when they mark product back in stock, triggers push
- **PHP table:** `app_stock_alerts (product_id, onesignal_player_id, created_at)`

### 📅 10.5 "New Collection" Launch Countdown
- ACF fields: `collection_name`, `collection_launch_date`, `collection_teaser_image`
- Flutter shows a countdown timer banner on home screen
- At launch, auto push notification sent (WordPress cron + OneSignal)

### 🌍 10.6 City-based Delivery Time Estimator
- Based on selected city at checkout, show estimated delivery days
- Managed via ACF: `city_delivery_times[]` (city name → days)
- Displayed in checkout before WhatsApp send

### 💬 10.7 Live Order Status via WhatsApp Number
- After placing order, show a "Check My Order Status" button
- Opens WhatsApp with pre-filled message: "مرحبا، أريد الاستفسار عن طلبي - الاسم: [name]"

### 🏅 10.8 Loyalty Points (Visual Only)
- Each order adds points (stored in Hive locally)
- No real backend logic needed — purely visual gamification
- Shows a progress bar to "Gold Customer" status
- Future: sync to WordPress user meta via REST

### 🎲 10.9 "Surprise Me" Button
- Fetches a random product from the WooCommerce API
- Shown with a playful animation
- **PHP:** `GET /app/v1/random-product` → returns one random visible product

### 📸 10.10 AR-Style "Try It On" Placeholder
- For accessories (rings, bracelets), show a fun "style inspiration" gallery
- Curated by admin via ACF image gallery field
- Framed as "How to Style" — avoids AR technical complexity

---

## 11. Folder Structure

```
5amat_app/
├── android/
│   └── app/src/main/AndroidManifest.xml     ← Deep link intent filters
├── ios/
│   └── Runner/Info.plist                    ← URL scheme + notification config
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   ├── woocommerce_service.dart
│   │   │   └── app_config_service.dart
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_theme.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   └── utils/
│   │       ├── whatsapp_helper.dart
│   │       └── currency_formatter.dart
│   ├── features/
│   │   ├── splash/
│   │   ├── onboarding/
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   ├── banner_carousel.dart
│   │   │   ├── category_scroller.dart
│   │   │   └── home_provider.dart
│   │   ├── shop/
│   │   ├── product_detail/
│   │   ├── cart/
│   │   │   ├── cart_screen.dart
│   │   │   ├── cart_item_tile.dart
│   │   │   ├── cart_provider.dart
│   │   │   └── cart_model.dart
│   │   ├── checkout/
│   │   ├── favourites/
│   │   ├── profile/
│   │   ├── search/
│   │   └── notifications/
│   └── shared/
│       ├── widgets/
│       │   ├── product_card.dart
│       │   ├── shimmer_loader.dart
│       │   ├── error_widget.dart
│       │   └── empty_state_widget.dart
│       ├── models/
│       │   ├── product_model.dart
│       │   ├── category_model.dart
│       │   ├── cart_item_model.dart
│       │   └── app_config_model.dart
│       └── providers/
│           ├── app_config_provider.dart
│           └── connectivity_provider.dart
├── assets/
│   ├── images/
│   ├── animations/        ← Lottie JSON files
│   └── fonts/
├── test/
└── pubspec.yaml
```

---

## 12. Development Phases & Timeline

### Phase 1 — Foundation (Week 1–2)
- [x] Set up Flutter project, dependencies, GoRouter
- [x] Configure WooCommerce REST API (read-only keys)
- [x] Build theme (colors, fonts — match website branding)
- [x] Implement app config endpoint in WordPress (PHP snippet #6.1)
- [x] Build ProductModel, CategoryModel from WooCommerce response
- [x] Splash screen + force update + maintenance check

### Phase 2 — Core Screens (Week 3–4)
- [x] HomeScreen with banners (from ACF) + categories + featured products
- [x] ShopScreen with pagination and filters
- [x] ProductDetailScreen with image gallery
- [x] CategoriesScreen
- [x] Cart (Hive) — add/remove/update qty

### Phase 3 — Checkout & Favourites (Week 5)
- [x] CheckoutScreen with form validation
- [x] WhatsApp message builder and launcher
- [x] Order log endpoint (PHP snippet #6.6)
- [x] FavouritesScreen (Hive)
- [x] ProfileScreen with local order history

### Phase 4 — Notifications & Deep Links (Week 6)
- [x] OneSignal Flutter SDK integration
- [x] WordPress notification admin panel (PHP snippet #6.2)
- [x] Auto-notification on new product (PHP snippet #6.3)
- [x] Deep link routing with GoRouter
- [x] Universal links verification files (PHP snippet #9)

### Phase 5 — Creative Features & Polish (Week 7)
- [x] "Surprise Me" random product feature
- [x] "Back in Stock" alert system
- [x] "Gift This" mode in checkout
- [x] Shimmer loading states, Lottie animations
- [x] Offline mode (show cached products)
- [x] RTL (Arabic) layout polish
- [x] "Make a Custom Order" flow (with image attachment)
- [x] Wishlist Sharing (deep link generation & read-only preview)
- [x] Launch Countdown Banner (real-time ticker based on WordPress options)
- [x] Order Status Tracking (pre-filled WhatsApp queries)
- [x] Lookbook Style Gallery (masonry grid & zoomable fullscreen photos)

### Phase 6 — QA & Submission (Week 8)
- [/] Full test on Android + iOS real devices (manifest and configuration verification)
- [ ] App Store metadata: screenshots, description (Arabic + English)
- [ ] Google Play: Data Safety form
- [ ] App Store: Privacy nutrition label + App Review notes
- [/] Build release versions (flutter build apk --release / flutter build ipa)
- [ ] Submit to both stores

---

## 13. Environment & CI/CD

### Secrets Management

```bash
# Build with secrets (never hardcode API keys)
flutter build apk \
  --dart-define=WC_CK=ck_xxxx \
  --dart-define=WC_CS=cs_xxxx \
  --dart-define=ONESIGNAL_APP_ID=xxxxx
```

### Recommended App Metadata

| Field | Value |
|---|---|
| App Name | 5امات هاندميد |
| Bundle ID (iOS) | com.zbooma.fiveamat |
| Package (Android) | com.zbooma.fiveamat |
| Min Android SDK | 23 (Android 6) |
| Min iOS | 13.0 |
| Orientation | Portrait only |
| Primary Language | Arabic |
| Secondary Language | English |

### App Review Notes (Copy-Paste)

```
This app connects customers to a handmade goods store (5amat-handmade.com).

Key flows:
1. Browsing: Products and categories are fetched from a WooCommerce REST API.
2. Cart: Items are stored locally (no account required).
3. Checkout: Users fill in their name, phone, and address. The order is then
   sent to the seller via a pre-filled WhatsApp message. There is NO in-app
   payment processing of any kind.
4. Notifications: We use OneSignal to send push notifications about new products
   and promotions. Users can opt out at any time in device settings.

Test Account: Not required — the app works without login.
```

---

## 📌 Summary Checklist

- [x] App store compliant (WhatsApp checkout = no payment gateway issue)
- [x] Full remote control from WordPress admin panel
- [x] Banners, texts, WhatsApp number — all editable from WP
- [x] Push notifications — send from WP admin or auto on new product
- [x] Deep links — every product, category, and promo screen reachable
- [x] No login required — cart and favourites stored locally in Hive
- [x] 10 creative features implementable with simple PHP snippets
- [x] Arabic-first RTL design
- [x] 8-week development timeline
- [x] CI/CD ready with secure secrets management

---

*Plan authored for 5amat Handmade App — May 2026*
