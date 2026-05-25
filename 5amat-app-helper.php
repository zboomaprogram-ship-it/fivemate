<?php
/**
 * Plugin Name: 5amat App Helper
 * Description: Registers ACF REST API configurations, deep linking associations, push notifications triggers, and order logging endpoints for the 5amat Handmade Flutter mobile app.
 * Version: 1.0.0
 * Author: Shemais
 * License: GPL2
 */

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly
}

// ==========================================
// 1. REGISTER OPTIONS PAGE AND FIELD GROUP
// ==========================================

// Define option helper that supports both ACF get_field option format and WordPress get_option native fallbacks
function app_get_option($key, $default = '')
{
    if (function_exists('get_field')) {
        $val = get_field($key, 'option');
        if ($val !== null && $val !== false) {
            return $val;
        }
    }
    return get_option('options_' . $key, $default);
}

// Add custom "App Settings" admin menu page that works completely natively without external plugins
add_action('admin_menu', function () {
    add_menu_page(
        'App Settings',
        '📱 App Settings',
        'manage_options',
        'app-settings',
        'app_settings_page',
        'dashicons-admin-generic',
        57
    );
});

// Render the native settings page and handle option updates
function app_settings_page()
{
    if (isset($_POST['save_settings'])) {
        update_option('options_home_welcome_text', sanitize_text_field($_POST['home_welcome_text']));
        update_option('options_home_subtitle', sanitize_text_field($_POST['home_subtitle']));
        update_option('options_promo_badge_text', sanitize_text_field($_POST['promo_badge_text']));
        update_option('options_whatsapp_number', sanitize_text_field($_POST['whatsapp_number']));
        update_option('options_whatsapp_greeting_text', sanitize_textarea_field($_POST['whatsapp_greeting_text']));
        update_option('options_support_email', sanitize_email($_POST['support_email']));
        update_option('options_onesignal_app_id', sanitize_text_field($_POST['onesignal_app_id']));
        update_option('options_onesignal_rest_key', sanitize_text_field($_POST['onesignal_rest_key']));
        update_option('options_maintenance_mode', isset($_POST['maintenance_mode']) ? 1 : 0);
        update_option('options_maintenance_message', sanitize_textarea_field($_POST['maintenance_message']));
        update_option('options_force_update_version', sanitize_text_field($_POST['force_update_version']));
        update_option('options_force_update_message', sanitize_textarea_field($_POST['force_update_message']));
        update_option('options_collection_name', sanitize_text_field($_POST['collection_name']));

        // Dynamic human-readable launch date auto-parsing to ISO format
        $launch_input = sanitize_text_field($_POST['collection_launch_date']);
        $date_parsed = strtotime($launch_input);
        if ($date_parsed !== false) {
            $launch_input = date('c', $date_parsed);
        }
        update_option('options_collection_launch_date', $launch_input);

        update_option('options_collection_teaser_image', sanitize_text_field($_POST['collection_teaser_image']));
        update_option('options_promo_banner', sanitize_text_field($_POST['promo_banner']));
        update_option('options_promo_deep_link', sanitize_text_field($_POST['promo_deep_link']));
        update_option('options_custom_order_enabled', isset($_POST['custom_order_enabled']) ? 1 : 0);

        // Process Banners (line-separated list of URLs)
        $banners_input = sanitize_textarea_field($_POST['banner_images']);
        $banners_lines = array_filter(array_map('trim', explode("\n", $banners_input)));
        $banners_array = [];
        foreach ($banners_lines as $line) {
            if (!empty($line)) {
                $banners_array[] = [
                    'image' => $line,
                    'link' => ''
                ];
            }
        }
        update_option('options_banner_images', $banners_array);

        // Process Style Gallery (line-separated list of URLs)
        $gallery_input = sanitize_textarea_field($_POST['style_gallery']);
        $gallery_lines = array_filter(array_map('trim', explode("\n", $gallery_input)));
        $gallery_array = [];
        foreach ($gallery_lines as $line) {
            if (!empty($line)) {
                $gallery_array[] = [
                    'image_url' => $line
                ];
            }
        }
        update_option('options_style_gallery', $gallery_array);

        // Process Featured Products
        $featured_input = sanitize_text_field($_POST['featured_product_ids']);
        $featured_ids = array_filter(array_map('intval', explode(',', $featured_input)));
        update_option('options_featured_product_ids', $featured_ids);

        echo '<div class="notice notice-success"><p>Settings saved successfully!</p></div>';
    }

    // Load options
    $home_welcome_text = get_option('options_home_welcome_text', 'أهلاً بكِ في خامات');
    $home_subtitle = get_option('options_home_subtitle', 'كل خامات ومستلزمات الهاند ميد');
    $promo_badge_text = get_option('options_promo_badge_text', 'جديد');
    $whatsapp_number = get_option('options_whatsapp_number', '201099684347');
    $whatsapp_greeting_text = get_option('options_whatsapp_greeting_text', "أهلاً بك في متجر خامات!\nتفاصيل طلبي:\n\n{items}\n\nالمجموع: {total} ج.م\n\nاسم العميل: {name}\nالهاتف: {phone}\nالمحافظة: {governorate}\nالعنوان بالتفصيل: {address}");
    $support_email = get_option('options_support_email', 'support@5amat-handmade.com');
    $onesignal_app_id = get_option('options_onesignal_app_id', '');
    $onesignal_rest_key = get_option('options_onesignal_rest_key', '');
    $maintenance_mode = get_option('options_maintenance_mode', 0);
    $maintenance_message = get_option('options_maintenance_message', 'المتجر في صيانة مؤقتة، نعود لكم قريباً.');
    $force_update_version = get_option('options_force_update_version', '1.0.0');
    $force_update_message = get_option('options_force_update_message', 'يرجى تحديث التطبيق للحصول على آخر الخصائص.');
    $collection_name = get_option('options_collection_name', 'مجموعة الصيف الجديد');
    $collection_launch_date = get_option('options_collection_launch_date', date('c', strtotime('+7 days')));
    $collection_teaser_image = get_option('options_collection_teaser_image', 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?q=80&w=600');
    $promo_banner = get_option('options_promo_banner', '');
    $promo_deep_link = get_option('options_promo_deep_link', '');
    $custom_order_enabled = get_option('options_custom_order_enabled', 1);

    // Banners text
    $banners_raw = get_option('options_banner_images', []);
    $banners_list = [];
    if (is_array($banners_raw)) {
        foreach ($banners_raw as $row) {
            if (isset($row['image'])) {
                if (is_string($row['image'])) {
                    $banners_list[] = $row['image'];
                } elseif (is_array($row['image']) && isset($row['image']['url'])) {
                    $banners_list[] = $row['image']['url'];
                }
            }
        }
    }
    $banner_images_text = implode("\n", $banners_list);

    // Style gallery text
    $gallery_raw = get_option('options_style_gallery', []);
    $gallery_list = [];
    if (is_array($gallery_raw)) {
        foreach ($gallery_raw as $row) {
            if (isset($row['image_url'])) {
                $gallery_list[] = $row['image_url'];
            }
        }
    }
    $style_gallery_text = implode("\n", $gallery_list);

    // Featured products
    $featured_raw = get_option('options_featured_product_ids', []);
    $featured_product_ids_text = is_array($featured_raw) ? implode(',', $featured_raw) : '';

    ?>
    <div class="wrap">
        <h1>📱 5amat App Configuration Settings</h1>
        <form method="post">
            <h2 class="title">General welcome text and messages</h2>
            <table class="form-table">
                <tr>
                    <th>Home Welcome Title (عنوان الترحيب بالرئيسية)</th>
                    <td><input type="text" name="home_welcome_text" class="regular-text"
                            value="<?php echo esc_attr($home_welcome_text); ?>" /></td>
                </tr>
                <tr>
                    <th>Home Welcome Subtitle (العنوان الفرعي بالرئيسية)</th>
                    <td><input type="text" name="home_subtitle" class="regular-text"
                            value="<?php echo esc_attr($home_subtitle); ?>" /></td>
                </tr>
                <tr>
                    <th>Promotion Badge (شارة العروض)</th>
                    <td><input type="text" name="promo_badge_text" class="regular-text"
                            value="<?php echo esc_attr($promo_badge_text); ?>" /></td>
                </tr>
            </table>

            <hr />
            <h2 class="title">WhatsApp Orders & Support (الطلب والتواصل)</h2>
            <table class="form-table">
                <tr>
                    <th>WhatsApp Phone Number (رقم الهاتف للواتساب)</th>
                    <td>
                        <input type="text" name="whatsapp_number" class="regular-text"
                            value="<?php echo esc_attr($whatsapp_number); ?>" />
                        <p class="description">Must include country code, no spaces or plus signs (e.g. 201099684347 / رقم
                            الهاتف مع رمز الدولة بدون مسافات أو علامة +)</p>
                    </td>
                </tr>
                <tr>
                    <th>Order Message Template (نص رسالة الطلب التلقائي)</th>
                    <td>
                        <textarea name="whatsapp_greeting_text" rows="6"
                            class="large-text"><?php echo esc_textarea($whatsapp_greeting_text); ?></textarea>
                        <p class="description">Use tags: {items}, {total}, {name}, {phone}, {governorate}, {address} (لا تقم
                            بتعديل الكلمات المحصورة بين الأقواس المجعدة)</p>
                    </td>
                </tr>
                <tr>
                    <th>Support Email (البريد الإلكتروني للدعم)</th>
                    <td>
                        <input type="email" name="support_email" class="regular-text"
                            value="<?php echo esc_attr($support_email); ?>" />
                        <p class="description">Customer support email address shown in the app (البريد الإلكتروني الظاهر
                            للمستخدمين لطلب الدعم الفني)</p>
                    </td>
                </tr>
            </table>

            <hr />
            <h2 class="title">Lookbook Style Gallery & Banners</h2>
            <table class="form-table">
                <tr>
                    <th>Home Slider Banners (بانرات السلايدر بالرئيسية)</th>
                    <td>
                        <textarea name="banner_images" rows="5"
                            class="large-text"><?php echo esc_textarea($banner_images_text); ?></textarea>
                        <p class="description">Enter one image URL per line. (رابط صورة واحد في كل سطر)</p>
                    </td>
                </tr>
                <tr>
                    <th>Style Gallery Images (صور معرض التنسيقات)</th>
                    <td>
                        <textarea name="style_gallery" rows="5"
                            class="large-text"><?php echo esc_textarea($style_gallery_text); ?></textarea>
                        <p class="description">Enter one image URL per line. (رابط صورة واحد في كل سطر)</p>
                    </td>
                </tr>
                <tr>
                    <th>Featured Product IDs (المنتجات المميزة)</th>
                    <td>
                        <input type="text" name="featured_product_ids" class="regular-text"
                            value="<?php echo esc_attr($featured_product_ids_text); ?>" />
                        <p class="description">Comma-separated WooCommerce product IDs (e.g. 15,22,109)</p>
                    </td>
                </tr>
            </table>

            <hr />
            <h2 class="title">Teaser Collection Countdown (العد التنازلي للتشكيلات)</h2>
            <table class="form-table">
                <tr>
                    <th>Upcoming Collection Title (اسم التشكيلة القادمة)</th>
                    <td><input type="text" name="collection_name" class="regular-text"
                            value="<?php echo esc_attr($collection_name); ?>" /></td>
                </tr>
                <tr>
                    <th>Launch Date & Time (وقت التدشين)</th>
                    <td>
                        <input type="text" name="collection_launch_date" class="regular-text"
                            value="<?php echo esc_attr($collection_launch_date); ?>" />
                        <p class="description">ISO format: YYYY-MM-DDTHH:MM:SS (e.g. 2026-06-01T18:00:00)</p>
                    </td>
                </tr>
                <tr>
                    <th>Teaser Image URL (رابط صورة التشكيلة)</th>
                    <td><input type="text" name="collection_teaser_image" class="regular-text"
                            value="<?php echo esc_attr($collection_teaser_image); ?>" /></td>
                </tr>
            </table>

            <hr />
            <h2 class="title">System Operations (الصيانة والتحديثات الإجبارية)</h2>
            <table class="form-table">
                <tr>
                    <th>Maintenance Mode (وضع الصيانة للمتجر)</th>
                    <td>
                        <label>
                            <input type="checkbox" name="maintenance_mode" value="1" <?php checked($maintenance_mode, 1); ?> />
                            Enable maintenance mode lock screen on the app
                        </label>
                    </td>
                </tr>
                <tr>
                    <th>Maintenance Message (رسالة وضع الصيانة)</th>
                    <td><textarea name="maintenance_message" rows="3"
                            class="large-text"><?php echo esc_textarea($maintenance_message); ?></textarea></td>
                </tr>
                <tr>
                    <th>Custom Design Orders Enabled (تفعيل طلبات التفصيل الخاص)</th>
                    <td>
                        <label>
                            <input type="checkbox" name="custom_order_enabled" value="1" <?php checked($custom_order_enabled, 1); ?> />
                            Show custom order submission screen in app profile tab
                        </label>
                    </td>
                </tr>
                <tr>
                    <th>Force Update Version (تحديث إجباري للإصدار)</th>
                    <td>
                        <input type="text" name="force_update_version" class="regular-text"
                            value="<?php echo esc_attr($force_update_version); ?>" />
                        <p class="description">Force users running versions lower than this to update the app (e.g. 1.1.0)
                        </p>
                    </td>
                </tr>
                <tr>
                    <th>Force Update Message (رسالة التحديث الإجباري)</th>
                    <td><textarea name="force_update_message" rows="3"
                            class="large-text"><?php echo esc_textarea($force_update_message); ?></textarea></td>
                </tr>
            </table>

            <hr />
            <h2 class="title">OneSignal Notifications (إشعارات الـ OneSignal)</h2>
            <table class="form-table">
                <tr>
                    <th>OneSignal App ID (معرّف تطبيق OneSignal)</th>
                    <td>
                        <input type="text" name="onesignal_app_id" class="regular-text"
                            value="<?php echo esc_attr($onesignal_app_id); ?>" placeholder="e.g. 8b671a53..." />
                        <p class="description">Your OneSignal App ID from dashboard settings (معرّف تطبيق OneSignal الخاص
                            بك)</p>
                    </td>
                </tr>
                <tr>
                    <th>OneSignal REST API Key (مفتاح API الخاص بـ OneSignal)</th>
                    <td>
                        <input type="text" name="onesignal_rest_key" class="regular-text"
                            value="<?php echo esc_attr($onesignal_rest_key); ?>" placeholder="e.g. os_v2_app_..." />
                        <p class="description">Your OneSignal REST API Key for secure server notification triggers (مفتاح
                            REST API لإرسال الإشعارات)</p>
                    </td>
                </tr>
            </table>

            <?php submit_button('Save App Settings (حفظ الإعدادات)', 'primary', 'save_settings'); ?>
        </form>
    </div>
    <?php
}

// Optionally register ACF local fields as a fallback if the administrator has ACF active and wants it there
add_action('acf/init', function () {
    if (function_exists('acf_add_local_field_group')) {
        acf_add_local_field_group([
            'key' => 'group_5amat_app_settings',
            'title' => 'App Remote Configuration Settings',
            'fields' => [
                [
                    'key' => 'field_5amat_banners',
                    'label' => 'Banners Slider (سلايدر البانرات)',
                    'name' => 'banner_images',
                    'type' => 'repeater',
                    'instructions' => 'Add banner images shown on the Home Screen. (أضف صور البانرات المعروضة بالرئيسية)',
                    'required' => 0,
                    'layout' => 'table',
                    'button_label' => 'Add Banner (إضافة بانر)',
                    'sub_fields' => [
                        [
                            'key' => 'field_5amat_banner_image',
                            'label' => 'Image (الصورة)',
                            'name' => 'image',
                            'type' => 'image',
                            'return_format' => 'url',
                            'preview_size' => 'medium',
                        ],
                        [
                            'key' => 'field_5amat_banner_link',
                            'label' => 'Product Deep Link (رابط المنتج)',
                            'name' => 'link',
                            'type' => 'text',
                            'instructions' => 'Optional: e.g. 5amat://product/123',
                        ],
                    ],
                ],
                [
                    'key' => 'field_5amat_welcome_text',
                    'label' => 'Home Welcome Text (عنوان الترحيب بالرئيسية)',
                    'name' => 'home_welcome_text',
                    'type' => 'text',
                    'default_value' => 'أهلاً بكِ في خامات',
                ],
                [
                    'key' => 'field_5amat_subtitle',
                    'label' => 'Home Subtitle (العنوان الفرعي بالرئيسية)',
                    'name' => 'home_subtitle',
                    'type' => 'text',
                    'default_value' => 'كل خامات ومستلزمات الهاند ميد',
                ],
                [
                    'key' => 'field_5amat_promo_badge',
                    'label' => 'Promo Badge Text (نص شارة العروض)',
                    'name' => 'promo_badge_text',
                    'type' => 'text',
                    'default_value' => 'جديد',
                ],
                [
                    'key' => 'field_5amat_whatsapp_number',
                    'label' => 'WhatsApp Number (رقم الواتساب)',
                    'name' => 'whatsapp_number',
                    'type' => 'text',
                    'instructions' => 'With country code, no spaces (e.g. 201099684347).',
                    'default_value' => '201099684347',
                ],
                [
                    'key' => 'field_5amat_whatsapp_greeting',
                    'label' => 'WhatsApp Order Greeting Text (نص رسالة طلب الواتساب)',
                    'name' => 'whatsapp_greeting_text',
                    'type' => 'textarea',
                    'default_value' => "أهلاً بك في متجر خامات!\nتفاصيل طلبي:\n\n{items}\n\nالمجموع: {total} ج.م\n\nاسم العميل: {name}\nالهاتف: {phone}\nالمحافظة: {governorate}\nالعنوان بالتفصيل: {address}",
                ],
                [
                    'key' => 'field_5amat_maintenance_mode',
                    'label' => 'Maintenance Mode (وضع الصيانة)',
                    'name' => 'maintenance_mode',
                    'type' => 'true_false',
                    'default_value' => 0,
                    'ui' => 1,
                ],
                [
                    'key' => 'field_5amat_maintenance_msg',
                    'label' => 'Maintenance Message (رسالة الصيانة)',
                    'name' => 'maintenance_message',
                    'type' => 'textarea',
                    'default_value' => 'المتجر في صيانة مؤقتة، نعود لكم قريباً.',
                ],
                [
                    'key' => 'field_5amat_force_update',
                    'label' => 'Force Update Target Version (إصدار التحديث الإجباري)',
                    'name' => 'force_update_version',
                    'type' => 'text',
                    'default_value' => '1.0.0',
                ],
                [
                    'key' => 'field_5amat_force_update_msg',
                    'label' => 'Force Update Message (رسالة طلب التحديث)',
                    'name' => 'force_update_message',
                    'type' => 'textarea',
                    'default_value' => 'يرجى تحديث التطبيق للحصول على آخر الخصائص.',
                ],
                [
                    'key' => 'field_5amat_featured_products',
                    'label' => 'Featured Products (منتجات مميزة)',
                    'name' => 'featured_product_ids',
                    'type' => 'relationship',
                    'post_type' => ['product'],
                    'filters' => ['search', 'post_html_class'],
                    'return_format' => 'id',
                ],
                [
                    'key' => 'field_5amat_promo_deep_link',
                    'label' => 'Promo Deep Link (رابط العرض الترويجي)',
                    'name' => 'promo_deep_link',
                    'type' => 'text',
                ],
                [
                    'key' => 'field_5amat_promo_banner',
                    'label' => 'Promo Banner (بانر العرض الترويجي)',
                    'name' => 'promo_banner',
                    'type' => 'image',
                    'return_format' => 'url',
                ],
                [
                    'key' => 'field_5amat_custom_order_enabled',
                    'label' => 'Custom Orders Enabled (تفعيل طلبات التصاميم الخاصة)',
                    'name' => 'custom_order_enabled',
                    'type' => 'true_false',
                    'default_value' => 1,
                    'ui' => 1,
                ],
                [
                    'key' => 'field_5amat_collection_name',
                    'label' => 'Countdown Collection Title (عنوان التشكيلة القادمة)',
                    'name' => 'collection_name',
                    'type' => 'text',
                    'default_value' => 'مجموعة الصيف الجديد',
                ],
                [
                    'key' => 'field_5amat_collection_launch_date',
                    'label' => 'Countdown Launch Date & Time (وقت إطلاق التشكيلة القادمة)',
                    'name' => 'collection_launch_date',
                    'type' => 'text',
                    'instructions' => 'ISO Format: YYYY-MM-DDTHH:MM:SS (e.g. 2026-06-01T18:00:00).',
                ],
                [
                    'key' => 'field_5amat_collection_teaser_image',
                    'label' => 'Countdown Teaser Image URL (رابط صورة التشكيلة القادمة)',
                    'name' => 'collection_teaser_image',
                    'type' => 'text',
                ],
                [
                    'key' => 'field_5amat_style_gallery',
                    'label' => 'Lookbook Style Gallery Images (صور معرض التنسيقات والأفكار)',
                    'name' => 'style_gallery',
                    'type' => 'repeater',
                    'button_label' => 'Add Image (إضافة صورة)',
                    'sub_fields' => [
                        [
                            'key' => 'field_5amat_gallery_image',
                            'label' => 'Image URL (رابط الصورة)',
                            'name' => 'image_url',
                            'type' => 'text',
                        ]
                    ]
                ],
            ],
            'location' => [
                [
                    [
                        'param' => 'options_page',
                        'operator' => '==',
                        'value' => 'app-settings',
                    ],
                ],
            ],
        ]);
    }
});

// ==========================================
// 2. REGISTER APP CONFIG ENDPOINT
// ==========================================
// GET /wp-json/app/v1/config

add_action('rest_api_init', function () {
    register_rest_route('app/v1', '/config', [
        'methods' => 'GET',
        'callback' => 'app_get_config',
        'permission_callback' => '__return_true',
    ]);
});

function app_get_config()
{
    $options = [
        'banners' => [],
        'home_welcome_text' => app_get_option('home_welcome_text', 'أهلاً بكِ في خامات'),
        'home_subtitle' => app_get_option('home_subtitle', 'كل خامات ومستلزمات الهاند ميد'),
        'promo_badge_text' => app_get_option('promo_badge_text', 'جديد'),
        'whatsapp_number' => app_get_option('whatsapp_number', '201099684347'),
        'whatsapp_greeting' => app_get_option('whatsapp_greeting_text', "أهلاً بك في متجر خامات!\nتفاصيل طلبي:\n\n{items}\n\nالمجموع: {total} ج.م\n\nاسم العميل: {name}\nالهاتف: {phone}\nالمحافظة: {governorate}\nالعنوان بالتفصيل: {address}"),
        'whatsapp_text_template' => app_get_option('whatsapp_greeting_text', "أهلاً بك في متجر خامات!\nتفاصيل طلبي:\n\n{items}\n\nالمجموع: {total} ج.م\n\nاسم العميل: {name}\nالهاتف: {phone}\nالمحافظة: {governorate}\nالعنوان بالتفصيل: {address}"),
        'support_email' => app_get_option('support_email', 'support@5amat-handmade.com'),
        'onesignal_app_id' => app_get_option('onesignal_app_id', ''),
        'force_update_version' => app_get_option('force_update_version', '1.0.0'),
        'force_update_message' => app_get_option('force_update_message', 'يرجى تحديث التطبيق للحصول على آخر الخصائص.'),
        'maintenance_mode' => (bool) app_get_option('maintenance_mode', false),
        'maintenance_message' => app_get_option('maintenance_message', 'المتجر في صيانة مؤقتة، نعود لكم قريباً.'),
        'featured_product_ids' => [],
        'promo_deep_link' => app_get_option('promo_deep_link', ''),
        'promo_banner' => '',
        'custom_order_enabled' => app_get_option('custom_order_enabled', null) !== null ? (bool) app_get_option('custom_order_enabled', true) : true,
        'collection_name' => app_get_option('collection_name', 'مجموعة الصيف الجديد'),
        'collection_launch_date' => app_get_option('collection_launch_date', date('c', strtotime('+7 days'))),
        'collection_teaser_image' => app_get_option('collection_teaser_image', 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?q=80&w=600'),
        'style_gallery' => [],
    ];

    // Build banners list
    $banners_raw = app_get_option('banner_images');
    if (is_array($banners_raw)) {
        foreach ($banners_raw as $row) {
            $image_url = '';
            if (is_array($row['image']) && isset($row['image']['url'])) {
                $image_url = $row['image']['url'];
            } elseif (is_string($row['image'])) {
                $image_url = $row['image'];
            }
            if (!empty($image_url)) {
                $options['banners'][] = $image_url;
            }
        }
    }

    // Build featured products IDs
    $featured_raw = app_get_option('featured_product_ids');
    if (is_array($featured_raw)) {
        $options['featured_product_ids'] = array_map(function ($p) {
            return is_object($p) ? $p->ID : intval($p);
        }, $featured_raw);
    }

    // Promo banner image
    $promo_img = app_get_option('promo_banner');
    if ($promo_img) {
        $options['promo_banner'] = is_array($promo_img) ? $promo_img['url'] : $promo_img;
    }

    // Build style gallery list
    $gallery_raw = app_get_option('style_gallery');
    $gallery_processed = [];
    if (is_array($gallery_raw)) {
        foreach ($gallery_raw as $row) {
            if (isset($row['image_url']) && !empty($row['image_url'])) {
                $gallery_processed[] = $row['image_url'];
            }
        }
    }
    if (empty($gallery_processed)) {
        $gallery_processed = [
            'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?q=80&w=600',
            'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?q=80&w=600',
            'https://images.unsplash.com/photo-1605100804763-247f67b3557e?q=80&w=600',
            'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?q=80&w=600',
        ];
    }
    $options['style_gallery'] = $gallery_processed;

    return rest_ensure_response($options);
}

// ==========================================
// 3. REGISTER FEATURED PRODUCTS DETAILED ENDPOINT
// ==========================================
// GET /wp-json/app/v1/featured-products

add_action('rest_api_init', function () {
    register_rest_route('app/v1', '/featured-products', [
        'methods' => 'GET',
        'callback' => 'app_get_featured_products',
        'permission_callback' => '__return_true',
    ]);
});

function app_get_featured_products()
{
    $ids_raw = app_get_option('featured_product_ids');
    if (empty($ids_raw))
        return rest_ensure_response([]);

    $ids = array_map(function ($p) {
        return is_object($p) ? $p->ID : intval($p);
    }, $ids_raw);

    $products = [];
    foreach ($ids as $id) {
        $product = wc_get_product($id);
        if (!$product || !$product->is_visible())
            continue;

        $image_id = $product->get_image_id();
        $image_url = $image_id ? wp_get_attachment_image_url($image_id, 'woocommerce_single') : wc_placeholder_img_src();

        $products[] = [
            'id' => $product->get_id(),
            'name' => $product->get_name(),
            'price' => floatval($product->get_price()),
            'regular_price' => floatval($product->get_regular_price()),
            'sale_price' => floatval($product->get_sale_price()),
            'on_sale' => $product->is_on_sale(),
            'image' => $image_url,
            'permalink' => get_permalink($id),
            'slug' => $product->get_slug(),
        ];
    }

    return rest_ensure_response($products);
}

// ==========================================
// 4. ONESIGNAL PUSH NOTIFICATIONS CONTROLLERS
// ==========================================

// Add custom "App Notifications" admin menu
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

function app_notifications_page()
{
    if (isset($_POST['send_notif'])) {
        $title = sanitize_text_field($_POST['notif_title']);
        $message = sanitize_textarea_field($_POST['notif_message']);

        $destination_type = sanitize_text_field($_POST['notif_destination_type']);
        $link = '';
        if ($destination_type === 'style-gallery') {
            $link = '5amat://style-gallery';
        } elseif ($destination_type === 'custom-order') {
            $link = '5amat://custom-order';
        } elseif ($destination_type === 'product') {
            $product_id = intval($_POST['notif_product_id']);
            if ($product_id > 0) {
                $link = '5amat://product/' . $product_id;
            }
        } elseif ($destination_type === 'category') {
            $cat_id = intval($_POST['notif_category_id']);
            if ($cat_id > 0) {
                $link = '5amat://category/' . $cat_id;
            }
        }

        $result = app_send_onesignal_notification($title, $message, $link);
        if (isset($result['error'])) {
            echo '<div class="notice notice-error"><p><strong>❌ Error (خطأ):</strong> ' . esc_html($result['error']) . '</p></div>';
        } elseif (isset($result['errors']) && !empty($result['errors'])) {
            $errors_str = is_array($result['errors']) ? implode(', ', $result['errors']) : strval($result['errors']);
            $friendly_message = '';
            if (strpos($errors_str, 'All included players are not subscribed') !== false) {
                $friendly_message = '<strong>توضيح:</strong> تم الاتصال بـ OneSignal ومفاتيحك صحيحة تماماً 💡، ولكن لا يوجد أي هاتف مشترك أو مسجل في لوحة تحكم OneSignal حالياً لاستلام الإشعارات. يرجى فتح التطبيق على الهاتف أولاً والموافقة على إعطاء صلاحية الإشعارات ليتم ربط جهازك وتلقي الإشعارات.';
            } elseif (strpos($errors_str, 'invalid authorization') !== false || strpos($errors_str, 'Unauthorized') !== false) {
                $friendly_message = '<strong>توضيح:</strong> مفتاح الـ REST API Key غير صحيح أو غير صالح. يرجى التأكد من نسخه بالكامل بشكل سليم من لوحة تحكم OneSignal وإعادة حفظ الإعدادات.';
            } elseif (strpos($errors_str, 'app_id not found') !== false) {
                $friendly_message = '<strong>توضيح:</strong> معرّف تطبيق OneSignal App ID غير صحيح أو لم يتم العثور عليه. يرجى التأكد من إدخال الـ App ID الصحيح في صفحة الإعدادات.';
            }
            echo '<div class="notice notice-error">';
            echo '<p><strong>❌ OneSignal Error:</strong> ' . esc_html($errors_str) . '</p>';
            if (!empty($friendly_message)) {
                echo '<p style="margin-top: 5px; font-size: 13px; background: #fff3cd; padding: 10px; border-left: 4px solid #ffc107; color: #856404; font-weight: 500;">' . $friendly_message . '</p>';
            }
            echo '</div>';
        } else {
            echo '<div class="notice notice-success"><p><strong>✅ Notification Sent Successfully!</strong> Response: ' . esc_html(json_encode($result)) . '</p></div>';
        }
    }

    // Get all products to show in select dropdown
    $products = get_posts([
        'post_type' => 'product',
        'post_status' => 'publish',
        'posts_per_page' => -1,
        'orderby' => 'title',
        'order' => 'ASC'
    ]);

    // Get all categories to show in select dropdown
    $categories = get_terms([
        'taxonomy' => 'product_cat',
        'hide_empty' => false,
    ]);
    ?>
    <div class="wrap">
        <h1>📱 Send App Push Notification</h1>
        <form method="post">
            <table class="form-table">
                <tr>
                    <th>Title (العنوان)</th>
                    <td><input type="text" name="notif_title" class="regular-text" required
                            placeholder="عنوان الإشعار..." /></td>
                </tr>
                <tr>
                    <th>Message (نص الرسالة)</th>
                    <td><textarea name="notif_message" rows="4" class="large-text" required
                            placeholder="تفاصيل الإشعار..."></textarea></td>
                </tr>
                <tr>
                    <th>Open Destination (وجهة فتح الإشعار)</th>
                    <td>
                        <select name="notif_destination_type" id="notif_destination_type"
                            onchange="toggleDestinationFields()" style="width: 350px;">
                            <option value="home">Home Screen (الصفحة الرئيسية)</option>
                            <option value="style-gallery">Lookbook Style Gallery (معرض التنسيقات والأفكار)</option>
                            <option value="custom-order">Custom Order Form (طلب تصميم خاص)</option>
                            <option value="product">Specific Product (منتج معين)</option>
                            <option value="category">Specific Category (قسم معين)</option>
                        </select>
                    </td>
                </tr>
                <tr id="row_product_select" style="display:none;">
                    <th>Select Product (اختر المنتج)</th>
                    <td>
                        <select name="notif_product_id" style="width: 350px;">
                            <option value="0">-- Choose Product --</option>
                            <?php foreach ($products as $p): ?>
                                <option value="<?php echo $p->ID; ?>"><?php echo esc_html($p->post_title); ?></option>
                            <?php endforeach; ?>
                        </select>
                    </td>
                </tr>
                <tr id="row_category_select" style="display:none;">
                    <th>Select Category (اختر القسم)</th>
                    <td>
                        <select name="notif_category_id" style="width: 350px;">
                            <option value="0">-- Choose Category --</option>
                            <?php foreach ($categories as $c): ?>
                                <option value="<?php echo $c->term_id; ?>"><?php echo esc_html($c->name); ?></option>
                            <?php endforeach; ?>
                        </select>
                    </td>
                </tr>
            </table>

            <script type="text/javascript">
                function toggleDestinationFields() {
                    var type = document.getElementById('notif_destination_type').value;
                    document.getElementById('row_product_select').style.display = (type === 'product') ? '' : 'none';
                    document.getElementById('row_category_select').style.display = (type === 'category') ? '' : 'none';
                }
            </script>

            <?php submit_button('Send Notification (إرسال الإشعار)', 'primary', 'send_notif'); ?>
        </form>
    </div>
    <?php
}

// OneSignal REST API trigger
function app_send_onesignal_notification($title, $message, $url = '')
{
    $onesignal_app_id = get_option('options_onesignal_app_id');
    $onesignal_rest_key = get_option('options_onesignal_rest_key');

    if (empty($onesignal_app_id) || $onesignal_app_id === 'YOUR_ONESIGNAL_APP_ID') {
        return ['error' => 'OneSignal App ID is not configured. Please fill it in the App Settings. (معرّف تطبيق OneSignal غير مضبوط)'];
    }
    if (empty($onesignal_rest_key) || $onesignal_rest_key === 'YOUR_ONESIGNAL_REST_KEY') {
        return ['error' => 'OneSignal REST API Key is not configured. Please fill it in the App Settings. (مفتاح API الخاص بـ OneSignal غير مضبوط)'];
    }

    $payload = [
        'app_id' => $onesignal_app_id,
        'included_segments' => ['All'],
        'headings' => ['en' => $title, 'ar' => $title],
        'contents' => ['en' => $message, 'ar' => $message],
    ];

    if (!empty($url)) {
        $payload['url'] = $url;
        $payload['data'] = ['deep_link' => $url];
    }

    $response = wp_remote_post('https://onesignal.com/api/v1/notifications', [
        'headers' => [
            'Content-Type' => 'application/json',
            'Authorization' => 'Basic ' . $onesignal_rest_key,
        ],
        'body' => json_encode($payload),
        'timeout' => 30,
    ]);

    if (is_wp_error($response)) {
        return ['error' => $response->get_error_message()];
    }

    $body = json_decode(wp_remote_retrieve_body($response), true);
    if (!is_array($body)) {
        $body = ['response_raw' => wp_remote_retrieve_body($response)];
    }
    return $body;
}

// Automatically send push notification when a new product is published
add_action('transition_post_status', function ($new_status, $old_status, $post) {
    if ($new_status === 'publish' && $old_status !== 'publish' && $post->post_type === 'product') {
        $product = wc_get_product($post->ID);
        if (!$product)
            return;

        $title = '🌸 منتج جديد وصل!';
        $message = $product->get_name() . ' — اضغط لتشوفيه';
        $link = '5amat://product/' . $post->ID;

        app_send_onesignal_notification($title, $message, $link);
    }
}, 10, 3);

// ==========================================
// 5. DEEP LINK EDIT BOXES IN WP DASHBOARD
// ==========================================

// Product details edit page box
add_action('woocommerce_product_options_general_product_data', function () {
    global $post;
    $deep_link = '5amat://product/' . $post->ID;
    echo '<div class="options_group">';
    echo '<p class="form-field"><label>📱 App Deep Link</label>';
    echo '<input type="text" value="' . esc_attr($deep_link) . '" readonly style="background:#f0f0f0;width:300px;" />';
    echo '<span class="description"> Copy this to share a direct link to this product in the app.</span>';
    echo '</p></div>';
});

// Category edit page box
add_action('product_cat_edit_form_fields', function ($term) {
    $deep_link = '5amat://category/' . $term->term_id;
    echo '<tr class="form-field">';
    echo '<th>📱 App Deep Link</th>';
    echo '<td>';
    echo '<input type="text" value="' . esc_attr($deep_link) . '" readonly style="background:#f0f0f0;width:300px;" />';
    echo '<p class="description">Copy this to deep link to this category in the app.</p>';
    echo '</td></tr>';
});

// ==========================================
// 6. ORDER LOG ENDPOINT (Optional telemetry)
// ==========================================
// POST /wp-json/app/v1/log-order

add_action('rest_api_init', function () {
    register_rest_route('app/v1', '/log-order', [
        'methods' => 'POST',
        'callback' => 'app_log_order',
        'permission_callback' => '__return_true',
    ]);
});

function app_log_order(WP_REST_Request $request)
{
    $data = $request->get_json_params();

    // Logs order internally inside WordPress post table under title
    $post_id = wp_insert_post([
        'post_title' => 'Order from ' . sanitize_text_field($data['name'] ?? 'Unknown'),
        'post_status' => 'publish',
        'post_type' => 'post', // Logs as standard post or custom post type
        'meta_input' => [
            'customer_name' => sanitize_text_field($data['name'] ?? ''),
            'customer_phone' => sanitize_text_field($data['phone'] ?? ''),
            'customer_city' => sanitize_text_field($data['city'] ?? ''),
            'order_items' => json_encode($data['items'] ?? []),
            'order_total' => floatval($data['total'] ?? 0),
            'sent_at' => current_time('mysql'),
        ],
    ]);

    if (is_wp_error($post_id)) {
        return new WP_Error('log_failed', 'Failed to log order', ['status' => 500]);
    }

    return rest_ensure_response(['success' => true, 'post_id' => $post_id]);
}

// ==========================================
// 6.5 RANDOM PRODUCT ENDPOINT
// ==========================================
// GET /wp-json/app/v1/random-product

add_action('rest_api_init', function () {
    register_rest_route('app/v1', '/random-product', [
        'methods' => 'GET',
        'callback' => 'app_get_random_product',
        'permission_callback' => '__return_true',
    ]);
});

function app_get_random_product()
{
    $args = [
        'post_type' => 'product',
        'post_status' => 'publish',
        'posts_per_page' => 1,
        'orderby' => 'rand',
    ];
    $query = new WP_Query($args);

    if (!$query->have_posts()) {
        return new WP_Error('no_products', 'No products found', ['status' => 404]);
    }

    $query->the_post();
    $product_id = get_the_ID();
    wp_reset_postdata();

    return rest_ensure_response([
        'id' => $product_id,
    ]);
}

// ==========================================
// 7. SERVE DEEP LINK VERIFICATION FILES (AASA & ASSETLINKS)
// ==========================================

add_action('init', function () {
    add_rewrite_rule('^\.well-known/apple-app-site-association$', 'index.php?aasa=1', 'top');
    add_rewrite_rule('^\.well-known/assetlinks\.json$', 'index.php?assetlinks=1', 'top');
});

add_filter('query_vars', function ($vars) {
    return array_merge($vars, ['aasa', 'assetlinks']);
});

add_action('template_redirect', function () {
    if (get_query_var('aasa')) {
        header('Content-Type: application/json');
        echo json_encode([
            'applinks' => [
                'apps' => [],
                'details' => [
                    [
                        'appID' => 'J3A4HJ8C4B.com.zbooma.fiveamat',
                        'paths' => ['/shop/product/*', '/product/*'],
                    ]
                ]
            ]
        ]);
        exit;
    }
    if (get_query_var('assetlinks')) {
        header('Content-Type: application/json');
        echo json_encode([
            [
                'relation' => ['delegate_permission/common.handle_all_urls'],
                'target' => [
                    'namespace' => 'android_app',
                    'package_name' => 'com.zbooma.fiveamat',
                    'sha256_cert_fingerprints' => ['68:7A:74:36:7C:A3:6B:80:4E:18:08:65:76:0C:98:44:0E:D9:43:D1:C3:D0:1E:05:46:0F:4A:F0:30:53:AD:66']
                ]
            ]
        ]);
        exit;
    }
});

// ==========================================
// 8. BACK IN STOCK ALERTS (DB & OBSERVER)
// ==========================================

// Ensure stock alerts table exists
function app_ensure_stock_alerts_table()
{
    global $wpdb;
    $table_name = $wpdb->prefix . 'app_stock_alerts';
    if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") != $table_name) {
        $charset_collate = $wpdb->get_charset_collate();
        $sql = "CREATE TABLE $table_name (
            id BIGINT(20) NOT NULL AUTO_INCREMENT,
            product_id BIGINT(20) NOT NULL,
            player_id VARCHAR(255) NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY product_player (product_id, player_id)
        ) $charset_collate;";
        require_once(ABSPATH . 'wp-admin/includes/upgrade.php');
        dbDelta($sql);
    }
}

