// import 'dart:convert';
//
// import 'package:rxdart/rxdart.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:superheroes/model/superhero.dart';
//
// class FavoriteSuperheroesStorage {
//   // для добавление - необходимо получить список текущих избранных и добавить нового героя
//   static const _key = 'favorite_superheroes';
//
//   final updater = PublishSubject<Null>();
//
//   static FavoriteSuperheroesStorage?
//       _instance; // статическая переменная _instance
//   factory FavoriteSuperheroesStorage.getInstance() => // factory конструктор который возвращает _instance если он не нулевой либо сохраняет новый _instance класса и его возвращает
//       _instance ??= FavoriteSuperheroesStorage._internal();
//   FavoriteSuperheroesStorage._internal();
//
//   // //получать на вход superhero - добавляет в избранное супергероя
//   // Future<bool> addToFavorites(final Superhero superhero) async {
//   //   // throw UnimplementedError();
//   //   final sp = await SharedPreferences.getInstance();
//   //
//   //   // поскольку в SharedPreferences нельзя сохранять данные модели - только Strig -
//   //   // значит храним геров в виде листа со string - где каждый стринг отдельный герой(приведенный к string) по нашему ключу _key
//   //   // rawSuperheroes - новый герой
//   //   // final rawSuperheroes =  sp.getStringList(_key) ?? [];   // список может быть пустой  ?? []
//   //
//   //   // добавляем нового героя
//   //   rawSuperheroes.add(json.encode(superhero.toJson()));
//   //   // superhero.toJson()- возвращает map с данными => json.encode превращает map в string
//   //   // сохраняем добавленного героя rawSuperheroes - трансформировав в String
//   //   // return sp.setStringList(_key, rawSuperheroes);
//   //   return setRawSuperheroes(rawSuperheroes);
//
//   //получать на вход superhero - добавляет в избранное супергероя
//   /// рефакторинг
//   Future<bool> addToFavorites(final Superhero superhero) async {
//     final rawSuperheroes = await _getRawSuperheroes();
//
//     /// получаем rawSuperheroes
//     rawSuperheroes.add(json.encode(superhero.toJson()));
//
//     /// добавляем rawSuperheroes
//     return _setRawSuperheroes(rawSuperheroes);
//
//     /// сохраняем rawSuperheroes
//   }
//
//   // // удалять по минимальным данным - id -  чем меньше инф, тем лучше
//   // Future<bool> removeFromFavorites(final String id) async {
//   //   // throw UnimplementedError();
//   //   final sp = await SharedPreferences.getInstance();
//   //   final rawSuperheroes =  sp.getStringList(_key) ?? [];
//   //   final superheroes = rawSuperheroes       // что бы удалить - берем  superheroes и мапим map- каждого превратили в
//   //       .map((rawSuperheroes) => Superhero.fromJson(json.decode(rawSuperheroes)))  //вызвав конструктор .fromJson с декодом json.decode(rawSuperheroes - из стринг в мар (обратно))
//   //       .toList();
//   //   superheroes.removeWhere((superheroes) => superheroes.id == id); // удаляем героя с айди который равен указанному в final String id
//   //      // из списка героев - сохраняем в stringList
//   //       final updatedRawSuperheroes
//   //       = superheroes.map((superhero) => json.encode(superhero.toJson())).toList();
//   //   return sp.setStringList(_key, updatedRawSuperheroes);
//   // }
//
//   /// рефакторинг
//   // удалять по минимальным данным - id -  чем меньше инф, тем лучше
//   Future<bool> removeFromFavorites(final String id) async {
//     final superheroes = await _getSuperheroes();
//     superheroes.removeWhere((superheroes) => superheroes.id == id);
//     return _setSuperheroes(superheroes);
//   }
//
//   /// рефакторинг1 _getRawSuperheroes
//   Future<List<String>> _getRawSuperheroes() async {
//     final sp = await SharedPreferences.getInstance();
//     return sp.getStringList(_key) ?? [];
//   }
//
//   /// рефакторинг2 _setRawSuperheroes
//   Future<bool> _setRawSuperheroes(final List<String> rawSuperheroes) async {
//     final sp = await SharedPreferences.getInstance();
//     final result = sp.setStringList(_key, rawSuperheroes);
//     updater.add(null); // прокидываем в updater новое сообщение
//     return result; // возвращаем результат
//   }
//
//   /// рефакторинг3 _getSuperheroes
//   Future<List<Superhero>> _getSuperheroes() async {
//     final rawSuperheroes = await _getRawSuperheroes();
//     return rawSuperheroes
//         .map(
//             (rawSuperheroes) => Superhero.fromJson(json.decode(rawSuperheroes)))
//         .toList();
//   }
//
//   Future<bool> _setSuperheroes(final List<Superhero> superheroes) async {
//     final rawSuperheroes = superheroes
//         .map((superhero) => json.encode(superhero.toJson()))
//         .toList();
//     return _setRawSuperheroes(rawSuperheroes);
//   }
//
//   // сохранять героев и получать первоначально к ним доступ до запроса в сеть // Superhero? - ?возможно его нет
//   Future<Superhero?> getSuperhero(final String id) async {
//     final superheroes = await _getSuperheroes();
//     // искать в коллекции эллемент и если его нет то возвращаем null
//     for (final superhero in superheroes) {
//       if (superhero.id == id) {
//         return superhero;
//       }
//     }
//     return null;
//   }
//
//   //выдавать весь список героев- которые отображаются на главном столе - Фавориты
//   Stream<List<Superhero>> observeFavoriteSuperheroes() async* {
//     yield await _getSuperheroes(); // возвращаем в Stream значение подождав из _getSuperheroes
//     // throw UnimplementedError();
//     await for (final _ in updater) {
//       yield await _getSuperheroes();
//     }
//   }
//
//   // на странице - наблюдать-observe-  значение - есть в фаворитах герой/звездочка или нет
//   Stream<bool> observeIsFavorite(final String id) {
//     return observeFavoriteSuperheroes() // вызвали метод observeFavoriteSuperheroes и на каждое значение - мапим - если один из них удовлетв этому условию то ворзвращаем true
//         .map((superheroes) =>
//             superheroes.any((superhero) => superhero.id == id));
//   }
//
//   Future<bool> updateIfInFavorites(final Superhero newSuperhero) async {
//     final superheroes = await _getSuperheroes();
//     final index =
//         superheroes.indexWhere((superhero) => superhero.id == newSuperhero.id);
//     // final isInFavorites = await observeIsFavorite(newSuperhero.id).first;
//     if (index == -1) {
//       return false;
//     }
//     superheroes[index] = newSuperhero;
//     return _setSuperheroes(superheroes);
//   }
// }
