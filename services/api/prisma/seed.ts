import { PrismaClient, ExerciseDifficulty, MuscleRole } from '@prisma/client';

const prisma = new PrismaClient();

const CATEGORIES = [
  { name: 'Strength', slug: 'strength' },
  { name: 'Cardio', slug: 'cardio' },
  { name: 'Mobility', slug: 'mobility' },
  { name: 'Bodyweight', slug: 'bodyweight' },
  { name: 'Recovery', slug: 'recovery' },
] as const;

const MUSCLE_GROUPS = [
  { name: 'Chest', slug: 'chest' },
  { name: 'Back', slug: 'back' },
  { name: 'Shoulders', slug: 'shoulders' },
  { name: 'Arms', slug: 'arms' },
  { name: 'Core', slug: 'core' },
  { name: 'Glutes', slug: 'glutes' },
  { name: 'Legs', slug: 'legs' },
  { name: 'Calves', slug: 'calves' },
] as const;

const EQUIPMENT_TYPES = [
  { name: 'Barbell', slug: 'barbell' },
  { name: 'Dumbbell', slug: 'dumbbell' },
  { name: 'Kettlebell', slug: 'kettlebell' },
  { name: 'Resistance Band', slug: 'resistance-band' },
  { name: 'Bodyweight', slug: 'bodyweight-equipment' },
] as const;

interface ExerciseSeed {
  slug: string;
  name: string;
  category: (typeof CATEGORIES)[number]['slug'];
  difficulty: ExerciseDifficulty;
  description: string;
  instructions: string;
  safetyTips: string;
  commonMistakes: string;
  primaryMuscles: Array<(typeof MUSCLE_GROUPS)[number]['slug']>;
  secondaryMuscles?: Array<(typeof MUSCLE_GROUPS)[number]['slug']>;
  equipment: Array<(typeof EQUIPMENT_TYPES)[number]['slug']>;
}