// POST /wp-json/app/v1/stock-alert
add_action('rest_api_init', function () {
    register_rest_route('app/v1', '/stock-alert', [
        'methods' => 'POST',
        'callback' => 'app_log_stock_alert',
        'permission_callback' => '__return_true',
    ]);
});

function app_log_stock_alert(WP_REST_Request $request)
{
    global $wpdb;
    $data = $request->get_json_params();
    $product_id = intval($data['product_id'] ?? 0);
    $player_id = sanitize_text_field($data['player_id'] ?? '');

    if ($product_id <= 0 || empty($player_id)) {
        return new WP_Error('invalid_data', 'Product ID and Player ID are required', ['status' => 400]);
    }

    app_ensure_stock_alerts_table();

    $table_name = $wpdb->prefix . 'app_stock_alerts';
    $result = $wpdb->replace(
        $table_name,
        [
            'product_id' => $product_id,
            'player_id' => $player_id,
            'created_at' => current_time('mysql'),
        ],
        ['%d', '%s', '%s']
    );

    if ($result === false) {
        return new WP_Error('db_error', 'Failed to register stock alert', ['status' => 500]);
    }

    return rest_ensure_response(['success' => true]);
}

// Send push notification specifically to subbed player IDs (subscription IDs)
function app_send_onesignal_notification_to_subscribers($title, $message, $player_ids, $url = '')
{
    $onesignal_app_id = get_option('options_onesignal_app_id');
    $onesignal_rest_key = get_option('options_onesignal_rest_key');

    if (empty($onesignal_app_id) || $onesignal_app_id === 'YOUR_ONESIGNAL_APP_ID') {
        return ['error' => 'OneSignal App ID is not configured. Please fill it in the App Settings. (معرّف تطبيق OneSignal غير مضبوط)'];
    }
    if (empty($onesignal_rest_key) || $onesignal_rest_key === 'YOUR_ONESIGNAL_REST_KEY') {
        return ['error' => 'OneSignal REST API Key is not configured. Please fill it in the App Settings. (مفتاح API الخاص بـ OneSignal غير مضبوط)'];
    }

    $payload = [
        'app_id' => $onesignal_app_id,
        'include_subscription_ids' => $player_ids,
        'headings' => ['en' => $title, 'ar' => $title],
        'contents' => ['en' => $message, 'ar' => $message],
    ];

    if (!empty($url)) {
        $payload['url'] = $url;
        $payload['data'] = ['deep_link' => $url];
    }

    $response = wp_remote_post('https://onesignal.com/api/v1/notifications', [
        'headers' => [
            'Content-Type' => 'application/json',
            'Authorization' => 'Basic ' . $onesignal_rest_key,
        ],
        'body' => json_encode($payload),
        'timeout' => 30,
    ]);

    if (is_wp_error($response)) {
        return ['error' => $response->get_error_message()];
    }

    $body = json_decode(wp_remote_retrieve_body($response), true);
    if (!is_array($body)) {
        $body = ['response_raw' => wp_remote_retrieve_body($response)];
    }
    return $body;
}

