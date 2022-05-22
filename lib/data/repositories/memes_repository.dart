import 'dart:convert';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/shared_preference_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';


class MemesRepository {
  final updater = PublishSubject<Null>();
  final SharedPreferenceData spData;

  static MemesRepository? _instance; // статическая переменная _instance
  factory MemesRepository.getInstance() =>
      // factory конструктор который возвращает _instance если он не нулевой либо сохраняет новый _instance класса и его возвращает
  _instance ??=
      MemesRepository._internal(SharedPreferenceData.getInstance());

  MemesRepository._internal(this.spData);
/// var1
  // Future<bool> addToMemes(final Meme newMeme) async {
  //   final memes = await getMemes();
  //   final memeIndex = memes.indexWhere((meme) => meme.id == newMeme.id);
  //   if (memeIndex == -1) {
  //     return _setMemes([...memes, newMeme]);
  //   }
  //   memes.removeAt(memeIndex);
  //   memes.insert(memeIndex, newMeme);
  //   return _setMemes(memes);
  // }
/// var2
  Future<bool> addToMemes(final Meme newMeme) async {
    final memes = await getMemes();
    final memeIndex = memes.indexWhere((meme) => meme.id == newMeme.id);
    if (memeIndex == -1) {
      memes.add(newMeme);
    } else {
      memes.removeAt(memeIndex);
      memes.insert(memeIndex, newMeme);
    }
    return _setMemes(memes);
  }


  // удалять по минимальным данным - id -  чем меньше инф, тем лучше
  Future<bool> removeFromMemes(final String id) async {
    final memes = await getMemes();
    memes.removeWhere((meme) => meme.id == id);
    return _setMemes(memes);
  }

  //выдавать весь список героев- которые отображаются на главном столе - Фавориты
  Stream<List<Meme>> observeMemes() async* {
    yield await getMemes(); // возвращаем в Stream значение подождав из _getMemes
    // throw UnimplementedError();
    await for (final _ in updater) {
      yield await getMemes();
    }
  }




  Future<List<Meme>> getMemes() async {
    final rawMemes = await spData.getMemes();
    return rawMemes
        .map((rawMeme) => Meme.fromJson(json.decode(rawMeme)))
        .toList();
  }

  // сохранять героев и получать первоначально к ним доступ до запроса в сеть // Meme? - ?возможно его нет
  Future<Meme?> getMeme(final String id) async {
    final memes = await getMemes();
    // искать в коллекции эллемент и если его нет то возвращаем null
 return memes.firstWhereOrNull((meme) => meme.id == id);
      }
    


  Future<bool> _setMemes(final List<Meme> memes) async {
    final rawMemes = memes.map((meme) => json.encode(meme.toJson())).toList();
    return _setRawMemes(rawMemes);
  }

  Future<bool> _setRawMemes(final List<String> rawMemes) {
    updater.add(null); // прокидываем в updater новое сообщение
    return spData.setMemes(rawMemes); // возвращаем результат
  }

}
