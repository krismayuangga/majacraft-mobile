import { useState } from 'react';
import { Alert } from 'react-native';
import { takePicture, pickImage, pickMultipleImages, validateImage } from '../lib/upload';

interface UseImagePickerReturn {
  images: string[];
  isLoading: boolean;
  addImageFromCamera: () => Promise<void>;
  addImageFromGallery: () => Promise<void>;
  addMultipleImages: () => Promise<void>;
  removeImage: (index: number) => void;
  clearImages: () => void;
}

export function useImagePicker(maxImages: number = 5): UseImagePickerReturn {
  const [images, setImages] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const addImageFromCamera = async () => {
    if (images.length >= maxImages) {
      Alert.alert('Limit Reached', `You can only upload ${maxImages} images`);
      return;
    }

    setIsLoading(true);
    try {
      const uri = await takePicture();
      if (uri) {
        const validation = await validateImage(uri);
        if (!validation.valid) {
          Alert.alert('Invalid Image', validation.error || 'Failed to validate image');
          return;
        }
        setImages(prev => [...prev, uri]);
      }
    } catch (error) {
      console.error('Error adding image from camera:', error);
      Alert.alert('Error', 'Failed to add image from camera');
    } finally {
      setIsLoading(false);
    }
  };

  const addImageFromGallery = async () => {
    if (images.length >= maxImages) {
      Alert.alert('Limit Reached', `You can only upload ${maxImages} images`);
      return;
    }

    setIsLoading(true);
    try {
      const uri = await pickImage();
      if (uri) {
        const validation = await validateImage(uri);
        if (!validation.valid) {
          Alert.alert('Invalid Image', validation.error || 'Failed to validate image');
          return;
        }
        setImages(prev => [...prev, uri]);
      }
    } catch (error) {
      console.error('Error adding image from gallery:', error);
      Alert.alert('Error', 'Failed to add image from gallery');
    } finally {
      setIsLoading(false);
    }
  };

  const addMultipleImages = async () => {
    const remaining = maxImages - images.length;
    if (remaining <= 0) {
      Alert.alert('Limit Reached', `You can only upload ${maxImages} images`);
      return;
    }

    setIsLoading(true);
    try {
      const uris = await pickMultipleImages(remaining);
      if (uris.length > 0) {
        // Validate all images
        const validatedUris: string[] = [];
        for (const uri of uris) {
          const validation = await validateImage(uri);
          if (validation.valid) {
            validatedUris.push(uri);
          } else {
            Alert.alert('Invalid Image', `${uri.split('/').pop()}: ${validation.error}`);
          }
        }
        
        if (validatedUris.length > 0) {
          setImages(prev => [...prev, ...validatedUris]);
        }
      }
    } catch (error) {
      console.error('Error adding multiple images:', error);
      Alert.alert('Error', 'Failed to add images from gallery');
    } finally {
      setIsLoading(false);
    }
  };

  const removeImage = (index: number) => {
    setImages(prev => prev.filter((_, i) => i !== index));
  };

  const clearImages = () => {
    setImages([]);
  };

  return {
    images,
    isLoading,
    addImageFromCamera,
    addImageFromGallery,
    addMultipleImages,
    removeImage,
    clearImages,
  };
}
