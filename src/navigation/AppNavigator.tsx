import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { NavigationContainer } from '@react-navigation/native';
import { View, Text, ActivityIndicator, StyleSheet } from 'react-native';

import { AuthProvider, useAuth } from '../lib/AuthContext';
import { AuthStackParamList, MainTabParamList } from './types';

// Screens
import LoginScreen    from '../screens/auth/LoginScreen';
import RegisterScreen from '../screens/auth/RegisterScreen';
import HomeScreen     from '../screens/buyer/HomeScreen';
import UploadScreen   from '../screens/seller/UploadScreen';
import StudioScreen   from '../screens/seller/StudioScreen';
import OrdersScreen   from '../screens/shared/OrdersScreen';
import ProfileScreen  from '../screens/shared/ProfileScreen';

const AuthStack = createNativeStackNavigator<AuthStackParamList>();
const Tab       = createBottomTabNavigator<MainTabParamList>();

// ─── Tab icon helper ─────────────────────────────────────────────────────────

function TabIcon({ emoji, focused }: { emoji: string; focused: boolean }) {
  return (
    <Text style={{ fontSize: 20, opacity: focused ? 1 : 0.5 }}>{emoji}</Text>
  );
}

// ─── Auth flow ───────────────────────────────────────────────────────────────

function AuthNavigator() {
  return (
    <AuthStack.Navigator screenOptions={{ headerShown: false }}>
      <AuthStack.Screen name="Login"    component={LoginScreen} />
      <AuthStack.Screen name="Register" component={RegisterScreen} />
    </AuthStack.Navigator>
  );
}

// ─── Main tabs ────────────────────────────────────────────────────────────────

function MainTabs() {
  const { isSeller } = useAuth();

  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          backgroundColor: '#111827',
          borderTopColor: '#1f2937',
          height: 60,
          paddingBottom: 8,
        },
        tabBarActiveTintColor: '#d97706',
        tabBarInactiveTintColor: '#6b7280',
        tabBarLabelStyle: { fontSize: 10, fontWeight: '600' },
      }}
    >
      <Tab.Screen
        name="Home"
        component={HomeScreen}
        options={{
          title: 'Beranda',
          tabBarIcon: ({ focused }) => <TabIcon emoji="🏠" focused={focused} />,
        }}
      />
      <Tab.Screen
        name="Orders"
        component={OrdersScreen}
        options={{
          title: 'Pesanan',
          tabBarIcon: ({ focused }) => <TabIcon emoji="📦" focused={focused} />,
        }}
      />
      {isSeller && (
        <Tab.Screen
          name="Upload"
          component={UploadScreen}
          options={{
            title: 'Upload',
            tabBarIcon: ({ focused }) => <TabIcon emoji="📷" focused={focused} />,
          }}
        />
      )}
      {isSeller && (
        <Tab.Screen
          name="Studio"
          component={StudioScreen}
          options={{
            title: 'Studio',
            tabBarIcon: ({ focused }) => <TabIcon emoji="🏪" focused={focused} />,
          }}
        />
      )}
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{
          title: 'Profil',
          tabBarIcon: ({ focused }) => <TabIcon emoji="👤" focused={focused} />,
        }}
      />
    </Tab.Navigator>
  );
}

// ─── Root navigator ───────────────────────────────────────────────────────────

function RootNavigator() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <View style={styles.splash}>
        <Text style={styles.splashBrand}>MAJA<Text style={{ color: '#d97706' }}>CRAFT</Text></Text>
        <ActivityIndicator color="#d97706" style={{ marginTop: 24 }} />
      </View>
    );
  }

  return (
    <NavigationContainer>
      {isAuthenticated ? <MainTabs /> : <AuthNavigator />}
    </NavigationContainer>
  );
}

// ─── App entry ────────────────────────────────────────────────────────────────

export default function AppNavigator() {
  return (
    <AuthProvider>
      <RootNavigator />
    </AuthProvider>
  );
}

const styles = StyleSheet.create({
  splash: {
    flex: 1, backgroundColor: '#0f0f0f',
    alignItems: 'center', justifyContent: 'center',
  },
  splashBrand: {
    fontSize: 36, fontWeight: '800',
    color: '#f5f5f0', letterSpacing: 4,
  },
});
