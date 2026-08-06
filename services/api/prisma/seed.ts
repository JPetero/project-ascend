import {
  PrismaClient,
  ExerciseDifficulty,
  MeasurementType,
  MuscleRole,
  FoodSourceType,
  LegalDocumentType,
  AchievementCategory,
} from '@prisma/client';

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
  measurementType: MeasurementType;
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
    measurementType: MeasurementType.REPS_WEIGHT,
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
    measurementType: MeasurementType.REPS_WEIGHT,
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
    measurementType: MeasurementType.REPS_WEIGHT,
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
    measurementType: MeasurementType.REPS_WEIGHT,
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
    measurementType: MeasurementType.REPS_WEIGHT,
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
    measurementType: MeasurementType.REPS_WEIGHT,
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
    measurementType: MeasurementType.REPS_WEIGHT,
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
    measurementType: MeasurementType.REPS_WEIGHT,
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
    measurementType: MeasurementType.REPS_WEIGHT,
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
    measurementType: MeasurementType.BODYWEIGHT,
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
    measurementType: MeasurementType.BODYWEIGHT,
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
    measurementType: MeasurementType.BODYWEIGHT,
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
    measurementType: MeasurementType.DURATION,
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
    measurementType: MeasurementType.DURATION,
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
    measurementType: MeasurementType.REPS_ONLY,
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
    measurementType: MeasurementType.DURATION,
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
    measurementType: MeasurementType.REPS_ONLY,
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
    measurementType: MeasurementType.REPS_ONLY,
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
    measurementType: MeasurementType.DURATION,
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
    measurementType: MeasurementType.REPS_ONLY,
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
    measurementType: MeasurementType.DURATION,
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
    measurementType: MeasurementType.BODYWEIGHT,
    description: 'An isolation exercise for the calves, rising onto the toes and lowering back down.',
    instructions:
      'Stand with feet hip-width apart, holding onto something for balance if needed. Rise onto the balls of your feet as high as possible, pause briefly, then lower your heels back to the floor under control.',
    safetyTips: 'Perform the movement through a full range of motion rather than small, fast bounces.',
    commonMistakes: 'Bouncing through a short range of motion, or leaning on support instead of doing the work.',
    primaryMuscles: ['calves'],
    equipment: ['bodyweight-equipment'],
  },
  // --- Bodyweight regressions and core work -------------------------------
  {
    slug: 'incline-push-up',
    name: 'Incline Push-Up',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.BODYWEIGHT,
    description: 'A push-up regression using an elevated surface to reduce the load, for building toward a standard push-up.',
    instructions: 'Place both hands on a stable elevated surface (bench, step, or sturdy table) slightly wider than shoulder-width. Walk your feet back until your body forms a straight line, then lower your chest to the surface and press back up.',
    safetyTips: 'Use a surface that will not slide or tip. Keep your core braced so your hips do not sag.',
    commonMistakes: 'Letting the hips sag or pike up, or only lowering a few inches instead of a full range of motion.',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['shoulders', 'arms'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'knee-push-up',
    name: 'Knee Push-Up',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.BODYWEIGHT,
    description: 'A push-up regression performed from the knees instead of the toes, for building pressing strength.',
    instructions: 'Start on hands and knees, hands slightly wider than shoulder-width, and cross your ankles behind you. Keep a straight line from knees to head, lower your chest toward the floor, then press back up.',
    safetyTips: 'Keep the core braced throughout rather than letting the lower back sag.',
    commonMistakes: 'Letting the hips pike up to make the movement easier, or flaring the elbows to 90 degrees.',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['shoulders', 'arms'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'wall-sit',
    name: 'Wall Sit',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.DURATION,
    description: 'An isometric lower-body hold with the back against a wall and knees bent to roughly 90 degrees.',
    instructions: 'Stand with your back against a wall and slide down until your thighs are roughly parallel to the floor, knees over ankles. Hold the position, keeping your back flat against the wall.',
    safetyTips: 'Stop if you feel sharp knee pain — mild muscular fatigue in the thighs is expected, joint pain is not.',
    commonMistakes: 'Letting the knees drift past the toes, or resting hands on the thighs to take weight off the legs.',
    primaryMuscles: ['legs'],
    secondaryMuscles: ['glutes'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'glute-bridge',
    name: 'Glute Bridge',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.BODYWEIGHT,
    description: 'A hip-hinge exercise lying on your back, raising the hips by squeezing the glutes.',
    instructions: 'Lie on your back with knees bent and feet flat on the floor, hip-width apart. Drive through your heels to lift your hips until your body forms a straight line from shoulders to knees, squeezing your glutes at the top, then lower under control.',
    safetyTips: 'Avoid overextending the lower back at the top — the lift should come from the glutes, not an arched spine.',
    commonMistakes: 'Pushing through the toes instead of the heels, or not fully extending the hips at the top.',
    primaryMuscles: ['glutes'],
    secondaryMuscles: ['legs', 'core'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'superman-hold',
    name: 'Superman Hold',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.DURATION,
    description: 'A prone isometric hold that lightly extends the spine to build lower-back and glute endurance.',
    instructions: 'Lie face down with arms extended in front of you. Simultaneously lift your arms, chest, and legs a few inches off the floor, and hold briefly before lowering.',
    safetyTips: 'This is a gentle extension, not a maximal arch — keep the range of motion small and controlled, especially if you have any back sensitivity.',
    commonMistakes: 'Yanking upward instead of lifting smoothly, or holding the breath instead of breathing normally.',
    primaryMuscles: ['back'],
    secondaryMuscles: ['glutes'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'dead-bug',
    name: 'Dead Bug',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.REPS_ONLY,
    description: 'A core-stability exercise performed on the back, moving opposite arm and leg while keeping the spine still.',
    instructions: 'Lie on your back with arms reaching toward the ceiling and knees bent at 90 degrees above your hips. Slowly lower one arm overhead and the opposite leg toward the floor while keeping your lower back pressed into the floor, then return and switch sides.',
    safetyTips: 'Only lower the arm/leg as far as you can while keeping your lower back flat on the floor.',
    commonMistakes: 'Letting the lower back arch off the floor, or moving too fast to control the position.',
    primaryMuscles: ['core'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'bird-dog',
    name: 'Bird Dog',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.REPS_ONLY,
    description: 'A core-stability exercise on hands and knees, extending the opposite arm and leg while keeping the torso still.',
    instructions: 'Start on hands and knees, hands under shoulders and knees under hips. Extend one arm forward and the opposite leg back until both are roughly parallel to the floor, hold briefly, then return and switch sides.',
    safetyTips: 'Keep the hips level throughout — avoid rotating the torso to gain extra range.',
    commonMistakes: 'Arching the lower back, or moving quickly instead of holding each position briefly.',
    primaryMuscles: ['core'],
    secondaryMuscles: ['back', 'glutes'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'step-up',
    name: 'Step-Up',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.BODYWEIGHT,
    description: 'A single-leg lower-body exercise stepping up onto a stable elevated surface.',
    instructions: 'Stand facing a sturdy step or bench. Place one foot fully on the surface, drive through that heel to stand up onto it, then step back down under control. Alternate legs.',
    safetyTips: 'Use a step height you can control without your back knee needing to help push you up.',
    commonMistakes: 'Pushing off the trailing leg instead of driving through the stepping leg, or using a step that is too high.',
    primaryMuscles: ['legs'],
    secondaryMuscles: ['glutes'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'chair-squat',
    name: 'Chair Squat',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.BODYWEIGHT,
    description: 'A bodyweight squat regression that uses a chair as a depth guide and safety net for beginners.',
    instructions: 'Stand in front of a sturdy chair with feet shoulder-width apart. Bend your knees and hips to lower yourself until you lightly touch the seat, then stand back up. Use it as a checkpoint, not a full rest between reps.',
    safetyTips: 'Make sure the chair will not slide. Keep the descent controlled rather than dropping onto the seat.',
    commonMistakes: 'Fully sitting down and pausing between every rep, or letting the knees cave inward.',
    primaryMuscles: ['legs'],
    secondaryMuscles: ['glutes'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'side-plank',
    name: 'Side Plank',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    measurementType: MeasurementType.DURATION,
    description: 'An isometric core hold on one side of the body, supported on one forearm.',
    instructions: 'Lie on your side with your elbow under your shoulder. Lift your hips until your body forms a straight line from ankles to head, hold, then repeat on the other side.',
    safetyTips: 'Stack your feet or stagger them for balance — whichever keeps your hips level without pain.',
    commonMistakes: 'Letting the hips sag toward the floor, or rotating the torso forward or backward.',
    primaryMuscles: ['core'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'bicycle-crunch',
    name: 'Bicycle Crunch',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.REPS_ONLY,
    description: 'A rotational core exercise alternating elbow-to-opposite-knee on your back.',
    instructions: 'Lie on your back with hands lightly behind your head and knees bent above your hips. Bring one elbow toward the opposite knee while extending the other leg, then switch sides in a smooth pedaling motion.',
    safetyTips: 'Avoid pulling on your neck with your hands — let your core do the work.',
    commonMistakes: 'Moving too fast to keep tension in the core, or fully straightening the extended leg to the floor.',
    primaryMuscles: ['core'],
    equipment: ['bodyweight-equipment'],
  },
  // --- Dumbbell -------------------------------------------------------------
  {
    slug: 'dumbbell-goblet-squat',
    name: 'Dumbbell Goblet Squat',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.REPS_WEIGHT,
    description: 'A squat variation holding a single dumbbell at the chest, a beginner-friendly way to learn squat mechanics.',
    instructions: 'Hold a dumbbell vertically against your chest with both hands. Squat down, keeping your chest up and elbows tracking inside your knees, until your thighs are at least parallel to the floor, then stand back up.',
    safetyTips: 'The front-loaded weight naturally encourages an upright torso — if you feel yourself folding forward, reduce the weight.',
    commonMistakes: 'Letting the knees cave inward, or only squatting a partial range of motion.',
    primaryMuscles: ['legs', 'glutes'],
    secondaryMuscles: ['core'],
    equipment: ['dumbbell'],
  },
  {
    slug: 'dumbbell-romanian-deadlift',
    name: 'Dumbbell Romanian Deadlift',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    measurementType: MeasurementType.REPS_WEIGHT,
    description: 'A hip-hinge exercise with dumbbells that targets the hamstrings and glutes through a controlled lowering phase.',
    instructions: 'Hold a dumbbell in each hand in front of your thighs. Keeping a slight bend in the knees and your back flat, hinge at the hips to lower the dumbbells along your legs until you feel a stretch in your hamstrings, then drive your hips forward to stand back up.',
    safetyTips: 'Keep the dumbbells close to your legs throughout, and stop the descent once your back would need to round to go further.',
    commonMistakes: 'Rounding the lower back, or turning it into a squat by bending the knees too much.',
    primaryMuscles: ['legs', 'glutes'],
    secondaryMuscles: ['back'],
    equipment: ['dumbbell'],
  },
  {
    slug: 'dumbbell-chest-press',
    name: 'Dumbbell Chest Press',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.REPS_WEIGHT,
    description: 'A pressing exercise lying on a bench or floor, pressing a dumbbell in each hand up from the chest.',
    instructions: 'Lie on a bench (or the floor) holding a dumbbell in each hand at chest level, elbows bent. Press the dumbbells up until your arms are extended, then lower them back under control.',
    safetyTips: 'Choose a weight you can lower under control — dropping the dumbbells at the bottom risks shoulder strain.',
    commonMistakes: 'Flaring the elbows out to 90 degrees, or letting the dumbbells drift together or apart unevenly.',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['shoulders', 'arms'],
    equipment: ['dumbbell'],
  },
  {
    slug: 'dumbbell-bent-over-row',
    name: 'Dumbbell Bent-Over Row',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    measurementType: MeasurementType.REPS_WEIGHT,
    description: 'A hinged rowing exercise pulling a dumbbell in each hand toward the ribs.',
    instructions: 'Hinge forward at the hips with a flat back, holding a dumbbell in each hand hanging below your shoulders. Pull the dumbbells up toward your ribs, squeezing your shoulder blades together, then lower under control.',
    safetyTips: 'Keep the hinge angle you can hold with a flat back — if your back rounds, stand up a bit taller.',
    commonMistakes: 'Using momentum to jerk the weight up, or rounding the lower back.',
    primaryMuscles: ['back'],
    secondaryMuscles: ['arms'],
    equipment: ['dumbbell'],
  },
  {
    slug: 'dumbbell-lateral-raise',
    name: 'Dumbbell Lateral Raise',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.REPS_WEIGHT,
    description: 'An isolation exercise raising dumbbells out to the sides to target the shoulders.',
    instructions: 'Stand holding a light dumbbell in each hand at your sides. With a slight bend in the elbows, raise both arms out to the sides until roughly shoulder height, then lower under control.',
    safetyTips: 'Use a light weight — this is an isolation movement, and swinging a heavy weight up risks shoulder impingement.',
    commonMistakes: 'Using momentum/swinging instead of a controlled raise, or raising the arms above shoulder height.',
    primaryMuscles: ['shoulders'],
    equipment: ['dumbbell'],
  },
  {
    slug: 'dumbbell-tricep-extension',
    name: 'Dumbbell Overhead Tricep Extension',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.REPS_WEIGHT,
    description: 'An isolation exercise extending a dumbbell overhead to target the triceps.',
    instructions: 'Hold one dumbbell with both hands overhead, arms extended. Bend your elbows to lower the dumbbell behind your head, keeping your upper arms still, then extend back up.',
    safetyTips: 'Keep your elbows pointed forward and close to your head rather than flaring out.',
    commonMistakes: 'Letting the elbows flare out wide, or using a weight heavy enough that the lower back arches to compensate.',
    primaryMuscles: ['arms'],
    equipment: ['dumbbell'],
  },
  // --- Barbell ---------------------------------------------------------------
  {
    slug: 'barbell-hip-thrust',
    name: 'Barbell Hip Thrust',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    measurementType: MeasurementType.REPS_WEIGHT,
    description: 'A glute-focused hip extension exercise with the upper back supported on a bench and a barbell across the hips.',
    instructions: 'Sit on the floor with your upper back against a bench and a padded barbell across your hips. Drive through your heels to extend your hips until your body forms a straight line from shoulders to knees, then lower under control.',
    safetyTips: 'Use a barbell pad and start with light weight to find a comfortable hip position before adding load.',
    commonMistakes: 'Hyperextending the lower back at the top instead of stopping at a straight line, or pushing through the toes.',
    primaryMuscles: ['glutes'],
    secondaryMuscles: ['legs'],
    equipment: ['barbell'],
  },
  {
    slug: 'barbell-romanian-deadlift',
    name: 'Barbell Romanian Deadlift',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    measurementType: MeasurementType.REPS_WEIGHT,
    description: 'A hip-hinge exercise lowering a barbell along the legs to target the hamstrings and glutes.',
    instructions: 'Hold a barbell in front of your thighs with an overhand grip. Keeping a slight bend in the knees and a flat back, hinge at the hips to lower the bar along your legs until you feel a hamstring stretch, then drive your hips forward to return to standing.',
    safetyTips: 'Keep the bar close to your legs throughout. Stop the descent once your back would need to round to go further.',
    commonMistakes: 'Rounding the lower back, or letting the bar drift away from the legs.',
    primaryMuscles: ['legs', 'glutes'],
    secondaryMuscles: ['back'],
    equipment: ['barbell'],
  },
  // --- Resistance band ---------------------------------------------------
  {
    slug: 'band-pull-apart',
    name: 'Band Pull-Apart',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.REPS_ONLY,
    description: 'A shoulder and upper-back exercise pulling a resistance band apart at chest height.',
    instructions: 'Hold a resistance band with both hands, arms extended in front of you at chest height. Pull the band apart by drawing your hands out to the sides, squeezing your shoulder blades together, then return under control.',
    safetyTips: 'Choose a band tension that lets you complete the movement smoothly without jerking.',
    commonMistakes: 'Bending the elbows to make the pull easier, or using momentum instead of a controlled squeeze.',
    primaryMuscles: ['back'],
    secondaryMuscles: ['shoulders'],
    equipment: ['resistance-band'],
  },
  {
    slug: 'band-bicep-curl',
    name: 'Band Bicep Curl',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.REPS_ONLY,
    description: 'An isolation exercise curling a resistance band to target the biceps.',
    instructions: 'Stand on the middle of a resistance band with feet hip-width apart, holding an end in each hand at your sides. Curl your hands toward your shoulders, keeping your elbows close to your body, then lower under control.',
    safetyTips: 'Check the band for wear before use, and keep tension on it throughout rather than letting it go slack.',
    commonMistakes: 'Swinging the upper arms forward to help the curl, or moving too fast to control the return.',
    primaryMuscles: ['arms'],
    equipment: ['resistance-band'],
  },
  {
    slug: 'band-overhead-press',
    name: 'Band Overhead Press',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.REPS_ONLY,
    description: 'A standing pressing exercise using a resistance band anchored underfoot.',
    instructions: 'Stand on the middle of a resistance band with feet shoulder-width apart, holding an end in each hand at shoulder height. Press both hands straight overhead, then lower back to shoulder height under control.',
    safetyTips: 'Brace your core to avoid arching your lower back as you press overhead.',
    commonMistakes: 'Pressing the hands forward instead of straight up, or arching the back to gain range of motion.',
    primaryMuscles: ['shoulders'],
    secondaryMuscles: ['arms'],
    equipment: ['resistance-band'],
  },
  // --- Mobility ---------------------------------------------------------
  {
    slug: 'hip-flexor-stretch',
    name: 'Kneeling Hip Flexor Stretch',
    category: 'mobility',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.DURATION,
    description: 'A static stretch in a half-kneeling position to lengthen the hip flexors of the rear leg.',
    instructions: 'Kneel on one knee with the other foot planted in front, both at roughly 90 degrees. Gently shift your hips forward until you feel a stretch in the front of the rear hip, keeping your torso upright. Hold, then switch sides.',
    safetyTips: 'Place a cushion under the kneeling knee if the floor is hard. Move into the stretch gradually rather than forcing it.',
    commonMistakes: 'Arching the lower back to fake extra range instead of moving from the hip, or bouncing in and out of the stretch.',
    primaryMuscles: ['legs'],
    secondaryMuscles: ['glutes'],
    equipment: ['bodyweight-equipment'],
  },
  {
    slug: 'ninety-ninety-hip-stretch',
    name: '90/90 Hip Stretch',
    category: 'mobility',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    measurementType: MeasurementType.DURATION,
    description: 'A seated hip-mobility stretch with both legs bent at roughly 90 degrees in opposite rotations.',
    instructions: 'Sit on the floor with your front leg bent 90 degrees in front of you and your back leg bent 90 degrees out to the side. Keeping your chest tall, lean gently forward over the front shin. Hold, then switch sides.',
    safetyTips: 'Work within a comfortable range — hip mobility varies a lot between people, so avoid forcing the position.',
    commonMistakes: 'Rounding the back to lean further forward instead of hinging from the hips, or forcing a position that causes pinching pain.',
    primaryMuscles: ['glutes'],
    secondaryMuscles: ['legs'],
    equipment: ['bodyweight-equipment'],
  },
  // --- Walking and running ------------------------------------------------
  {
    slug: 'brisk-walk',
    name: 'Brisk Walk',
    category: 'cardio',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.DISTANCE_DURATION,
    description: 'Continuous walking at a purposeful pace, the foundation cardio entry point for any fitness level.',
    instructions: 'Walk at a pace where you can hold a conversation but feel your breathing rate increase — noticeably faster than a stroll. Maintain that pace for the planned duration or distance.',
    safetyTips: 'Wear supportive footwear and choose a flat, well-lit route if walking outdoors. Stop if you feel dizzy, chest pain, or unusual shortness of breath.',
    commonMistakes: 'Walking so slowly it provides little cardio benefit, or starting too fast and being unable to sustain the pace.',
    primaryMuscles: ['legs'],
    secondaryMuscles: ['calves'],
    equipment: [],
  },
  {
    slug: 'easy-run',
    name: 'Easy Run',
    category: 'cardio',
    difficulty: ExerciseDifficulty.BEGINNER,
    measurementType: MeasurementType.DISTANCE_DURATION,
    description: 'A conversational-pace run intended to build aerobic base without excessive fatigue.',
    instructions: 'Run at a pace where you could still speak in short sentences. If you cannot, slow down — this session is about consistent aerobic time, not speed.',
    safetyTips: 'Warm up with a few minutes of walking first. Stop and walk if you feel joint pain, chest pain, or lightheadedness.',
    commonMistakes: 'Running every session at maximum effort, which raises injury risk and undermines aerobic-base building.',
    primaryMuscles: ['legs'],
    secondaryMuscles: ['calves', 'core'],
    equipment: [],
  },
  {
    slug: 'interval-run',
    name: 'Interval Run',
    category: 'cardio',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    measurementType: MeasurementType.DISTANCE_DURATION,
    description: 'Alternating segments of faster running and easy jogging or walking recovery.',
    instructions: 'Alternate a harder-effort running segment with an easy jogging or walking recovery segment, repeating for the planned number of rounds. The hard segments should feel challenging but sustainable for their duration.',
    safetyTips: 'Only add interval work once a comfortable easy-run base is established. Skip this session if you are dealing with any leg or foot pain.',
    commonMistakes: 'Sprinting all-out on the hard segments (unsustainable and injury-prone) instead of a controlled hard effort, or cutting recovery segments short.',
    primaryMuscles: ['legs'],
    secondaryMuscles: ['calves', 'core'],
    equipment: [],
  },
];

/** Bidirectional alternative pairs — both directions are inserted explicitly. */
const ALTERNATIVE_PAIRS: Array<[string, string]> = [
  ['barbell-back-squat', 'bodyweight-squat'],
  ['barbell-back-squat', 'dumbbell-goblet-squat'],
  ['barbell-bench-press', 'push-up'],
  ['barbell-bench-press', 'dumbbell-chest-press'],
  ['pull-up', 'resistance-band-row'],
  ['barbell-row', 'resistance-band-row'],
  ['barbell-row', 'dumbbell-bent-over-row'],
  ['dumbbell-lunge', 'bodyweight-squat'],
  ['deadlift', 'dumbbell-romanian-deadlift'],
  ['deadlift', 'barbell-romanian-deadlift'],
  ['overhead-press', 'dumbbell-shoulder-press'],
  ['overhead-press', 'band-overhead-press'],
  ['dumbbell-bicep-curl', 'band-bicep-curl'],
  ['push-up', 'incline-push-up'],
  ['push-up', 'knee-push-up'],
  ['incline-push-up', 'knee-push-up'],
  ['bodyweight-squat', 'chair-squat'],
  ['plank', 'wall-sit'],
  ['barbell-hip-thrust', 'glute-bridge'],
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
    targetDistanceMeters?: number;
    restSeconds?: number;
  }>;
}

// The original four Sprint 2 plans, kept exactly as-is (name, slug, and
// exercise line-up) since `test/workout-engine.e2e-spec.ts` references
// 'full-body-strength' by slug and its exact exercise list — renaming or
// restructuring it would break that coverage for no real benefit. The nine
// plans required by this build session's brief are additional, appended
// below: "at least these starter plans" is a minimum list, not a
// replacement for what already existed.
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
  // Nine more starter plans, added this session, chosen to cover a
  // genuinely different training context each (equipment level, split
  // style, or modality) rather than variations on the same session.
  // "Upper/Lower Starter" and "Push/Pull/Legs Starter" are each a single
  // representative session introducing that split style, not a full
  // multi-day rotation — the data model represents one Workout at a time,
  // so a real multi-day program is future work (see
  // packages/docs/roadmap.md); it would be misleading to imply more days
  // of programming exist than are actually seeded here.
  {
    slug: 'beginner-full-body',
    name: 'Beginner Full Body',
    category: 'strength',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A beginner-friendly full-body strength session using approachable variations of the major lifts.',
    estimatedDurationMinutes: 40,
    exercises: [
      { exercise: 'dumbbell-goblet-squat', order: 1, targetSets: 3, targetReps: 10, restSeconds: 90 },
      { exercise: 'dumbbell-chest-press', order: 2, targetSets: 3, targetReps: 10, restSeconds: 90 },
      { exercise: 'dumbbell-bent-over-row', order: 3, targetSets: 3, targetReps: 10, restSeconds: 90 },
      { exercise: 'glute-bridge', order: 4, targetSets: 3, targetReps: 12, restSeconds: 60 },
      { exercise: 'plank', order: 5, targetSets: 3, targetDurationSeconds: 30, restSeconds: 45 },
    ],
  },
  {
    slug: 'home-bodyweight',
    name: 'Home Bodyweight',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A no-equipment full-body session you can do anywhere, using bodyweight-only movements and their regressions.',
    estimatedDurationMinutes: 30,
    exercises: [
      { exercise: 'bodyweight-squat', order: 1, targetSets: 3, targetReps: 15, restSeconds: 60 },
      { exercise: 'knee-push-up', order: 2, targetSets: 3, targetReps: 10, restSeconds: 60 },
      { exercise: 'glute-bridge', order: 3, targetSets: 3, targetReps: 15, restSeconds: 45 },
      { exercise: 'bird-dog', order: 4, targetSets: 2, targetReps: 10, restSeconds: 30 },
      { exercise: 'plank', order: 5, targetSets: 3, targetDurationSeconds: 30, restSeconds: 45 },
    ],
  },
  {
    slug: 'dumbbell-full-body',
    name: 'Dumbbell Full Body',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'A complete strength session using only a pair of dumbbells, covering every major movement pattern.',
    estimatedDurationMinutes: 45,
    exercises: [
      { exercise: 'dumbbell-goblet-squat', order: 1, targetSets: 4, targetReps: 10, restSeconds: 90 },
      { exercise: 'dumbbell-romanian-deadlift', order: 2, targetSets: 3, targetReps: 10, restSeconds: 90 },
      { exercise: 'dumbbell-chest-press', order: 3, targetSets: 3, targetReps: 10, restSeconds: 90 },
      { exercise: 'dumbbell-bent-over-row', order: 4, targetSets: 3, targetReps: 10, restSeconds: 90 },
      { exercise: 'dumbbell-lateral-raise', order: 5, targetSets: 3, targetReps: 12, restSeconds: 60 },
    ],
  },
  {
    slug: 'upper-lower-starter',
    name: 'Upper/Lower Starter',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'An introductory session touching both an upper- and lower-body pattern, for anyone starting an upper/lower split. One representative session — plan the alternating days yourself for now.',
    estimatedDurationMinutes: 45,
    exercises: [
      { exercise: 'barbell-back-squat', order: 1, targetSets: 4, targetReps: 8, restSeconds: 120 },
      { exercise: 'dumbbell-romanian-deadlift', order: 2, targetSets: 3, targetReps: 10, restSeconds: 90 },
      { exercise: 'barbell-bench-press', order: 3, targetSets: 4, targetReps: 8, restSeconds: 120 },
      { exercise: 'barbell-row', order: 4, targetSets: 3, targetReps: 10, restSeconds: 90 },
    ],
  },
  {
    slug: 'push-pull-legs-starter',
    name: 'Push/Pull/Legs Starter',
    category: 'strength',
    difficulty: ExerciseDifficulty.INTERMEDIATE,
    description: 'An introductory session touching a push, a pull, and a leg pattern, for anyone starting a push/pull/legs split. One representative session — plan the rotating days yourself for now.',
    estimatedDurationMinutes: 45,
    exercises: [
      { exercise: 'barbell-bench-press', order: 1, targetSets: 3, targetReps: 8, restSeconds: 120 },
      { exercise: 'overhead-press', order: 2, targetSets: 3, targetReps: 8, restSeconds: 90 },
      { exercise: 'pull-up', order: 3, targetSets: 3, targetReps: 6, restSeconds: 90 },
      { exercise: 'barbell-row', order: 4, targetSets: 3, targetReps: 10, restSeconds: 90 },
      { exercise: 'barbell-back-squat', order: 5, targetSets: 3, targetReps: 8, restSeconds: 120 },
    ],
  },
  {
    slug: 'calisthenics-starter',
    name: 'Calisthenics Starter',
    category: 'bodyweight',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A bodyweight-only strength session for building toward pull-ups, push-ups, and core control.',
    estimatedDurationMinutes: 30,
    exercises: [
      { exercise: 'incline-push-up', order: 1, targetSets: 3, targetReps: 10, restSeconds: 60 },
      { exercise: 'resistance-band-row', order: 2, targetSets: 3, targetReps: 12, restSeconds: 60 },
      { exercise: 'bodyweight-squat', order: 3, targetSets: 3, targetReps: 15, restSeconds: 60 },
      { exercise: 'side-plank', order: 4, targetSets: 2, targetDurationSeconds: 20, restSeconds: 30 },
      { exercise: 'bicycle-crunch', order: 5, targetSets: 3, targetReps: 16, restSeconds: 30 },
    ],
  },
  {
    slug: 'mobility-and-recovery',
    name: 'Mobility and Recovery',
    category: 'mobility',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A gentle mobility and recovery session for rest days or as a warm-up before training.',
    estimatedDurationMinutes: 15,
    exercises: [
      { exercise: 'cat-cow-stretch', order: 1, targetSets: 2, targetDurationSeconds: 60, restSeconds: 15 },
      { exercise: 'worlds-greatest-stretch', order: 2, targetSets: 2, targetReps: 5, restSeconds: 30 },
      { exercise: 'hip-flexor-stretch', order: 3, targetSets: 2, targetDurationSeconds: 30, restSeconds: 15 },
      { exercise: 'ninety-ninety-hip-stretch', order: 4, targetSets: 2, targetDurationSeconds: 30, restSeconds: 15 },
      { exercise: 'foam-roll-quad-release', order: 5, targetSets: 1, targetDurationSeconds: 90, restSeconds: 0 },
    ],
  },
  {
    slug: 'beginner-walking-plan',
    name: 'Beginner Walking Plan',
    category: 'cardio',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'A low-impact cardio session built entirely around brisk walking, for anyone starting a cardio habit.',
    estimatedDurationMinutes: 25,
    exercises: [
      { exercise: 'brisk-walk', order: 1, targetSets: 1, targetDurationSeconds: 1500, targetDistanceMeters: 2000, restSeconds: 0 },
    ],
  },
  {
    slug: 'beginner-running-plan',
    name: 'Beginner Running Plan',
    category: 'cardio',
    difficulty: ExerciseDifficulty.BEGINNER,
    description: 'An easy-effort running session with a short interval finisher, for anyone starting a running habit.',
    estimatedDurationMinutes: 25,
    exercises: [
      { exercise: 'easy-run', order: 1, targetSets: 1, targetDurationSeconds: 900, targetDistanceMeters: 1500, restSeconds: 60 },
      { exercise: 'interval-run', order: 2, targetSets: 4, targetDurationSeconds: 60, targetDistanceMeters: 200, restSeconds: 90 },
    ],
  },
];

interface FoodSeed {
  slug: string;
  name: string;
  alternateName?: string;
  servingDescription: string;
  servingGrams: number | null;
  caloriesPerServing: number;
  proteinGramsPerServing: number;
  carbGramsPerServing: number;
  fatGramsPerServing: number;
  fiberGramsPerServing?: number;
  sodiumMgPerServing?: number;
  /** Additional named serving options beyond the reference serving above.
   * `grams: null` means that option isn't gram-convertible (e.g. "1 can"
   * of a product whose can size varies) — logging by that option scales
   * directly by quantity rather than through a gram ratio. */
  servings?: Array<{ label: string; grams: number | null; isDefault?: boolean }>;
}

// A modest, illustrative multi-region dataset — not a comprehensive food
// database. Values are approximate (typical reference-food composition
// figures), which is exactly why every Food row carries `isEstimated:
// true`. Philippine staples are included explicitly per this session's
// brief, alongside common global staples, so the nutrition log is usable
// out of the box for a broad range of diets rather than just one region.
const NUTRITION_FOODS: FoodSeed[] = [
  // --- Philippine staples --------------------------------------------------
  {
    slug: 'cooked-white-rice',
    name: 'Cooked White Rice',
    servingDescription: '1 cup cooked (158 g)',
    servingGrams: 158,
    caloriesPerServing: 205,
    proteinGramsPerServing: 4.3,
    carbGramsPerServing: 44.5,
    fatGramsPerServing: 0.4,
    fiberGramsPerServing: 0.6,
    sodiumMgPerServing: 1.6,
    servings: [
      { label: '1 cup cooked', grams: 158, isDefault: true },
      { label: '1/2 cup cooked', grams: 79 },
    ],
  },
  {
    slug: 'egg-boiled',
    name: 'Egg (Boiled)',
    servingDescription: '1 large egg (50 g)',
    servingGrams: 50,
    caloriesPerServing: 78,
    proteinGramsPerServing: 6.3,
    carbGramsPerServing: 0.6,
    fatGramsPerServing: 5.3,
    fiberGramsPerServing: 0,
    sodiumMgPerServing: 62,
    servings: [{ label: '1 large egg', grams: 50, isDefault: true }],
  },
  {
    slug: 'chicken-breast-cooked',
    name: 'Chicken Breast (Cooked, Skinless)',
    servingDescription: '100 g',
    servingGrams: 100,
    caloriesPerServing: 165,
    proteinGramsPerServing: 31,
    carbGramsPerServing: 0,
    fatGramsPerServing: 3.6,
    fiberGramsPerServing: 0,
    sodiumMgPerServing: 74,
  },
  {
    slug: 'chicken-thigh-cooked',
    name: 'Chicken Thigh (Cooked, Skinless)',
    servingDescription: '100 g',
    servingGrams: 100,
    caloriesPerServing: 209,
    proteinGramsPerServing: 26,
    carbGramsPerServing: 0,
    fatGramsPerServing: 10.9,
    fiberGramsPerServing: 0,
    sodiumMgPerServing: 90,
  },
  {
    slug: 'canned-sardines',
    name: 'Canned Sardines in Oil',
    servingDescription: '1 can, drained (92 g)',
    servingGrams: 92,
    caloriesPerServing: 191,
    proteinGramsPerServing: 22.7,
    carbGramsPerServing: 0,
    fatGramsPerServing: 10.5,
    fiberGramsPerServing: 0,
    sodiumMgPerServing: 282,
    servings: [
      { label: '1 can, drained', grams: null, isDefault: true },
      { label: '100 g', grams: 100 },
    ],
  },
  {
    slug: 'milkfish-bangus-cooked',
    name: 'Milkfish (Bangus), Cooked',
    alternateName: 'Bangus',
    servingDescription: '100 g',
    servingGrams: 100,
    caloriesPerServing: 175,
    proteinGramsPerServing: 20.5,
    carbGramsPerServing: 0,
    fatGramsPerServing: 10,
    fiberGramsPerServing: 0,
    sodiumMgPerServing: 78,
  },
  {
    slug: 'tuna-canned-in-water',
    name: 'Tuna, Canned in Water (Drained)',
    servingDescription: '100 g',
    servingGrams: 100,
    caloriesPerServing: 116,
    proteinGramsPerServing: 25.5,
    carbGramsPerServing: 0,
    fatGramsPerServing: 0.8,
    fiberGramsPerServing: 0,
    sodiumMgPerServing: 247,
  },
  {
    slug: 'tofu-firm',
    name: 'Tofu (Firm)',
    servingDescription: '100 g',
    servingGrams: 100,
    caloriesPerServing: 144,
    proteinGramsPerServing: 15.5,
    carbGramsPerServing: 3.3,
    fatGramsPerServing: 8.7,
    fiberGramsPerServing: 2.3,
    sodiumMgPerServing: 14,
  },
  {
    slug: 'mung-beans-cooked',
    name: 'Mung Beans, Cooked',
    alternateName: 'Monggo',
    servingDescription: '1 cup cooked (202 g)',
    servingGrams: 202,
    caloriesPerServing: 212,
    proteinGramsPerServing: 14.2,
    carbGramsPerServing: 38.7,
    fatGramsPerServing: 0.8,
    fiberGramsPerServing: 15.4,
    sodiumMgPerServing: 4,
  },
  {
    slug: 'water-spinach-cooked',
    name: 'Water Spinach, Cooked',
    alternateName: 'Kangkong',
    servingDescription: '1 cup cooked (128 g)',
    servingGrams: 128,
    caloriesPerServing: 22,
    proteinGramsPerServing: 2.6,
    carbGramsPerServing: 3.9,
    fatGramsPerServing: 0.3,
    fiberGramsPerServing: 2.1,
    sodiumMgPerServing: 88,
  },
  {
    slug: 'banana',
    name: 'Banana',
    alternateName: 'Saba / Lakatan',
    servingDescription: '1 medium (100 g)',
    servingGrams: 100,
    caloriesPerServing: 89,
    proteinGramsPerServing: 1.1,
    carbGramsPerServing: 22.8,
    fatGramsPerServing: 0.3,
    fiberGramsPerServing: 2.6,
    sodiumMgPerServing: 1,
    servings: [{ label: '1 medium', grams: 100, isDefault: true }],
  },
  {
    slug: 'sweet-potato-boiled',
    name: 'Sweet Potato, Boiled',
    alternateName: 'Kamote',
    servingDescription: '1 medium (151 g)',
    servingGrams: 151,
    caloriesPerServing: 135,
    proteinGramsPerServing: 2.7,
    carbGramsPerServing: 31.6,
    fatGramsPerServing: 0.2,
    fiberGramsPerServing: 4.5,
    sodiumMgPerServing: 41,
  },
  {
    slug: 'rolled-oats-dry',
    name: 'Rolled Oats (Dry)',
    servingDescription: '1/2 cup dry (40 g)',
    servingGrams: 40,
    caloriesPerServing: 150,
    proteinGramsPerServing: 5.3,
    carbGramsPerServing: 27,
    fatGramsPerServing: 2.6,
    fiberGramsPerServing: 4,
    sodiumMgPerServing: 0,
  },
  {
    slug: 'pandesal',
    name: 'Pandesal (Bread Roll)',
    servingDescription: '1 piece (30 g)',
    servingGrams: 30,
    caloriesPerServing: 84,
    proteinGramsPerServing: 2.4,
    carbGramsPerServing: 15.6,
    fatGramsPerServing: 1.3,
    fiberGramsPerServing: 0.6,
    sodiumMgPerServing: 130,
    servings: [{ label: '1 piece', grams: 30, isDefault: true }],
  },
  {
    slug: 'peanut-butter',
    name: 'Peanut Butter',
    servingDescription: '2 tbsp (32 g)',
    servingGrams: 32,
    caloriesPerServing: 188,
    proteinGramsPerServing: 8,
    carbGramsPerServing: 6.9,
    fatGramsPerServing: 16,
    fiberGramsPerServing: 1.9,
    sodiumMgPerServing: 147,
  },
  // --- Global staples --------------------------------------------------
  {
    slug: 'greek-yogurt-plain',
    name: 'Greek Yogurt, Plain (Low-Fat)',
    alternateName: 'Yogurt',
    servingDescription: '1 cup (245 g)',
    servingGrams: 245,
    caloriesPerServing: 154,
    proteinGramsPerServing: 23,
    carbGramsPerServing: 8.8,
    fatGramsPerServing: 3.8,
    fiberGramsPerServing: 0,
    sodiumMgPerServing: 82,
  },
  {
    slug: 'lentils-cooked',
    name: 'Lentils, Cooked',
    servingDescription: '1 cup cooked (198 g)',
    servingGrams: 198,
    caloriesPerServing: 230,
    proteinGramsPerServing: 17.9,
    carbGramsPerServing: 39.9,
    fatGramsPerServing: 0.8,
    fiberGramsPerServing: 15.6,
    sodiumMgPerServing: 4,
  },
  {
    slug: 'black-beans-cooked',
    name: 'Black Beans, Cooked',
    servingDescription: '1 cup cooked (172 g)',
    servingGrams: 172,
    caloriesPerServing: 227,
    proteinGramsPerServing: 15.2,
    carbGramsPerServing: 40.8,
    fatGramsPerServing: 0.9,
    fiberGramsPerServing: 15,
    sodiumMgPerServing: 2,
  },
  {
    slug: 'potato-boiled',
    name: 'Potato, Boiled (With Skin)',
    servingDescription: '1 medium (167 g)',
    servingGrams: 167,
    caloriesPerServing: 128,
    proteinGramsPerServing: 2.9,
    carbGramsPerServing: 29.9,
    fatGramsPerServing: 0.1,
    fiberGramsPerServing: 2.9,
    sodiumMgPerServing: 6,
  },
  {
    slug: 'pasta-cooked',
    name: 'Pasta, Cooked',
    servingDescription: '1 cup cooked (140 g)',
    servingGrams: 140,
    caloriesPerServing: 221,
    proteinGramsPerServing: 8.1,
    carbGramsPerServing: 43.2,
    fatGramsPerServing: 1.3,
    fiberGramsPerServing: 2.5,
    sodiumMgPerServing: 1,
  },
  {
    slug: 'salmon-cooked',
    name: 'Salmon, Cooked',
    servingDescription: '100 g',
    servingGrams: 100,
    caloriesPerServing: 208,
    proteinGramsPerServing: 20.4,
    carbGramsPerServing: 0,
    fatGramsPerServing: 13.4,
    fiberGramsPerServing: 0,
    sodiumMgPerServing: 59,
  },
  {
    slug: 'ground-beef-85-cooked',
    name: 'Ground Beef (85% Lean), Cooked',
    alternateName: 'Ground Meat',
    servingDescription: '100 g',
    servingGrams: 100,
    caloriesPerServing: 250,
    proteinGramsPerServing: 26,
    carbGramsPerServing: 0,
    fatGramsPerServing: 15,
    fiberGramsPerServing: 0,
    sodiumMgPerServing: 75,
  },
  {
    slug: 'apple',
    name: 'Apple',
    servingDescription: '1 medium (182 g)',
    servingGrams: 182,
    caloriesPerServing: 95,
    proteinGramsPerServing: 0.5,
    carbGramsPerServing: 25,
    fatGramsPerServing: 0.3,
    fiberGramsPerServing: 4.4,
    sodiumMgPerServing: 2,
    servings: [{ label: '1 medium', grams: 182, isDefault: true }],
  },
  {
    slug: 'orange',
    name: 'Orange',
    servingDescription: '1 medium (131 g)',
    servingGrams: 131,
    caloriesPerServing: 62,
    proteinGramsPerServing: 1.2,
    carbGramsPerServing: 15.4,
    fatGramsPerServing: 0.2,
    fiberGramsPerServing: 3.1,
    sodiumMgPerServing: 0,
    servings: [{ label: '1 medium', grams: 131, isDefault: true }],
  },
  {
    slug: 'broccoli-cooked',
    name: 'Broccoli, Cooked',
    servingDescription: '1 cup cooked (156 g)',
    servingGrams: 156,
    caloriesPerServing: 55,
    proteinGramsPerServing: 3.7,
    carbGramsPerServing: 11.2,
    fatGramsPerServing: 0.6,
    fiberGramsPerServing: 5.1,
    sodiumMgPerServing: 64,
  },
  {
    slug: 'carrot-raw',
    name: 'Carrot, Raw',
    servingDescription: '1 medium (61 g)',
    servingGrams: 61,
    caloriesPerServing: 25,
    proteinGramsPerServing: 0.6,
    carbGramsPerServing: 5.8,
    fatGramsPerServing: 0.1,
    fiberGramsPerServing: 1.7,
    sodiumMgPerServing: 42,
    servings: [{ label: '1 medium', grams: 61, isDefault: true }],
  },
];

async function seedNutrition() {
  for (const food of NUTRITION_FOODS) {
    const row = await prisma.food.upsert({
      where: { slug: food.slug },
      create: {
        slug: food.slug,
        name: food.name,
        alternateName: food.alternateName,
        sourceType: FoodSourceType.SEED,
        servingDescription: food.servingDescription,
        servingGrams: food.servingGrams,
        caloriesPerServing: food.caloriesPerServing,
        proteinGramsPerServing: food.proteinGramsPerServing,
        carbGramsPerServing: food.carbGramsPerServing,
        fatGramsPerServing: food.fatGramsPerServing,
        fiberGramsPerServing: food.fiberGramsPerServing,
        sodiumMgPerServing: food.sodiumMgPerServing,
        isEstimated: true,
      },
      update: {
        name: food.name,
        alternateName: food.alternateName,
        servingDescription: food.servingDescription,
        servingGrams: food.servingGrams,
        caloriesPerServing: food.caloriesPerServing,
        proteinGramsPerServing: food.proteinGramsPerServing,
        carbGramsPerServing: food.carbGramsPerServing,
        fatGramsPerServing: food.fatGramsPerServing,
        fiberGramsPerServing: food.fiberGramsPerServing,
        sodiumMgPerServing: food.sodiumMgPerServing,
      },
    });

    // Re-derive serving options from scratch each run, same pattern as
    // the exercise seed's muscle/equipment join rows.
    await prisma.foodServing.deleteMany({ where: { foodId: row.id } });
    if (food.servings?.length) {
      await prisma.foodServing.createMany({
        data: food.servings.map((serving) => ({
          foodId: row.id,
          label: serving.label,
          grams: serving.grams,
          isDefault: serving.isDefault ?? false,
        })),
      });
    }
  }

  // eslint-disable-next-line no-console
  console.log(`Seeded ${NUTRITION_FOODS.length} foods.`);
}

// --- Scenario 1: Terms and safety (see packages/docs/product/user-scenario-bible.md) ---
//
// PRODUCT-SAFE DRAFT — NOT FINAL LEGAL COPY. This content is written to
// satisfy the founder's required safety points (educational-only scope,
// professional-care guidance, stop-on-symptoms warning, user responsibility,
// no blanket harm-disclaimer language) so the acceptance flow has something
// real to show and record against. It has NOT been reviewed by a lawyer and
// is NOT jurisdiction-specific. It must go through professional legal
// review before any production release — see
// packages/docs/product/wellness-ethics-bible.md.
const TERMS_OF_SERVICE_V1 = `# Project Ascend — Terms of Service (Draft v1)

**This is a product-safe draft pending professional legal review. Do not
treat this as final legal copy.**

## What Ascend is

Project Ascend provides educational fitness and wellness support — workout
planning and logging, nutrition tracking, and guidance from the Atlas/Nova
companion. It is **not a replacement for a doctor, physiotherapist,
dietitian, or other licensed professional**. Where a question or situation
falls outside general fitness guidance, Ascend will say so and recommend you
consult a qualified professional rather than guess.

## When Ascend will warn you

Ascend may show a warning when a planned or logged activity appears
inconsistent with your stated profile, recent training history, or any
limitations you've told us about. These warnings are a prompt to pause and
think, not a medical judgment.

## Stop if something feels wrong

Stop the activity and seek appropriate care if you experience pain,
dizziness, difficulty breathing, chest pain, or any other concerning
symptom during exercise. Do not continue "through" these signals because an
app suggested a target — no target in Ascend overrides how your body
actually feels.

## Your responsibility

You remain responsible for the exercise and nutrition decisions you make
while using Ascend, including deciding whether a given workout, weight, or
recommendation is appropriate for you on a given day. Ascend's guidance is
support for that decision-making, not a substitute for your own judgment or
a professional's.

## Liability

This section requires professional legal drafting for your jurisdiction
before release. It will describe the company's responsibilities and any
limitations on liability in specific, accurate terms — it will not use
sweeping language like "we are not responsible for any harm," since that
kind of blanket disclaimer does not remove a company's actual legal
obligations and misrepresents them to users.

## Changes to these terms

If we materially change these terms, you'll be asked to review and accept
the new version before continuing to use Ascend. We keep a record of which
version you accepted and when.`;

const PRIVACY_POLICY_V1 = `# Project Ascend — Privacy Policy (Draft v1)

**This is a product-safe draft pending professional legal review. Do not
treat this as final legal copy.**

## What we store

Your profile (name, date of birth, height, weight, and similar fields you
provide), your workout and nutrition logs, your companion and preference
settings, and account/authentication records (including which sign-in
providers are linked to your account).

## Why

To run the app you're using — plan and log workouts, track nutrition,
personalize the Atlas/Nova companion, and keep your data in sync across
your devices.

## Your control

You can review and update your profile at any time from your dashboard. A
full data-export and deletion flow is planned; see
packages/docs/product/parking-lot.md for its current status.

## Changes to this policy

If we materially change this policy, you'll be asked to review and accept
the new version before continuing to use Ascend, the same as Terms of
Service changes.`;

const LEGAL_DOCUMENTS = [
  { type: LegalDocumentType.TERMS_OF_SERVICE, version: 'v1', content: TERMS_OF_SERVICE_V1 },
  { type: LegalDocumentType.PRIVACY_POLICY, version: 'v1', content: PRIVACY_POLICY_V1 },
] as const;

async function seedLegalDocuments() {
  for (const doc of LEGAL_DOCUMENTS) {
    await prisma.legalDocument.upsert({
      where: { type_version: { type: doc.type, version: doc.version } },
      create: { type: doc.type, version: doc.version, content: doc.content },
      update: { content: doc.content },
    });
  }

  // eslint-disable-next-line no-console
  console.log(`Seeded ${LEGAL_DOCUMENTS.length} legal documents.`);
}

// `key` is the stable identity `AchievementsService`'s rules match
// against — see services/api/src/modules/achievements/achievements.service.ts.
// Recovery achievements aren't seeded yet — deload doesn't have a
// countable "did this" trigger the way workout/nutrition/cardio logging
// do; `AchievementCategory` already reserves room for it.
const ACHIEVEMENTS = [
  {
    key: 'first_workout',
    title: 'First Steps',
    description: 'Complete your first workout.',
    iconAsset: 'fitness_center',
    category: AchievementCategory.WORKOUT,
    targetSteps: 1,
  },
  {
    key: 'ten_workouts',
    title: 'Building the Habit',
    description: 'Complete 10 workouts.',
    iconAsset: 'fitness_center',
    category: AchievementCategory.WORKOUT,
    targetSteps: 10,
  },
  {
    key: 'fifty_workouts',
    title: 'Iron Will',
    description: 'Complete 50 workouts.',
    iconAsset: 'military_tech',
    category: AchievementCategory.WORKOUT,
    targetSteps: 50,
  },
  {
    key: 'first_personal_record',
    title: 'New Best',
    description: 'Set your first personal record.',
    iconAsset: 'emoji_events',
    category: AchievementCategory.WORKOUT,
    targetSteps: 1,
  },
  {
    key: 'seven_day_streak',
    title: 'One Week Strong',
    description: 'Reach a 7-day workout streak.',
    iconAsset: 'local_fire_department',
    category: AchievementCategory.CONSISTENCY,
    targetSteps: 7,
  },
  {
    key: 'thirty_day_streak',
    title: 'Unstoppable',
    description: 'Reach a 30-day workout streak.',
    iconAsset: 'local_fire_department',
    category: AchievementCategory.CONSISTENCY,
    targetSteps: 30,
  },
  {
    key: 'first_meal_logged',
    title: 'Fueling Up',
    description: 'Log your first meal.',
    iconAsset: 'restaurant',
    category: AchievementCategory.NUTRITION,
    targetSteps: 1,
  },
  {
    key: 'hundred_meals_logged',
    title: 'Nutrition Nerd',
    description: 'Log 100 meals.',
    iconAsset: 'restaurant',
    category: AchievementCategory.NUTRITION,
    targetSteps: 100,
  },
  {
    key: 'first_cardio_session',
    title: 'On the Move',
    description: 'Log your first cardio session.',
    iconAsset: 'directions_run',
    category: AchievementCategory.CARDIO,
    targetSteps: 1,
  },
  {
    key: 'ten_cardio_sessions',
    title: 'Going the Distance',
    description: 'Log 10 cardio sessions.',
    iconAsset: 'directions_run',
    category: AchievementCategory.CARDIO,
    targetSteps: 10,
  },
] as const;

async function seedAchievements() {
  for (const achievement of ACHIEVEMENTS) {
    await prisma.achievement.upsert({
      where: { key: achievement.key },
      create: achievement,
      update: {
        title: achievement.title,
        description: achievement.description,
        iconAsset: achievement.iconAsset,
        category: achievement.category,
        targetSteps: achievement.targetSteps,
      },
    });
  }

  // eslint-disable-next-line no-console
  console.log(`Seeded ${ACHIEVEMENTS.length} achievements.`);
}

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
        measurementType: exercise.measurementType,
        description: exercise.description,
        instructions: exercise.instructions,
        safetyTips: exercise.safetyTips,
        commonMistakes: exercise.commonMistakes,
      },
      update: {
        name: exercise.name,
        categoryId: categoryIds.get(exercise.category)!,
        difficulty: exercise.difficulty,
        measurementType: exercise.measurementType,
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
        targetDistanceMeters: entry.targetDistanceMeters,
        restSeconds: entry.restSeconds ?? 60,
      })),
    });
  }

  // eslint-disable-next-line no-console
  console.log(
    `Seeded ${CATEGORIES.length} categories, ${MUSCLE_GROUPS.length} muscle groups, ${EQUIPMENT_TYPES.length} equipment types, ${EXERCISES.length} exercises, ${WORKOUTS.length} workouts.`,
  );

  await seedNutrition();
  await seedLegalDocuments();
  await seedAchievements();
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
