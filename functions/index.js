const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.createUserWithRole = functions.https.onCall(async (data, context) => {
  // 1️⃣ Kiểm tra người gọi có phải là admin không
  const callerUid = context.auth?.uid;
  if (!callerUid) {
    throw new functions.https.HttpsError('unauthenticated', 'Bạn chưa đăng nhập.');
  }

  const callerDoc = await admin.firestore().collection('users').doc(callerUid).get();
  const callerRole = callerDoc.data()?.role;
  if (callerRole !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Chỉ admin mới có quyền tạo tài khoản.');
  }

  // 2️⃣ Lấy dữ liệu từ app gửi lên
  const { email, password, name, role } = data;
  if (!email || !password || !role) {
    throw new functions.https.HttpsError('invalid-argument', 'Thiếu thông tin người dùng.');
  }

  // 3️⃣ Tạo user trong Firebase Authentication
  const userRecord = await admin.auth().createUser({
    email: email,
    password: password,
  });

  // 4️⃣ Lưu role và thông tin vào Firestore
  await admin.firestore().collection('users').doc(userRecord.uid).set({
    name: name,
    email: email,
    role: role,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { message: `Tạo tài khoản ${role} thành công!` };
});
