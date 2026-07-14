const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

try {
  initializeApp();
} catch (error) {
  console.error("Firebase Admin SDK Initialization Error:");
  process.exit(1);
}

const db = getFirestore();

const args = process.argv.slice(2);
const isExecute = args.includes('--execute');

async function cleanup() {
  console.log(`CLEANUP SCRIPT (${isExecute ? 'EXECUTE MODE' : 'DRY RUN MODE'})`);
  
  // Only delete documents with IDs matching our seed patterns
  const patterns = {
    chulop: doc => doc.id.length > 20, // UID length
    lophoc: doc => doc.id.endsWith('_01'),
    hocvien: doc => doc.id.startsWith('HV'),
    buoihoc: doc => doc.id.includes('_B00'),
    diemdanh: doc => doc.id.includes('_B00') && doc.id.includes('HV')
  };
  
  let toDelete = [];
  
  for (const [colName, checker] of Object.entries(patterns)) {
    const snap = await db.collection(colName).get();
    for (const doc of snap.docs) {
      if (checker(doc)) {
        toDelete.push({ ref: doc.ref, path: `${colName}/${doc.id}` });
      }
    }
  }
  
  console.log(`Found ${toDelete.length} documents matching seed data.`);
  
  if (!isExecute) {
    toDelete.forEach(d => console.log(`  - WILL DELETE: ${d.path}`));
    console.log("\nDRY RUN completed. Run with --execute to actually delete.");
    process.exit(0);
  }
  
  let deletedCount = 0;
  for (let i = 0; i < toDelete.length; i += 500) {
    const chunk = toDelete.slice(i, i + 500);
    const batch = db.batch();
    chunk.forEach(op => batch.delete(op.ref));
    await batch.commit();
    deletedCount += chunk.length;
  }
  
  console.log(`Successfully deleted ${deletedCount} documents.`);
}

cleanup().catch(err => console.error(err));
