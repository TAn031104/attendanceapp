const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// Initialize Firebase Admin SDK
try {
  initializeApp();
} catch (error) {
  console.error("Firebase Admin SDK Initialization Error:");
  console.error("Please ensure GOOGLE_APPLICATION_CREDENTIALS is set or gcloud ADC is available.");
  process.exit(1);
}

const db = getFirestore();

// Parse command line arguments
const args = process.argv.slice(2);
const isExecute = args.includes('--execute');
const ownerUidArg = args.find(arg => arg.startsWith('--owner-uid='))?.split('=')[1];

async function verifyAccessAndGetOwner() {
  console.log("==================================================");
  console.log("PHASE 1 - VERIFY FIREBASE ACCESS");
  
  if (!process.env.GOOGLE_CLOUD_PROJECT) {
      console.log("Warning: Project ID may not be explicitly set. Make sure it defaults to attendanceapp-a6ac7.");
  }

  let ownerUid = ownerUidArg;
  
  if (!ownerUid) {
    try {
      const listUsersResult = await getAuth().listUsers(1);
      if (listUsersResult.users.length === 0) {
        console.error("No Firebase Auth users found! Please create a user or pass --owner-uid=<uid>");
        process.exit(1);
      }
      ownerUid = listUsersResult.users[0].uid;
      console.log(`Successfully verified Admin access. Using owner UID: ${ownerUid}`);
    } catch (error) {
      console.error("Failed to verify admin access:", error.message);
      console.error("\nSafest method to authenticate:");
      console.error("1. Run: gcloud auth application-default login");
      console.error("2. OR set GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json");
      process.exit(1);
    }
  } else {
      console.log(`Using provided owner UID: ${ownerUid}`);
  }
  
  return ownerUid;
}

