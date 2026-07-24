/** Navigation type definitions */

export type AuthStackParamList = {
  Login: undefined;
  Register: undefined;
};

export type MainTabParamList = {
  Home:    undefined;  // WebView buyer
  Orders:  undefined;  // WebView pesanan
  Upload:  undefined;  // Native kamera (seller only)
  Studio:  undefined;  // WebView studio seller
  Profile: undefined;  // Native profile
};

export type RootStackParamList = {
  Auth: undefined;
  Main: undefined;
};
