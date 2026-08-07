import { NutrientCategoryCode } from '@prisma/client';

/**
 * Curated seed content for the free Ascend Nutrition Library (Build
 * Session 8 Part 11). Every article carries the same SAFETY_NOTE — this
 * is general nutrition education, never a diagnosis and never a
 * specific supplement dose recommendation. References cite an
 * organization by name only; no URLs are generated (see this module's
 * seed logic).
 */

export const SAFETY_NOTE =
  'This article is general nutrition education, not medical advice. It does not diagnose any health condition and does not recommend a specific supplement or dose — talk with a healthcare provider before changing your diet significantly or starting a supplement, especially if you are pregnant, nursing, or managing a health condition.';

export interface NutrientArticleSeed {
  slug: string;
  title: string;
  summary: string;
  body: string;
  foodSources: { foodName: string; amount: string }[];
  references: { label: string }[];
}

export interface NutrientCategorySeed {
  code: NutrientCategoryCode;
  name: string;
  description: string;
  articles: NutrientArticleSeed[];
}

export const NUTRIENT_LIBRARY_SEED: NutrientCategorySeed[] = [
  {
    code: NutrientCategoryCode.MACRONUTRIENT,
    name: 'Macronutrients',
    description:
      'The nutrients your body needs in large amounts for energy and structure: protein, carbohydrates, fat, and fiber.',
    articles: [
      {
        slug: 'protein',
        title: 'Protein',
        summary:
          'Protein supplies amino acids your body uses to build and repair muscle, enzymes, and other tissues.',
        body: 'Protein is made of amino acids, some of which your body cannot produce on its own and must get from food. It supports muscle repair and growth, immune function, and the production of hormones and enzymes. Guidance from major health bodies suggests protein needs vary with body size, activity level, and goals, and are commonly expressed as grams per kilogram of body weight rather than a single fixed number for everyone.',
        foodSources: [
          { foodName: 'Chicken breast', amount: '31g protein per 100g' },
          { foodName: 'Lentils (cooked)', amount: '9g protein per 100g' },
          { foodName: 'Greek yogurt', amount: '10g protein per 100g' },
          { foodName: 'Eggs', amount: '13g protein per 100g' },
        ],
        references: [{ label: 'Dietary Guidelines for Americans' }],
      },
      {
        slug: 'carbohydrates',
        title: 'Carbohydrates',
        summary:
          "Carbohydrates are the body's primary quick-access energy source, found in foods like grains, fruit, and vegetables.",
        body: "Carbohydrates break down into glucose, which fuels the brain and muscles. They're commonly grouped into simple carbohydrates (found in fruit, milk, and added sugars) and complex carbohydrates (found in whole grains, legumes, and starchy vegetables), the latter typically digesting more slowly and often paired with more fiber.",
        foodSources: [
          { foodName: 'Oats (dry)', amount: '66g carbohydrate per 100g' },
          { foodName: 'Banana', amount: '23g carbohydrate per 100g' },
          { foodName: 'Brown rice (cooked)', amount: '23g carbohydrate per 100g' },
          { foodName: 'Sweet potato', amount: '20g carbohydrate per 100g' },
        ],
        references: [{ label: 'USDA FoodData Central' }],
      },
      {
        slug: 'fat',
        title: 'Fat',
        summary:
          'Dietary fat supplies concentrated energy, supports cell structure, and helps absorb fat-soluble vitamins.',
        body: 'Fats are commonly grouped into saturated, unsaturated (monounsaturated and polyunsaturated), and trans fats. Unsaturated fats, found in foods like olive oil, nuts, and fatty fish, are generally associated with better health outcomes than saturated and trans fats when eaten in their place. Fat also carries vitamins A, D, E, and K.',
        foodSources: [
          { foodName: 'Olive oil', amount: '100g fat per 100g' },
          { foodName: 'Almonds', amount: '49g fat per 100g' },
          { foodName: 'Salmon', amount: '13g fat per 100g' },
          { foodName: 'Avocado', amount: '15g fat per 100g' },
        ],
        references: [{ label: 'American Heart Association' }],
      },
      {
        slug: 'fiber',
        title: 'Fiber',
        summary:
          "Fiber is the part of plant food your body can't fully digest, supporting digestion and steady energy.",
        body: 'Dietary fiber comes from plant foods and is generally split into soluble fiber (which dissolves in water and can slow digestion) and insoluble fiber (which adds bulk to stool). A diet with a variety of fruits, vegetables, whole grains, and legumes typically provides both types.',
        foodSources: [
          { foodName: 'Black beans (cooked)', amount: '8.7g fiber per 100g' },
          { foodName: 'Raspberries', amount: '6.5g fiber per 100g' },
          { foodName: 'Chia seeds', amount: '34g fiber per 100g' },
          { foodName: 'Whole wheat pasta (cooked)', amount: '3.9g fiber per 100g' },
        ],
        references: [{ label: 'Dietary Guidelines for Americans' }],
      },
    ],
  },
  {
    code: NutrientCategoryCode.MINERAL,
    name: 'Minerals',
    description:
      'Inorganic nutrients the body needs in smaller amounts for structure, signaling, and fluid balance.',
    articles: [
      {
        slug: 'calcium',
        title: 'Calcium',
        summary: 'Calcium supports bone and tooth structure, muscle function, and nerve signaling.',
        body: "The majority of the body's calcium is stored in bones and teeth, with a small amount circulating in blood where it supports muscle contraction, nerve signaling, and blood clotting. Dairy products, fortified plant milks, and leafy greens are common dietary sources.",
        foodSources: [
          { foodName: 'Milk', amount: '113mg calcium per 100g' },
          { foodName: 'Kale (cooked)', amount: '150mg calcium per 100g' },
          { foodName: 'Sardines (with bones)', amount: '382mg calcium per 100g' },
          { foodName: 'Fortified plant milk', amount: 'Varies by brand — check the label' },
        ],
        references: [{ label: 'NIH Office of Dietary Supplements' }],
      },
      {
        slug: 'iron',
        title: 'Iron',
        summary: 'Iron helps red blood cells carry oxygen throughout the body.',
        body: 'Iron exists in food in two forms: heme iron (from animal sources, generally absorbed more easily) and non-heme iron (from plant sources). Pairing non-heme iron foods with a source of vitamin C can help the body absorb more of it.',
        foodSources: [
          { foodName: 'Beef', amount: '2.6mg iron per 100g' },
          { foodName: 'Spinach (cooked)', amount: '2.7mg iron per 100g' },
          { foodName: 'Lentils (cooked)', amount: '3.3mg iron per 100g' },
          { foodName: 'Fortified cereal', amount: 'Varies by brand — check the label' },
        ],
        references: [{ label: 'NIH Office of Dietary Supplements' }],
      },
      {
        slug: 'magnesium',
        title: 'Magnesium',
        summary:
          "Magnesium is involved in hundreds of the body's enzymatic reactions, including energy production and muscle function.",
        body: 'Magnesium supports processes ranging from protein synthesis to muscle and nerve function to blood glucose regulation. It is found widely across plant and animal foods, particularly nuts, seeds, whole grains, and leafy greens.',
        foodSources: [
          { foodName: 'Pumpkin seeds', amount: '550mg magnesium per 100g' },
          { foodName: 'Spinach (cooked)', amount: '79mg magnesium per 100g' },
          { foodName: 'Almonds', amount: '270mg magnesium per 100g' },
          { foodName: 'Black beans (cooked)', amount: '70mg magnesium per 100g' },
        ],
        references: [{ label: 'NIH Office of Dietary Supplements' }],
      },
      {
        slug: 'potassium',
        title: 'Potassium',
        summary:
          'Potassium helps regulate fluid balance, nerve signals, and muscle contractions, including the heartbeat.',
        body: 'Potassium works alongside sodium to help maintain fluid balance across cells and supports normal muscle and nerve function. Fruits and vegetables, especially bananas, potatoes, and leafy greens, are well known dietary sources.',
        foodSources: [
          { foodName: 'Potato (with skin)', amount: '425mg potassium per 100g' },
          { foodName: 'Banana', amount: '358mg potassium per 100g' },
          { foodName: 'White beans (cooked)', amount: '561mg potassium per 100g' },
          { foodName: 'Spinach (cooked)', amount: '558mg potassium per 100g' },
        ],
        references: [{ label: 'NIH Office of Dietary Supplements' }],
      },
    ],
  },
  {
    code: NutrientCategoryCode.VITAMIN,
    name: 'Vitamins',
    description:
      'Organic compounds the body needs in small amounts for processes like immune function, vision, and blood formation.',
    articles: [
      {
        slug: 'vitamin-d',
        title: 'Vitamin D',
        summary: 'Vitamin D helps the body absorb calcium and supports bone and immune health.',
        body: 'The body can produce vitamin D when skin is exposed to sunlight, and it is also available from a small number of foods and fortified products. Because natural food sources are limited, many public health guidelines highlight it as a nutrient worth paying attention to.',
        foodSources: [
          { foodName: 'Fatty fish (e.g. salmon)', amount: 'Varies by species and preparation' },
          { foodName: 'Fortified milk', amount: 'Varies by brand — check the label' },
          { foodName: 'Egg yolks', amount: 'A small amount per yolk' },
          { foodName: 'UV-exposed mushrooms', amount: 'Varies by product' },
        ],
        references: [{ label: 'NIH Office of Dietary Supplements' }],
      },
      {
        slug: 'vitamin-c',
        title: 'Vitamin C',
        summary:
          'Vitamin C is an antioxidant involved in immune function, collagen production, and iron absorption.',
        body: 'Vitamin C supports the growth and repair of tissues throughout the body and acts as an antioxidant, helping protect cells from damage. It is found widely in fruits and vegetables, particularly citrus fruits, peppers, and berries.',
        foodSources: [
          { foodName: 'Red bell pepper', amount: '128mg vitamin C per 100g' },
          { foodName: 'Orange', amount: '53mg vitamin C per 100g' },
          { foodName: 'Strawberries', amount: '59mg vitamin C per 100g' },
          { foodName: 'Broccoli (cooked)', amount: '89mg vitamin C per 100g' },
        ],
        references: [{ label: 'NIH Office of Dietary Supplements' }],
      },
      {
        slug: 'vitamin-a',
        title: 'Vitamin A',
        summary: 'Vitamin A supports vision, immune function, and skin health.',
        body: 'Vitamin A comes in two main dietary forms: preformed vitamin A (retinol, from animal sources) and provitamin A carotenoids (like beta-carotene, from plant sources), which the body converts into active vitamin A. It plays a role in low-light vision, immune defense, and cell growth.',
        foodSources: [
          { foodName: 'Sweet potato', amount: '1,043mcg RAE per 100g (as beta-carotene)' },
          { foodName: 'Carrots', amount: '835mcg RAE per 100g (as beta-carotene)' },
          { foodName: 'Spinach (cooked)', amount: '469mcg RAE per 100g (as beta-carotene)' },
          {
            foodName: 'Beef liver',
            amount: "Very high — a small serving covers a full day's need",
          },
        ],
        references: [{ label: 'NIH Office of Dietary Supplements' }],
      },
      {
        slug: 'vitamin-b12',
        title: 'Vitamin B12',
        summary: 'Vitamin B12 supports red blood cell formation and nervous system function.',
        body: 'Vitamin B12 is found naturally in animal products, which is why people following vegan diets are often advised to consider fortified foods or a supplement — a conversation worth having with a healthcare provider rather than self-prescribing a dose. It works closely with folate in red blood cell production and DNA synthesis.',
        foodSources: [
          { foodName: 'Clams', amount: '98mcg vitamin B12 per 100g' },
          { foodName: 'Beef', amount: '2.6mcg vitamin B12 per 100g' },
          {
            foodName: 'Nutritional yeast (fortified)',
            amount: 'Varies by brand — check the label',
          },
          { foodName: 'Fortified plant milk', amount: 'Varies by brand — check the label' },
        ],
        references: [{ label: 'NIH Office of Dietary Supplements' }],
      },
    ],
  },
];
