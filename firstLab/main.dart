import 'dart:math';

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() {
  runApp(MyApp());
}

class Pocket {
  final dynamic value;
  int frequency;
  double relativeFrequency;
  double theoreticalFrequency;
  double f;

  Pocket(this.value, this.frequency, this.relativeFrequency, this.theoreticalFrequency,this.f);
}


class Distribution {
  final int value;
  final double frequency;

  Distribution(this.value, this.frequency);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Статистические характеристики наборов данных дискретных случайных величин',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProbabilityDistributionsPage(),
    );
  }
}

class ProbabilityDistributionsPage extends StatefulWidget {
  @override
  _ProbabilityDistributionsPageState createState() =>
      _ProbabilityDistributionsPageState();
}

class _ProbabilityDistributionsPageState extends State<ProbabilityDistributionsPage> {
  String dropdownValue = 'Bernoulli';
  List<Distribution> data = [];
  List<Widget> inputFields = [];
  late List<TextEditingController> _controllers;

  List<Pocket> pockets = [];


  List<double>? _values = [];
  List<double>? _probabilities = [];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculateDistribution() {
    List<Distribution> distributionData = [];
    if (_controllers.isNotEmpty) {
      switch (dropdownValue) {
        case 'Bernoulli':
          distributionData = _generateBernoulliDistribution();
          break;
        case 'Binomial':
          distributionData = _generateBinomialDistribution();
          break;
        case 'Poisson':
          distributionData = _generatePoissonDistribution();
          break;
        case 'Discrete':
          distributionData = _generateDiscreteDistribution();
          break;
      }
    }
    
    setState(() {
      data = distributionData;
    });
  }

  List<Distribution> _generateBernoulliDistribution() {
    double p = double.parse(_controllers[1].text);
    int numberOfValues = int.parse(_controllers[0].text);
    Random random = Random();
    List<Distribution> distributionData = [];
    for (int i = 0; i < numberOfValues; i++) {
      distributionData.add(
        Distribution(i, random.nextDouble() < p ? 1 : 0)
      );
    }
    return distributionData;
  }

  List<Distribution> _generateBinomialDistribution() {
    double p = double.parse(_controllers[1].text);
    int n = int.parse(_controllers[2].text);
    int numberOfValues = int.parse(_controllers[0].text);
    Random random = Random();
    List<Distribution> distributionData = [];
    for (int i = 0; i < numberOfValues; i++) {
      int successes = 0;
      for (int j = 0; j < n; j++) {
        if (random.nextDouble() < p) {
          successes++;
        }
      }
      distributionData.add(Distribution(i, successes.toDouble() ));
    }
    return distributionData;
  }

  List<Distribution> _generatePoissonDistribution() {
    double lambda = double.parse(_controllers[1].text);
    int numberOfValues = int.parse(_controllers[0].text);
    Random random = Random();
    List<Distribution> distributionData = [];
    for (int i = 0; i < numberOfValues; i++) {
      int k = 0;
      double p = 1.0;
      double lExp = exp(-lambda);
      do {
        k++;
        p *= random.nextDouble();
      } while (p > lExp);
      distributionData.add(Distribution(i, k.toDouble()));
    }
    return distributionData;
  }

