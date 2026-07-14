const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Khởi tạo app
initializeApp();
const db = getFirestore();

async function migrate() {
  const oldUid = 'Q3CA4EByn7MHVNgCTupZiFXwIdo1'; // UID seed
  const args = process.argv.slice(2);
  const newUid = args[0];

  if (!newUid) {
    console.error('Vui lòng cung cấp UID mới! Vd: node migrate_uid.js <NEW_UID>');
    process.exit(1);
  }

  console.log(`Bắt đầu chuyển dữ liệu từ ${oldUid} sang ${newUid}...`);

  const collections = ['chulop', 'lophoc', 'hocvien', 'buoihoc', 'diemdanh'];
  let totalMigrated = 0;

  for (const col of collections) {
    let snapshot;
    if (col === 'chulop') {
      const doc = await db.collection(col).doc(oldUid).get();
      if (doc.exists) {
        await db.collection(col).doc(newUid).set({
          ...doc.data(),
          uid: newUid
        });
        await db.collection(col).doc(oldUid).delete();
        console.log(`Đã chuyển chulop doc.`);
        totalMigrated++;
      }
    } else {
      snapshot = await db.collection(col).where('uidChuLop', '==', oldUid).get();
      const batch = db.batch();
      snapshot.docs.forEach(doc => {
        batch.update(doc.ref, { uidChuLop: newUid });
        totalMigrated++;
      });
      if (snapshot.size > 0) {
        await batch.commit();
        console.log(`Đã chuyển ${snapshot.size} documents trong ${col}`);
      }
    }
  }

  console.log(`Hoàn tất! Đã chuyển ${totalMigrated} documents sang UID ${newUid}.`);
}

migrate().catch(console.error);
