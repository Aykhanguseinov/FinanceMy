import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hwfgehxldfqyvqqanpea.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3ZmdlaHhsZGZxeXZxcWFucGVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk3MTY2OTgsImV4cCI6MjA0NTI5MjY5OH0.p7h3UX_z3v16-jNC5105g3fUks_9uh2XBKUCe_Irxn0',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мой Бюджет',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BudgetApp(),
    );
  }
}

class BudgetApp extends StatefulWidget {
  @override
  _BudgetAppState createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> {
  List<Transaction> transactions = [];
  List<Category> categories = [
    Category(name: 'Учеба', type: TransactionType.income, color: Colors.green),
    Category(name: 'Отдых', type: TransactionType.expense, color: Colors.red),
    Category(name: 'Еда', type: TransactionType.income, color: Colors.blue), 
    Category(name: 'Спорт', type: TransactionType.expense, color: Colors.orange), 
  ];
  DateTime selectedDate = DateTime.now();
  TransactionType selectedType = TransactionType.income;
  String? selectedCategory;
  double? amount;
  String? description;
  bool showAddTransactionScreen = false;
  DateTimeRange? selectedDateRange; 

  @override
  void initState() {
    super.initState();
    transactions = [
      Transaction(type: TransactionType.income, amount: 1000, category: 'Учеба', date: DateTime.now()),
      Transaction(type: TransactionType.expense, amount: 200, category: 'Отдых', date: DateTime.now()),
      Transaction(type: TransactionType.expense, amount: 150, category: 'Еда', date: DateTime.now()),
      Transaction(type: TransactionType.expense, amount: 50, category: 'Спорт', date: DateTime.now()),

    ];
  }

  void addTransaction(Transaction newTransaction) {
    setState(() {
      transactions.add(newTransaction);
      showAddTransactionScreen = false;
    });
  }

  void addCategory(String categoryName, TransactionType categoryType, Color color) {
    setState(() {
      categories.add(Category(name: categoryName, type: categoryType, color: color));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мой Бюджет'),
        actions: [
          
        ],
      ),
      body: showAddTransactionScreen
          ? AddTransactionScreen(
              onSubmit: addTransaction,
              categories: categories,
              selectedType: selectedType,
              selectedCategory: selectedCategory,
              amount: amount,
              description: description,
              selectedDate: selectedDate,
            )
          : BudgetOverview(
              transactions: transactions,
              selectedDate: selectedDate,
              selectedDateRange: selectedDateRange,
              categories: categories,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            showAddTransactionScreen = true;
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class BudgetOverview extends StatefulWidget {
  final List<Transaction> transactions;
  final DateTime selectedDate;
  final DateTimeRange? selectedDateRange;
  final List<Category> categories;

  BudgetOverview({
    required this.transactions,
    required this.selectedDate,
    required this.selectedDateRange,
    required this.categories,
  });

  @override
  _BudgetOverviewState createState() => _BudgetOverviewState();
}

class _BudgetOverviewState extends State<BudgetOverview> {
  DateTime _selectedDate = DateTime.now(); 
  DateTimeRange? _selectedDateRange; 
  TransactionType? selectedType;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _selectedDateRange = widget.selectedDateRange;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = widget.selectedDateRange != null
        ? widget.transactions
            .where((transaction) => transaction.date.isAfter(widget.selectedDateRange!.start) && transaction.date.isBefore(widget.selectedDateRange!.end))
            .toList()
        : widget.transactions
            .where((transaction) => transaction.date.day == _selectedDate.day && transaction.date.month == _selectedDate.month && transaction.date.year == _selectedDate.year)
            .toList();

    final totalIncome = filteredTransactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<double>(0, (previousValue, element) => previousValue + element.amount);
    final totalExpense = filteredTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<double>(0, (previousValue, element) => previousValue + element.amount);

    final incomeData = filteredTransactions
        .where((transaction) => transaction.type == TransactionType.income)
        .map((transaction) => MapEntry(transaction.category, transaction.amount))
        .groupListsBy((entry) => entry.key) 
        .map((category, entries) => MapEntry(category, entries.fold<double>(0, (sum, entry) => sum + entry.value)))
        .entries.toList();
    final expenseData = filteredTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .map((transaction) => MapEntry(transaction.category, transaction.amount))
        .groupListsBy((entry) => entry.key) 
        .map((category, entries) => MapEntry(category, entries.fold<double>(0, (sum, entry) => sum + entry.value)))
        .entries.toList();

    final pieChartData = [
      ...incomeData.map((entry) {
        final category = widget.categories.firstWhereOrNull((c) => c.name == entry.key); // Используем firstWhereOrNull
        return PieChartData(category: entry.key, amount: entry.value, color: category?.color ?? Colors.grey); // Устанавливаем цвет по умолчанию
      }),
      ...expenseData.map((entry) {
        final category = widget.categories.firstWhereOrNull((c) => c.name == entry.key); // Используем firstWhereOrNull
        return PieChartData(category: entry.key, amount: entry.value, color: category?.color ?? Colors.grey); // Устанавливаем цвет по умолчанию
      }),
    ];

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(Duration(days: 1));
                    });
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(Duration(days: 1));
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    ).then((pickedDate) {
                      if (pickedDate == null) return;
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                    });
                  },
                  child: Text('Выбрать дату'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDateRange: _selectedDateRange ?? DateTimeRange(start: DateTime.now().subtract(Duration(days: 7)), end: DateTime.now()),
                    ).then((pickedDateRange) {
                      if (pickedDateRange == null) return;
                      setState(() {
                        _selectedDateRange = pickedDateRange;
                      });
                    });
                  },
                  child: Text('Выбрать период'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  if (incomeData.isNotEmpty || expenseData.isNotEmpty)
                    Expanded(
                      child: Container(
                        child: SfCircularChart(
                          title: ChartTitle(text: 'Доходы и расходы'),
                          legend: Legend(isVisible: true),
                          series: <CircularSeries>[ 
                            PieSeries<PieChartData, String>(
                              dataSource: pieChartData,
                              xValueMapper: (PieChartData data, _) => data.category,
                              yValueMapper: (PieChartData data, _) => data.amount,
                              pointColorMapper: (PieChartData data, _) => data.color,
                              dataLabelSettings: DataLabelSettings(isVisible: true),
                              name: 'Доходы',
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 40),
                  Text(
                    'Доход: $totalIncome',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Расход: $totalExpense',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            
          ),
        ],
      ),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  final Function(Transaction) onSubmit;
  final List<Category> categories;
  final TransactionType? selectedType;
  final String? selectedCategory;
  final double? amount;
  final String? description;
  final DateTime selectedDate;

  AddTransactionScreen({
    required this.onSubmit,
    required this.categories,
    this.selectedType,
    this.selectedCategory,
    this.amount,
    this.description,
    required this.selectedDate,
  });

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  TransactionType? selectedType;
  String? selectedCategory;
  double? amount;
  String? description;
  DateTime? date;

  @override
  void initState() {
    super.initState();
    selectedType = widget.selectedType;
    selectedCategory = widget.selectedCategory;
    amount = widget.amount;
    description = widget.description;
    date = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<TransactionType>(
                value: selectedType,
                onChanged: (value) {
                  setState(() {
                    selectedType = value;
                  });
                },
                items: TransactionType.values.map((TransactionType type) {
                  return DropdownMenuItem<TransactionType>(
                    value: type,
                    child: Text(type == TransactionType.income ? 'Доход' : 'Расход'),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Тип'),
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                items: widget.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.name,
                    child: Text(category.name),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Категория'),
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите сумму';
                  }
                  return null;
                },
                onSaved: (value) {
                  amount = double.tryParse(value!);
                },
                decoration: InputDecoration(labelText: 'Сумма'),
              ),
              TextFormField(
                onSaved: (value) {
                  description = value;
                },
                decoration: InputDecoration(labelText: 'Описание (необязательно)'),
              ),
              ElevatedButton(
                onPressed: () {
                  showDatePicker(
                    context: context,
                    initialDate: date ?? widget.selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  ).then((pickedDate) {
                    if (pickedDate == null) return;
                    setState(() {
                      date = pickedDate;
                    });
                  });
                },
                child: Text('Выбрать дату'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final newTransaction = Transaction(
                      type: selectedType!,
                      amount: amount!,
                      category: selectedCategory!,
                      description: description,
                      date: date ?? widget.selectedDate,
                    );
                    widget.onSubmit(newTransaction);
                  }
                },
                child: Text('Добавить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum TransactionType { income, expense }

class Transaction {
  final TransactionType type;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;

  Transaction({
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
  });
}

class Category {
  final String name;
  final TransactionType type;
  final Color color;

  Category({required this.name, required this.type, required this.color});
}





class PieChartData {
  final String category;
  final double amount;
  final Color color;

  PieChartData({required this.category, required this.amount, required this.color});
}

