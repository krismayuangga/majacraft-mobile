import { useEffect } from 'react';
import { View, Text, StyleSheet, ActivityIndicator, Alert } from 'react-native';
import { useRouter, Redirect } from 'expo-router';
import { useAuth } from '../lib/AuthContext';
import { StatusBar } from 'expo-status-bar';

export default function Index() {
  const { isLoading, isAuthenticated } = useAuth();

  // Direct redirect approach
  if (!isLoading) {
    if (isAuthenticated) {
      return <Redirect href="/(tabs)" />;
    } else {
      return <Redirect href="/(auth)/login" />;
    }
  }

  return (
    <View style={styles.container}>
      <StatusBar style="auto" />
      <Text style={styles.title}>MajaCraft</Text>
      <ActivityIndicator size="large" color="#007AFF" style={styles.loader} />
      <Text style={styles.subtitle}>Loading...</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#007AFF',
    marginBottom: 20,
  },
  loader: {
    marginVertical: 20,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
  },
});