  List<Distribution> _generateDiscreteDistribution() {
    
    int numberOfValues = int.parse(_controllers[0].text);
    Random random = Random();
    List<Distribution> distributionData = [];
    for (int i = 0; i < numberOfValues; i++) {
      double v = 0;
      for(int j = 0; j < _values!.length; j++){
        if(_values![j] == _values!.last){
          v = _values![j];
        }
        else{
          if(random.nextDouble() < _probabilities![j]){
            v = _values![j];
            break;
          }
        }
      }
      distributionData.add(Distribution(i, v));
    }
    return distributionData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Статистические характеристики наборов данных дискретных случайных величин'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Информация'),
                    content: const SingleChildScrollView(
                      child: Text(
                        """Для начала нужно выбрать вид распределения из выпадающего списка.
                        \nЗатем ввести необходимые параметры. Для дискретного распределения также нужно нажать на дополнительную кнопку справа от поля ввода количества дискретных величин, в отркывшемся окне ввести величины и соответствующие им вероятности генерации этих величин.
                        \n Когда все готово, нужно нажать на кнопку 'Сгенерировать' """,
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Закрыть'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DropdownButton<String>(
              value: dropdownValue,
              onChanged: (String? newValue) {
                setState(() {
                  data.clear();
                  pockets.clear();
                  dropdownValue = newValue!;
                  _updateInputFields();
                });
              },
              items: <String>[
                'Bernoulli',
                'Binomial',
                'Poisson',
                'Discrete'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            ...inputFields,
            if(_controllers.first.text!='')
            ElevatedButton(
              onPressed: () {
                _calculateDistribution();
                _calculatePockets(data);

              },
              child: Text('Сгенерировать'),
            ),
            // SizedBox(height: 20),
            if (data.isNotEmpty)
              GridView.count(crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: MediaQuery.of(context).size.width / (MediaQuery.of(context).size.height - 300), 
                children: [
                  ChartWidget(
                    chart: charts.LineChart(
                      _createDistributionData(dropdownValue, data),
                      animate: true,
                    )
                  ),
                  ChartWidget(
                    chart: charts.LineChart(
                      _createFXChart(pockets),
                      animate: true,
                    )
                  ),
                  ChartWidget(
                    chart: charts.BarChart(
                      _createFrequencyChartSeries(pockets),
                      animate: true,
                   )
                  ),
                  ChartWidget(
                    chart: charts.BarChart(
                      _createRelativeAndTheoreticalFrequencyChartSeries(pockets),
                      animate: true,
                    )
                  ),
                ],
              )
              // Row(
              //     children: [
              //       Column(
              //         children: [
              //           Container(
              //             constraints: chartsConstrains,
              //             child: Expanded(
                            // child: charts.LineChart(
                            //   _createDistributionData(dropdownValue, data),
                            //   animate: true,
                            // ),
              //             ),
              //           ),
              //           Container(
              //             constraints: chartsConstrains,
              //             child: Expanded(
                            // child: charts.BarChart(
                            //   _createFrequencyChartSeries(pockets),
                            //   animate: true,
                            // ),
              //             ),
              //           ),
              //         ],
              //       ),
              //       Column(
              //         children: [
              //           Container(
              //             constraints: chartsConstrains,
              //             child: Expanded(
              //               child: charts.LineChart(
              //                 _createFXChart(pockets),
              //                 animate: true,
              //               ),
              //             ),
              //           ),
              //           Container(
              //             constraints: chartsConstrains,
              //             child: Expanded(
              //               child: charts.BarChart(
              //                 _createRelativeAndTheoreticalFrequencyChartSeries(pockets),
              //                 animate: true,
              //               ),
              //             ),
              //           ),
              //         ],
              //       ),
              //     ],
              //   ),
          ],
        ),
      ),
    );
  }

  void _updateInputFields() {
    inputFields.clear();
    inputFields.add(TextFormField(
      keyboardType: TextInputType.number,
        decoration: InputDecoration(
        labelText: 'Введите кол-во генерируемых чисел',
      ),
      onChanged: (value) {
        _controllers[0].text = value;
        setState(() {});
      },
    ));
    switch (dropdownValue) {
      case 'Bernoulli':
        
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Введите вероятность',
          ),
          onChanged: (value) {
            _controllers[1].text = value;
            setState(() {});
          },
        ));
        break;
      case 'Binomial':
        
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Введите вероятность',
          ),
          onChanged: (value) {
            _controllers[1].text = value;
            setState(() {});
          },
        ));
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Введите количество карманов',
          ),
          onChanged: (value) {
            _controllers[2].text = value;
            setState(() {});
          },
        ));
        break;
      case 'Poisson':
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Введите лямбду',
          ),
          onChanged: (value) {
            _controllers[1].text = value;
            setState(() {});
          },
        ));
        break;
      case 'Discrete':
        int numberOfValues = 0;
        inputFields.add(
          Row(
            children: [
              SizedBox(
                width: 400,
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Введите количество дискретных величин',
                  ),
                  onChanged: (value) {
                    numberOfValues = int.parse(value);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 50,),
              ElevatedButton(
                onPressed: () {
                  _showValueProbabilityDialog(context, numberOfValues);
                  setState(() {});
                },
                child: Text('Ввести дискретные величины и их вероятности'),
              )
            ],
        ));
        // inputFields.add(TextFormField(
        //   keyboardType: TextInputType.number,
        //   decoration: InputDecoration(
        //     labelText: 'Введите количество дискретных величин',
        //   ),
        //   onChanged: (value) {
        //     numberOfValues = int.parse(value);
        //     setState(() {});
        //   },
        // ));
        // inputFields.add(ElevatedButton(
        //   onPressed: () {
        //     _showValueProbabilityDialog(context, numberOfValues);
        //     setState(() {});
        //   },
        //   child: Text('Set Values and Probabilities'),
        // ));
        break;
    }
    setState(() {
          
    });
  }

  void _showValueProbabilityDialog(BuildContext context, int numberOfValues) {
    List<double> values = List.filled(numberOfValues, 0);
    List<double> probabilities = List.filled(numberOfValues, 0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Values and Probabilities'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: numberOfValues,
              itemBuilder: (BuildContext context, int index) {
                return Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Value ${index + 1}',
                        ),
                        onChanged: (value) {
                          values[index] = double.parse(value);
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Probability ${index + 1}',
                        ),
                        onChanged: (value) {
                          probabilities[index] = double.parse(value);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                    {'values': values, 'probabilities': probabilities});
                    _values = values;
                    _probabilities = probabilities;
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  List<charts.Series<Distribution, num>> _createFXChart(List<Pocket> pockets) {
    List<Distribution> l = [];
    for(int i = 0; i <pockets.length; i++){
      l.add(Distribution(pockets[i].value.toInt(), pockets[i].f));
    }
    return [
      charts.Series<Distribution, int>(
        id: 'F(x)',
        domainFn: (Distribution dist, _) => dist.value,
        measureFn: (Distribution dist, _) => dist.frequency,
        data: l,
      )
    ];
  }
  List<charts.Series<Distribution, int>> _createDistributionData(
      String distributionType,
      List<Distribution> distributionData,
    ) 
    {
      String seriesId;
      switch (distributionType) {
        case 'Bernoulli':
          seriesId = 'Bernoulli Distribution';
          break;
        case 'Binomial':
          seriesId = 'Binomial Distribution';
          break;
        case 'Poisson':
          seriesId = 'Poisson Distribution';
          break;
        case 'Discrete':
          seriesId = 'Discrete Distribution';
          break;
        default:
          seriesId = 'Unknown Distribution';
      }

      return [
        charts.Series<Distribution, int>(
          id: seriesId,
          domainFn: (Distribution dist, _) => dist.value,
          measureFn: (Distribution dist, _) => dist.frequency,
          data: distributionData,
        ),
      ];
    }

  List<charts.Series<Pocket, String>> _createFrequencyChartSeries(List<Pocket> pockets) {
    return [
      charts.Series<Pocket, String>(
        id: 'Frequency',
        domainFn: (Pocket pocket, _) => pocket.value.toString(),
        measureFn: (Pocket pocket, _) => pocket.frequency,
        data: pockets,
      ),
    ];
  }

  List<charts.Series<Pocket, String>> _createRelativeAndTheoreticalFrequencyChartSeries(List<Pocket> pockets) {
    List<charts.Series<Pocket, String>> seriesList = [];

    seriesList.add(charts.Series<Pocket, String>(
      id: 'Relative Frequency',
      domainFn: (Pocket pocket, _) => pocket.value.toString(),
      measureFn: (Pocket pocket, _) => pocket.relativeFrequency,
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      data: pockets,
    ));

    seriesList.add(charts.Series<Pocket, String>(
      id: 'Theoretical Frequency',
      domainFn: (Pocket pocket, _) => pocket.value.toString(),
      measureFn: (Pocket pocket, _) => _calculateTheoreticalFrequency(pocket.value),
      colorFn: (_, __) => charts.MaterialPalette.deepOrange.shadeDefault,
      data: pockets,
    ));

    return seriesList;
  }

  void _calculatePockets(List<Distribution> distributionData) {
    pockets.clear();
    Set<dynamic> uniqueValues = distributionData.map((e) => e.frequency).toSet();
    List<dynamic> sortedValues = uniqueValues.toList()..sort();
    double previousF = 0.0;
    sortedValues.forEach((value) {
      int frequency = distributionData.where((e) => e.frequency == value).length;
      double relativeFrequency = frequency / distributionData.length;
      double theoreticalFrequency = _calculateTheoreticalFrequency(value);

      double f = value == sortedValues.first ? relativeFrequency : previousF + relativeFrequency;

      pockets.add(Pocket(value, frequency, relativeFrequency, theoreticalFrequency, f));

      previousF = f;      

    });
    
  }

  double _calculateTheoreticalFrequency(dynamic value) {
    switch (dropdownValue) {
      case 'Bernoulli':
        double p = double.parse(_controllers[1].text);
        return (value == 1) ? p : 1 - p;
      case 'Binomial':
        double p = double.parse(_controllers[1].text);
        int n = int.parse(_controllers[2].text);
        return _binomialProbability(value, p, n);
      case 'Poisson':
        double lambda = double.parse(_controllers[1].text);
        return _poissonProbability(value, lambda);
      case 'Discrete':
        return _calculateDiscreteProbability(value, _values!, _probabilities!);
      default:
        return 0.0;
    }
  }


  double _binomialProbability(dynamic value, double p, int n) {
    int k = value.toInt();
    return (_factorial(n) / (_factorial(k) * _factorial(n - k))) * pow(p, k) * pow(1 - p, n - k);
  }

  double _poissonProbability(dynamic value, double lambda) {
    int k = value.toInt();
    return exp(-lambda) * pow(lambda, k) / _factorial(k);
  }

  double _calculateDiscreteProbability(dynamic value, List<double> values, List<double> probabilities) {
    int index = values.indexOf(value.toDouble());
    if (index != -1 && index < probabilities.length) {
      return probabilities[index];
    } else {
      return 0.0;
    }
  }


  double _factorial(int n) {
    if (n == 0 || n == 1) {
      return 1;
    }
    double result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }
}
class ChartWidget extends StatelessWidget {
  final Widget chart;

  const ChartWidget({required this.chart});

  @override
  Widget build(BuildContext context) {
    
    return Padding(
        padding: EdgeInsets.all(8.0),
        child: Container(
          // constraints: chartsConstrains,
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: chart,
        ),
      
    );
  }
}

