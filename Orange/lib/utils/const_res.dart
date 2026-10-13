class ConstRes {
  ///------------------------ Backend urls and key ------------------------///

  // K09: real API base URL. NOTE: `base` must end with a trailing slash so
  // aBaseUrl == "<base>api/" and aImageBaseUrl == "<base>public/storage/".
  static const String base = 'https://ketua.sanaa.co/'; // Base url
  static const String aBaseUrl = '${base}api/';
  static const String aImageBaseUrl = '${base}public/storage/';

  // K09: shared app gate key (checkHeader). This is NOT authentication —
  // per-user auth uses the bearer token from /api/auth/* (see ApiProvider).
  // Rotate this together with the server's API_KEY env value.
  static const String apiKey = '328e40f3b646d2bc9120a9ff9935eb2598a74b5a8f38f173';

  ///------------------------ Agora app Id ------------------------///
  static const String agoraAppId = ""; // Agora app id
  static const String customerId = ""; // Agora customer id
  static const String customerSecret = ""; // Agora customer secret

  ///------------------------ RevenueCate ------------------------///
  static const String revenueCatAndroidApiKey = ""; // RevenueCat android api key
  static const String revenueCatAppleApiKey = ""; // RevenueCat apple api key
}