function generateSampleData(ownerUid) {
  const now = Timestamp.now();
  const collections = {
    chulop: [],
    lophoc: [],
    hocvien: [],
    buoihoc: [],
    diemdanh: []
  };

  // 1. Owner
  collections.chulop.push({
    id: ownerUid,
    data: {
      uid: ownerUid,
      maChuLop: "CL001",
      hoTen: "Nguyễn Minh Anh",
      email: "minhanh.tutor@example.com",
      soDienThoai: "0900000000",
      tenCoSo: "Lớp học Minh Anh",
      ngayTao: now
    }
  });

  // 2. Classes
  const classes = [
    {
      id: "TOAN8_01",
      data: {
        maLop: "TOAN8_01",
        tenLop: "Toán lớp 8",
        monHoc: "Toán",
        moTa: "Ôn tập kiến thức và luyện bài nâng cao",
        uidChuLop: ownerUid,
        siSoToiDa: 15,
        hocPhi: 800000,
        donViHocPhi: "tháng",
        ngayBatDau: now,
        ngayKetThuc: null,
        trangThai: "Đang hoạt động",
        ngayTao: now,
        batBuocKiemTraViTri: true,
        banKinhChoPhep: 100
      }
    },
    {
      id: "ANH7_01",
      data: {
        maLop: "ANH7_01",
        tenLop: "Tiếng Anh lớp 7",
        monHoc: "Tiếng Anh",
        moTa: "Củng cố ngữ pháp và giao tiếp cơ bản",
        uidChuLop: ownerUid,
        siSoToiDa: 12,
        hocPhi: 700000,
        donViHocPhi: "tháng",
        ngayBatDau: now,
        ngayKetThuc: null,
        trangThai: "Đang hoạt động",
        ngayTao: now,
        batBuocKiemTraViTri: false,
        banKinhChoPhep: 100
      }
    },
    {
      id: "LY9_01",
      data: {
        maLop: "LY9_01",
        tenLop: "Vật lý lớp 9",
        monHoc: "Vật lý",
        moTa: "Ôn thi tuyển sinh lớp 10",
        uidChuLop: ownerUid,
        siSoToiDa: 10,
        hocPhi: 900000,
        donViHocPhi: "tháng",
        ngayBatDau: now,
        ngayKetThuc: null,
        trangThai: "Tạm dừng",
        ngayTao: now,
        batBuocKiemTraViTri: true,
        banKinhChoPhep: 150
      }
    }
  ];
  collections.lophoc = classes;

  // 3. Learners
  const hocvienList = [];
  const addHV = (maLop, index, status, email = null, phone = null, parent = null) => {
    const id = `HV${String(index).padStart(3, '0')}`;
    hocvienList.push({
      id: id,
      data: {
        maHocVien: id,
        hoTen: `Học Viên ${index}`,
        email: email,
        soDienThoai: phone,
        ngaySinh: null,
        maLop: maLop,
        uidChuLop: ownerUid,
        tenPhuHuynh: parent?.name || null,
        soDienThoaiPhuHuynh: parent?.phone || null,
        ghiChu: "",
        ngayThamGia: now,
        trangThai: status
      }
    });
  };

  // TOAN8_01: HV001-HV005
  addHV("TOAN8_01", 1, "Đang học", "hv001@example.com", "0900000001", {name: "Phụ Huynh 1", phone: "0910000001"});
  addHV("TOAN8_01", 2, "Đang học", "hv002@example.com", "0900000002");
  addHV("TOAN8_01", 3, "Tạm nghỉ", "hv003@example.com", "0900000003"); // One on break
  addHV("TOAN8_01", 4, "Đã nghỉ", null, null, null); // Null fields & dropped out
  addHV("TOAN8_01", 5, "Đang học", "hv005@example.com", "0900000005");
  
  // ANH7_01: HV006-HV009
  addHV("ANH7_01", 6, "Đang học", "hv006@example.com", "0900000006");
  addHV("ANH7_01", 7, "Đang học", "hv007@example.com", "0900000007");
  addHV("ANH7_01", 8, "Đang học", "hv008@example.com", "0900000008");
  addHV("ANH7_01", 9, "Đang học", "hv009@example.com", "0900000009");
  
  // LY9_01: HV010-HV012
  addHV("LY9_01", 10, "Đang học", "hv010@example.com", "0900000010");
  addHV("LY9_01", 11, "Đang học", "hv011@example.com", "0900000011");
  addHV("LY9_01", 12, "Đang học", "hv012@example.com", "0900000012");
  
  collections.hocvien = hocvienList;

  // 4. Sessions & Attendance
  const sessionData = [];
  const attendanceData = [];
  
  const generateSessions = (maLop, indexOffset, hasGPS) => {
    // 1 Past, 1 Today, 1 Cancelled/Future
    const statuses = ["Đã hoàn thành", "Sắp diễn ra", "Đã hủy"];
    const dates = [
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7 days ago
      new Date(), // today
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
    ];
    
    for (let i = 0; i < 3; i++) {
      const bhId = `${maLop}_B00${i + 1}`;
      sessionData.push({
        id: bhId,
        data: {
          maBuoiHoc: bhId,
          maLop: maLop,
          uidChuLop: ownerUid,
          ngayHoc: Timestamp.fromDate(dates[i]),
          gioBatDau: "18:00",
          gioKetThuc: "19:30",
          diaDiem: "Phòng A",
          viTriLop: hasGPS ? { latitude: 10.7725, longitude: 106.6578 } : null,
          noiDungBuoiHoc: `Bài học số ${i + 1}`,
          trangThai: statuses[i]
        }
      });
      
      // Attendance for completed session
      if (statuses[i] === "Đã hoàn thành") {
        const students = hocvienList.filter(hv => hv.data.maLop === maLop);
        const attendanceTypes = ["Có mặt", "Đi trễ", "Vắng", "Có phép"];
        students.forEach((sv, idx) => {
          const ddId = `${bhId}_${sv.id}`;
          attendanceData.push({
            id: ddId,
            data: {
              maHocVien: sv.id,
              maBuoiHoc: bhId,
              maLop: maLop,
              uidChuLop: ownerUid,
              trangThai: attendanceTypes[idx % 4],
              thoiGianDiemDanh: now,
              ghiChu: ""
            }
          });
        });
      }
    }
  };
  
  generateSessions("TOAN8_01", 0, true);
  generateSessions("ANH7_01", 3, false);
  generateSessions("LY9_01", 6, true);
  
  collections.buoihoc = sessionData;
  collections.diemdanh = attendanceData;
  
  return collections;
}

