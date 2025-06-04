import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {  static final cloudinary = CloudinaryPublic(
    'ddqioakcd',  // Cloudinary cloud name
    'testing',   // Upload preset
    cache: false,
  );

  static Future<String> uploadImage(String imagePath) async {
    try {      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imagePath,
          resourceType: CloudinaryResourceType.Image,
          folder: 'buddy_images', // Organize images in a folder
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      throw e;
    }
  }
}
