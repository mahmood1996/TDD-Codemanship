import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  CDWarehouseTest()
    ..leaveReviewFromCustomerOnCD()
    ..searchForCDExistsInTheWareHouse()
    ..searchForCDThrowsNotFoundExceptionIfNotExistsInTheWareHouse()
    ..stockCountIs2AfterReceivingBatchOf2CDs()
    ..stockCountIs4AfterReceiving2BatchesOf2CDs()
    ..stockCountThrowsNotFoundExceptionIfNotExistInTheWareHouse()
    ..makeOrderWithCDInStock()
    ..makeOrderWithCDsOutOfStock()
    ..stockCountDecreasedAfterBuyingCD()
    ..makeOrderAfterAcceptingPayment()
    ..stockCountDoesNotDecreasedIfPaymentRefused()
    ..orderAddedAfterAcceptingPaymentAndInStock();
}

class CDWarehouseTest {
  late Customer _customer;
  late Artist _artist;
  late CD _cd;
  late Warehouse _warehouse;
  late Payable _paymentGateway;

  CDWarehouseTest() {
    setUp(() {
      _customer = Customer('Mahmoud Abdulrazik');
      _artist = Artist('Sami Yousef');
      _cd = CD('Hasbi Rabi', _artist);
      _paymentGateway = MockPaymentGateway();
      _warehouse = Warehouse(stockedCDs: [_cd], paymentGateway: _paymentGateway);
    });
  }

  void leaveReviewFromCustomerOnCD() {
    test('Leave Review On CD', () {
      var review = Review(_customer, 5, 'Nice song from sami');
      _cd.leaveReview(review);
      expect(_cd.getReviews(), contains(review));
    });
  }

  void searchForCDExistsInTheWareHouse() {
    test('Search For CD That exists In Warehouse', () {
      _warehouse.receiveBatch(Batch(_cd, 1, RecordLabel('M2A')));
      expect(_warehouse.search(_cd.title, _cd.artist), equals(_cd));
    });
  }

  void searchForCDThrowsNotFoundExceptionIfNotExistsInTheWareHouse() {
    test('Search For CD That Not Exists In Warehouse', () {
      CD _newCD = CD('The Teacher', _artist);
      expect(() => _warehouse.search(_newCD.title, _newCD.artist),
          throwsA(isA<CDNotFoundException>()));
    });
  }


  void stockCountIs2AfterReceivingBatchOf2CDs() {
    _stockCountIsSumOfNoOfCDsInEachBatch(2, 1, 2);
  }

  void stockCountIs4AfterReceiving2BatchesOf2CDs() {
    _stockCountIsSumOfNoOfCDsInEachBatch(4, 2, 2);
  }

  void _stockCountIsSumOfNoOfCDsInEachBatch(int expected, int numberOfBatches, int numberOfCDs) {
    test('Stock Count Is $expected After Receiving $numberOfBatches Batch Of $numberOfCDs CDs', () {
      for (int batchIndex = 1; batchIndex <= numberOfBatches; batchIndex ++) {
        _warehouse.receiveBatch(Batch(_cd, numberOfCDs, RecordLabel('M2A')));
      }
      expect(_warehouse.count(_cd.title), equals(expected));
    });
  }

  void stockCountThrowsNotFoundExceptionIfNotExistInTheWareHouse() {
    test(
        'Stock Count Throws Not Found Exception If It Is Not Exist In The WareHouse',
        () {
      var _newCD = CD('Ellahy', Artist('Mashary Rashed Elafasy'));
      expect(() => _warehouse.count(_newCD.title),
          throwsA(isA<CDNotFoundException>()));
    });
  }

  void makeOrderWithCDInStock() {
    test('Making Order with CD In Stock', () {
      _warehouse.receiveBatch(Batch(_cd, 4, RecordLabel('M2A')));
      var result = _warehouse.buyCD(_cd.title, 2, _customer);
      var order = Order(_cd, _customer, 2);
      expect(result, order);
    });
  }

  void makeOrderWithCDsOutOfStock() {
    test('Making Order with CD Out Of Stock', () {
      _warehouse.receiveBatch(Batch(_cd, 2, RecordLabel('M2A')));
      expect(() => _warehouse.buyCD(_cd.title, 4, _customer), throwsA(isA<CDOutOfStockException>()));
    });
  }

  void stockCountDecreasedAfterBuyingCD() {
    test('Stock Count Decreased After Buying CD', () {
      _warehouse.receiveBatch(Batch(_cd, 4, RecordLabel('M2A')));
      _warehouse.buyCD(_cd.title, 2, _customer);
      expect(_warehouse.count(_cd.title), 2);
    });
  }

  void makeOrderAfterAcceptingPayment() {
    test('Payment Called When buying for CD', () {
      _warehouse.receiveBatch(Batch(_cd, 1, RecordLabel('M2A')));
      _warehouse.buyCD(_cd.title, 1, _customer);
      when(_paymentGateway.pay()).thenAnswer((_) {});
      verify(_paymentGateway.pay());
    });
  }

