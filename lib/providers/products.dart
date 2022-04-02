import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_complete_guide/models/http_exception.dart';
import 'dart:convert';
import 'product.dart';
import 'package:http/http.dart' as http;

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];

  // bool _showFavoritesOnly = false;
  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    // if (_showFavoritesOnly) {
    //   return _items.where((element) => element.isFavorite).toList();
    // } else {
    return [..._items];
    // }
  }

  List<Product> get favoriteItems {
    return _items.where((element) => element.isFavorite).toList();
  }
  // void showFavoriteOnly() {
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }

  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts() async {
    var url =
        'https://flutter-learn-cedb4-default-rtdb.firebaseio.com/products.json?auth=$authToken&orderBy="creatorId"&equalTo="$userId"';
    try {
      final response = await http.get(url);
      final extractData = jsonDecode(response.body) as Map<String, dynamic>;
      if (extractData == null) {
        return;
      }
      url =
          'https://flutter-learn-cedb4-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
      final favoritesResponse = await http.get(url);
      final favResData = json.decode(favoritesResponse.body);
      final List<Product> loadedProducts = [];
      extractData.forEach((pid, prodData) {
        loadedProducts.add(Product(
          id: pid,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          // isFavorite: false,
          isFavorite: favResData[pid] == null
              ? false
              : favResData[pid]['isFavorite'] ?? false,
          imageUrl: prodData['imageUrl'],
        ));
      });
      _items = loadedProducts;
    } catch (err) {
      log(err);
      throw err;
    }
  }

  Future<void> addProduct(Product product) {
    final url =
        'https://flutter-learn-cedb4-default-rtdb.firebaseio.com/products.json?auth=$authToken';
    return http
        .post(
      url,
      body: json.encode({
        'title': product.title,
        'description': product.description,
        'price': product.price,
        'isFavorite': product.isFavorite,
        'imageUrl': product.imageUrl,
        'creatorId': userId,
      }),
    )
        .then((value) {
      final newProduct = Product(
          title: product.title,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl,
          id: json.decode(value.body)['name']);
      _items.add(newProduct);
      notifyListeners();
    }).catchError((err) {
      print(err);
      throw err;
    });
  }

  Future<void> updateProduct(String pid, Product product) async {
    final productIndex = _items.indexWhere((element) => element.id == pid);
    if (productIndex >= 0) {
      final url =
          'https://flutter-learn-cedb4-default-rtdb.firebaseio.com/products/$pid.json?auth=$authToken';
      await http.patch(url,
          body: json.encode({
            'title': product.title,
            'description': product.description,
            'price': product.price,
            'imageUrl': product.imageUrl,
          }));
      _items[productIndex] = product;
      notifyListeners();
    } else {
      print(',,,');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://flutter-learn-cedb4-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex =
        _items.indexWhere((element) => element.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeWhere((element) => element.id == id);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product!');
    }
    existingProduct = null;
  }
}