// Observe WooCommerce product stock status changes
add_action('woocommerce_product_stock_status_changed', 'app_handle_stock_status_changed', 10, 4);

function app_handle_stock_status_changed($product_id, $new_status, $old_status, $product)
{
    if ($new_status === 'instock') {
        global $wpdb;
        $table_name = $wpdb->prefix . 'app_stock_alerts';

        // Check if table exists
        if ($wpdb->get_var("SHOW TABLES LIKE '$table_name'") == $table_name) {
            $subscribers = $wpdb->get_results($wpdb->prepare(
                "SELECT player_id FROM $table_name WHERE product_id = %d",
                $product_id
            ));

            if (!empty($subscribers)) {
                $player_ids = array_map(function ($sub) {
                    return $sub->player_id;
                }, $subscribers);

                $product_name = get_the_title($product_id);
                $title = '🌸 المنتج متوفر الآن!';
                $message = 'بشرى سارة! منتج "' . $product_name . '" متوفر الآن في المخزن. اطلبيه الآن قبل نفاد الكمية!';
                $link = '5amat://product/' . $product_id;

                app_send_onesignal_notification_to_subscribers($title, $message, $player_ids, $link);

                // Delete alert registrations
                $wpdb->delete($table_name, ['product_id' => $product_id]);
            }
        }
    }
}


