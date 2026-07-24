/** Navigation type definitions */

export type MainTabParamList = {
  Home:    undefined;
  Search:  undefined;
  Cart:    undefined;
  Orders:  undefined;
  Profile: undefined;
};

/** Root stack — Tabs always rendered; Login/Register as modals */
export type RootStackParamList = {
  Tabs:     undefined;
  Login:    { redirect?: string } | undefined;
  Register: undefined;
};