async function validateAndRun() {
  const ownerUid = await verifyAccessAndGetOwner();
  const data = generateSampleData(ownerUid);
  
  console.log("\n==================================================");
  console.log("PHASE 8 - DATA INTEGRITY VALIDATION");
  
  // Validation
  let hasError = false;
  const lophocIds = new Set(data.lophoc.map(l => l.id));
  const buoihocIds = new Set(data.buoihoc.map(b => b.id));
  const hocvienIds = new Set(data.hocvien.map(h => h.id));
  
  for (const l of data.lophoc) {
    if (l.data.uidChuLop !== ownerUid) { console.error(`Error: lophoc ${l.id} owner mismatch.`); hasError = true; }
  }
  for (const h of data.hocvien) {
    if (!lophocIds.has(h.data.maLop)) { console.error(`Error: hocvien ${h.id} references invalid class ${h.data.maLop}.`); hasError = true; }
    if (h.data.uidChuLop !== ownerUid) { console.error(`Error: hocvien ${h.id} owner mismatch.`); hasError = true; }
  }
  for (const b of data.buoihoc) {
    if (!lophocIds.has(b.data.maLop)) { console.error(`Error: buoihoc ${b.id} references invalid class ${b.data.maLop}.`); hasError = true; }
  }
  for (const d of data.diemdanh) {
    if (!hocvienIds.has(d.data.maHocVien)) { console.error(`Error: diemdanh ${d.id} references invalid hocvien.`); hasError = true; }
    if (!buoihocIds.has(d.data.maBuoiHoc)) { console.error(`Error: diemdanh ${d.id} references invalid buoihoc.`); hasError = true; }
  }
  
  if (hasError) {
    console.error("Integrity validation failed! Aborting.");
    process.exit(1);
  } else {
    console.log("Validation passed successfully.");
  }
  
  console.log("\n==================================================");
  console.log(`PHASE 9 - SCRIPT OUTPUT (${isExecute ? 'EXECUTE MODE' : 'DRY RUN MODE'})`);
  console.log(`Target project: ${process.env.GCLOUD_PROJECT || 'attendanceapp-a6ac7'}`);
  console.log(`Owner UID: ${ownerUid}`);
  
  let totalPlanned = 0;
  for (const [col, docs] of Object.entries(data)) {
    console.log(`Collection [${col}]: ${docs.length} documents planned.`);
    totalPlanned += docs.length;
  }
  console.log(`Total Planned Writes: ${totalPlanned}`);
  
  // Check existence
  let toCreate = [];
  let toSkip = [];
  
  for (const [colName, docs] of Object.entries(data)) {
    for (const doc of docs) {
      const docRef = db.collection(colName).doc(doc.id);
      const snap = await docRef.get();
      if (snap.exists) {
        toSkip.push({ col: colName, id: doc.id });
      } else {
        toCreate.push({ ref: docRef, data: doc.data, col: colName, id: doc.id });
      }
    }
  }
  
  console.log(`Documents already exist (will be skipped): ${toSkip.length}`);
  toSkip.forEach(s => console.log(`  - SKIP: ${s.col}/${s.id}`));
  
  if (!isExecute) {
    console.log("\nDRY RUN completed successfully. No data was written.");
    console.log("To execute, run: node scripts/seed_firestore.js --execute");
    process.exit(0);
  }
  
  console.log("\nStarting EXECUTION...");
  const startTime = Date.now();
  let successCount = 0;
  
  // Batch write
  for (let i = 0; i < toCreate.length; i += 500) {
    const chunk = toCreate.slice(i, i + 500);
    const batch = db.batch();
    chunk.forEach(op => {
      batch.set(op.ref, op.data);
    });
    await batch.commit();
    successCount += chunk.length;
  }
  
  const endTime = Date.now();
  console.log(`\nExecution Summary:`);
  console.log(`- Created documents: ${successCount}`);
  console.log(`- Skipped documents: ${toSkip.length}`);
  console.log(`- Time elapsed: ${(endTime - startTime) / 1000} seconds`);
}

validateAndRun().catch(err => {
  console.error("Fatal Error:", err);
  process.exit(1);
});
