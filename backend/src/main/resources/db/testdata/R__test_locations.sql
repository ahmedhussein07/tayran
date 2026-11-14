-- ============================================================================
-- TEST DATA ONLY. Sample villages and streets for local development and tests.
-- Loaded only by the dev profile and the integration tests
-- (spring.flyway.locations includes classpath:db/testdata). Never load in production.
-- Repeatable and idempotent: safe to run again.
-- ============================================================================

INSERT INTO villages (name_ar, name_en, sort_order) VALUES
    ('كفر الياسمين', 'Kafr El Yasmin (test)', 1),
    ('كفر البحر',    'Kafr El Bahr (test)',   2),
    ('كفر الشجرة',   'Kafr El Shagara (test)', 3),
    ('كفر النور',    'Kafr El Nour (test)',   4)
ON CONFLICT (name_ar) DO NOTHING;

INSERT INTO streets (village_id, name_ar, name_en, sort_order)
SELECT v.id, s.name_ar, s.name_en, s.sort_order
FROM villages v
JOIN (VALUES
    ('كفر الياسمين', 'شارع الجامع الكبير', 'Big Mosque St (test)',   1),
    ('كفر الياسمين', 'شارع المدرسة',       'School St (test)',       2),
    ('كفر الياسمين', 'شارع الترعة',        'Canal St (test)',        3),
    ('كفر الياسمين', 'شارع السوق',         'Market St (test)',       4),
    ('كفر الياسمين', 'شارع المحطة',        'Station St (test)',      5),
    ('كفر الياسمين', 'شارع الوحدة الصحية', 'Health Unit St (test)',  6),
    ('كفر الياسمين', 'شارع البوستة',       'Post Office St (test)',  7),
    ('كفر الياسمين', 'شارع المجلس',        'Council St (test)',      8),
    ('كفر البحر',    'شارع البحر',         'Sea St (test)',          1),
    ('كفر البحر',    'شارع الكنيسة',       'Church St (test)',       2),
    ('كفر البحر',    'شارع المدرسة',       'School St (test)',       3),
    ('كفر الشجرة',   'شارع الجمعية',       'Co-op St (test)',        1),
    ('كفر الشجرة',   'شارع المستشفى',      'Hospital St (test)',     2),
    ('كفر النور',    'شارع النور',         'Nour St (test)',         1),
    ('كفر النور',    'شارع الجامع',        'Mosque St (test)',       2)
) AS s (village_name_ar, name_ar, name_en, sort_order) ON s.village_name_ar = v.name_ar
ON CONFLICT (village_id, name_ar) DO NOTHING;
