const mongoose = require('mongoose');
const dotenv = require('dotenv');
const slugify = require('slugify');
const Product = require('../models/Product');

dotenv.config({ path: './.env' });

const categories = ['men', 'women', 'kids', 'shoes', 'accessories'];
const subCategoriesByCategory = {
  men: ['t-shirts', 'shirts', 'pants', 'jackets', 'hoodies'],
  women: ['dresses', 'shirts', 'pants', 'jackets', 'sweaters'],
  kids: ['t-shirts', 'pants', 'hoodies', 'sweaters', 'shoes'],
  shoes: ['shoes', 'accessories'],
  accessories: ['accessories', 'shoes'],
};

const brandByCategory = {
  men: 'UrbanCraft',
  women: 'LuxeLane',
  kids: 'MiniMode',
  shoes: 'StrideLab',
  accessories: 'StyleNest',
};

const imageSets = [
  [
    'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=900&q=80',
  ],
  [
    'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=900&q=80',
  ],
  [
    'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?auto=format&fit=crop&w=900&q=80',
  ],
  [
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=80',
  ],
];

const colorPalette = [
  { name: 'Black', hex: '#111827' },
  { name: 'White', hex: '#F9FAFB' },
  { name: 'Blue', hex: '#2563EB' },
  { name: 'Red', hex: '#DC2626' },
  { name: 'Green', hex: '#059669' },
  { name: 'Beige', hex: '#D6C6A5' },
  { name: 'Grey', hex: '#6B7280' },
  { name: 'Navy', hex: '#1E3A8A' },
];

function createSizes(seed) {
  const base = 20 + (seed % 20);
  return [
    { size: 'S', stock: base, sku: `SKU-${seed}-S` },
    { size: 'M', stock: base + 10, sku: `SKU-${seed}-M` },
    { size: 'L', stock: base + 8, sku: `SKU-${seed}-L` },
    { size: 'XL', stock: base + 5, sku: `SKU-${seed}-XL` },
  ];
}

function createColors(seed, category) {
  const firstColor = colorPalette[seed % colorPalette.length];
  const secondColor = colorPalette[(seed + 3) % colorPalette.length];
  const imageSet = imageSets[seed % imageSets.length];

  return [
    {
      name: firstColor.name,
      hex: firstColor.hex,
      images: imageSet,
      stock: 50 + (seed % 25),
    },
    {
      name: secondColor.name,
      hex: secondColor.hex,
      images: imageSet,
      stock: 40 + (seed % 20),
    },
    {
      name: category === 'accessories' ? 'Brown' : 'Grey',
      hex: category === 'accessories' ? '#8B5E3C' : '#6B7280',
      images: imageSet,
      stock: 25 + (seed % 18),
    },
  ];
}

function buildProducts(total = 40) {
  return Array.from({ length: total }, (_, index) => {
    const seed = index + 1;
    const category = categories[index % categories.length];
    const subCategoryOptions = subCategoriesByCategory[category];
    const subCategory = subCategoryOptions[index % subCategoryOptions.length];
    const price = 19 + (index % 10) * 6 + Math.floor(index / 5) * 3;

    const name = `${category.toUpperCase()} ${subCategory} Collection #${seed}`;

    return {
      name,
      slug: slugify(name, { lower: true, strict: true }),
      description:
        `Premium ${subCategory} for ${category} made with breathable fabric and modern fit. ` +
        'Designed for all-day comfort and effortless style.',
      price,
      category,
      subCategory,
      sizes: createSizes(seed),
      colors: createColors(seed, category),
      brand: brandByCategory[category],
      tags: [category, subCategory, 'trending', seed % 2 === 0 ? 'new-arrival' : 'best-seller'],
      rating: Number((3.8 + (seed % 12) * 0.1).toFixed(1)),
      numReviews: 10 + (seed % 90),
      isFeatured: seed <= 24,
      isAvailable: true,
      discount: seed % 3 === 0 ? 15 : seed % 5 === 0 ? 25 : 0,
      specifications: {
        material: seed % 2 === 0 ? 'Cotton Blend' : 'Polyester Blend',
        care: 'Machine wash cold',
        weight: `${250 + (seed % 6) * 20}g`,
        origin: 'India',
        fit: seed % 2 === 0 ? 'Regular' : 'Slim',
        length: 'Standard',
      },
      views: 100 + seed * 13,
      sold: 20 + seed * 3,
    };
  });
}

async function seedProducts() {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error('MONGODB_URI is missing in backend/.env');
    }

    await mongoose.connect(process.env.MONGODB_URI);

    await Product.deleteMany({});

    const products = buildProducts(40);
    await Product.insertMany(products);

    console.log(`✅ Seeded ${products.length} products successfully.`);
    process.exit(0);
  } catch (error) {
    console.error(`❌ Seeding failed: ${error.message}`);
    process.exit(1);
  }
}

seedProducts();
