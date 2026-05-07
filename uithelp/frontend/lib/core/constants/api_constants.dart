class Api {
  //static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  static const String baseUrl = 'http://localhost:3000/api'; // Web/iOS
  //static const String baseUrl   = 'http://192.168.20.31:3000/api'; // Mạng Lan LVAn

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String forgotPassword = '/auth/forgetPassword';
  static const String verifyForgotOtp = '/auth/verifyForgotOtp';
  static const String resetPassword = '/auth/resetPassword';
  static const String verifyRegisterOtp = '/auth/verifyRegisterOtp';

  //Post endpoints
  static const String createPost = "/posts/";
  static const String getPost = "/posts/";
  static const String getMyPosts = "/posts/my";
  static String updatePost(String id) => "/posts/$id";
  static String deletePost(String id) => "/posts/$id";
  static String getPostById(String id) => "/posts/$id";

  // FCM
  static const String updateFcmToken = "/auth/fcm-token";

  //Comment
  static const String createComment = "/comments/";
  static String getComment(String postId) => "/comments/$postId";
  static String deleteComment(String commentId) => "/comments/$commentId";

  //Match
  static const String getMyMatches = "/matches/";
  static const String createMatch = "/matches/";
  static String getSuggestedMatches(String postId) =>
      "/matches/suggest/$postId";
  static String getMatch(String id) => "/matches/$id";
  static String respondMatch(String id) => "/matches/$id/respond";
  static String closeMatch(String id) => "/matches/$id/close";

  // Locket
  static const String getLockets = "/lockets/";
  static const String getMyLockets = "/lockets/my";
  static const String createLocket = "/lockets/";
  static String deleteLocket(String id) => "/lockets/$id";
  static String reactLocket(String id) => "/lockets/$id/reactions";
  static String getLocketReactions(String id) => "/lockets/$id/reactions";
  static String commentLocket(String id) => "/lockets/$id/comments";
  static String getLocketComments(String id) => "/lockets/$id/comments";

  // Notifications
  static const String getNotifications = "/notifications";
  static const String getUnreadCount = "/notifications/unread-count";
  static const String markAllRead = "/notifications/read-all";
  static String markRead(String id) => "/notifications/$id/read";
  static String deleteNotification(String id) => "/notifications/$id";
  static const String deleteAllNotifications = "/notifications";

  // Conversations
  static const String getConversations = "/conversations";
  static const String createConversation = "/conversations";
  static String getMessages(String convId) => "/conversations/$convId/messages";
  static String sendMessage(String convId) => "/conversations/$convId/messages";
  static String markConvRead(String convId) => "/conversations/$convId/read";
  static String deleteMessage(String convId, String msgId) =>
      "/conversations/$convId/messages/$msgId";

  // Users
  static String getUserById(String id) => "/auth/users/$id";
}
