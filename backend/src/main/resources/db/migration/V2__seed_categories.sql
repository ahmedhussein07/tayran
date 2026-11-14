-- The 8 main categories, in display order. color_token names the design system's pastel for each tile.
INSERT INTO categories (name_ar, name_en, icon_key, color_token, sort_order) VALUES
    ('خضار وفاكهة', 'Fruits & vegetables', 'produce', 'pastel-mint',   1),
    ('مخبوزات',     'Bakery',              'bread',   'pastel-wheat',  2),
    ('ألبان وبيض',  'Dairy & eggs',        'dairy',   'pastel-sky',    3),
    ('لحوم وفراخ',  'Meat & poultry',      'chicken', 'pastel-blush',  4),
    ('سناكس',       'Snacks',              'chips',   'pastel-butter', 5),
    ('مشروبات',     'Beverages',           'juice',   'pastel-lilac',  6),
    ('منظفات',      'Cleaning',            'spray',   'pastel-aqua',   7),
    ('عناية شخصية', 'Personal care',       'pump',    'pastel-rose',   8);
