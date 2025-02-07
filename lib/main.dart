import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'create_profile_screen.dart';
import 'gender_select_screen.dart';
import 'setup_screen.dart';
import 'age_pick_screen.dart';
import 'height_pick_screen.dart';
import 'goal_pick_screen.dart';
import 'activity_level_screen.dart';
import 'weight_pick_screen.dart';
import 'home_screen.dart';
import 'workouts_screen.dart';
import 'profile_screen.dart';
import 'get_started_screen.dart';
import 'quick_start_screen.dart';
import 'progress_screen.dart';
import 'add_exercises_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'measures_screen.dart';
import 'exercise_info_screen.dart';
import 'challenges_screen.dart';
import 'routine_screen.dart';
import 'preset_routine_screen.dart';
import 'create_preset_screen.dart';
import 'current_workout_screen.dart';
import 'update_goals_screen.dart';
import 'edit_profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => GetStartedScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/create_profile': (context) => CreateProfileScreen(),
        '/gender_select': (context) => GenderSelectionScreen(),
        '/setup': (context) => SetupScreen(),
        '/age_pick': (context) => AgePickerPage(),
        '/height_pick': (context) => HeightPickerPage(),
        '/goal': (context) => GoalPickerScreen(),
        '/activity_level': (context) => ActivityLevelPickerScreen(),
        '/weight_pick': (context) => WeightPickerPage(),
        '/home': (context) => HomeScreen(),
        '/workout': (context) => WorkoutPage(addedExercises: []),
        '/profile': (context) => ProfilePage(),
        '/quick_start': (context) => EmptyWorkoutPage(),
        '/progress': (context) => ProgressPage(),
        '/add_exercises': (context) => AddExercisesPage(),
        '/settings': (context) => SettingsPage(),
        '/notifications': (context) => NotificationsPage(),
        '/measures': (context) => MeasuresPage(),
        '/exercise_info': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            return Scaffold(
              body: Center(
                child: Text('No exercise data provided'),
              ),
            );
          }
          return ExerciseInfoPage(exercise: args);
        },
        '/challenges': (context) => ChallengesScreen(),
        '/routine': (context) => RoutinePage(),
        '/preset_routine': (context) => PresetRoutineScreen(),
        '/create_preset_routine': (context) => CreatePresetScreen(),
        '/current_workout': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            return Scaffold(
              body: Center(
                child: Text('No workout data provided'),
              ),
            );
          }
          return CurrentWorkoutPage(title: args['title'], exercises: args['exercises']);
        },
        '/update_goals': (context) => UpdateGoalsScreen(),
        '/edit_profile': (context) => EditProfilePage(),
      },
    );
  }
}

