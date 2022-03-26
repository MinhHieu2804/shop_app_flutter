import 'package:flutter/material.dart';
import 'package:flutter_complete_guide/providers/order.dart' show Orders;
import 'package:flutter_complete_guide/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../widgets/order_item.dart';

class OrdersScreen extends StatelessWidget {
  static const String routeName = '/orders';

  @override
  Widget build(BuildContext context) {
    final orderData = Provider.of<Orders>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Yours Orders')),
      drawer: AppDrawer(),
      body: ListView.builder(
          itemBuilder: (context, i) => OrderItem(orderData.orders[i]),
          itemCount: orderData.orders.length),
    );
  }
}
