import 'package:image_picker/image_picker.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';

class MainBloc {
  Stream<List<Meme>> observeMemes() =>
      MemesRepository.getInstance().observeMemes();

  Future<String?> selectMeme() async { /// ImagePicker
    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery);  /// ImagePicker   (main_bloc.dart   main_page.dart    create_meme_page.dart    create_meme_bloc.dart)
    // if (xfile == null)...
    return xfile?.path;   /// ImagePicker    - / если xfile не будет, то вернется  null
  }

  void dispose() {}
}
