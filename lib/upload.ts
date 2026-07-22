import * as ImagePicker from 'expo-image-picker';
import * as FileSystem from 'expo-file-system';
import { Alert } from 'react-native';
import { UPLOAD_CONFIG } from '../constants/config';

/**
 * Request camera permissions
 */
export async function requestCameraPermissions(): Promise<boolean> {
  try {
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert(
        'Permission Required',
        'Camera permission is required to take photos.'
      );
      return false;
    }
    return true;
  } catch (error) {
    console.error('Error requesting camera permissions:', error);
    return false;
  }
}

/**
 * Request media library permissions
 */
export async function requestMediaLibraryPermissions(): Promise<boolean> {
  try {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert(
        'Permission Required',
        'Media library permission is required to select photos.'
      );
      return false;
    }
    return true;
  } catch (error) {
    console.error('Error requesting media library permissions:', error);
    return false;
  }
}

/**
 * Launch camera to take a photo
 */
export async function takePicture(): Promise<string | null> {
  const hasPermission = await requestCameraPermissions();
  if (!hasPermission) return null;

  try {
    const result = await ImagePicker.launchCameraAsync({
      mediaTypes: ['images'],
      allowsEditing: true,
      aspect: [4, 3],
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      return result.assets[0].uri;
    }
    return null;
  } catch (error) {
    console.error('Error taking picture:', error);
    Alert.alert('Error', 'Failed to take picture. Please try again.');
    return null;
  }
}

/**
 * Pick image from gallery
 */
export async function pickImage(): Promise<string | null> {
  const hasPermission = await requestMediaLibraryPermissions();
  if (!hasPermission) return null;

  try {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsEditing: true,
      aspect: [4, 3],
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      return result.assets[0].uri;
    }
    return null;
  } catch (error) {
    console.error('Error picking image:', error);
    Alert.alert('Error', 'Failed to pick image. Please try again.');
    return null;
  }
}

/**
 * Pick multiple images from gallery
 */
export async function pickMultipleImages(maxImages: number = 5): Promise<string[]> {
  const hasPermission = await requestMediaLibraryPermissions();
  if (!hasPermission) return [];

  try {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsMultipleSelection: true,
      quality: 0.8,
    });

    if (!result.canceled && result.assets.length > 0) {
      const uris = result.assets.slice(0, maxImages).map(asset => asset.uri);
      return uris;
    }
    return [];
  } catch (error) {
    console.error('Error picking multiple images:', error);
    Alert.alert('Error', 'Failed to pick images. Please try again.');
    return [];
  }
}

/**
 * Get file size in bytes
 */
export async function getFileSize(uri: string): Promise<number> {
  try {
    const fileInfo = await FileSystem.getInfoAsync(uri);
    if (fileInfo.exists && 'size' in fileInfo) {
      return fileInfo.size;
    }
    return 0;
  } catch (error) {
    console.error('Error getting file size:', error);
    return 0;
  }
}

/**
 * Validate image file
 */
export async function validateImage(uri: string): Promise<{ valid: boolean; error?: string }> {
  try {
    const size = await getFileSize(uri);
    
    if (size === 0) {
      return { valid: false, error: 'Invalid file' };
    }
    
    if (size > UPLOAD_CONFIG.MAX_IMAGE_SIZE) {
      const maxSizeMB = UPLOAD_CONFIG.MAX_IMAGE_SIZE / (1024 * 1024);
      return { valid: false, error: `File size exceeds ${maxSizeMB}MB limit` };
    }
    
    return { valid: true };
  } catch (error) {
    console.error('Error validating image:', error);
    return { valid: false, error: 'Failed to validate file' };
  }
}

/**
 * Create FormData for image upload
 */
export async function createImageFormData(
  uri: string,
  fieldName: string = 'file',
  folder: string = 'products'
): Promise<FormData> {
  const filename = uri.split('/').pop() || 'image.jpg';
  const match = /\.(\w+)$/.exec(filename);
  const type = match ? `image/${match[1]}` : 'image/jpeg';

  const formData = new FormData();
  formData.append(fieldName, {
    uri,
    name: filename,
    type,
  } as any);
  formData.append('folder', folder);

  return formData;
}