// ==========================================
// 6.7 LOYALTY POINTS ENDPOINT
// ==========================================
// GET /wp-json/app/v1/loyalty-points?phone=<phone>

add_action('rest_api_init', function () {
    register_rest_route('app/v1', '/loyalty-points', [
        'methods' => 'GET',
        'callback' => 'app_get_loyalty_points',
        'permission_callback' => '__return_true',
    ]);
});

function app_get_loyalty_points(WP_REST_Request $request)
{
    $phone = sanitize_text_field($request->get_param('phone'));
    if (empty($phone)) {
        return new WP_Error('missing_phone', 'Phone parameter is required', ['status' => 400]);
    }

    // Clean up phone number to make query robust (remove spaces, plus, dashes, leading country codes)
    $clean_phone = preg_replace('/[^0-9]/', '', $phone);

    if (!class_exists('WooCommerce')) {
        return rest_ensure_response([
            'points' => 0,
            'completed_orders_count' => 0,
            'note' => 'WooCommerce is not active'
        ]);
    }

    // Standardize Egyptian phones (e.g. 010... or 2010...)
    $phone_variations = [$clean_phone];
    if (strpos($clean_phone, '20') === 0) {
        $phone_variations[] = '0' . substr($clean_phone, 2);
        $phone_variations[] = substr($clean_phone, 2);
    } else if (strpos($clean_phone, '0') === 0) {
        $phone_variations[] = '20' . substr($clean_phone, 1);
        $phone_variations[] = substr($clean_phone, 1);
    } else {
        $phone_variations[] = '0' . $clean_phone;
        $phone_variations[] = '20' . $clean_phone;
    }
    $phone_variations = array_unique($phone_variations);

    // Query WooCommerce orders matching the billing phone
    $query = new WC_Order_Query([
        'limit' => -1,
        'status' => ['completed', 'processing'],
        'billing_phone' => $phone_variations,
        'return' => 'ids',
    ]);
    $orders = $query->get_orders();
    $orders_count = count($orders);

    // 10 points per order
    $points = $orders_count * 10;

    return rest_ensure_response([
        'points' => $points,
        'completed_orders_count' => $orders_count,
        'phone_queried' => $phone,
    ]);
}


