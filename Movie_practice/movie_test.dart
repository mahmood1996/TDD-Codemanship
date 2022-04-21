import 'package:flutter_test/flutter_test.dart';

void main() {
  MovieTest().applyRatingAndReviewForMovie();
  MovieTest().calculateAverageRatingForReviews();
  MovieTest().reportMovieReviews();
}

class MovieTest {
  late Movie movie;

  void createMovie() {
    movie = Movie('The Abyss');
  }

  void applyRatingAndReviewForMovie() {
    late MovieReview movieReview;
    setUp(() {
      createMovie();
      movieReview = MovieReview(5, 'Ahmed', 'Nice Movie i watched');
    });
    test('applyRatingAndReviewForMovie', () {
      movie.addReview(movieReview);
      expect(movie.reviews().contains(movieReview), true);
    });
  }

  void calculateAverageRatingForReviews() {
    setUp(createMovie);
    test('calculateAverageRatingForReviews', () {
      movie.addReview(MovieReview(4, 'Anonymous', 'ok'));
      movie.addReview(MovieReview(5, 'Anonymous', 'ok'));
      movie.addReview(MovieReview(3, 'Anonymous', 'ok'));
      movie.addReview(MovieReview(2, 'Anonymous', 'ok'));
      movie.addReview(MovieReview(1, 'Anonymous', 'ok'));
      movie.addReview(MovieReview(5, 'Anonymous', 'ok'));
      expect(movie.averageRate(), 3.3333333333333335);
    });
  }

  void reportMovieReviews() {
    late MovieReporter movieReporter;
    setUp(() {
      createMovie();
      movieReporter = MovieReporter();
    });
    test('reportMovieReviews', () {
      expect(movieReporter.report(movie), _expectedMovieReport(movie));
    });
  }

  String _expectedMovieReport(Movie movie) {
    return '''${movie.movieName}
      5     ${movie.reviewsCountWithRate(5)}
      4     ${movie.reviewsCountWithRate(4)}
      3     ${movie.reviewsCountWithRate(3)}
      2     ${movie.reviewsCountWithRate(2)}
      1     ${movie.reviewsCountWithRate(1)}''';
  }
}

class MovieReporter {
  String report(Movie movie) {
    return '''${movie.movieName}
      5     ${movie.reviewsCountWithRate(5)}
      4     ${movie.reviewsCountWithRate(4)}
      3     ${movie.reviewsCountWithRate(3)}
      2     ${movie.reviewsCountWithRate(2)}
      1     ${movie.reviewsCountWithRate(1)}''';
  }
}

class MovieReview {
  final int rating;
  final String reviewerName;
  final String reviewDescription;
  MovieReview(this.rating, this.reviewerName, this.reviewDescription);
}

class Movie {
  final List<MovieReview> _reviews;
  final String movieName;

  Movie(this.movieName) : _reviews = [];

  void addReview(MovieReview movieReview) {
    _reviews.add(movieReview);
  }

  List<MovieReview> reviews() {
    return List.unmodifiable(_reviews);
  }

  int reviewsCountWithRate(int rate) {
    if (!_rates.contains(rate)) return 0;
    return _rates.reduce((value, element) => value + element);
  }

  Iterable<int> get _rates => _reviews.map<int>((element) => element.rating);

  double averageRate() {
    return _reviews
        .map<double>((element) => element.rating / _reviews.length)
        .reduce((value, element) => value + element);
  }
}
