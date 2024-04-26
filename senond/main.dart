import 'dart:math';
import 'package:data/data.dart';
import 'package:data/stats.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
Random random = Random(617);
void main() {
  runApp(MyApp());
}

class Pocket {
  double value;
  double p;
  double frequency;
  double relativeFrequency;
  double theoreticalFrequency;
  double f;
  double norm;

  Pocket(this.value,this.p, this.frequency, this.relativeFrequency,this.f, this.theoreticalFrequency,this.norm);
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
      title: 'Статистические характеристики наборов данных непрерывных случайных величин',
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
  String dropdownValue = 'Нормальное';
  List<Distribution> data = [];
  List<Widget> inputFields = [];
  late List<TextEditingController> _controllers;

  List<Pocket> pockets = [];

  late double min;
  late double max;
  late double pocketSize;
  int pocketAmount=12;

  

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (_) => TextEditingController());
    _updateInputFields();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

 
  void _calculateDistribution(){
    List<Distribution> distributionData = [];
    int numberOfValues = int.parse(_controllers[0].text);
    double a = double.parse(_controllers[1].text);
    double b = double.parse(_controllers[2].text);
    if (_controllers.isNotEmpty) {
      switch (dropdownValue) {
        case 'Равномерное':
          for(int i = 0; i <numberOfValues; i++){
            distributionData.add(Distribution(i,UniformDistribution(a,b).sample()));
          }
          break;
        case 'Нормальное':
          for(int i = 0; i <numberOfValues; i++){
            distributionData.add(Distribution(i,NormalDistribution(a,b).sample()));
          }
          break;
        case 'Гамма':
          for(int i = 0; i <numberOfValues; i++){
            distributionData.add(Distribution(i,GammaDistribution(a, b).sample()));
          }
          break;
        case 'Бета':
          for(int i = 0; i <numberOfValues; i++){
            distributionData.add(Distribution(i, _generateBetalDist(a,b)));
          }
          break;
      }
    }
    
    setState(() {
      data = distributionData;
    });
  }
  double _generateBetalDist(double shape, double scale){
    double sum = 0;
    for (int i = 0; i < shape; i++) {
      sum += -log(Random().nextDouble());
    }
    return sum * scale;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистические характеристики наборов данных непрерывных случайных величин'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Информация'),
                    content: const SingleChildScrollView(
                      child: Text(
                        """Для начала нужно выбрать вид распределения из выпадающего списка.
                        \nЗатем ввести необходимые параметры. 
                        \n Когда все готово, нужно нажать на кнопку 'Сгенерировать' """,
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Закрыть'),
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
                'Равномерное',
                'Нормальное',
                'Гамма',
                'Бета'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            ...inputFields,
            if(_controllers.every((element) => element.text!=null))
            ElevatedButton(
              onPressed: () {
                _calculateDistribution();
                _calculatePockets(data);

              },
              child: const Text('Сгенерировать'),
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
                    // chart: charts.BarChart(
                    //   _createRelativeAndTheoreticalFrequencyChartSeries(pockets),
                    //   animate: true,
                    // )
                    chart: charts.NumericComboChart(
                      _createRelativeAndTheoreticalFrequencyChartSeries(pockets),
                      animate: true,
                      customSeriesRenderers: [
                        charts.LineRendererConfig(
                          customRendererId: 'Theoretical Frequency',
                          symbolRenderer: charts.CircleSymbolRenderer()
                          
                        ),
                      ],
                      behaviors: [
                        charts.PanAndZoomBehavior(
                          
                        ),
                      ],
                    ),
                  ),
                ],
              )
              
          ],
        ),
      ),
    );
  }

  void _updateInputFields() {
    inputFields.clear();
    inputFields.add(TextFormField(
      keyboardType: TextInputType.number,
        decoration: const InputDecoration(
        labelText: 'Введите кол-во генерируемых чисел',
      ),
      onChanged: (value) {
        _controllers[0].text = value;
        setState(() {});
      },
    ));
    switch (dropdownValue) {
      case 'Равномерное':
        
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'от а',
          ),
          onChanged: (value) {
            _controllers[1].text = value;
            setState(() {});
          },
        ));
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'до b',
          ),
          onChanged: (value) {
            _controllers[2].text = value;
            setState(() {});
          },
        ));
        break;
      case 'Нормальное':
        
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Введите мат. ожидание',
          ),
          onChanged: (value) {
            _controllers[1].text = value;
            setState(() {});
          },
        ));
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Введите СКО',
          ),
          onChanged: (value) {
            _controllers[2].text = value;
            setState(() {});
          },
        ));
        break;
      case 'Гамма':
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Введите а-параметр формы',
          ),
          onChanged: (value) {
            _controllers[1].text = value;
            setState(() {});
          },
        ));
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Введите В-параметр масштаба',
          ),
          onChanged: (value) {
            _controllers[2].text = value;
            setState(() {});
          },
        ));
        break;
      case 'Бета':
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Введите а-параметр формы',
          ),
          onChanged: (value) {
            _controllers[1].text = value;
            setState(() {});
          },
        ));
        inputFields.add(TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Введите В-параметр масштаба',
          ),
          onChanged: (value) {
            _controllers[2].text = value;
            setState(() {});
          },
        ));
        break;
    }
    setState(() {
          
    });
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
      return [
        charts.Series<Distribution, int>(
          id: dropdownValue,
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
List<charts.Series<dynamic, num>> _createRelativeAndTheoreticalFrequencyChartSeries(List<Pocket> pockets) {
  List<charts.Series<dynamic, num>> seriesList = [];

  seriesList.add(charts.Series<dynamic, num>(
    id: 'Relative Frequency',
    domainFn: (datum, index) => pockets[index!].value, 
    measureFn: (datum, index) => pockets[index!].relativeFrequency, 
    colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
    data: pockets,
  ));

  seriesList.add(charts.Series<dynamic, num>(
    id: 'Theoretical Frequency',
    domainFn: (datum, index) => pockets[index!].value, 
    measureFn: (datum, index) => pockets[index!].norm, 
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
    if(dropdownValue =='Равномерное'){
      min = 17;
      max = min*2;
    }
    else{
      min = sortedValues.first;
      max = sortedValues.last;
    }
    print('$min $max');
    pocketSize = (max-min)/pocketAmount;
    // print(pocketSize);
    List<double> karmans = List.generate(
      pocketAmount,
      (index) => (min + (index + 1) * pocketSize),
    );

    List<double> karmansValue = List.filled(pocketAmount, 0);
    
    for (int i = 0; i < distributionData.length; i++) {
      int j = 0;
      while (j!=pocketAmount-1){
        // print('i $i j $j');
        if(distributionData[i].frequency<karmans[j]){
          break;
        }
        j++;
      }
      karmansValue[j] ++;
    }

    List<double> percentedFrequency = karmansValue.map((val) => val / int.parse(_controllers[0].text)).toList();
    // print(percentedFrequency);
    // print(karmans.toString());
    // print(karmansValue.toString());
    double sum = percentedFrequency.reduce((value, element) => value + element);
    for (int i = 1; i < pocketAmount; i++) {
      double value;
      if(dropdownValue=='Гамма' && dropdownValue=='Бета'){
        if(i==1){
          value = min+pocketSize;
        }
        else{
          value = pockets[i-1].value +pocketSize;
        }
      }
      else{
        value = min + i * pocketSize;
      }
      // print(value);
      double rf = karmansValue[i] /100;
      double tf=percentedFrequency[i-1];

      double f = value == sortedValues.first ? rf : previousF + rf;
      double normtf = tf / sum;
      pockets.add(Pocket(value,karmans[i],karmansValue[i],rf,f,tf,normtf));
      
      previousF = f;  
      
    }
    
  }
}



class ChartWidget extends StatelessWidget {
  final Widget chart;

  const ChartWidget({required this.chart});

  @override
  Widget build(BuildContext context) {
    
    return Padding(
        padding: const EdgeInsets.all(8.0),
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

