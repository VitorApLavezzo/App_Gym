// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class Exercise {
  String name;
  int sets;
  int repetitions;
  int duration;
  String? timeUnit;

  Exercise({
    required this.name,
    required this.sets,
    required this.repetitions,
    required this.duration,
    this.timeUnit,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'repetitions': repetitions,
      'duration': duration,
      'timeUnit': timeUnit,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      sets: json['sets'],
      repetitions: json['repetitions'],
      duration: json['duration'],
      timeUnit: json['timeUnit'],
    );
  }
}

class ExerciseGroup {
  String groupName;
  List<Exercise> exercises;

  ExerciseGroup({
    required this.groupName,
    required this.exercises,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupName': groupName,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }

  factory ExerciseGroup.fromJson(Map<String, dynamic> json) {
    return ExerciseGroup(
      groupName: json['groupName'],
      exercises: (json['exercises'] as List<dynamic>)
          .map((exercise) => Exercise.fromJson(exercise))
          .toList(),
    );
  }
}

class ExerciseListScreen extends StatefulWidget {
  final ExerciseGroup group;
  final Function(List<Exercise>) onExerciseChanged;
  final List<String> timeUnitOptions;

  const ExerciseListScreen({
    super.key,
    required this.group,
    required this.onExerciseChanged,
    required this.timeUnitOptions,
  });

  @override
  _ExerciseListScreenState createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  List<Exercise> exercises = [];

  @override
  void initState() {
    super.initState();
    exercises = widget.group.exercises;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.groupName),
      ),
      body: ReorderableListView(
        onReorder: _onReorder,
        children: exercises
            .map(
              (exercise) => Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                key: Key(exercise.name), // Chave única para cada Card
                child: ListTile(
                  title: Text(
                    exercise.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Séries: ${exercise.sets}, Repetições: ${exercise.repetitions}, Duração: ${exercise.duration} ${exercise.timeUnit ?? ''}',
                    style: const TextStyle(
                        fontSize: 14, color: Color.fromARGB(255, 61, 61, 61)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editExercise(exercise);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteExercise(exercise);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Exercise item = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, item);
    });
    widget.onExerciseChanged(exercises);
  }

  void _addExercise() {
    TextEditingController nameController = TextEditingController();
    TextEditingController setsController = TextEditingController();
    TextEditingController repetitionsController = TextEditingController();
    TextEditingController durationController = TextEditingController();
    String? selectedTimeUnit; // Sem opção padrão

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Novo Exercício'),
          content: Column(
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Nome do Exercício'),
              ),
              TextField(
                controller: setsController,
                decoration: const InputDecoration(labelText: 'Séries'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repetitionsController,
                decoration: const InputDecoration(labelText: 'Repetições'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duração'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                value: selectedTimeUnit,
                items: widget.timeUnitOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedTimeUnit = newValue;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  exercises.add(
                    Exercise(
                      name: nameController.text,
                      sets: int.parse(setsController.text),
                      repetitions: int.parse(repetitionsController.text),
                      duration: durationController.text.isNotEmpty
                          ? int.parse(durationController.text)
                          : 0,
                      timeUnit: selectedTimeUnit,
                    ),
                  );
                });

                widget.onExerciseChanged(exercises);

                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _editExercise(Exercise exercise) {
    // Utilize um TextEditingController para controlar os campos do formulário de edição
    TextEditingController nameController =
        TextEditingController(text: exercise.name);
    TextEditingController setsController =
        TextEditingController(text: exercise.sets.toString());
    TextEditingController repetitionsController =
        TextEditingController(text: exercise.repetitions.toString());
    TextEditingController durationController =
        TextEditingController(text: exercise.duration.toString());
    String? selectedTimeUnit = exercise.timeUnit;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Exercício'),
          content: Column(
            children: [
              // Inclua campos de edição para cada propriedade do exercício
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Nome do Exercício'),
              ),
              TextField(
                controller: setsController,
                decoration: const InputDecoration(labelText: 'Séries'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repetitionsController,
                decoration: const InputDecoration(labelText: 'Repetições'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duração'),
                keyboardType: TextInputType.number,
              ),
              // Inclua um DropdownButtonFormField para a unidade de tempo
              DropdownButtonFormField<String>(
                value: selectedTimeUnit,
                items: ['seconds', 'minutes', 'none'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedTimeUnit = newValue;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Atualize os valores do exercício
                setState(() {
                  exercise.name = nameController.text;
                  exercise.sets = int.parse(setsController.text);
                  exercise.repetitions = int.parse(repetitionsController.text);
                  exercise.duration = int.parse(durationController.text);
                  exercise.timeUnit = selectedTimeUnit;
                });

                // Atualize as mudanças persistindo os dados ou chamando a função onExerciseChanged
                widget.onExerciseChanged(exercises);

                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _deleteExercise(Exercise exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Exercício'),
          content: const Text('Deseja realmente excluir este exercício?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Remova o exercício da lista
                setState(() {
                  exercises.remove(exercise);
                });

                // Atualize as mudanças persistindo os dados ou chamando a função onExerciseChanged
                widget.onExerciseChanged(exercises);

                Navigator.of(context).pop();
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ExerciseGroup> exerciseGroups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      List<String>? serializedGroups = prefs.getStringList('exerciseGroups');
      if (serializedGroups != null) {
        exerciseGroups = serializedGroups
            .map((serializedGroup) =>
                ExerciseGroup.fromJson(jsonDecode(serializedGroup)))
            .toList();
      }
    });
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> serializedGroups =
        exerciseGroups.map((group) => jsonEncode(group.toJson())).toList();

    prefs.setStringList('exerciseGroups', serializedGroups);
  }

  void _deleteGroup(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Grupo de Exercícios'),
          content: const Text(
              'Deseja realmente excluir este grupo e todos os exercícios associados?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  exerciseGroups.removeAt(index);
                });

                _saveData();

                Navigator.of(context).pop();
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _editGroupName(ExerciseGroup group) {
    TextEditingController groupNameController =
        TextEditingController(text: group.groupName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Nome do Grupo'),
          content: TextField(
            controller: groupNameController,
            decoration: const InputDecoration(labelText: 'Novo Nome do Grupo'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Atualize o nome do grupo
                setState(() {
                  group.groupName = groupNameController.text;
                });

                // Atualize as mudanças persistindo os dados ou chamando a função onGroupChanged
                _saveData(); // Substitua por sua lógica de salvamento de dados
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness App'),
      ),
      body: ReorderableListView(
      onReorder: _onReorderGroups,
      children: exerciseGroups
          .asMap()
          .map(
            (index, group) => MapEntry(
              index,
              Card(
                key: ValueKey(group),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    group.groupName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${group.exercises.length} exercícios',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  onTap: () {
                    _navigateToExerciseList(group);
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editGroupName(group);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteGroup(index);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .values
          .toList(),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _addGroup,
      child: const Icon(Icons.add),
    ),
  );
}
  void _onReorderGroups(int oldIndex, int newIndex) {
  setState(() {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final ExerciseGroup item = exerciseGroups.removeAt(oldIndex);
    exerciseGroups.insert(newIndex, item);
  });
  _saveData(); // Substitua por sua lógica de salvamento de dados
}

  void _addGroup() {
    TextEditingController groupNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Novo Grupo de Exercícios'),
          content: TextField(
            controller: groupNameController,
            decoration: const InputDecoration(labelText: 'Nome do Grupo'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  exerciseGroups.add(
                    ExerciseGroup(
                      groupName: groupNameController.text,
                      exercises: [],
                    ),
                  );
                });

                _saveData();

                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToExerciseList(ExerciseGroup group) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseListScreen(
          group: group,
          onExerciseChanged: (exercises) {
            setState(() {
              group.exercises = exercises;
              _saveData();
            });
          },
          timeUnitOptions: const ['segundos', 'minutos', 'none'],
        ),
      ),
    );
  }
}
