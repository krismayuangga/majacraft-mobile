import React from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet, Platform,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { BottomTabBarProps } from '@react-navigation/bottom-tabs';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

// ─── Design exact dari web app (Lucide → MaterialCommunityIcons equivalent) ──
const BG              = '#1C1A14';
const ACTIVE_COLOR    = '#fbbf24';   // amber-400
const INACTIVE_COLOR  = '#92400e';   // amber-900
const BORDER_COLOR    = 'rgba(120, 53, 15, 0.4)';
const CART_ACTIVE_BG  = '#f59e0b';   // amber-500
const CART_INACTIVE_BG = '#b45309';  // amber-700

// Icon mapping: Lucide → MaterialCommunityIcons
const ICON_MAP: Record<string, { active: string; inactive: string }> = {
  Home:    { active: 'home',                 inactive: 'home-outline'          },
  Search:  { active: 'magnify',              inactive: 'magnify'               },
  Cart:    { active: 'cart',                 inactive: 'cart-outline'          },
  Orders:  { active: 'clipboard-list',       inactive: 'clipboard-list-outline'},
  Profile: { active: 'account-circle',       inactive: 'account-circle-outline'},
};

interface TabConfig {
  route: string;
  label: string;
  isCenter?: boolean;
}

const TABS: TabConfig[] = [
  { route: 'Home',    label: 'Beranda'   },
  { route: 'Search',  label: 'Cari'      },
  { route: 'Cart',    label: 'Keranjang', isCenter: true },
  { route: 'Orders',  label: 'Pesanan'   },
  { route: 'Profile', label: 'Akun'      },
];

export default function CustomTabBar({ state, navigation }: BottomTabBarProps) {
  const insets      = useSafeAreaInsets();
  const activeRoute = state.routes[state.index]?.name;

  return (
    <View style={[styles.container, { paddingBottom: Math.max(insets.bottom, 4) }]}>
      {TABS.map((tab) => {
        const isFocused = activeRoute === tab.route;
        const icons     = ICON_MAP[tab.route] ?? { active: 'circle', inactive: 'circle-outline' };
        const iconName  = isFocused ? icons.active : icons.inactive;
        const onPress   = () => { if (!isFocused) navigation.navigate(tab.route); };

        // ── Keranjang: tombol bulat elevated ─────────────────────────────────
        if (tab.isCenter) {
          return (
            <TouchableOpacity
              key={tab.route}
              onPress={onPress}
              style={styles.centerWrapper}
              activeOpacity={0.85}
            >
              <View style={[
                styles.centerBtn,
                { backgroundColor: isFocused ? CART_ACTIVE_BG : CART_INACTIVE_BG },
              ]}>
                <Icon
                  name={iconName}
                  size={26}
                  color={BG}
                />
              </View>
              <Text style={[styles.label, { color: isFocused ? ACTIVE_COLOR : INACTIVE_COLOR }]}>
                {tab.label}
              </Text>
            </TouchableOpacity>
          );
        }

        // ── Tab biasa ─────────────────────────────────────────────────────────
        return (
          <TouchableOpacity
            key={tab.route}
            onPress={onPress}
            style={styles.tab}
            activeOpacity={0.7}
          >
            {/* Garis aktif di atas */}
            {isFocused && <View style={styles.activeBar} />}
            <Icon
              name={iconName}
              size={24}
              color={isFocused ? ACTIVE_COLOR : INACTIVE_COLOR}
            />
            <Text style={[styles.label, { color: isFocused ? ACTIVE_COLOR : INACTIVE_COLOR }]}>
              {tab.label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    backgroundColor: BG,
    borderTopWidth: 1,
    borderTopColor: BORDER_COLOR,
    height: 64,
    alignItems: 'flex-end',
  },

  // Tab biasa
  tab: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'flex-end',
    paddingBottom: 8,
    height: '100%',
    position: 'relative',
  },
  label: {
    fontSize: 10,
    fontWeight: '600',
    marginTop: 2,
  },
  activeBar: {
    position: 'absolute',
    top: 0,
    left: '15%',
    right: '15%',
    height: 2,
    backgroundColor: ACTIVE_COLOR,
    borderBottomLeftRadius: 2,
    borderBottomRightRadius: 2,
  },

  // Keranjang bulat
  centerWrapper: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'flex-end',
    paddingBottom: 8,
  },
  centerBtn: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: -20,
    marginBottom: 2,
    borderWidth: 1,
    borderColor: 'rgba(245, 158, 11, 0.5)',
    ...Platform.select({
      android: { elevation: 8 },
      ios: {
        shadowColor: '#92400e',
        shadowOffset: { width: 0, height: 3 },
        shadowOpacity: 0.6,
        shadowRadius: 6,
      },
    }),
  },
});