  void stockCountDoesNotDecreasedIfPaymentRefused() {
    test('Stock Count Does Not Decreased If Payment Refused', () {
      _warehouse.receiveBatch(Batch(_cd, 1, RecordLabel('M2A')));
      when(_paymentGateway.pay()).thenThrow(PaymentRefusedException());
      _warehouse.buyCD(_cd.title, 1, _customer);
      expect(_warehouse.count(_cd.title), 1);
    });
  }

  void orderAddedAfterAcceptingPaymentAndInStock() {
    test('Order Added After Accepting Payment And In Stock', () {
      _warehouse.receiveBatch(Batch(_cd, 2, RecordLabel('M2A')));
      when(_paymentGateway.pay()).thenAnswer((_) {});
      var result = _warehouse.buyCD(_cd.title, 1, _customer);
      expect(_warehouse.orders(), contains(result));
    });
  }
}

class MockPaymentGateway extends Mock implements Payable {}

abstract class Payable {
  void pay();
}

class CDOutOfStockException implements Exception {}
class CDNotFoundException implements Exception {}
class PaymentRefusedException implements Exception {}

class Batch {
  final CD cd;
  final int quantity;
  final RecordLabel recordLabel;

  Batch(this.cd, this.quantity, this.recordLabel);
}

class RecordLabel {
  final String name;

  RecordLabel(this.name);
}

class Warehouse {
  final Payable paymentGateway;
  late final List<CD> _stockedCDs;
  late final List<Order> _orders;
  late final Stock _stock;

  Warehouse({List <CD> stockedCDs = const <CD> [], required this.paymentGateway}) {
    _stockedCDs = List.from(stockedCDs);
    _orders = <Order> [];
    _stock = Stock(stockedCDs: _stockedCDs);
  }

  CD search(String title, Artist artist) {
    return _stockedCDs.firstWhere(
        (element) => element.title == title && element.artist == artist,
        orElse: () => throw CDNotFoundException());
  }

  void receiveBatch(Batch batch) {
    _stock.increaseCDCount(batch.cd, batch.quantity);
  }

  int count(String title) {
    return _stock.count(_findCDByTitle(title));
  }

  Order buyCD(String title, int quantity, Customer customer) {
    try {
      return _buyCD(title, quantity, customer);
    } on PaymentRefusedException {
      return Order(_findCDByTitle(title), customer, 0);
    }
  }

  Order _buyCD(String title, int quantity, Customer customer) {
    if (count(title) < quantity) throw CDOutOfStockException();
    paymentGateway.pay();
    _stock.decreaseCDCount(_findCDByTitle(title), quantity);
    return _makeOrder(_findCDByTitle(title), customer, quantity);
  }

  Order _makeOrder(CD cd, Customer customer, int quantity) {
    var result = Order(cd, customer, quantity);
    _orders.add(result);
    return result;
  }

  CD _findCDByTitle(String title) {
    return _stockedCDs.firstWhere((element) => element.title == title,
        orElse: () => throw CDNotFoundException());
  }

  List<Order> orders() {
    return List.unmodifiable(_orders);
  }
}

class Stock {
  late final Map<CD, int> _stockQuantity;

  Stock({List <CD> stockedCDs = const <CD> []}) {
    _stockQuantity = <CD, int> {
      for (var cd in stockedCDs) cd : 0
    };
  }

  int count(CD cd) {
    return _stockQuantity[cd] ?? 0;
  }

  void increaseCDCount(CD cd, int value) {
    _stockQuantity[cd] = count(cd) + value;
  }

  void decreaseCDCount(CD cd, int value) {
    _stockQuantity[cd] = count(cd) - value;
  }
}

class Order {
  final CD cd;
  final Customer customer;
  final int quantity;

  Order(this.cd, this.customer, this.quantity);

  @override
  int get hashCode => Object.hashAll([cd, customer, quantity]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Order) return false;
    return cd == other.cd &&
        quantity == other.quantity &&
        customer == other.customer;
  }
}


class CD {
  final List<Review> _reviews;

  final String title;
  final Artist artist;

  CD(this.title, this.artist) : _reviews = <Review>[];

  void leaveReview(Review review) => _reviews.add(review);

  List<Review> getReviews() => List.unmodifiable(_reviews);

  @override
  int get hashCode => Object.hashAll([title, artist]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CD) return false;
    return other.title == title && artist == other.artist;
  }
}

class Review {
  final Customer customer;
  final int rating;
  final String description;

  Review(this.customer, this.rating, this.description) {
    assert(rating >= 1 && rating <= 10);
  }

  @override
  int get hashCode => Object.hashAll([customer, rating, description]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Review) return false;
    return customer == other.customer &&
        rating == other.rating &&
        description == other.description;
  }
}

class Customer {
  final String name;

  Customer(this.name);

  @override
  int get hashCode => Object.hashAll([name]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Customer) return false;
    return name == other.name;
  }
}

class Artist {
  Artist(String name);
}
