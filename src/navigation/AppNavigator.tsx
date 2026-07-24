import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { NavigationContainer } from '@react-navigation/native';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';

import { AuthProvider, useAuth } from '../lib/AuthContext';
import { MainTabParamList, RootStackParamList } from './types';
import LoginScreen    from '../screens/auth/LoginScreen';
import RegisterScreen from '../screens/auth/RegisterScreen';
import TabWebView     from '../screens/main/TabWebView';
import CustomTabBar   from './CustomTabBar';
import { WEB_PAGES } from '../constants/config';

const Root = createNativeStackNavigator<RootStackParamList>();
const Tab  = createBottomTabNavigator<MainTabParamList>();

function MainTabs() {
  const { isAuthenticated } = useAuth();

  return (
    <Tab.Navigator
      screenOptions={{ headerShown: false }}
      tabBar={(props) => <CustomTabBar {...props} />}
    >
      <Tab.Screen name="Home">
        {() => <TabWebView url={WEB_PAGES.HOME} />}
      </Tab.Screen>
      <Tab.Screen name="Search">
        {() => <TabWebView url={WEB_PAGES.PRODUCTS} />}
      </Tab.Screen>

      {/* Protected tabs — intercept tabPress jika belum login */}
      <Tab.Screen
        name="Cart"
        listeners={({ navigation }) => ({
          tabPress: (e) => {
            if (!isAuthenticated) {
              e.preventDefault();
              navigation.getParent()?.navigate('Login' as never, { redirect: WEB_PAGES.CART } as never);
            }
          },
        })}
      >
        {() => <TabWebView url={WEB_PAGES.CART} protected />}
      </Tab.Screen>
      <Tab.Screen
        name="Orders"
        listeners={({ navigation }) => ({
          tabPress: (e) => {
            if (!isAuthenticated) {
              e.preventDefault();
              navigation.getParent()?.navigate('Login' as never, { redirect: WEB_PAGES.ORDERS } as never);
            }
          },
        })}
      >
        {() => <TabWebView url={WEB_PAGES.ORDERS} protected />}
      </Tab.Screen>
      <Tab.Screen
        name="Profile"
        listeners={({ navigation }) => ({
          tabPress: (e) => {
            if (!isAuthenticated) {
              e.preventDefault();
              navigation.getParent()?.navigate('Login' as never, { redirect: WEB_PAGES.PROFILE } as never);
            }
          },
        })}
      >
        {() => <TabWebView url={WEB_PAGES.PROFILE} protected />}
      </Tab.Screen>
    </Tab.Navigator>
  );
}

function RootNavigator() {
  const { isLoading } = useAuth();

  if (isLoading) {
    return (
      <View style={styles.splash}>
        <Text style={styles.splashBrand}>
          MAJA<Text style={{ color: '#d97706' }}>CRAFT</Text>
        </Text>
        <ActivityIndicator color="#d97706" style={{ marginTop: 24 }} />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <Root.Navigator screenOptions={{ headerShown: false }}>
        <Root.Screen name="Tabs" component={MainTabs} />
        <Root.Screen
          name="Login"
          component={LoginScreen}
          options={{ presentation: 'modal', animation: 'slide_from_bottom' }}
        />
        <Root.Screen
          name="Register"
          component={RegisterScreen}
          options={{ presentation: 'modal', animation: 'slide_from_bottom' }}
        />
      </Root.Navigator>
    </NavigationContainer>
  );
}

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
    color: '#f5f5f0', letterSpacing: 6,
  },
});