const EXERCISES: ExerciseSeed[] = [
  {
    slug: 'barbell-back-squat',
    name: 'Barbell Back Squat',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'A compound lower-body lift: a loaded barbell across the upper back, squatting to depth and standing back up.',
    instructions:
      'Set the bar in a rack at upper-chest height. Step under it, rest it across your upper trapezius, and unrack it. Stand with feet shoulder-width apart. Bend your knees and hips together to descend until thighs are at least parallel to the floor, keeping your chest up and knees tracking over your toes. Drive through your heels to stand back up.',
    safetyTips:
      'Use a squat rack with safety bars set just below your bottom position. Keep your lower back neutral, not rounded. Stop the set if you lose tightness in your core.',
    commonMistakes: 'Letting the knees cave inward, rounding the lower back, or rising onto the toes instead of driving through the heels.',
    primaryMuscles: ['legs', 'glutes'],
    secondaryMuscles: ['core'],
    equipment: ['barbell'],
  },
  {
    slug: 'barbell-bench-press',
    name: 'Barbell Bench Press',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'A compound upper-body push: pressing a loaded barbell from the chest to full arm extension while lying on a bench.',
    instructions:
      'Lie on a flat bench with eyes under the bar. Grip slightly wider than shoulder-width. Unrack the bar over your chest, lower it under control to your mid-chest, then press it back up to full extension.',
    safetyTips: 'Always use a spotter or safety arms when lifting near your limit. Keep your feet flat on the floor and shoulder blades pulled together.',
    commonMistakes: 'Bouncing the bar off the chest, flaring the elbows to 90 degrees, or lifting the hips off the bench.',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['shoulders', 'arms'],
    equipment: ['barbell'],
  },
  {
    slug: 'deadlift',
    name: 'Deadlift',
    category: 'strength',
    difficulty: ExerciseDifficulty.ADVANCED,
    description: 'A full-body hinge lift: pulling a loaded barbell from the floor to hip level.',
    instructions:
      'Stand with feet hip-width apart, bar over mid-foot. Hinge at the hips and bend the knees to grip the bar just outside your legs. Keep your back flat, chest up, and drive through the floor to stand tall, keeping the bar close to your body throughout.',
    safetyTips: 'Keep the bar close to your shins and thighs the whole lift. Never round your lower back to force a rep — lower the weight instead.',
    commonMistakes: "Letting the bar drift away from the body, hyperextending at the top, or starting with the hips too low (turning it into a squat).",
    primaryMuscles: ['back', 'glutes'],
    secondaryMuscles: ['legs', 'core'],
    equipment: ['barbell'],
  },
  {
    slug: 'overhead-press',
    name: 'Overhead Press',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'A standing compound push: pressing a barbell from shoulder height to overhead.',
    instructions:
      'Stand with the bar racked at shoulder height, grip just outside shoulder-width. Brace your core and press the bar straight overhead, moving your head back slightly to let it pass, then finish with the bar over your ears.',
    safetyTips: 'Avoid arching the lower back excessively to compensate for limited shoulder mobility — keep glutes and core braced.',
    commonMistakes: 'Pressing the bar forward instead of straight up, or using leg drive without intending to (turning it into a push press).',
    primaryMuscles: ['shoulders'],
    secondaryMuscles: ['arms'],
    equipment: ['barbell'],
  },
  {
    slug: 'barbell-row',
    name: 'Barbell Row',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'A compound pulling exercise: hinging forward and rowing a barbell to the torso.',
    instructions:
      'Hinge at the hips with a flat back until your torso is close to parallel with the floor. Grip the bar just outside your legs. Pull it to your lower ribcage, squeezing your shoulder blades together, then lower under control.',
    safetyTips: 'Keep your lower back neutral throughout — if it starts to round, reduce the weight.',
    commonMistakes: 'Using momentum (jerking the torso up) instead of pulling with the back, or rowing to the wrong height.',
    primaryMuscles: ['back'],
    secondaryMuscles: ['arms'],
    equipment: ['barbell'],
  },
  {
    slug: 'dumbbell-bicep-curl',
    name: 'Dumbbell Bicep Curl',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'An isolation exercise for the biceps using a pair of dumbbells.',
    instructions:
      'Stand holding a dumbbell in each hand, arms fully extended, palms facing forward. Curl the weights toward your shoulders without swinging your torso, then lower under control.',
    safetyTips: 'Keep your elbows tucked at your sides and avoid using momentum from your hips or shoulders.',
    commonMistakes: 'Swinging the weight up using body momentum, or only performing a partial range of motion.',
    primaryMuscles: ['arms'],
    equipment: ['dumbbell'],
  },
  {
    slug: 'dumbbell-shoulder-press',
    name: 'Dumbbell Shoulder Press',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A seated or standing press of two dumbbells from shoulder height to overhead.',
    instructions:
      'Hold a dumbbell in each hand at shoulder height, palms facing forward. Press both weights overhead until your arms are fully extended, then lower back to shoulder height.',
    safetyTips: 'Avoid locking the elbows aggressively at the top, and keep your core braced to protect your lower back.',
    commonMistakes: 'Arching the lower back excessively, or letting the dumbbells drift forward instead of pressing straight up.',
    primaryMuscles: ['shoulders'],
    secondaryMuscles: ['arms'],
    equipment: ['dumbbell'],
  },
  {
    slug: 'dumbbell-lunge',
    name: 'Dumbbell Lunge',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A single-leg strength exercise stepping forward into a lunge while holding dumbbells.',
    instructions:
      'Hold a dumbbell in each hand at your sides. Step forward with one leg, lowering your hips until both knees are bent around 90 degrees. Push through the front heel to return to standing, then alternate legs.',
    safetyTips: 'Keep your front knee tracking over your foot, not caving inward, and avoid letting the back knee slam into the floor.',
    commonMistakes: 'Taking too short a step (limiting range of motion), or leaning the torso too far forward.',
    primaryMuscles: ['legs', 'glutes'],
    equipment: ['dumbbell'],
  },
  {
    slug: 'kettlebell-swing',
    name: 'Kettlebell Swing',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'A ballistic hip-hinge movement that swings a kettlebell from between the legs to chest height using hip drive.',
    instructions:
      'Stand with feet shoulder-width apart, kettlebell on the floor in front of you. Hinge at the hips to grip it, then hike it back between your legs. Snap your hips forward to swing the bell up to chest height, letting it float briefly before it falls back into the next hinge.',
    safetyTips: 'The power comes from the hips, not the arms or lower back — never squat the movement or muscle it up with your shoulders.',
    commonMistakes: 'Squatting instead of hinging, or using the arms to lift the bell instead of hip drive.',
    primaryMuscles: ['glutes', 'back'],
    secondaryMuscles: ['core'],
    equipment: ['kettlebell'],
  },
  {
    slug: 'push-up',
    name: 'Push-Up',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A bodyweight pressing exercise performed in a plank position.',
    instructions:
      'Start in a plank position, hands slightly wider than shoulder-width. Lower your chest toward the floor by bending your elbows, keeping your body in a straight line, then press back up.',
    safetyTips: 'Keep your core and glutes braced so your hips don’t sag or pike during the movement.',
    commonMistakes: 'Letting the hips sag, flaring the elbows straight out to the sides, or only performing a partial range of motion.',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['arms', 'shoulders'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'pull-up',
    name: 'Pull-Up',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.ADVANCED,
    description: 'A bodyweight pulling exercise hanging from and pulling the body up to a bar.',
    instructions:
      'Hang from a pull-up bar with an overhand grip, slightly wider than shoulder-width. Pull your chin above the bar by driving your elbows down and back, then lower under control to a full hang.',
    safetyTips: 'Avoid kipping or swinging momentum if training strength rather than a specific kipping skill.',
    commonMistakes: 'Not achieving a full range of motion (partial reps), or excessive swinging.',
    primaryMuscles: ['back'],
    secondaryMuscles: ['arms'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'bodyweight-squat',
    name: 'Bodyweight Squat',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A fundamental lower-body movement squatting down and standing back up using only body weight.',
    instructions:
      'Stand with feet shoulder-width apart. Bend your knees and hips to lower your body until your thighs are at least parallel to the floor, keeping your chest up, then stand back up.',
    safetyTips: 'Keep your weight balanced through your whole foot, not just your toes or heels.',
    commonMistakes: 'Letting the knees cave inward, or not reaching a full range of motion.',
    primaryMuscles: ['legs', 'glutes'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'plank',
    name: 'Plank',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'An isometric core hold, supporting the body in a straight line on the forearms and toes.',
    instructions:
      'Rest on your forearms and toes, elbows under your shoulders. Keep your body in a straight line from head to heels, bracing your core and glutes, and hold the position.',
    safetyTips: 'Stop if your lower back starts to sag or ache — that means your core has fatigued and form is breaking down.',
    commonMistakes: 'Letting the hips sag toward the floor, or piking the hips up too high.',
    primaryMuscles: ['core'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'mountain-climbers',
    name: 'Mountain Climbers',
    category: 'cardio',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A dynamic bodyweight exercise driving the knees toward the chest from a plank position at pace.',
    instructions:
      'Start in a high plank. Drive one knee toward your chest, then quickly switch legs, as if running in place horizontally, keeping your hips low and core braced.',
    safetyTips: 'Keep your hands firmly planted and your core tight to avoid your hips bouncing excessively.',
    commonMistakes: 'Letting the hips rise too high (turning it into a hip-flexor stretch rather than a conditioning movement).',
    primaryMuscles: ['core'],
    secondaryMuscles: ['legs'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'burpee',
    name: 'Burpee',
    category: 'cardio',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'A full-body conditioning movement combining a squat, plank, push-up, and jump.',
    instructions:
      'From standing, squat down and place your hands on the floor. Jump your feet back into a plank, perform a push-up, jump your feet back to your hands, then explode upward into a jump.',
    safetyTips: 'Step back into the plank instead of jumping if you need to protect your lower back or wrists.',
    commonMistakes: 'Letting the hips sag during the plank/push-up phase, or skipping the full squat depth on landing.',
    primaryMuscles: ['legs'],
    secondaryMuscles: ['core', 'arms'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'jumping-jacks',
    name: 'Jumping Jacks',
    category: 'cardio',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A classic full-body cardio movement jumping the feet and arms out and back in.',
    instructions:
      'Start standing with feet together, arms at your sides. Jump your feet out to the sides while raising your arms overhead, then jump back to the starting position.',
    safetyTips: 'Land softly with slightly bent knees to reduce impact on the joints.',
    commonMistakes: 'Landing stiff-legged, or not fully extending the arms overhead.',
    primaryMuscles: ['legs'],
    secondaryMuscles: ['shoulders'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'resistance-band-row',
    name: 'Resistance Band Row',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A pulling exercise for the back using a resistance band anchored in front of the body.',
    instructions:
      'Anchor a band at chest height. Hold an end in each hand, arms extended toward the anchor. Pull both handles toward your torso, squeezing your shoulder blades together, then extend back out under control.',
    safetyTips: 'Keep a slight bend in the knees and a neutral spine throughout the pull.',
    commonMistakes: 'Using the arms alone without engaging the back, or leaning back excessively to add momentum.',
    primaryMuscles: ['back'],
    secondaryMuscles: ['arms'],
    equipment: ['resistance-band'],
  },
  {
    slug: 'resistance-band-lateral-walk',
    name: 'Resistance Band Lateral Walk',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A hip and glute activation exercise stepping sideways against band resistance.',
    instructions:
      'Place a looped band around your legs, above the knees or ankles. Get into a quarter-squat stance and step sideways, keeping tension on the band, for the desired number of steps in each direction.',
    safetyTips: 'Keep your knees tracking over your toes and avoid standing fully upright between steps, which releases band tension.',
    commonMistakes: 'Standing too upright (losing glute engagement), or taking steps that are too large and unstable.',
    primaryMuscles: ['glutes'],
    secondaryMuscles: ['legs'],
    equipment: ['resistance-band'],
  },
  {
    slug: 'cat-cow-stretch',
    name: 'Cat-Cow Stretch',
    category: 'mobility',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A gentle, flowing spinal mobility exercise performed on hands and knees.',
    instructions:
      'Start on hands and knees. Inhale, dropping your belly and lifting your chest and tailbone (cow). Exhale, rounding your spine toward the ceiling and tucking your chin (cat). Flow smoothly between the two.',
    safetyTips: 'Move within a comfortable range — this should never be painful, only a gentle stretch.',
    commonMistakes: 'Moving too fast to actually mobilize the spine, or only moving the neck instead of the whole spine.',
    primaryMuscles: ['back'],
    secondaryMuscles: ['core'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'worlds-greatest-stretch',
    name: "World's Greatest Stretch",
    category: 'mobility',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'A multi-plane dynamic stretch combining a lunge, rotation, and hamstring stretch in one flow.',
    instructions:
      'Step into a deep lunge. Place both hands on the floor inside your front foot. Rotate your torso and reach your front-side arm toward the ceiling, then return your hand to the floor and straighten your front leg for a hamstring stretch. Repeat on both sides.',
    safetyTips: 'Move slowly and only rotate as far as feels comfortable in your hips and thoracic spine.',
    commonMistakes: 'Rushing through the positions instead of holding each briefly, or letting the front knee collapse inward.',
    primaryMuscles: ['legs'],
    secondaryMuscles: ['back', 'shoulders'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'foam-roll-quad-release',
    name: 'Foam Roll Quad Release',
    category: 'recovery',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A self-myofascial release technique for the quadriceps using a foam roller.',
    instructions:
      'Lie face down with a foam roller under your thighs, supporting your weight on your forearms. Slowly roll from just above the knee to just below the hip, pausing on any tender spots for a few breaths.',
    safetyTips: 'Avoid rolling directly over the knee joint itself, and keep pressure moderate rather than maximal.',
    commonMistakes: 'Rolling too quickly to allow the tissue to actually release, or rolling directly over a joint.',
    primaryMuscles: ['legs'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'standing-calf-raise',
    name: 'Standing Calf Raise',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'An isolation exercise for the calves, rising onto the toes and lowering back down.',
    instructions:
      'Stand with feet hip-width apart, holding onto something for balance if needed. Rise onto the balls of your feet as high as possible, pause briefly, then lower your heels back to the floor under control.',
    safetyTips: 'Perform the movement through a full range of motion rather than small, fast bounces.',
    commonMistakes: 'Bouncing through a short range of motion, or leaning on support instead of doing the work.',
    primaryMuscles: ['calves'],
    equipment: ['bodyweight-equipment'],
  },
];

/** Bidirectional alternative pairs — both directions are inserted explicitly. */
const ALTERNATIVE_PAIRS: Array<[string, string]> = [
  ['barbell-back-squat', 'bodyweight-squat'],
  ['barbell-bench-press', 'push-up'],
  ['pull-up', 'resistance-band-row'],
  ['barbell-row', 'resistance-band-row'],
  ['dumbbell-lunge', 'bodyweight-squat'],
];

interface WorkoutSeed {
  slug: string;
  name: string;
  category: (typeof CATEGORIES)[number]['slug'];
  difficulty: ExerciseDifficulty;
  description: string;
  estimatedDurationMinutes: number;
  exercises: Array<{
    exercise: string;
    order: number;
    targetSets: number;
    targetReps?: number;
    targetDurationSeconds?: number;
    restSeconds?: number;
  }>;
}

const WORKOUTS: WorkoutSeed[] = [
  {
    slug: 'full-body-strength',
    name: 'Full Body Strength',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'A balanced full-body strength session covering the major lower- and upper-body movement patterns.',
    estimatedDurationMinutes: 45,
    exercises: [
      { exercise: 'barbell-back-squat', order: 1, targetSets: 4, targetReps: 8, restSeconds: 120 },
      { exercise: 'barbell-bench-press', order: 2, targetSets: 4, targetReps: 8, restSeconds: 120 },
      { exercise: 'barbell-row', order: 3, targetSets: 3, targetReps: 10, restSeconds: 90 },
      { exercise: 'plank', order: 4, targetSets: 3, targetDurationSeconds: 45, restSeconds: 60 },
    ],
  },
  {
    slug: 'upper-body-push',
    name: 'Upper Body Push',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'Chest, shoulders, and triceps-focused pressing session.',
    estimatedDurationMinutes: 40,
    exercises: [
      { exercise: 'barbell-bench-press', order: 1, targetSets: 4, targetReps: 8, restSeconds: 120 },
      { exercise: 'overhead-press', order: 2, targetSets: 3, targetReps: 8, restSeconds: 90 },
      { exercise: 'push-up', order: 3, targetSets: 3, targetReps: 15, restSeconds: 60 },
      { exercise: 'dumbbell-bicep-curl', order: 4, targetSets: 3, targetReps: 12, restSeconds: 60 },
    ],
  },
  {
    slug: 'bodyweight-hiit-blast',
    name: 'Bodyweight HIIT Blast',
    category: 'cardio',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'A fast-paced, equipment-free conditioning circuit.',
    estimatedDurationMinutes: 20,
    exercises: [
      { exercise: 'jumping-jacks', order: 1, targetSets: 4, targetDurationSeconds: 30, restSeconds: 15 },
      { exercise: 'burpee', order: 2, targetSets: 4, targetReps: 10, restSeconds: 30 },
      { exercise: 'mountain-climbers', order: 3, targetSets: 4, targetDurationSeconds: 30, restSeconds: 15 },
      { exercise: 'bodyweight-squat', order: 4, targetSets: 4, targetReps: 15, restSeconds: 30 },
    ],
  },
  {
    slug: 'mobility-recovery-flow',
    name: 'Mobility & Recovery Flow',
    category: 'mobility',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A gentle mobility and recovery session for rest days or warm-ups.',
    estimatedDurationMinutes: 15,
    exercises: [
      { exercise: 'cat-cow-stretch', order: 1, targetSets: 2, targetDurationSeconds: 60, restSeconds: 15 },
      { exercise: 'worlds-greatest-stretch', order: 2, targetSets: 2, targetReps: 5, restSeconds: 30 },
      { exercise: 'foam-roll-quad-release', order: 3, targetSets: 1, targetDurationSeconds: 90, restSeconds: 0 },
    ],
  },
];

async function main() {
  const categoryIds = new Map<string, string>();
  for (const category of CATEGORIES) {
    const row = await prisma.exerciseCategory.upsert({
      where: { slug: category.slug },
      create: category,
      update: { name: category.name },
    });
    categoryIds.set(category.slug, row.id);
  }

  const muscleIds = new Map<string, string>();
  for (const muscle of MUSCLE_GROUPS) {
    const row = await prisma.muscleGroup.upsert({
      where: { slug: muscle.slug },
      create: muscle,
      update: { name: muscle.name },
    });
    muscleIds.set(muscle.slug, row.id);
  }

  const equipmentIds = new Map<string, string>();
  for (const equipment of EQUIPMENT_TYPES) {
    const row = await prisma.equipmentType.upsert({
      where: { slug: equipment.slug },
      create: equipment,
      update: { name: equipment.name },
    });
    equipmentIds.set(equipment.slug, row.id);
  }

  const exerciseIds = new Map<string, string>();
  for (const exercise of EXERCISES) {
    const row = await prisma.exercise.upsert({
      where: { slug: exercise.slug },
      create: {
        slug: exercise.slug,
        name: exercise.name,
        categoryId: categoryIds.get(exercise.category)!,
        difficulty: exercise.difficulty,
        description: exercise.description,
        instructions: exercise.instructions,
        safetyTips: exercise.safetyTips,
        commonMistakes: exercise.commonMistakes,
      },
      update: {
        name: exercise.name,
        categoryId: categoryIds.get(exercise.category)!,
        difficulty: exercise.difficulty,
        description: exercise.description,
        instructions: exercise.instructions,
        safetyTips: exercise.safetyTips,
        commonMistakes: exercise.commonMistakes,
      },
    });
    exerciseIds.set(exercise.slug, row.id);

    // Re-derive the muscle/equipment join rows from scratch each run so
    // editing a seed exercise's muscles/equipment doesn't leave stale rows.
    await prisma.exerciseMuscle.deleteMany({ where: { exerciseId: row.id } });
    await prisma.exerciseMuscle.createMany({
      data: [
        ...exercise.primaryMuscles.map((slug) => ({
          exerciseId: row.id,
          muscleGroupId: muscleIds.get(slug)!,
          role: MuscleRole.PRIMARY,
        })),
        ...(exercise.secondaryMuscles ?? []).map((slug) => ({
          exerciseId: row.id,
          muscleGroupId: muscleIds.get(slug)!,
          role: MuscleRole.SECONDARY,
        })),
      ],
    });

    await prisma.exerciseEquipment.deleteMany({ where: { exerciseId: row.id } });
    await prisma.exerciseEquipment.createMany({
      data: exercise.equipment.map((slug) => ({
        exerciseId: row.id,
        equipmentTypeId: equipmentIds.get(slug)!,
      })),
    });
  }

  for (const [a, b] of ALTERNATIVE_PAIRS) {
    for (const [from, to] of [
      [a, b],
      [b, a],
    ]) {
      await prisma.exerciseAlternative.upsert({
        where: {
          exerciseId_alternativeExerciseId: {
            exerciseId: exerciseIds.get(from)!,
            alternativeExerciseId: exerciseIds.get(to)!,
          },
        },
        create: {
          exerciseId: exerciseIds.get(from)!,
          alternativeExerciseId: exerciseIds.get(to)!,
        },
        update: {},
      });
    }
  }

  for (const workout of WORKOUTS) {
    const row = await prisma.workout.upsert({
      where: { slug: workout.slug },
      create: {
        slug: workout.slug,
        name: workout.name,
        categoryId: categoryIds.get(workout.category)!,
        difficulty: workout.difficulty,
        description: workout.description,
        estimatedDurationMinutes: workout.estimatedDurationMinutes,
      },
      update: {
        name: workout.name,
        categoryId: categoryIds.get(workout.category)!,
        difficulty: workout.difficulty,
        description: workout.description,
        estimatedDurationMinutes: workout.estimatedDurationMinutes,
      },
    });

    await prisma.workoutExercise.deleteMany({ where: { workoutId: row.id } });
    await prisma.workoutExercise.createMany({
      data: workout.exercises.map((entry) => ({
        workoutId: row.id,
        exerciseId: exerciseIds.get(entry.exercise)!,
        order: entry.order,
        targetSets: entry.targetSets,
        targetReps: entry.targetReps,
        targetDurationSeconds: entry.targetDurationSeconds,
        restSeconds: entry.restSeconds ?? 60,
      })),
    });
  }

  // eslint-disable-next-line no-console
  console.log(
    `Seeded ${CATEGORIES.length} categories, ${MUSCLE_GROUPS.length} muscle groups, ${EQUIPMENT_TYPES.length} equipment types, ${EXERCISES.length} exercises, ${WORKOUTS.length} workouts.`,
  );
}

main()
  .catch((error) => {
    // eslint-disable-next-line no-console
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
